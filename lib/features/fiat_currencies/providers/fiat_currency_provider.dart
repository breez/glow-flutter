import 'dart:async';

import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/features/fiat_currencies/models/fiat_state.dart';
import 'package:glow/logging/app_logger.dart';
import 'package:glow/providers/sdk_provider.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

final Logger _log = AppLogger.getLogger('FiatCurrencyProvider');

/// Legacy SharedPreferences key (single currency, for migration).
const String _legacyPreferredFiatCurrencyKey = 'preferred_fiat_currency';

/// SharedPreferences key for preferred fiat currency IDs (list).
const String _preferredFiatCurrenciesKey = 'preferred_fiat_currencies';

/// SharedPreferences key for the active dashboard currency index.
const String _activeCurrencyIndexKey = 'active_fiat_currency_index';

/// Duration between automatic exchange rate refreshes.
const Duration _rateRefreshInterval = Duration(seconds: 30);

/// Notifier that manages fiat currency state: available currencies, rates,
/// preferred currencies list, and the active currency for dashboard display.
class FiatCurrencyNotifier extends AsyncNotifier<FiatCurrencyState> {
  Timer? _rateRefreshTimer;

  @override
  Future<FiatCurrencyState> build() async {
    _log.d('FiatCurrencyNotifier: loading currencies and rates');

    final BreezSdk sdk = await ref.watch(sdkProvider.future);

    // Load currencies and rates in parallel
    final List<Object> results = await Future.wait(<Future<Object>>[
      sdk.listFiatCurrencies(),
      sdk.listFiatRates(),
    ]);

    final ListFiatCurrenciesResponse currenciesResponse =
        results[0] as ListFiatCurrenciesResponse;
    final ListFiatRatesResponse ratesResponse =
        results[1] as ListFiatRatesResponse;

    // Build rates map: currencyId -> sats-per-unit
    final Map<String, double> ratesMap = <String, double>{};
    for (final Rate rate in ratesResponse.rates) {
      ratesMap[rate.coin] = rate.value;
    }

    // Load saved preferences (with migration from legacy single-currency key)
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> preferredIds = await _loadPreferredCurrencies(prefs);
    final int activeIndex = prefs.getInt(_activeCurrencyIndexKey) ?? 0;

    _log.i(
      'FiatCurrencyNotifier: loaded ${currenciesResponse.currencies.length} '
      'currencies, ${ratesMap.length} rates, '
      'preferred=$preferredIds, activeIndex=$activeIndex',
    );

    // Start auto-refresh timer
    _startRateRefreshTimer();
    ref.onDispose(_stopRateRefreshTimer);

    return FiatCurrencyState(
      preferredCurrencyIds: preferredIds,
      activeCurrencyIndex: activeIndex,
      availableCurrencies: currenciesResponse.currencies,
      rates: ratesMap,
    );
  }

  /// Load preferred currencies from SharedPreferences, migrating from legacy
  /// single-currency key if needed.
  Future<List<String>> _loadPreferredCurrencies(
    SharedPreferences prefs,
  ) async {
    // Check for new key first
    final List<String>? savedList = prefs.getStringList(
      _preferredFiatCurrenciesKey,
    );
    if (savedList != null) {
      return savedList;
    }

    // Migrate from legacy single-currency key
    final String? legacyId = prefs.getString(_legacyPreferredFiatCurrencyKey);
    if (legacyId != null) {
      _log.i('Migrating legacy preferred currency: $legacyId');
      final List<String> migrated = <String>[legacyId];
      await prefs.setStringList(_preferredFiatCurrenciesKey, migrated);
      await prefs.remove(_legacyPreferredFiatCurrencyKey);
      return migrated;
    }

    // Default
    return kDefaultPreferredCurrencies;
  }

  void _startRateRefreshTimer() {
    _stopRateRefreshTimer();
    _rateRefreshTimer = Timer.periodic(_rateRefreshInterval, (_) {
      refreshRates();
    });
  }

  void _stopRateRefreshTimer() {
    _rateRefreshTimer?.cancel();
    _rateRefreshTimer = null;
  }

  /// Toggle a currency in/out of the preferred list.
  /// Prevents removing the last preferred currency.
  Future<void> toggleCurrency(String currencyId) async {
    final FiatCurrencyState currentState = state.requireValue;
    final List<String> currentIds = List<String>.from(
      currentState.preferredCurrencyIds,
    );

    if (currentIds.contains(currencyId)) {
      // Don't allow removing last currency
      if (currentIds.length <= 1) {
        _log.w('Cannot remove last preferred currency');
        return;
      }
      currentIds.remove(currencyId);
    } else {
      currentIds.add(currencyId);
    }

    await _savePreferredCurrencies(currentIds);

    // Clamp active index if needed
    final int safeIndex = currentState.activeCurrencyIndex.clamp(
      0,
      currentIds.length - 1,
    );

    state = AsyncValue<FiatCurrencyState>.data(
      currentState.copyWith(
        preferredCurrencyIds: currentIds,
        activeCurrencyIndex: safeIndex,
      ),
    );
  }

