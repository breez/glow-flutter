import 'dart:io' show Platform;
import 'dart:ui';

import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:glow/config/app_config.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Bitcoin balance units
enum BalanceUnit { sats, btc }

/// Service for formatting transaction/payment-related values and dates
/// Following Inversion of Control principle
class TransactionFormatter {
  const TransactionFormatter();

  static final DateFormat _monthDateFormat = DateFormat.Md(Platform.localeName);
  static final DateFormat _yearMonthDayFormat = DateFormat.yMd(Platform.localeName);
  static final DateFormat _yearMonthDayHourMinuteFormat = DateFormat.yMd(
    Platform.localeName,
  ).add_jm();
  static final DateFormat _hourMinuteDayFormat = DateFormat.jm(Platform.localeName);

  // Bitcoin conversion constants
  static const int _satoshisPerBitcoin = 100000000;

  static final NumberFormat _satsFormat = NumberFormat.decimalPattern(Platform.localeName);

  /// Formats sats with locale-aware thousand separators
  String formatSats(BigInt sats) {
    return _satsFormat.format(sats.toInt());
  }

  /// Formats sats to BTC with proper decimal places (8 decimals)
  String formatBtc(BigInt sats) {
    final double btc = sats.toDouble() / _satoshisPerBitcoin;
    return btc.toStringAsFixed(8);
  }

  /// Formats balance with currency unit
  String formatBalance(BigInt sats, {BalanceUnit unit = BalanceUnit.sats}) {
    return switch (unit) {
      BalanceUnit.sats => '${formatSats(sats)} sats',
      BalanceUnit.btc => '${formatBtc(sats)} BTC',
    };
  }

  /// Converts sats to fiat using exchange rate with locale-aware formatting
  String formatFiat(BigInt sats, double exchangeRate, String currencyCode) {
    final double btc = sats.toDouble() / _satoshisPerBitcoin;
    final double fiatValue = btc * exchangeRate;
    try {
      final NumberFormat fiatFormat = NumberFormat.simpleCurrency(
        locale: Platform.localeName,
        name: currencyCode,
      );
      return fiatFormat.format(fiatValue);
    } catch (_) {
      return '${fiatValue.toStringAsFixed(2)} $currencyCode';
    }
  }

  /// Parses a string amount to satoshis
  /// Handles both BTC and SAT formats
  BigInt parseSats(String amount, {BalanceUnit unit = BalanceUnit.sats}) {
    if (amount.isEmpty) {
      return BigInt.zero;
    }

    final String cleaned = amount.replaceAll(RegExp(r'[^\d.]'), '');
    final double parsed = double.tryParse(cleaned) ?? 0;

    return switch (unit) {
      BalanceUnit.sats => BigInt.from(parsed.toInt()),
      BalanceUnit.btc => BigInt.from((parsed * _satoshisPerBitcoin).toInt()),
    };
  }

  /// Formats payment status for display
  String formatStatus(PaymentStatus status) {
    return switch (status) {
      PaymentStatus.completed => 'Completed',
      PaymentStatus.pending => 'Pending',
      PaymentStatus.failed => 'Failed',
    };
  }

  /// Formats payment type for display
  String formatType(PaymentType type) {
    return switch (type) {
      PaymentType.send => 'Send',
      PaymentType.receive => 'Receive',
    };
  }

  /// Formats payment method for display
  String formatMethod(PaymentMethod method) {
    return switch (method) {
      PaymentMethod.lightning => 'Lightning',
      PaymentMethod.spark => 'Spark',
      PaymentMethod.token => 'Token',
      PaymentMethod.deposit => 'Deposit',
      PaymentMethod.withdraw => 'Withdraw',
      PaymentMethod.unknown => 'Unknown',
    };
  }

