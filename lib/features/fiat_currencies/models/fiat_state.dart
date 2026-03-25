import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:equatable/equatable.dart';

/// State representation for fiat currency feature
class FiatCurrencyState extends Equatable {
  const FiatCurrencyState({
    this.preferredCurrencyId,
    this.availableCurrencies = const <FiatCurrency>[],
    this.rates = const <String, double>{},
  });

  /// The user's preferred fiat currency ID (e.g. "USD").
  /// null means BTC-only mode (no fiat conversion).
  final String? preferredCurrencyId;

  /// All available fiat currencies from the SDK.
  final List<FiatCurrency> availableCurrencies;

  /// Currency ID to sats-per-unit exchange rate.
  final Map<String, double> rates;

  /// Returns the preferred [FiatCurrency] object, or null if none selected.
  FiatCurrency? get preferredCurrency {
    if (preferredCurrencyId == null) {
      return null;
    }
    try {
      return availableCurrencies.firstWhere(
        (FiatCurrency c) => c.id == preferredCurrencyId,
      );
    } catch (_) {
      return null;
    }
  }

  /// Returns the exchange rate for the preferred currency, or null.
  double? get preferredRate {
    if (preferredCurrencyId == null) {
      return null;
    }
    return rates[preferredCurrencyId];
  }

  FiatCurrencyState copyWith({
    String? Function()? preferredCurrencyId,
    List<FiatCurrency>? availableCurrencies,
    Map<String, double>? rates,
  }) {
    return FiatCurrencyState(
      preferredCurrencyId: preferredCurrencyId != null
          ? preferredCurrencyId()
          : this.preferredCurrencyId,
      availableCurrencies: availableCurrencies ?? this.availableCurrencies,
      rates: rates ?? this.rates,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        preferredCurrencyId,
        availableCurrencies,
        rates,
      ];
}
