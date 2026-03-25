import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart' as breez_sdk_spark show defaultConfig;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/config/app_config.dart';
import 'package:glow/logging/app_logger.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

final Logger log = AppLogger.getLogger('ConfigService');

/// Service for managing persistent app configuration
class ConfigService {
  static const String _maxDepositClaimFeeTypeKey = 'max_deposit_claim_fee_type';
  static const String _maxDepositClaimFeeValueKey = 'max_deposit_claim_fee_value';

  /// Default max deposit claim fee from SDK
  static final MaxFee defaultMaxDepositClaimFee = MaxFee.rate(satPerVbyte: BigInt.one);

  final SharedPreferences _prefs;

  ConfigService(this._prefs);

  /// Get the current max deposit claim fee
  /// Returns the persisted value or default if not set
  MaxFee getMaxDepositClaimFee() {
    final String? type = _prefs.getString(_maxDepositClaimFeeTypeKey);
    final String? value = _prefs.getString(_maxDepositClaimFeeValueKey);

    if (type == null || value == null) {
      log.d('No persisted max deposit claim fee, using SDK default');
      return defaultMaxDepositClaimFee;
    }

    try {
      final BigInt feeValue = BigInt.parse(value);
      if (type == 'rate') {
        log.d('Loaded max deposit claim fee: rate=$feeValue sat/vByte');
        return MaxFee.rate(satPerVbyte: feeValue);
      } else if (type == 'fixed') {
        log.d('Loaded max deposit claim fee: fixed=$feeValue sats');
        return MaxFee.fixed(amount: feeValue);
      } else if (type == 'networkRecommended') {
        log.d('Loaded max deposit claim fee: networkRecommended=$feeValue sats');
        return MaxFee.networkRecommended(leewaySatPerVbyte: feeValue);
      }
    } catch (e) {
      log.e('Failed to parse persisted fee, using SDK default: $e');
    }

    return defaultMaxDepositClaimFee;
  }

  /// Set the max deposit claim fee and persist it
  Future<void> setMaxDepositClaimFee(MaxFee fee) async {
    final Future<Null> result = fee.when(
      rate: (BigInt satPerVbyte) async {
        await _prefs.setString(_maxDepositClaimFeeTypeKey, 'rate');
        await _prefs.setString(_maxDepositClaimFeeValueKey, satPerVbyte.toString());
        log.i('Saved max deposit claim fee: rate=$satPerVbyte sat/vByte');
      },
      fixed: (BigInt amount) async {
        await _prefs.setString(_maxDepositClaimFeeTypeKey, 'fixed');
        await _prefs.setString(_maxDepositClaimFeeValueKey, amount.toString());
        log.i('Saved max deposit claim fee: fixed=$amount sats');
      },
      networkRecommended: (BigInt leewaySatPerVbyte) async {
        await _prefs.setString(_maxDepositClaimFeeTypeKey, 'networkRecommended');
        await _prefs.setString(_maxDepositClaimFeeValueKey, leewaySatPerVbyte.toString());
        log.i('Saved max deposit claim fee: rate=$leewaySatPerVbyte sat/vByte');
      },
    );
    await result;
  }

  /// Reset to default fee
  Future<void> resetMaxDepositClaimFee() async {
    await _prefs.remove(_maxDepositClaimFeeTypeKey);
    await _prefs.remove(_maxDepositClaimFeeValueKey);
    log.i('Reset max deposit claim fee to default');
  }

  /// Create a Config instance for the given network
  /// Merges SDK defaults with app-specific config and user preferences
  Config createConfig({required Network network, MaxFee? maxDepositClaimFee}) {
    // Get SDK defaults for the network
    final Config networkDefaults = breez_sdk_spark.defaultConfig(network: network);

    // Use provided fee, or user's saved preference, or network default
    final MaxFee effectiveFee = maxDepositClaimFee ?? getMaxDepositClaimFee();

    return Config(
      apiKey: AppConfig.apiKey,
      network: network,
      syncIntervalSecs: networkDefaults.syncIntervalSecs,
      maxDepositClaimFee: effectiveFee,
      lnurlDomain: AppConfig.lnurlDomain,
      preferSparkOverLightning: networkDefaults.preferSparkOverLightning,
      useDefaultExternalInputParsers: networkDefaults.useDefaultExternalInputParsers,
      privateEnabledDefault: networkDefaults.privateEnabledDefault,
      optimizationConfig: networkDefaults.optimizationConfig,
      maxConcurrentClaims: networkDefaults.maxConcurrentClaims,
    );
  }
}

/// Provider for ConfigService
final Provider<ConfigService> configServiceProvider = Provider<ConfigService>((Ref ref) {
  throw UnimplementedError('ConfigService must be overridden in main.dart with SharedPreferences');
});
