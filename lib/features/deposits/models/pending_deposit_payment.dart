import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:equatable/equatable.dart';
import 'package:glow/logging/app_logger.dart';
import 'package:logger/logger.dart';

final Logger _log = AppLogger.getLogger('PendingDepositPayment');

/// Represents an unclaimed deposit as a pending payment
/// This allows deposits to appear in the payment list with "Waiting Fee Acceptance" status
class PendingDepositPayment extends Equatable {
  const PendingDepositPayment({
    required this.deposit,
    required this.requiredFeeSats,
    required this.requiredFeeRateSatPerVbyte,
    required this.isRejected,
  });

  /// The underlying deposit info
  final DepositInfo deposit;

  /// Required fee in sats (from claimError if present)
  final BigInt requiredFeeSats;

  /// Required fee rate in sat/vbyte (from claimError if present)
  final BigInt requiredFeeRateSatPerVbyte;

  /// Whether user has rejected this deposit's fee
  final bool isRejected;

  /// Unique identifier for this deposit (used for tracking rejection)
  String get id => '${deposit.txid}:${deposit.vout}';

  /// Amount in sats
  BigInt get amountSats => deposit.amountSats;

  /// Transaction ID
  String get txid => deposit.txid;

  /// Output index
  int get vout => deposit.vout;

  /// Get fee information from claim error if present
  static PendingDepositPayment? fromDepositInfo(DepositInfo deposit, {required bool isRejected}) {
    final String depositId = '${deposit.txid}:${deposit.vout}';

    // Check if deposit has a fee-related error
    final DepositClaimError? error = deposit.claimError;

    if (error == null) {
      // No error - can be auto-claimed, still show as pending for user awareness
      _log.d('Deposit $depositId has no claim error, can be auto-claimed');
      return PendingDepositPayment(
        deposit: deposit,
        requiredFeeSats: BigInt.zero,
        requiredFeeRateSatPerVbyte: BigInt.zero,
        isRejected: isRejected,
      );
    }

    return error.maybeWhen(
      maxDepositClaimFeeExceeded:
          (
            String tx,
            int vout,
            Fee? maxFee,
            BigInt requiredFeeSats,
            BigInt requiredFeeRateSatPerVbyte,
          ) {
            _log.w(
              'Deposit $depositId: maxDepositClaimFeeExceeded - '
              'requiredFee: $requiredFeeSats sats, '
              'feeRate: $requiredFeeRateSatPerVbyte sat/vByte, '
              'maxFee: $maxFee',
            );
            return PendingDepositPayment(
              deposit: deposit,
              requiredFeeSats: requiredFeeSats,
              requiredFeeRateSatPerVbyte: requiredFeeRateSatPerVbyte,
              isRejected: isRejected,
            );
          },
      orElse: () {
        // Other errors (missing UTXO, generic) - log them
        error.when(
          maxDepositClaimFeeExceeded:
              (
                String tx,
                int vout,
                Fee? maxFee,
                BigInt requiredFeeSats,
                BigInt requiredFeeRateSatPerVbyte,
              ) {
                // Already handled above
              },
          missingUtxo: (String tx, int vout) {
            _log.i('Deposit $depositId: missingUtxo - UTXO not yet visible on network');
          },
          generic: (String message) {
            _log.w('Deposit $depositId: generic error - $message');
          },
        );

        return PendingDepositPayment(
          deposit: deposit,
          requiredFeeSats: BigInt.zero,
          requiredFeeRateSatPerVbyte: BigInt.zero,
          isRejected: isRejected,
        );
      },
    );
  }

  /// Check if this deposit has a fee requirement
  bool get hasFeeRequirement =>
      requiredFeeSats > BigInt.zero || requiredFeeRateSatPerVbyte > BigInt.zero;

  @override
  List<Object?> get props => <Object?>[
    id,
    deposit,
    requiredFeeSats,
    requiredFeeRateSatPerVbyte,
    isRejected,
  ];
}
