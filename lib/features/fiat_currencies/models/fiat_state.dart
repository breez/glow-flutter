import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:equatable/equatable.dart';

/// Default preferred currencies matching misty-breez.
const List<String> kDefaultPreferredCurrencies = <String>[
  'USD',
  'EUR',
  'GBP',
  'JPY',
];

/// State representation for fiat currency feature.
/// Supports multiple preferred currencies with reordering.
class FiatCurrencyState extends Equatable {
  const FiatCurrencyState({
    this.preferredCurrencyIds = kDefaultPreferredCurrencies,
    this.activeCurrencyIndex = 0,
    this.availableCurrencies = const <FiatCurrency>[],
    this.rates = const <String, double>{},
  });

  /// Ordered list of preferred fiat currency IDs (e.g. ['USD', 'EUR']).
  /// Empty list means BTC-only mode (no fiat conversion).
  final List<String> preferredCurrencyIds;

  /// Index of the currently active preferred currency (for dashboard display).
  final int activeCurrencyIndex;

  /// All available fiat currencies from the SDK.
  final List<FiatCurrency> availableCurrencies;

  /// Currency ID to sats-per-unit exchange rate.
  final Map<String, double> rates;

  /// Returns the active preferred currency ID, or null if none.
  String? get activeCurrencyId {
    if (preferredCurrencyIds.isEmpty) {
      return null;
    }
    final int safeIndex = activeCurrencyIndex.clamp(
      0,
      preferredCurrencyIds.length - 1,
    );
    return preferredCurrencyIds[safeIndex];
  }

  /// Returns the active [FiatCurrency] object, or null if none selected.
  FiatCurrency? get preferredCurrency {
    final String? id = activeCurrencyId;
    if (id == null) {
      return null;
    }
    try {
      return availableCurrencies.firstWhere(
        (FiatCurrency c) => c.id == id,
      );
    } catch (_) {
      return null;
    }
  }

  /// Returns the exchange rate for the active preferred currency, or null.
  double? get preferredRate {
    final String? id = activeCurrencyId;
    if (id == null) {
      return null;
    }
    return rates[id];
  }

  /// Returns the list of preferred [FiatCurrency] objects (in order).
  List<FiatCurrency> get preferredCurrencies {
    return preferredCurrencyIds
        .map((String id) {
          try {
            return availableCurrencies.firstWhere(
              (FiatCurrency c) => c.id == id,
            );
          } catch (_) {
            return null;
          }
        })
        .whereType<FiatCurrency>()
        .toList();
  }

  /// Whether a given currency ID is in the preferred list.
  bool isPreferred(String currencyId) {
    return preferredCurrencyIds.contains(currencyId);
  }

  FiatCurrencyState copyWith({
    List<String>? preferredCurrencyIds,
    int? activeCurrencyIndex,
    List<FiatCurrency>? availableCurrencies,
    Map<String, double>? rates,
  }) {
    return FiatCurrencyState(
      preferredCurrencyIds: preferredCurrencyIds ?? this.preferredCurrencyIds,
      activeCurrencyIndex: activeCurrencyIndex ?? this.activeCurrencyIndex,
      availableCurrencies: availableCurrencies ?? this.availableCurrencies,
      rates: rates ?? this.rates,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        preferredCurrencyIds,
        activeCurrencyIndex,
        availableCurrencies,
        rates,
      ];
}