  /// Formats timestamp to relative time (e.g., "2 hours ago")
  /// Uses relative format for dates within 4 days, otherwise shows full date
  String formatRelativeTime(BigInt timestamp) {
    final DateTime date = _toDateTime(timestamp);
    final DateTime fourDaysAgo = DateTime.now().subtract(const Duration(days: 4));

    if (fourDaysAgo.isBefore(date)) {
      return timeago.format(date, locale: _getSystemLocale().languageCode);
    } else {
      return formatYearMonthDay(date);
    }
  }

  /// Formats full timestamp as year/month/day
  String formatYearMonthDay(DateTime date) => _yearMonthDayFormat.format(date);

  /// Formats full timestamp as month/day
  String formatMonthDate(DateTime date) => _monthDateFormat.format(date);

  /// Formats full timestamp as year, month, day, hour, and minute
  String formatYearMonthDayHourMinute(DateTime date) =>
      _yearMonthDayHourMinuteFormat.format(date).replaceAll(' ', ' ');

  /// Formats time as hour and minute
  String formatHourMinute(DateTime date) => _hourMinuteDayFormat.format(date);

  /// Formats full datetime for display
  String formatDateTime(BigInt timestamp) {
    final DateTime date = _toDateTime(timestamp);
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Gets a short description for payment details
  String getShortDescription(PaymentDetails? details) {
    if (details == null) {
      return '';
    }

    return switch (details) {
      PaymentDetails_Lightning(:final String? description) => description ?? '',
      PaymentDetails_Token(:final TokenMetadata metadata) => metadata.name,
      PaymentDetails_Withdraw() => 'On-chain withdrawal',
      PaymentDetails_Deposit() => 'On-chain deposit',
      PaymentDetails_Spark() => 'Spark payment',
    };
  }

  /// Formats amount with sign based on payment type
  String formatAmountWithSign(BigInt amount, PaymentType type) {
    final String formattedAmount = formatSats(amount);
    return switch (type) {
      PaymentType.send => '- $formattedAmount',
      PaymentType.receive => '+ $formattedAmount',
    };
  }

  /// Converts BigInt timestamp (seconds) to DateTime
  /// Assumes timestamp is in seconds since epoch
  DateTime _toDateTime(BigInt timestamp) {
    return DateTime.fromMillisecondsSinceEpoch(timestamp.toInt() * 1000);
  }

  /// Gets the system locale for date/time formatting
  Locale _getSystemLocale() {
    try {
      final List<String> parts = Platform.localeName.split('_');
      return Locale(parts[0], parts.length > 1 ? parts[1] : null);
    } catch (e) {
      final List<String> defaultLocaleParts = AppConfig.defaultLocale.split('_');
      final String defaultLocaleCode = defaultLocaleParts[0];
      final String? countryCode = defaultLocaleParts.length > 1 ? defaultLocaleParts[1] : null;
      return Locale(defaultLocaleCode, countryCode);
    }
  }

  /// Sets up locale messages for the timeago package
  /// Call this during app initialization
  static void setupLocales() {
    timeago.setLocaleMessages('en', timeago.EnMessages());
    timeago.setLocaleMessages('bg', timeago.EnMessages());
    timeago.setLocaleMessages('cs', timeago.CsMessages());
    timeago.setLocaleMessages('de', timeago.DeMessages());
    timeago.setLocaleMessages('el', timeago.GrMessages());
    timeago.setLocaleMessages('es', timeago.EsMessages());
    timeago.setLocaleMessages('fi', timeago.FiMessages());
    timeago.setLocaleMessages('fr', timeago.FrMessages());
    timeago.setLocaleMessages('it', timeago.ItMessages());
    timeago.setLocaleMessages('pt', timeago.PtBrMessages());
    timeago.setLocaleMessages('sk', timeago.EnMessages());
    timeago.setLocaleMessages('sv', timeago.SvMessages());
  }
}

extension LocaleExt on Locale {
  String get languageCode => _languageCode;

  String get _languageCode {
    if (countryCode != null) {
      return '${languageCode}_${countryCode!}'.toLowerCase();
    }
    return languageCode.toLowerCase();
  }
}
