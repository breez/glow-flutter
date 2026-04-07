import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glow/features/deposits/providers/deposit_claimer.dart';
import 'package:glow/features/deposits/widgets/deposit_card.dart';
import 'package:glow/widgets/warning_box.dart';
import 'package:glow/features/deposits/models/unclaimed_deposits_state.dart';

void main() {
  group('DepositCard', () {
    // Helper function to create mock DepositInfo
    DepositInfo createMockDeposit({
      required BigInt amountSats,
      String? txid,
      int? vout,
      DepositClaimError? claimError,
      String? refundTx,
      String? refundTxId,
    }) {
      return DepositInfo(
        txid: txid ?? 'test_txid_${DateTime.now().millisecondsSinceEpoch}',
        vout: vout ?? 0,
        amountSats: amountSats,
        claimError: claimError,
        refundTx: refundTx,
        refundTxId: refundTxId,
      );
    }

    DepositCardData cardDataFromDeposit(DepositInfo deposit) {
      final DepositClaimer claimer = const DepositClaimer();
      final bool hasError = claimer.hasError(deposit);
      final bool hasRefund = claimer.hasRefund(deposit);
      final String formattedTxid = claimer.formatTxid(deposit.txid);
      final String? formattedErrorMessage = hasError && deposit.claimError != null
          ? claimer.formatError(deposit.claimError!)
          : null;
      return DepositCardData(
        deposit: deposit,
        hasError: hasError,
        hasRefund: hasRefund,
        formattedTxid: formattedTxid,
        formattedErrorMessage: formattedErrorMessage,
      );
    }

    // Helper to create DepositCard widget from DepositInfo
    Widget makeDepositCard(
      DepositInfo deposit, {
      Key? cardKey,
      VoidCallback? onRetryClaim,
      VoidCallback? onRefund,
      VoidCallback? onCopyTxid,
    }) {
      final DepositCardData cardData = cardDataFromDeposit(deposit);
      return DepositCard(
        key: cardKey,
        deposit: cardData.deposit,
        hasError: cardData.hasError,
        hasRefund: cardData.hasRefund,
        formattedTxid: cardData.formattedTxid,
        formattedErrorMessage: cardData.formattedErrorMessage,
        onRetryClaim: onRetryClaim ?? () {},
        onRefund: onRefund ?? () {},
        onCopyTxid: onCopyTxid ?? () {},
      );
    }

    // Helper to wrap widget with MaterialApp and ProviderScope
    Widget makeTestable(Widget child) {
      return ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: SafeArea(child: child)),
        ),
      );
    }

    group('initial state (collapsed)', () {
      final List<Map<String, Object>> testCases = <Map<String, Object>>[
        <String, Object>{
          'desc': 'shows deposit amount',
          'deposit': createMockDeposit(amountSats: BigInt.from(10000)),
          'expect': (WidgetTester tester) async {
            expect(find.text('10000 sats'), findsOneWidget);
          },
        },
        <String, Object>{
          'desc': 'shows "Waiting to claim" status when no error',
          'deposit': createMockDeposit(amountSats: BigInt.from(10000)),
          'expect': (WidgetTester tester) async {
            expect(find.text('Waiting to claim'), findsOneWidget);
          },
        },
        <String, Object>{
          'desc': 'shows "Failed to claim" status when error exists',
          'deposit': createMockDeposit(
            amountSats: BigInt.from(10000),
            claimError: const DepositClaimError.generic(message: 'Test error'),
          ),
          'expect': (WidgetTester tester) async {
            expect(find.text('Failed to claim'), findsOneWidget);
          },
        },
        <String, Object>{
          'desc': 'shows expand icon when collapsed',
          'deposit': createMockDeposit(amountSats: BigInt.from(10000)),
          'expect': (WidgetTester tester) async {
            expect(find.byIcon(Icons.expand_more), findsOneWidget);
            expect(find.byIcon(Icons.expand_less), findsNothing);
          },
        },
        <String, Object>{
          'desc': 'shows wallet icon',
          'deposit': createMockDeposit(amountSats: BigInt.from(10000)),
          'expect': (WidgetTester tester) async {
            expect(find.byIcon(Icons.account_balance_wallet_outlined), findsOneWidget);
          },
        },
        <String, Object>{
          'desc': 'does not show transaction details when collapsed',
          'deposit': createMockDeposit(amountSats: BigInt.from(10000), txid: 'test_transaction_id'),
          'expect': (WidgetTester tester) async {
            expect(find.text('Transaction'), findsNothing);
            expect(find.text('Output'), findsNothing);
            expect(find.text('Retry Claim'), findsNothing);
          },
        },
      ];
      for (final Map<String, Object> tc in testCases) {
        testWidgets(tc['desc'] as String, (WidgetTester tester) async {
          final DepositInfo deposit = tc['deposit'] as DepositInfo;
          await tester.pumpWidget(makeTestable(makeDepositCard(deposit)));
          await (tc['expect'] as Function)(tester);
        });
      }
    });

    group('expanded state', () {
      testWidgets('expands when tapped', (WidgetTester tester) async {
        final DepositInfo deposit = createMockDeposit(amountSats: BigInt.from(10000));
        await tester.pumpWidget(makeTestable(makeDepositCard(deposit)));
        await tester.tap(find.byType(InkWell));
        await tester.pumpAndSettle();
        expect(find.text('Transaction'), findsOneWidget);
      });

      testWidgets('shows transaction ID when expanded', (WidgetTester tester) async {
        final DepositInfo deposit = createMockDeposit(
          amountSats: BigInt.from(10000),
          txid: '1234567890abcdefghijklmnopqrstuvwxyz',
        );
        await tester.pumpWidget(makeTestable(makeDepositCard(deposit)));
        await tester.tap(find.byType(InkWell));
        await tester.pumpAndSettle();
        expect(find.textContaining('12345678'), findsOneWidget);
        expect(find.textContaining('stuvwxyz'), findsOneWidget);
      });

      testWidgets('shows output index when expanded', (WidgetTester tester) async {
        final DepositInfo deposit = createMockDeposit(amountSats: BigInt.from(10000), vout: 5);
        await tester.pumpWidget(makeTestable(makeDepositCard(deposit)));
        await tester.tap(find.byType(InkWell));
        await tester.pumpAndSettle();
        expect(find.text('Output'), findsOneWidget);
        expect(find.text('5'), findsOneWidget);
      });

      testWidgets('shows retry claim button when expanded', (WidgetTester tester) async {
        final DepositInfo deposit = createMockDeposit(amountSats: BigInt.from(10000));
        await tester.pumpWidget(makeTestable(makeDepositCard(deposit)));
        await tester.tap(find.byType(InkWell));
        await tester.pumpAndSettle();
        expect(find.text('Retry Claim'), findsOneWidget);
        expect(find.byIcon(Icons.refresh), findsOneWidget);
      });

      testWidgets('shows divider when expanded', (WidgetTester tester) async {
        final DepositInfo deposit = createMockDeposit(amountSats: BigInt.from(10000));
        await tester.pumpWidget(makeTestable(makeDepositCard(deposit)));
        await tester.tap(find.byType(InkWell));
        await tester.pumpAndSettle();
        expect(find.byType(Divider), findsOneWidget);
      });

      testWidgets('collapses when tapped again', (WidgetTester tester) async {
        final DepositInfo deposit = createMockDeposit(amountSats: BigInt.from(10000));
        final Key cardKey = Key('deposit_card_${deposit.txid}');
        await tester.pumpWidget(
          makeTestable(
            makeDepositCard(
              deposit,
              cardKey: cardKey,
              onRetryClaim: () {},
              onRefund: () {},
              onCopyTxid: () {},
            ),
          ),
        );
        // Expand
        await tester.tap(find.byKey(cardKey));
        await tester.pumpAndSettle();
        expect(find.text('Transaction'), findsOneWidget);
        // Collapse
        await tester.tap(find.byKey(cardKey));
        await tester.pumpAndSettle();
        expect(find.text('Transaction'), findsNothing);
      });
    });
    group('error state', () {
      testWidgets('shows error banner when error exists', (WidgetTester tester) async {
        final DepositInfo deposit = createMockDeposit(
          amountSats: BigInt.from(10000),
          claimError: const DepositClaimError.generic(message: 'Test error'),
        );
        await tester.pumpWidget(makeTestable(makeDepositCard(deposit)));
        // Expand to see error
        await tester.tap(find.byType(InkWell));
        await tester.pumpAndSettle();
        expect(find.byType(WarningBox), findsOneWidget);
      });

      testWidgets('shows error border color when error exists', (WidgetTester tester) async {
        final DepositInfo deposit = createMockDeposit(
          amountSats: BigInt.from(10000),
          claimError: const DepositClaimError.generic(message: 'Test error'),
        );
        await tester.pumpWidget(makeTestable(makeDepositCard(deposit)));

        final Card card = tester.widget<Card>(find.byType(Card));
        final RoundedRectangleBorder shape = card.shape as RoundedRectangleBorder;
        // Error border should have some alpha (not fully transparent)
        expect((shape.side.color.a * 255.0).round().clamp(0, 255), greaterThan(0));
      });

      testWidgets('does not show error banner when no error', (WidgetTester tester) async {
        final DepositInfo deposit = createMockDeposit(amountSats: BigInt.from(10000));
        await tester.pumpWidget(makeTestable(makeDepositCard(deposit)));

        await tester.tap(find.byType(InkWell));
        await tester.pumpAndSettle();

        expect(find.byType(WarningBox), findsNothing);
      });
    });

    group('refund transaction', () {
      testWidgets('shows refund button when refund exists', (WidgetTester tester) async {
        final DepositInfo deposit = createMockDeposit(
          amountSats: BigInt.from(10000),
          refundTx: 'refund_transaction_data',
        );
        await tester.pumpWidget(makeTestable(makeDepositCard(deposit)));

        await tester.tap(find.byType(InkWell));
        await tester.pumpAndSettle();

        expect(find.text('View Refund'), findsOneWidget);
        expect(find.byIcon(Icons.info_outline), findsOneWidget);
      });

      testWidgets('does not show refund button when no refund', (WidgetTester tester) async {
        final DepositInfo deposit = createMockDeposit(amountSats: BigInt.from(10000));
        await tester.pumpWidget(makeTestable(makeDepositCard(deposit)));

        await tester.tap(find.byType(InkWell));
        await tester.pumpAndSettle();

        expect(find.text('View Refund'), findsNothing);
      });

      testWidgets('calls onShowRefundInfo when refund button tapped', (WidgetTester tester) async {
        bool callbackCalled = false;
        final DepositInfo deposit = createMockDeposit(
          amountSats: BigInt.from(10000),
          refundTx: 'refund_transaction_data',
        );
        await tester.pumpWidget(
          makeTestable(
            makeDepositCard(
              deposit,
              onRefund: () {
                callbackCalled = true;
              },
            ),
          ),
        );

        await tester.tap(find.byType(InkWell));
        await tester.pumpAndSettle();

        await tester.tap(find.text('View Refund'));
        await tester.pumpAndSettle();

        expect(callbackCalled, true);
      });
    });

    group('callbacks', () {
      testWidgets('calls onRetryClaim when retry button tapped', (WidgetTester tester) async {
        bool callbackCalled = false;
        final DepositInfo deposit = createMockDeposit(amountSats: BigInt.from(10000));
        await tester.pumpWidget(
          makeTestable(
            makeDepositCard(
              deposit,
              onRetryClaim: () {
                callbackCalled = true;
              },
            ),
          ),
        );

        await tester.tap(find.byType(InkWell));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Retry Claim'));
        await tester.pumpAndSettle();

        expect(callbackCalled, true);
      });
    });

    group('visual styling', () {
      testWidgets('uses Card widget', (WidgetTester tester) async {
        final DepositInfo deposit = createMockDeposit(amountSats: BigInt.from(10000));
        await tester.pumpWidget(makeTestable(makeDepositCard(deposit)));

        expect(find.byType(Card), findsOneWidget);
      });

      testWidgets('uses InkWell for tap feedback', (WidgetTester tester) async {
        final DepositInfo deposit = createMockDeposit(amountSats: BigInt.from(10000));
        await tester.pumpWidget(makeTestable(makeDepositCard(deposit)));

        expect(find.byType(InkWell), findsOneWidget);
      });

      testWidgets('has proper padding', (WidgetTester tester) async {
        final DepositInfo deposit = createMockDeposit(amountSats: BigInt.from(10000));
        await tester.pumpWidget(makeTestable(makeDepositCard(deposit)));

        // Find the Padding widget that wraps the content
        final Padding padding = tester.widget<Padding>(
          find.descendant(of: find.byType(InkWell), matching: find.byType(Padding)).first,
        );

        expect(padding.padding, const EdgeInsets.all(16));
      });
    });

    group('edge cases', () {
      testWidgets('handles very long transaction IDs', (WidgetTester tester) async {
        final DepositInfo deposit = createMockDeposit(
          amountSats: BigInt.from(10000),
          txid: 'a' * 100, // Very long txid
        );

        await tester.pumpWidget(makeTestable(makeDepositCard(deposit)));

        await tester.tap(find.byType(InkWell));
        await tester.pumpAndSettle();

        // Should show truncated version
        expect(find.textContaining('aaaaaaaa'), findsOneWidget);
      });

      testWidgets('handles very large amounts', (WidgetTester tester) async {
        final DepositInfo deposit = createMockDeposit(amountSats: BigInt.from(99999999));

        await tester.pumpWidget(makeTestable(makeDepositCard(deposit)));

        expect(find.text('99999999 sats'), findsOneWidget);
      });

      testWidgets('handles zero amount', (WidgetTester tester) async {
        final DepositInfo deposit = createMockDeposit(amountSats: BigInt.zero);

        await tester.pumpWidget(makeTestable(makeDepositCard(deposit)));

        expect(find.text('0 sats'), findsOneWidget);
      });
    });
  });
}
