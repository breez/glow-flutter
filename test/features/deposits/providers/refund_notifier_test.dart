import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glow/features/deposits/providers/refund_provider.dart';
import 'package:glow/features/deposits/refund/refund_state.dart';
import 'package:glow/providers/sdk_provider.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'refund_notifier_test.mocks.dart';

@GenerateMocks(<Type>[BreezSdk])
void main() {
  group('RefundNotifier', () {
    late MockBreezSdk mockSdk;
    late ProviderContainer container;
    late DepositInfo mockDeposit;

    setUp(() {
      mockSdk = MockBreezSdk();
      mockDeposit = DepositInfo(
        txid: 'test_txid',
        vout: 0,
        amountSats: BigInt.from(10000),
      );

      container = ProviderContainer(
        overrides: [
          sdkProvider.overrideWith((Ref ref) async => mockSdk),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial state is RefundInitial', () {
      final RefundState state = container.read(refundProvider(mockDeposit));
      expect(state, isA<RefundInitial>());
      expect((state as RefundInitial).deposit, equals(mockDeposit));
    });

    group('prepareRefund', () {
      final RecommendedFees mockFees = RecommendedFees(
        fastestFee: BigInt.from(10),
        halfHourFee: BigInt.from(5),
        hourFee: BigInt.from(2),
        economyFee: BigInt.from(1),
        minimumFee: BigInt.from(1),
      );

      test('Valid address transitions to RefundReady', () async {
        when(mockSdk.recommendedFees()).thenAnswer((_) async => mockFees);

        final RefundNotifier notifier = container.read(refundProvider(mockDeposit).notifier);
        await notifier.prepareRefund('bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq');

        final RefundState state = container.read(refundProvider(mockDeposit));
        expect(state, isA<RefundReady>());
        final RefundReady readyState = state as RefundReady;
        expect(readyState.destinationAddress, equals('bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq'));
        expect(readyState.fees, equals(mockFees));
        expect(readyState.selectedSpeed, equals(RefundFeeSpeed.regular));

        verify(mockSdk.recommendedFees()).called(1);
      });

      test('Shows RefundPreparing state during fee fetch', () async {
        when(mockSdk.recommendedFees()).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 100));
          return mockFees;
        });

        final RefundNotifier notifier = container.read(refundProvider(mockDeposit).notifier);
        final Future<void> prepareTask =
            notifier.prepareRefund('1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa');

        // Give it a moment to enter preparing state
        await Future<void>.delayed(const Duration(milliseconds: 10));

        final RefundState state = container.read(refundProvider(mockDeposit));
        expect(state, isA<RefundPreparing>());
        expect((state as RefundPreparing).destinationAddress, equals('1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa'));

        await prepareTask;
      });

      test('Network error during fee fetch transitions to RefundError', () async {
        when(mockSdk.recommendedFees()).thenThrow(Exception('Network error'));

        final RefundNotifier notifier = container.read(refundProvider(mockDeposit).notifier);
        await notifier.prepareRefund('3J98t1WpEZ73CNmYviecrnyiWrnqRhWNLy');

        final RefundState state = container.read(refundProvider(mockDeposit));
        expect(state, isA<RefundError>());
        expect((state as RefundError).message, equals('Failed to fetch fees'));
        expect(state.technicalDetails, contains('Network error'));
      });

      test('Insufficient funds detection transitions to RefundError', () async {
        final DepositInfo smallDeposit = DepositInfo(
          txid: 'test_txid',
          vout: 0,
          amountSats: BigInt.from(100), // Too small for any fee
        );

        when(mockSdk.recommendedFees()).thenAnswer((_) async => mockFees);

        final ProviderContainer smallDepositContainer = ProviderContainer(
          overrides: [
            sdkProvider.overrideWith((Ref ref) async => mockSdk),
          ],
        );

        final RefundNotifier notifier =
            smallDepositContainer.read(refundProvider(smallDeposit).notifier);
        await notifier.prepareRefund('bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq');

        final RefundState state = smallDepositContainer.read(refundProvider(smallDeposit));
        expect(state, isA<RefundError>());
        expect((state as RefundError).message, equals('Insufficient funds'));
        expect(state.technicalDetails, contains('network fees'));

        smallDepositContainer.dispose();
      });

      test('Works with all Bitcoin address formats', () async {
        when(mockSdk.recommendedFees()).thenAnswer((_) async => mockFees);

        final RefundNotifier notifier = container.read(refundProvider(mockDeposit).notifier);

        // Legacy
        await notifier.prepareRefund('1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa');
        expect(container.read(refundProvider(mockDeposit)), isA<RefundReady>());

        // P2SH
        await notifier.prepareRefund('3J98t1WpEZ73CNmYviecrnyiWrnqRhWNLy');
        expect(container.read(refundProvider(mockDeposit)), isA<RefundReady>());

        // Bech32
        await notifier.prepareRefund('bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq');
        expect(container.read(refundProvider(mockDeposit)), isA<RefundReady>());

        // Taproot
        await notifier.prepareRefund('bc1p5d7rjq7g6rdk2yhzks9smlaqtedr4dekq08ge8ztwac72sfr9rusxg3297');
        expect(container.read(refundProvider(mockDeposit)), isA<RefundReady>());

        verify(mockSdk.recommendedFees()).called(4);
      });
    });

    group('selectFeeSpeed', () {
      final RecommendedFees mockFees = RecommendedFees(
        fastestFee: BigInt.from(10),
        halfHourFee: BigInt.from(5),
        hourFee: BigInt.from(2),
        economyFee: BigInt.from(1),
        minimumFee: BigInt.from(1),
      );

      setUp(() async {
        when(mockSdk.recommendedFees()).thenAnswer((_) async => mockFees);

        final RefundNotifier notifier = container.read(refundProvider(mockDeposit).notifier);
        await notifier.prepareRefund('bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq');
      });

      test('Updates selected fee speed to economy', () {
        final RefundNotifier notifier = container.read(refundProvider(mockDeposit).notifier);
        notifier.selectFeeSpeed(RefundFeeSpeed.economy);

        final RefundState state = container.read(refundProvider(mockDeposit));
        expect(state, isA<RefundReady>());
        expect((state as RefundReady).selectedSpeed, equals(RefundFeeSpeed.economy));
      });

      test('Updates selected fee speed to priority', () {
        final RefundNotifier notifier = container.read(refundProvider(mockDeposit).notifier);
        notifier.selectFeeSpeed(RefundFeeSpeed.priority);

        final RefundState state = container.read(refundProvider(mockDeposit));
        expect(state, isA<RefundReady>());
        expect((state as RefundReady).selectedSpeed, equals(RefundFeeSpeed.priority));
      });

      test('Preserves other state properties when changing speed', () {
        final RefundNotifier notifier = container.read(refundProvider(mockDeposit).notifier);
        notifier.selectFeeSpeed(RefundFeeSpeed.economy);

        final RefundReady state = container.read(refundProvider(mockDeposit)) as RefundReady;
        expect(state.deposit, equals(mockDeposit));
        expect(state.destinationAddress, equals('bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq'));
        expect(state.fees, equals(mockFees));
      });

      test('Does nothing when not in RefundReady state', () {
        final ProviderContainer freshContainer = ProviderContainer(
          overrides: [
            sdkProvider.overrideWith((Ref ref) async => mockSdk),
          ],
        );

        final RefundNotifier notifier =
            freshContainer.read(refundProvider(mockDeposit).notifier);
        notifier.selectFeeSpeed(RefundFeeSpeed.priority);

        final RefundState state = freshContainer.read(refundProvider(mockDeposit));
        expect(state, isA<RefundInitial>()); // Still in initial state

        freshContainer.dispose();
      });
    });

    group('sendRefund', () {
      final RecommendedFees mockFees = RecommendedFees(
        fastestFee: BigInt.from(10),
        halfHourFee: BigInt.from(5),
        hourFee: BigInt.from(2),
        economyFee: BigInt.from(1),
        minimumFee: BigInt.from(1),
      );

      setUp(() async {
        when(mockSdk.recommendedFees()).thenAnswer((_) async => mockFees);

        final RefundNotifier notifier = container.read(refundProvider(mockDeposit).notifier);
        await notifier.prepareRefund('bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq');
      });

      test('Successful refund transitions to RefundSuccess', () async {
        const String expectedTxId = 'refund_tx_123';
        when(
          mockSdk.refundDeposit(request: anyNamed('request')),
        ).thenAnswer((_) async => RefundDepositResponse(txId: expectedTxId, txHex: 'mock_hex'));

        final RefundNotifier notifier = container.read(refundProvider(mockDeposit).notifier);
        await notifier.sendRefund();

        final RefundState state = container.read(refundProvider(mockDeposit));
        expect(state, isA<RefundSuccess>());
        expect((state as RefundSuccess).txId, equals(expectedTxId));

        verify(mockSdk.refundDeposit(request: anyNamed('request'))).called(1);
      });

      test('SDK error during refund transitions to RefundError', () async {
        when(
          mockSdk.refundDeposit(request: anyNamed('request')),
        ).thenThrow(Exception('SDK error'));

        final RefundNotifier notifier = container.read(refundProvider(mockDeposit).notifier);
        await notifier.sendRefund();

        final RefundState state = container.read(refundProvider(mockDeposit));
        expect(state, isA<RefundError>());
        expect((state as RefundError).message, equals('Failed to send refund'));
        expect(state.technicalDetails, contains('SDK error'));
      });

      test('Passes correct parameters to SDK', () async {
        when(
          mockSdk.refundDeposit(request: anyNamed('request')),
        ).thenAnswer((_) async => RefundDepositResponse(txId: 'tx_id', txHex: 'mock_hex'));

        final RefundNotifier notifier = container.read(refundProvider(mockDeposit).notifier);
        notifier.selectFeeSpeed(RefundFeeSpeed.economy);
        await notifier.sendRefund();

        final Object? captured = verify(mockSdk.refundDeposit(request: captureAnyNamed('request'))).captured.single;
        expect(captured, isA<RefundDepositRequest>());

        final RefundDepositRequest request = captured! as RefundDepositRequest;
        expect(request.txid, equals('test_txid'));
        expect(request.vout, equals(0));
        expect(request.destinationAddress, equals('bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq'));
        expect(request.fee, isA<Fee>());
      });

      test('Does nothing when not in RefundReady state', () async {
        final ProviderContainer freshContainer = ProviderContainer(
          overrides: [
            sdkProvider.overrideWith((Ref ref) async => mockSdk),
          ],
        );

        when(
          mockSdk.refundDeposit(request: anyNamed('request')),
        ).thenAnswer((_) async => RefundDepositResponse(txId: 'tx_id', txHex: 'mock_hex'));

        final RefundNotifier notifier =
            freshContainer.read(refundProvider(mockDeposit).notifier);
        await notifier.sendRefund();

        final RefundState state = freshContainer.read(refundProvider(mockDeposit));
        expect(state, isA<RefundInitial>()); // Still in initial state

        verifyNever(mockSdk.refundDeposit(request: anyNamed('request')));

        freshContainer.dispose();
      });
    });

    group('isValidBitcoinAddress', () {
      test('Validates addresses correctly', () {
        final RefundNotifier notifier = container.read(refundProvider(mockDeposit).notifier);

        expect(notifier.isValidBitcoinAddress('1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa'), isTrue);
        expect(notifier.isValidBitcoinAddress('3J98t1WpEZ73CNmYviecrnyiWrnqRhWNLy'), isTrue);
        expect(
          notifier.isValidBitcoinAddress('bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq'),
          isTrue,
        );
        expect(
          notifier.isValidBitcoinAddress(
            'bc1p5d7rjq7g6rdk2yhzks9smlaqtedr4dekq08ge8ztwac72sfr9rusxg3297',
          ),
          isTrue,
        );

        expect(notifier.isValidBitcoinAddress('invalid_address'), isFalse);
        expect(notifier.isValidBitcoinAddress(''), isFalse);
      });
    });
  });
}
