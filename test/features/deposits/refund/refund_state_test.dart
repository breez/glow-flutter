import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glow/features/deposits/refund/refund_state.dart';

void main() {
  group('RefundState', () {
    final DepositInfo mockDeposit = DepositInfo(
      txid: 'mock_txid',
      vout: 0,
      amountSats: BigInt.from(10000),
    );

    final RecommendedFees mockFees = RecommendedFees(
      fastestFee: BigInt.from(10), // 1800 sats total
      halfHourFee: BigInt.from(5), // 900 sats total
      hourFee: BigInt.from(2), // 360 sats total
      economyFee: BigInt.from(1), // 180 sats total
      minimumFee: BigInt.from(1),
    );

    group('State getters', () {
      test('RefundInitial - isInitial returns true', () {
        final RefundState state = RefundInitial(deposit: mockDeposit);
        expect(state.isInitial, isTrue);
        expect(state.isPreparing, isFalse);
        expect(state.isReady, isFalse);
      });

      test('RefundPreparing - isPreparing returns true', () {
        final RefundState state = RefundPreparing(
          deposit: mockDeposit,
          destinationAddress: 'bc1qtest',
        );
        expect(state.isPreparing, isTrue);
        expect(state.isInitial, isFalse);
        expect(state.isReady, isFalse);
      });

      test('RefundReady - isReady returns true', () {
        final RefundState state = RefundReady(
          deposit: mockDeposit,
          destinationAddress: 'bc1qtest',
          fees: mockFees,
        );
        expect(state.isReady, isTrue);
        expect(state.isInitial, isFalse);
      });

      test('RefundSuccess - isSuccess returns true', () {
        const RefundState state = RefundSuccess(txId: 'success_tx');
        expect(state.isSuccess, isTrue);
        expect(state.isError, isFalse);
      });

      test('RefundError - isError returns true and errorMessage is set', () {
        const RefundState state = RefundError(message: 'Test error');
        expect(state.isError, isTrue);
        expect(state.errorMessage, equals('Test error'));
      });
    });

    group('RefundReady - Fee calculations', () {
      late RefundReady state;

      setUp(() {
        state = RefundReady(
          deposit: mockDeposit,
          destinationAddress: 'bc1qtest',
          fees: mockFees,
        );
      });

      test('selectedFeeRate returns correct rate for economy', () {
        final RefundReady economyState = state.copyWith(selectedSpeed: RefundFeeSpeed.economy);
        expect(economyState.selectedFeeRate, equals(BigInt.from(2)));
      });

      test('selectedFeeRate returns correct rate for regular (default)', () {
        expect(state.selectedFeeRate, equals(BigInt.from(5)));
      });

      test('selectedFeeRate returns correct rate for priority', () {
        final RefundReady priorityState = state.copyWith(selectedSpeed: RefundFeeSpeed.priority);
        expect(priorityState.selectedFeeRate, equals(BigInt.from(10)));
      });

      test('estimatedFeeSats calculates correctly (180 vbytes)', () {
        // Default is regular: 5 sat/vbyte * 180 vbytes = 900 sats
        expect(state.estimatedFeeSats, equals(BigInt.from(900)));

        // Economy: 2 * 180 = 360
        final RefundReady economyState = state.copyWith(selectedSpeed: RefundFeeSpeed.economy);
        expect(economyState.estimatedFeeSats, equals(BigInt.from(360)));

        // Priority: 10 * 180 = 1800
        final RefundReady priorityState = state.copyWith(selectedSpeed: RefundFeeSpeed.priority);
        expect(priorityState.estimatedFeeSats, equals(BigInt.from(1800)));
      });

      test('getEstimatedFeeSatsForSpeed calculates for specific speed', () {
        expect(
          state.getEstimatedFeeSatsForSpeed(RefundFeeSpeed.economy),
          equals(BigInt.from(360)),
        );
        expect(
          state.getEstimatedFeeSatsForSpeed(RefundFeeSpeed.regular),
          equals(BigInt.from(900)),
        );
        expect(
          state.getEstimatedFeeSatsForSpeed(RefundFeeSpeed.priority),
          equals(BigInt.from(1800)),
        );
      });
    });

    group('RefundReady - Affordability', () {
      test('All speeds affordable with sufficient funds', () {
        final RefundReady state = RefundReady(
          deposit: mockDeposit, // 10000 sats
          destinationAddress: 'bc1qtest',
          fees: mockFees,
        );

        final Map<RefundFeeSpeed, bool> affordability = state.getAffordability();
        expect(affordability[RefundFeeSpeed.economy], isTrue);
        expect(affordability[RefundFeeSpeed.regular], isTrue);
        expect(affordability[RefundFeeSpeed.priority], isTrue);
      });

      test('Only economy affordable with limited funds', () {
        final DepositInfo smallDeposit = DepositInfo(
          txid: 'mock_txid',
          vout: 0,
          amountSats: BigInt.from(500), // 500 sats
        );

        final RefundReady state = RefundReady(
          deposit: smallDeposit,
          destinationAddress: 'bc1qtest',
          fees: mockFees,
        );

        final Map<RefundFeeSpeed, bool> affordability = state.getAffordability();
        expect(affordability[RefundFeeSpeed.economy], isTrue); // 360 sats
        expect(affordability[RefundFeeSpeed.regular], isFalse); // 900 sats
        expect(affordability[RefundFeeSpeed.priority], isFalse); // 1800 sats
      });

      test('No speeds affordable with insufficient funds', () {
        final DepositInfo tinyDeposit = DepositInfo(
          txid: 'mock_txid',
          vout: 0,
          amountSats: BigInt.from(100), // 100 sats
        );

        final RefundReady state = RefundReady(
          deposit: tinyDeposit,
          destinationAddress: 'bc1qtest',
          fees: mockFees,
        );

        final Map<RefundFeeSpeed, bool> affordability = state.getAffordability();
        expect(affordability[RefundFeeSpeed.economy], isFalse); // 360 > 100
        expect(affordability[RefundFeeSpeed.regular], isFalse);
        expect(affordability[RefundFeeSpeed.priority], isFalse);
      });

      test('Edge case: exactly enough for economy but not regular', () {
        final DepositInfo edgeCaseDeposit = DepositInfo(
          txid: 'mock_txid',
          vout: 0,
          amountSats: BigInt.from(400), // Between 360 and 900
        );

        final RefundReady state = RefundReady(
          deposit: edgeCaseDeposit,
          destinationAddress: 'bc1qtest',
          fees: mockFees,
        );

        final Map<RefundFeeSpeed, bool> affordability = state.getAffordability();
        expect(affordability[RefundFeeSpeed.economy], isTrue); // 400 > 360
        expect(affordability[RefundFeeSpeed.regular], isFalse); // 400 < 900
        expect(affordability[RefundFeeSpeed.priority], isFalse);
      });
    });

    group('RefundReady - copyWith', () {
      test('copyWith updates selected fee speed', () {
        final RefundReady state = RefundReady(
          deposit: mockDeposit,
          destinationAddress: 'bc1qtest',
          fees: mockFees,
          selectedSpeed: RefundFeeSpeed.regular,
        );

        final RefundReady updated = state.copyWith(selectedSpeed: RefundFeeSpeed.priority);
        expect(updated.selectedSpeed, equals(RefundFeeSpeed.priority));
        expect(updated.deposit, equals(state.deposit));
        expect(updated.destinationAddress, equals(state.destinationAddress));
        expect(updated.fees, equals(state.fees));
      });
    });
  });
}
