import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/providers/sdk_provider.dart';

/// Service for handling deposit claim operations
class DepositClaimer {
  const DepositClaimer();

  /// Claims a deposit through the SDK
  Future<void> claimDeposit(WidgetRef ref, DepositInfo deposit) async {
    await ref.read(claimDepositProvider(deposit).future);
  }

  /// Formats transaction ID for display (shortened)
  String formatTxid(String txid) {
    if (txid.length <= 16) {
      return txid;
    }
    return '${txid.substring(0, 8)}...${txid.substring(txid.length - 8)}';
  }

  /// Formats deposit claim error for user-friendly display
  /// Pass currentFee to check if the error is still valid with current settings
  String formatError(DepositClaimError error, {MaxFee? currentFee}) {
    return error.when(
      maxDepositClaimFeeExceeded:
          (
            String tx,
            int vout,
            Fee? maxFee,
            BigInt requiredFeeSats,
            BigInt requiredFeeRateSatPerVbyte,
          ) {
            // Check if current fee is sufficient
            if (currentFee != null) {
              final bool isFeeSufficient = currentFee.when(
                rate: (BigInt rate) => rate >= requiredFeeRateSatPerVbyte,
                fixed: (BigInt fixed) => fixed >= requiredFeeSats,
                networkRecommended: (BigInt leewaySatPerVbyte) =>
                    leewaySatPerVbyte >= requiredFeeRateSatPerVbyte,
              );

              if (isFeeSufficient) {
                return 'Ready to claim. Tap "CLAIM" to proceed.';
              }
            }

            return 'Fee too low to claim. Tap "CLAIM" to increase your fee limit.';
          },
      missingUtxo: (String tx, int vout) => 'Transaction output not found on chain',
      generic: (String message) {
        // Handle specific generic error cases with user-friendly messages
        if (message.contains('Calculated fees exceed UTXO amount')) {
          return 'Amount too small to cover fees. Tap "REFUND" to recover on-chain.';
        }
        // For other generic errors, return the original message
        return message;
      },
    );
  }

  /// Formats max fee for display
  String formatMaxFee(Fee maxFee) {
    return maxFee.when(
      fixed: (BigInt amount) => '$amount sats',
      rate: (BigInt rate) => '~${99 * rate.toInt()} sats ($rate sat/vByte)',
    );
  }

  /// Checks if deposit has an error
  bool hasError(DepositInfo deposit) {
    return deposit.claimError != null;
  }

  /// Checks if deposit has a refund transaction
  bool hasRefund(DepositInfo deposit) {
    return deposit.refundTx != null;
  }
}

/// Provider for the deposit claimer service
final Provider<DepositClaimer> depositClaimerProvider = Provider<DepositClaimer>((Ref ref) {
  return const DepositClaimer();
});
