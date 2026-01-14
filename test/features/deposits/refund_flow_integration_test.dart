import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glow/features/deposits/providers/refund_provider.dart';
import 'package:glow/features/deposits/refund/refund_layout.dart';
import 'package:glow/features/deposits/refund/refund_state.dart';
import 'package:glow/providers/sdk_provider.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'providers/refund_notifier_test.mocks.dart';

@GenerateMocks(<Type>[BreezSdk])
void main() {
  group('Refund Flow Integration Tests', () {
    late MockBreezSdk mockSdk;
    late DepositInfo mockDeposit;
    late RecommendedFees mockFees;

    setUp(() {
      mockSdk = MockBreezSdk();
      mockDeposit = DepositInfo(
        txid: 'test_txid',
        vout: 0,
        amountSats: BigInt.from(10000),
      );

      mockFees = RecommendedFees(
        fastestFee: BigInt.from(10),
        halfHourFee: BigInt.from(5),
        hourFee: BigInt.from(2),
        economyFee: BigInt.from(1),
        minimumFee: BigInt.from(1),
      );
    });

    testWidgets('Complete happy path - successful refund', (WidgetTester tester) async {
      when(mockSdk.recommendedFees()).thenAnswer((_) async => mockFees);
      when(mockSdk.refundDeposit(request: anyNamed('request')))
          .thenAnswer((_) async => RefundDepositResponse(txId: 'refund_tx_123', txHex: 'mock_hex'));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sdkProvider.overrideWith((Ref ref) async => mockSdk),
          ],
          child: MaterialApp(
            home: Consumer(
              builder: (BuildContext context, WidgetRef ref, Widget? child) {
                final RefundState state = ref.watch(refundProvider(mockDeposit));
                final RefundNotifier notifier = ref.read(refundProvider(mockDeposit).notifier);

                return RefundLayout(
                  state: state,
                  onPrepareRefund: notifier.prepareRefund,
                  onSelectFeeSpeed: notifier.selectFeeSpeed,
                  onSendRefund: notifier.sendRefund,
                  onRetry: notifier.prepareRefund,
                  onCancel: () {},
                );
              },
            ),
          ),
        ),
      );

      // 1. Initial state - address input visible
      expect(find.text('Get Refund'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('GET REFUND'), findsOneWidget);

      // 2. Enter valid address
      await tester.enterText(find.byType(TextFormField), 'bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq');
      await tester.pumpAndSettle();

      // 3. Tap GET REFUND button
      await tester.tap(find.text('GET REFUND'));
      await tester.pump();

      // 4. Loading state appears
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // 5. Wait for fees to be fetched
      await tester.pumpAndSettle();

      // 6. Fee selection displayed
      expect(find.text('Choose Processing Speed'), findsOneWidget);
      expect(find.text('ECONOMY'), findsOneWidget);
      expect(find.text('REGULAR'), findsOneWidget);
      expect(find.text('PRIORITY'), findsOneWidget);
      expect(find.text('Deposit amount:'), findsOneWidget);
      expect(find.text('CONFIRM'), findsOneWidget);

      // 7. Select economy speed
      await tester.tap(find.text('ECONOMY'));
      await tester.pumpAndSettle();

      // 8. Verify delivery estimate updated
      expect(find.textContaining('~1 hour'), findsOneWidget);

      // 9. Tap CONFIRM button
      await tester.tap(find.text('CONFIRM'));
      await tester.pump();

      // 10. Wait for refund to complete
      await tester.pumpAndSettle();

      // 11. Verify SDK methods called
      verify(mockSdk.recommendedFees()).called(1);
      verify(mockSdk.refundDeposit(request: anyNamed('request'))).called(1);

      // 12. Verify success state (PaymentStatusView should be shown)
      expect(find.text('Choose Processing Speed'), findsNothing);
      expect(find.text('CONFIRM'), findsNothing);
    });

    testWidgets('Network error during fee fetch', (WidgetTester tester) async {
      when(mockSdk.recommendedFees()).thenThrow(Exception('Network error'));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sdkProvider.overrideWith((Ref ref) async => mockSdk),
          ],
          child: MaterialApp(
            home: Consumer(
              builder: (BuildContext context, WidgetRef ref, Widget? child) {
                final RefundState state = ref.watch(refundProvider(mockDeposit));
                final RefundNotifier notifier = ref.read(refundProvider(mockDeposit).notifier);

                return RefundLayout(
                  state: state,
                  onPrepareRefund: notifier.prepareRefund,
                  onSelectFeeSpeed: notifier.selectFeeSpeed,
                  onSendRefund: notifier.sendRefund,
                  onRetry: notifier.prepareRefund,
                  onCancel: () {},
                );
              },
            ),
          ),
        ),
      );

      // Enter valid address
      await tester.enterText(find.byType(TextFormField), 'bc1qtest');
      await tester.pumpAndSettle();

      // Tap GET REFUND button
      await tester.tap(find.text('GET REFUND'));
      await tester.pump();

      // Wait for error
      await tester.pumpAndSettle();

      // Verify error displayed
      expect(find.text('Failed to fetch fees'), findsOneWidget);
      expect(find.textContaining('Network error'), findsOneWidget);
      expect(find.text('BACK'), findsOneWidget);
    });

    testWidgets('SDK error during refund execution', (WidgetTester tester) async {
      when(mockSdk.recommendedFees()).thenAnswer((_) async => mockFees);
      when(mockSdk.refundDeposit(request: anyNamed('request')))
          .thenThrow(Exception('Refund failed'));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sdkProvider.overrideWith((Ref ref) async => mockSdk),
          ],
          child: MaterialApp(
            home: Consumer(
              builder: (BuildContext context, WidgetRef ref, Widget? child) {
                final RefundState state = ref.watch(refundProvider(mockDeposit));
                final RefundNotifier notifier = ref.read(refundProvider(mockDeposit).notifier);

                return RefundLayout(
                  state: state,
                  onPrepareRefund: notifier.prepareRefund,
                  onSelectFeeSpeed: notifier.selectFeeSpeed,
                  onSendRefund: notifier.sendRefund,
                  onRetry: notifier.prepareRefund,
                  onCancel: () {},
                );
              },
            ),
          ),
        ),
      );

      // Enter address and prepare refund
      await tester.enterText(find.byType(TextFormField), 'bc1qtest');
      await tester.tap(find.text('GET REFUND'));
      await tester.pumpAndSettle();

      // Fee selection displayed
      expect(find.text('CONFIRM'), findsOneWidget);

      // Tap CONFIRM to send refund
      await tester.tap(find.text('CONFIRM'));
      await tester.pumpAndSettle();

      // Verify error displayed
      expect(find.text('Failed to send refund'), findsOneWidget);
      expect(find.textContaining('Refund failed'), findsOneWidget);
    });

    testWidgets('Invalid address entered', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sdkProvider.overrideWith((Ref ref) async => mockSdk),
          ],
          child: MaterialApp(
            home: Consumer(
              builder: (BuildContext context, WidgetRef ref, Widget? child) {
                final RefundState state = ref.watch(refundProvider(mockDeposit));
                final RefundNotifier notifier = ref.read(refundProvider(mockDeposit).notifier);

                return RefundLayout(
                  state: state,
                  onPrepareRefund: notifier.prepareRefund,
                  onSelectFeeSpeed: notifier.selectFeeSpeed,
                  onSendRefund: notifier.sendRefund,
                  onRetry: notifier.prepareRefund,
                  onCancel: () {},
                );
              },
            ),
          ),
        ),
      );

      // Enter invalid address
      await tester.enterText(find.byType(TextFormField), 'invalid_address');
      await tester.pumpAndSettle();

      // Tap GET REFUND button
      await tester.tap(find.text('GET REFUND'));
      await tester.pumpAndSettle();

      // Verify validation error displayed
      expect(find.text('Invalid Bitcoin address format'), findsOneWidget);

      // Verify still in initial state
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('Choose Processing Speed'), findsNothing);

      // SDK should not be called
      verifyNever(mockSdk.recommendedFees());
    });

    testWidgets('Insufficient funds - all speeds disabled', (WidgetTester tester) async {
      final DepositInfo tinyDeposit = DepositInfo(
        txid: 'test_txid',
        vout: 0,
        amountSats: BigInt.from(100), // Too small
      );

      when(mockSdk.recommendedFees()).thenAnswer((_) async => mockFees);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sdkProvider.overrideWith((Ref ref) async => mockSdk),
          ],
          child: MaterialApp(
            home: Consumer(
              builder: (BuildContext context, WidgetRef ref, Widget? child) {
                final RefundState state = ref.watch(refundProvider(tinyDeposit));
                final RefundNotifier notifier = ref.read(refundProvider(tinyDeposit).notifier);

                return RefundLayout(
                  state: state,
                  onPrepareRefund: notifier.prepareRefund,
                  onSelectFeeSpeed: notifier.selectFeeSpeed,
                  onSendRefund: notifier.sendRefund,
                  onRetry: notifier.prepareRefund,
                  onCancel: () {},
                );
              },
            ),
          ),
        ),
      );

      // Enter address and prepare refund
      await tester.enterText(find.byType(TextFormField), 'bc1qtest');
      await tester.tap(find.text('GET REFUND'));
      await tester.pumpAndSettle();

      // Verify error about insufficient funds
      expect(find.text('Insufficient funds'), findsOneWidget);
      expect(find.textContaining('network fees'), findsOneWidget);
    });

    testWidgets('User changes fee speed multiple times', (WidgetTester tester) async {
      when(mockSdk.recommendedFees()).thenAnswer((_) async => mockFees);
      when(mockSdk.refundDeposit(request: anyNamed('request')))
          .thenAnswer((_) async => RefundDepositResponse(txId: 'refund_tx_123', txHex: 'mock_hex'));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sdkProvider.overrideWith((Ref ref) async => mockSdk),
          ],
          child: MaterialApp(
            home: Consumer(
              builder: (BuildContext context, WidgetRef ref, Widget? child) {
                final RefundState state = ref.watch(refundProvider(mockDeposit));
                final RefundNotifier notifier = ref.read(refundProvider(mockDeposit).notifier);

                return RefundLayout(
                  state: state,
                  onPrepareRefund: notifier.prepareRefund,
                  onSelectFeeSpeed: notifier.selectFeeSpeed,
                  onSendRefund: notifier.sendRefund,
                  onRetry: notifier.prepareRefund,
                  onCancel: () {},
                );
              },
            ),
          ),
        ),
      );

      // Enter address and prepare refund
      await tester.enterText(find.byType(TextFormField), 'bc1qtest');
      await tester.tap(find.text('GET REFUND'));
      await tester.pumpAndSettle();

      // Fee selection displayed
      expect(find.text('ECONOMY'), findsOneWidget);
      expect(find.text('REGULAR'), findsOneWidget);
      expect(find.text('PRIORITY'), findsOneWidget);

      // Change to economy
      await tester.tap(find.text('ECONOMY'));
      await tester.pumpAndSettle();
      expect(find.textContaining('~1 hour'), findsOneWidget);

      // Change to priority
      await tester.tap(find.text('PRIORITY'));
      await tester.pumpAndSettle();
      expect(find.textContaining('~10 minutes'), findsOneWidget);

      // Change back to regular
      await tester.tap(find.text('REGULAR'));
      await tester.pumpAndSettle();
      expect(find.textContaining('~30 minutes'), findsOneWidget);

      // Confirm refund
      await tester.tap(find.text('CONFIRM'));
      await tester.pumpAndSettle();

      // Verify refund completed
      verify(mockSdk.refundDeposit(request: anyNamed('request'))).called(1);
    });
  });
}
