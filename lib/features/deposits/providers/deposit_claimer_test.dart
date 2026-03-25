import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glow/features/deposits/providers/deposit_claimer.dart';

void main() {
  late DepositClaimer claimer;
  setUp(() {
    claimer = const DepositClaimer();
  });

  group('formatTxid', () {
    final List<String> shortTxids = <String>['short', '1234567890123456'];
    for (final String txid in shortTxids) {
      test('returns full txid for "$txid"', () {
        expect(claimer.formatTxid(txid), txid);
      });
    }

    test('returns shortened txid when length > 16', () {
      const String longTxid = '1234567890abcdefghijklmnopqrstuvwxyz';
      final String result = claimer.formatTxid(longTxid);
      expect(result, '12345678...stuvwxyz');
      expect(result.length, 19); // 8 + 3 + 8
    });
  });

  group('hasError', () {
    test('true when deposit has claim error', () {
      final DepositInfo deposit = _createMockDeposit(
        claimError: const DepositClaimError.missingUtxo(tx: 'test', vout: 0),
      );
      expect(claimer.hasError(deposit), true);
    });
    test('false when deposit has no claim error', () {
      final DepositInfo deposit = _createMockDeposit();
      expect(claimer.hasError(deposit), false);
    });
  });

  group('hasRefund', () {
    test('true when deposit has refund transaction', () {
      final DepositInfo deposit = _createMockDeposit(refundTx: 'refund_tx_data');
      expect(claimer.hasRefund(deposit), true);
    });
    test('false when deposit has no refund transaction', () {
      final DepositInfo deposit = _createMockDeposit();
      expect(claimer.hasRefund(deposit), false);
    });
  });

  group('formatError', () {
    test('depositClaimFeeExceeded with fixed max fee', () {
      final DepositClaimError error = DepositClaimError.maxDepositClaimFeeExceeded(
        tx: 'test',
        vout: 0,
        maxFee: Fee.fixed(amount: BigInt.from(1000)),
        requiredFeeSats: BigInt.from(1500),
        requiredFeeRateSatPerVbyte: BigInt.from(15),
      );
      final String result = claimer.formatError(error);
      expect(result, contains('1500 sats needed'));
      expect(result, contains('your max: 1000 sats'));
      expect(result, contains('Retry Claim'));
    });
    test('depositClaimFeeExceeded with rate max fee', () {
      final DepositClaimError error = DepositClaimError.maxDepositClaimFeeExceeded(
        tx: 'test',
        vout: 0,
        maxFee: Fee.rate(satPerVbyte: BigInt.from(10)),
        requiredFeeSats: BigInt.from(1500),
        requiredFeeRateSatPerVbyte: BigInt.from(15),
      );
      final String result = claimer.formatError(error);
      expect(result, contains('1500 sats needed'));
      expect(result, contains('your max: ~990 sats (10 sat/vByte)'));
    });
    test('missingUtxo error', () {
      final DepositClaimError error = const DepositClaimError.missingUtxo(tx: 'test', vout: 0);
      expect(claimer.formatError(error), 'Transaction output not found on chain');
    });
    test('generic error', () {
      final DepositClaimError error = const DepositClaimError.generic(
        message: 'Custom error message',
      );
      expect(claimer.formatError(error), 'Custom error message');
    });
  });

  group('formatMaxFee', () {
    test('fixed max fee', () {
      final Fee maxFee = Fee.fixed(amount: BigInt.from(2000));
      expect(claimer.formatMaxFee(maxFee), '2000 sats');
    });
    test('rate max fee', () {
      final Fee maxFee = Fee.rate(satPerVbyte: BigInt.from(15));
      expect(claimer.formatMaxFee(maxFee), '~1485 sats (15 sat/vByte)');
    });
  });
}

// Helper function to create mock DepositInfo
DepositInfo _createMockDeposit({
  String? txid,
  int? vout,
  BigInt? amountSats,
  DepositClaimError? claimError,
  String? refundTx,
  String? refundTxId,
}) {
  return DepositInfo(
    txid: txid ?? 'test_txid',
    vout: vout ?? 0,
    amountSats: amountSats ?? BigInt.from(10000),
    claimError: claimError,
    refundTx: refundTx,
    refundTxId: refundTxId,
  );
}