  /// Reorder preferred currencies (for drag-and-drop).
  Future<void> reorderCurrencies(int oldIndex, int newIndex) async {
    final FiatCurrencyState currentState = state.requireValue;
    final List<String> currentIds = List<String>.from(
      currentState.preferredCurrencyIds,
    );

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final String item = currentIds.removeAt(oldIndex);
    currentIds.insert(newIndex, item);

    await _savePreferredCurrencies(currentIds);

    state = AsyncValue<FiatCurrencyState>.data(
      currentState.copyWith(preferredCurrencyIds: currentIds),
    );
  }

  /// Cycle the dashboard currency to the next preferred currency.
  Future<void> cycleDashboardCurrency() async {
    final FiatCurrencyState currentState = state.requireValue;
    if (currentState.preferredCurrencyIds.isEmpty) {
      return;
    }

    final int nextIndex =
        (currentState.activeCurrencyIndex + 1) %
        currentState.preferredCurrencyIds.length;

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_activeCurrencyIndexKey, nextIndex);

    _log.d('Dashboard currency cycled to index $nextIndex');

    state = AsyncValue<FiatCurrencyState>.data(
      currentState.copyWith(activeCurrencyIndex: nextIndex),
    );
  }

  /// Fetch the latest exchange rates from the SDK.
  Future<void> refreshRates() async {
    if (!state.hasValue) {
      return;
    }

    _log.d('FiatCurrencyNotifier: refreshing rates');

    try {
      final BreezSdk sdk = await ref.read(sdkProvider.future);
      final ListFiatRatesResponse ratesResponse = await sdk.listFiatRates();

      final Map<String, double> ratesMap = <String, double>{};
      for (final Rate rate in ratesResponse.rates) {
        ratesMap[rate.coin] = rate.value;
      }

      final FiatCurrencyState currentState = state.requireValue;
      state = AsyncValue<FiatCurrencyState>.data(
        currentState.copyWith(rates: ratesMap),
      );

      _log.d('FiatCurrencyNotifier: refreshed ${ratesMap.length} rates');
    } catch (e) {
      _log.w('FiatCurrencyNotifier: rate refresh failed: $e');
    }
  }

  /// Convert sats to a formatted fiat string using the active preferred currency.
  /// Returns null if no preferred currency or rate is unavailable.
  String? formatSatsAsFiat(BigInt sats) {
    if (!state.hasValue) {
      return null;
    }
    final FiatCurrencyState currentState = state.requireValue;
    final String? currencyId = currentState.activeCurrencyId;
    if (currencyId == null) {
      return null;
    }
    return formatSatsAsFiatForCurrency(sats, currencyId);
  }

  /// Convert sats to a formatted fiat string for a specific currency.
  /// Returns null if the currency or rate is unavailable.
  String? formatSatsAsFiatForCurrency(BigInt sats, String currencyId) {
    if (!state.hasValue) {
      return null;
    }

    final FiatCurrencyState currentState = state.requireValue;
    final double? rate = currentState.rates[currencyId];
    if (rate == null || rate == 0) {
      return null;
    }

    FiatCurrency? currency;
    try {
      currency = currentState.availableCurrencies.firstWhere(
        (FiatCurrency c) => c.id == currencyId,
      );
    } catch (_) {
      return null;
    }

    // rate is sats-per-unit of fiat, so fiatValue = sats / rate
    final double fiatValue = sats.toDouble() / rate;
    final int fractionSize = currency.info.fractionSize;
    final String formattedValue = fiatValue.toStringAsFixed(fractionSize);

    // Use the currency symbol grapheme if available, otherwise use the ID
    final String symbol = currency.info.symbol?.grapheme ??
        currency.info.uniqSymbol?.grapheme ??
        currencyId;

    return '$symbol$formattedValue';
  }

  /// Convert a fiat amount to sats for a specific currency.
  /// Returns null if the currency or rate is unavailable.
  BigInt? fiatToSats(double fiatAmount, String currencyId) {
    if (!state.hasValue) {
      return null;
    }

    final FiatCurrencyState currentState = state.requireValue;
    final double? rate = currentState.rates[currencyId];
    if (rate == null || rate == 0) {
      return null;
    }

    // rate is sats-per-unit, so sats = fiatAmount * rate
    return BigInt.from((fiatAmount * rate).round());
  }

  Future<void> _savePreferredCurrencies(List<String> ids) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_preferredFiatCurrenciesKey, ids);
    _log.i('Preferred currencies saved: $ids');
  }
}

/// Provider for fiat currency state.
final AsyncNotifierProvider<FiatCurrencyNotifier, FiatCurrencyState>
    fiatCurrencyProvider =
    AsyncNotifierProvider<FiatCurrencyNotifier, FiatCurrencyState>(
  FiatCurrencyNotifier.new,
);
