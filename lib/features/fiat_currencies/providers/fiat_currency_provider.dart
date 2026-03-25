import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/features/fiat_currencies/models/fiat_state.dart';
import 'package:glow/logging/app_logger.dart';
import 'package:glow/providers/sdk_provider.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

final Logger _log = AppLogger.getLogger('FiatCurrencyProvider');

/// SharedPreferences key for the user's preferred fiat currency.
const String _preferredFiatCurrencyKey = 'preferred_fiat_currency';

/// Notifier that manages fiat currency state: available currencies, rates,
/// and the user's preferred currency selection.
class FiatCurrencyNotifier extends AsyncNotifier<FiatCurrencyState> {
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

    // Load saved preference
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? savedCurrencyId = prefs.getString(_preferredFiatCurrencyKey);

    _log.i(
      'FiatCurrencyNotifier: loaded ${currenciesResponse.currencies.length} '
      'currencies, ${ratesMap.length} rates, preferred=$savedCurrencyId',
    );

    return FiatCurrencyState(
      preferredCurrencyId: savedCurrencyId,
      availableCurrencies: currenciesResponse.currencies,
      rates: ratesMap,
    );
  }

  /// Set the preferred fiat currency. Pass null to use BTC-only mode.
  Future<void> setPreferredCurrency(String? currencyId) async {
    final FiatCurrencyState currentState = state.requireValue;

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (currencyId == null) {
      await prefs.remove(_preferredFiatCurrencyKey);
    } else {
      await prefs.setString(_preferredFiatCurrencyKey, currencyId);
    }

    _log.i('FiatCurrencyNotifier: preferred currency set to $currencyId');

    state = AsyncValue<FiatCurrencyState>.data(
      currentState.copyWith(preferredCurrencyId: () => currencyId),
    );
  }

  /// Fetch the latest exchange rates from the SDK.
  Future<void> refreshRates() async {
    _log.d('FiatCurrencyNotifier: refreshing rates');

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

    _log.i('FiatCurrencyNotifier: refreshed ${ratesMap.length} rates');
  }

  /// Convert sats to a formatted fiat string using the preferred currency.
  /// Returns null if no preferred currency or rate is unavailable.
  String? formatSatsAsFiat(BigInt sats) {
    if (!state.hasValue) {
      return null;
    }

    final FiatCurrencyState currentState = state.requireValue;
    final String? currencyId = currentState.preferredCurrencyId;
    if (currencyId == null) {
      return null;
    }

    final double? rate = currentState.rates[currencyId];
    if (rate == null || rate == 0) {
      return null;
    }

    final FiatCurrency? currency = currentState.preferredCurrency;
    if (currency == null) {
      return null;
    }

    // rate is sats-per-unit of fiat, so fiatValue = sats / rate
    final double fiatValue = sats.toDouble() / rate;
    final int fractionSize = currency.info.fractionSize;
    final String formattedValue = fiatValue.toStringAsFixed(fractionSize);

    // Use the currency symbol grapheme if available, otherwise use the ID
    final String symbol =
        currency.info.symbol?.grapheme ?? currency.info.uniqSymbol?.grapheme ?? currencyId;

    return '$symbol$formattedValue';
  }
}

/// Provider for fiat currency state.
final AsyncNotifierProvider<FiatCurrencyNotifier, FiatCurrencyState>
    fiatCurrencyProvider =
    AsyncNotifierProvider<FiatCurrencyNotifier, FiatCurrencyState>(
  FiatCurrencyNotifier.new,
);
