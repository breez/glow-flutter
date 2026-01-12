import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';

/// Utility for parsing SDK error messages into user-friendly text
class ErrorParser {
  /// Parse SDK error and extract meaningful message
  static String parseError(Object error) {
    // Handle DepositClaimError specifically
    if (error is DepositClaimError) {
      return _parseDepositClaimError(error);
    }

    return _parseErrorString(error.toString());
  }

  /// Parse error string into user-friendly message
  static String _parseErrorString(String errorString) {
    // Check for dust limit error
    final RegExp dustLimitRegex = RegExp(
      r'utxo amount minus fees is less than the dust amount:\s*(\d+)',
      caseSensitive: false,
    );
    final Match? dustMatch = dustLimitRegex.firstMatch(errorString);
    if (dustMatch != null) {
      //final String dustAmount = dustMatch.group(1) ?? 'unknown';
      return 'Amount is too low to process.';
    }

    // Check for network/connection errors
    if (errorString.toLowerCase().contains('network') ||
        errorString.toLowerCase().contains('connection')) {
      return 'Please check your connection and try again.';
    }

    // Extract generic service error message
    final RegExp serviceErrorRegex = RegExp(
      r'service provider error:\s*graphql error:\s*(.+?)(?:\s*$)',
      caseSensitive: false,
    );
    final Match? serviceMatch = serviceErrorRegex.firstMatch(errorString);
    if (serviceMatch != null) {
      final String message = serviceMatch.group(1) ?? '';
      return message.trim();
    }

    // Extract SparkSdkError message
    final RegExp sparkErrorRegex = RegExp(r'SparkSdkError:\s*(.+?)(?:\s*$)', caseSensitive: false);
    final Match? sparkMatch = sparkErrorRegex.firstMatch(errorString);
    if (sparkMatch != null) {
      final String message = sparkMatch.group(1) ?? '';
      return message.trim();
    }

    // Fallback to original error message
    return errorString;
  }

  /// Parse DepositClaimError into user-friendly message
  static String _parseDepositClaimError(DepositClaimError error) {
    return error.when(
      maxDepositClaimFeeExceeded:
          (
            String tx,
            int vout,
            Fee? maxFee,
            BigInt requiredFeeSats,
            BigInt requiredFeeRateSatPerVbyte,
          ) {
            return 'Network fees have changed.';
          },
      missingUtxo: (String tx, int vout) {
        return 'On-chain transaction not yet confirmed on the blockchain.';
      },
      generic: (String message) {
        if (message.contains('Calculated fees exceed UTXO amount')) {
          return 'Amount is too low to cover the required network fees.';
        }
        // Parse the generic message for known patterns
        return _parseErrorString(message);
      },
    );
  }
}
