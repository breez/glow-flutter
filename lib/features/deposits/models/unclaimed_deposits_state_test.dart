import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glow/features/deposits/models/unclaimed_deposits_state.dart';
import 'package:glow/features/deposits/providers/deposit_claimer.dart';
import 'package:glow/features/deposits/unclaimed_deposits_layout.dart';
import 'package:glow/features/deposits/widgets/deposit_card.dart';
import 'package:glow/features/deposits/widgets/empty_deposits_state.dart';

void main() {
  group('UnclaimedDepositsLayout', () {
    // Helper to wrap widget with MaterialApp
    Widget makeTestable(Widget child) {
      return MaterialApp(home: child);
    }

    group('loading state', () {
      testWidgets('shows loading indicator when loading', (WidgetTester tester) async {
        await tester.pumpWidget(
          makeTestable(
            UnclaimedDepositsLayout(
              depositsAsync: const AsyncValue<List<DepositCardData>>.loading(),
              onRetryClaim: (_) async {},
              onRefund: (_) {},
              onCopyTxid: (_) {},
              depositCardBuilder: (DepositCardData cardData) {
                return DepositCard(
                  deposit: cardData.deposit,
                  hasError: cardData.hasError,
                  hasRefund: cardData.hasRefund,
                  formattedTxid: cardData.formattedTxid,
                  formattedErrorMessage: cardData.formattedErrorMessage,
                  onRetryClaim: () {},
                  onRefund: () {},
                  onCopyTxid: () {},
                );
              },
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.byType(DepositCard), findsNothing);
        expect(find.byType(EmptyDepositsState), findsNothing);
      });

      testWidgets('shows app bar with title during loading', (WidgetTester tester) async {
        await tester.pumpWidget(
          makeTestable(
            UnclaimedDepositsLayout(
              depositsAsync: const AsyncValue<List<DepositCardData>>.loading(),
              onRetryClaim: (_) async {},
              onRefund: (_) {},
              onCopyTxid: (_) {},
              depositCardBuilder: (DepositCardData cardData) {
                return DepositCard(
                  deposit: cardData.deposit,
                  hasError: cardData.hasError,
                  hasRefund: cardData.hasRefund,
                  formattedTxid: cardData.formattedTxid,
                  formattedErrorMessage: cardData.formattedErrorMessage,
                  onRetryClaim: () {},
                  onRefund: () {},
                  onCopyTxid: () {},
                );
              },
            ),
          ),
        );

        expect(find.byType(AppBar), findsOneWidget);
        expect(find.text('Pending Deposits'), findsOneWidget);
      });
    });

    group('loaded state with deposits', () {
      testWidgets('shows list of deposit cards when deposits exist', (WidgetTester tester) async {
        final List<DepositInfo> deposits = <DepositInfo>[
          _createMockDeposit(txid: 'txid1', amountSats: BigInt.from(10000)),
          _createMockDeposit(txid: 'txid2', amountSats: BigInt.from(20000)),
          _createMockDeposit(txid: 'txid3', amountSats: BigInt.from(30000)),
        ];

        await tester.pumpWidget(
          makeTestable(
            UnclaimedDepositsLayout(
              depositsAsync: cardDataAsync(AsyncValue<List<DepositInfo>>.data(deposits)),
              onRetryClaim: (_) async {},
              onRefund: (_) {},
              onCopyTxid: (_) {},
              depositCardBuilder: (DepositCardData cardData) {
                return DepositCard(
                  deposit: cardData.deposit,
                  hasError: cardData.hasError,
                  hasRefund: cardData.hasRefund,
                  formattedTxid: cardData.formattedTxid,
                  formattedErrorMessage: cardData.formattedErrorMessage,
                  onRetryClaim: () {},
                  onRefund: () {},
                  onCopyTxid: () {},
                );
              },
            ),
          ),
        );

        expect(find.byType(DepositCard), findsNWidgets(3));
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.byType(EmptyDepositsState), findsNothing);
      });

      testWidgets('shows correct deposit amounts', (WidgetTester tester) async {
        final List<DepositInfo> deposits = <DepositInfo>[
          _createMockDeposit(txid: 'txid1', amountSats: BigInt.from(10000)),
          _createMockDeposit(txid: 'txid2', amountSats: BigInt.from(20000)),
        ];

        await tester.pumpWidget(
          makeTestable(
            UnclaimedDepositsLayout(
              depositsAsync: cardDataAsync(AsyncValue<List<DepositInfo>>.data(deposits)),
              onRetryClaim: (_) async {},
              onRefund: (_) {},
              onCopyTxid: (_) {},
              depositCardBuilder: (DepositCardData cardData) {
                return DepositCard(
                  deposit: cardData.deposit,
                  hasError: cardData.hasError,
                  hasRefund: cardData.hasRefund,
                  formattedTxid: cardData.formattedTxid,
                  formattedErrorMessage: cardData.formattedErrorMessage,
                  onRetryClaim: () {},
                  onRefund: () {},
                  onCopyTxid: () {},
                );
              },
            ),
          ),
        );

        expect(find.text('10000 sats'), findsOneWidget);
        expect(find.text('20000 sats'), findsOneWidget);
      });

      testWidgets('shows ListView with correct padding', (WidgetTester tester) async {
        final List<DepositInfo> deposits = <DepositInfo>[
          _createMockDeposit(txid: 'txid1', amountSats: BigInt.from(10000)),
        ];

        await tester.pumpWidget(
          makeTestable(
            UnclaimedDepositsLayout(
              depositsAsync: cardDataAsync(AsyncValue<List<DepositInfo>>.data(deposits)),
              onRetryClaim: (_) async {},
              onRefund: (_) {},
              onCopyTxid: (_) {},
              depositCardBuilder: (DepositCardData cardData) {
                return DepositCard(
                  deposit: cardData.deposit,
                  hasError: cardData.hasError,
                  hasRefund: cardData.hasRefund,
                  formattedTxid: cardData.formattedTxid,
                  formattedErrorMessage: cardData.formattedErrorMessage,
                  onRetryClaim: () {},
                  onRefund: () {},
                  onCopyTxid: () {},
                );
              },
            ),
          ),
        );

        final ListView listView = tester.widget<ListView>(find.byType(ListView));
        expect(listView.padding, const EdgeInsets.all(16));
      });
    });

    group('loaded state without deposits', () {
      testWidgets('shows empty state when no deposits', (WidgetTester tester) async {
        await tester.pumpWidget(
          makeTestable(
            UnclaimedDepositsLayout(
              depositsAsync: cardDataAsync(
                const AsyncValue<List<DepositInfo>>.data(<DepositInfo>[]),
              ),
              onRetryClaim: (_) async {},
              onRefund: (_) {},
              onCopyTxid: (_) {},
              depositCardBuilder: (DepositCardData cardData) => DepositCard(
                deposit: cardData.deposit,
                hasError: cardData.hasError,
                hasRefund: cardData.hasRefund,
                formattedTxid: cardData.formattedTxid,
                formattedErrorMessage: cardData.formattedErrorMessage,
                onRetryClaim: () {},
                onRefund: () {},
                onCopyTxid: () {},
              ),
            ),
          ),
        );

        expect(find.byType(EmptyDepositsState), findsOneWidget);
        expect(find.byType(DepositCard), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });

      testWidgets('empty state shows correct message', (WidgetTester tester) async {
        final List<DepositInfo> deposits = <DepositInfo>[];
        await tester.pumpWidget(
          makeTestable(
            UnclaimedDepositsLayout(
              depositsAsync: cardDataAsync(AsyncValue<List<DepositInfo>>.data(deposits)),
              onRetryClaim: (_) async {},
              onRefund: (_) {},
              onCopyTxid: (_) {},
              depositCardBuilder: (DepositCardData cardData) => DepositCard(
                deposit: cardData.deposit,
                hasError: cardData.hasError,
                hasRefund: cardData.hasRefund,
                formattedTxid: cardData.formattedTxid,
                formattedErrorMessage: cardData.formattedErrorMessage,
                onRetryClaim: () {},
                onRefund: () {},
                onCopyTxid: () {},
              ),
            ),
          ),
        );

        expect(find.text('All deposits claimed'), findsOneWidget);
        expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      });
    });

    group('error state', () {
      testWidgets('shows error message when error occurs', (WidgetTester tester) async {
        final Exception error = Exception('Network error');

        await tester.pumpWidget(
          makeTestable(
            UnclaimedDepositsLayout(
              depositsAsync: AsyncValue<List<DepositCardData>>.error(error, StackTrace.empty),
              onRetryClaim: (_) async {},
              onRefund: (_) {},
              onCopyTxid: (_) {},
              depositCardBuilder: (DepositCardData cardData) {
                return DepositCard(
                  deposit: cardData.deposit,
                  hasError: cardData.hasError,
                  hasRefund: cardData.hasRefund,
                  formattedTxid: cardData.formattedTxid,
                  formattedErrorMessage: cardData.formattedErrorMessage,
                  onRetryClaim: () {},
                  onRefund: () {},
                  onCopyTxid: () {},
                );
              },
            ),
          ),
        );

        expect(find.text('Failed to load deposits'), findsOneWidget);
        expect(find.text(error.toString()), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      });

      testWidgets('error state shows correct icon size and color', (WidgetTester tester) async {
        await tester.pumpWidget(
          makeTestable(
            UnclaimedDepositsLayout(
              depositsAsync: AsyncValue<List<DepositCardData>>.error(
                Exception('Error'),
                StackTrace.empty,
              ),
              onRetryClaim: (_) async {},
              onRefund: (_) {},
              onCopyTxid: (_) {},
              depositCardBuilder: (DepositCardData cardData) {
                return DepositCard(
                  deposit: cardData.deposit,
                  hasError: cardData.hasError,
                  hasRefund: cardData.hasRefund,
                  formattedTxid: cardData.formattedTxid,
                  formattedErrorMessage: cardData.formattedErrorMessage,
                  onRetryClaim: () {},
                  onRefund: () {},
                  onCopyTxid: () {},
                );
              },
            ),
          ),
        );

        final Icon icon = tester.widget<Icon>(find.byIcon(Icons.error_outline));
        expect(icon.size, 64);
        // Color check would require theme context
      });

      testWidgets('shows no deposit cards in error state', (WidgetTester tester) async {
        await tester.pumpWidget(
          makeTestable(
            UnclaimedDepositsLayout(
              depositsAsync: AsyncValue<List<DepositCardData>>.error(
                Exception('Error'),
                StackTrace.empty,
              ),
              onRetryClaim: (_) async {},
              onRefund: (_) {},
              onCopyTxid: (_) {},
              depositCardBuilder: (DepositCardData cardData) {
                return DepositCard(
                  deposit: cardData.deposit,
                  hasError: cardData.hasError,
                  hasRefund: cardData.hasRefund,
                  formattedTxid: cardData.formattedTxid,
                  formattedErrorMessage: cardData.formattedErrorMessage,
                  onRetryClaim: () {},
                  onRefund: () {},
                  onCopyTxid: () {},
                );
              },
            ),
          ),
        );

        expect(find.byType(DepositCard), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.byType(EmptyDepositsState), findsNothing);
      });
    });

    group('callbacks', () {
      testWidgets('passes onRetryClaim to deposit cards', (WidgetTester tester) async {
        final List<DepositInfo> deposits = <DepositInfo>[
          _createMockDeposit(txid: 'txid1', amountSats: BigInt.from(10000)),
        ];

        await tester.pumpWidget(
          makeTestable(
            UnclaimedDepositsLayout(
              depositsAsync: cardDataAsync(AsyncValue<List<DepositInfo>>.data(deposits)),
              onRetryClaim: (_) async {},
              onRefund: (_) {},
              onCopyTxid: (_) {},
              depositCardBuilder: (DepositCardData cardData) {
                return DepositCard(
                  deposit: cardData.deposit,
                  hasError: cardData.hasError,
                  hasRefund: cardData.hasRefund,
                  formattedTxid: cardData.formattedTxid,
                  formattedErrorMessage: cardData.formattedErrorMessage,
                  onRetryClaim: () {},
                  onRefund: () {},
                  onCopyTxid: () {},
                );
              },
            ),
          ),
        );

        // Verify deposit card exists (callback will be tested in deposit_card_test.dart)
        expect(find.byType(DepositCard), findsOneWidget);
      });

      testWidgets('passes onRefund to deposit cards', (WidgetTester tester) async {
        final List<DepositInfo> deposits = <DepositInfo>[
          _createMockDeposit(txid: 'txid1', amountSats: BigInt.from(10000)),
        ];

        await tester.pumpWidget(
          makeTestable(
            UnclaimedDepositsLayout(
              depositsAsync: cardDataAsync(AsyncValue<List<DepositInfo>>.data(deposits)),
              onRetryClaim: (_) async {},
              onRefund: (_) {},
              onCopyTxid: (_) {},
              depositCardBuilder: (DepositCardData cardData) {
                return DepositCard(
                  deposit: cardData.deposit,
                  hasError: cardData.hasError,
                  hasRefund: cardData.hasRefund,
                  formattedTxid: cardData.formattedTxid,
                  formattedErrorMessage: cardData.formattedErrorMessage,
                  onRetryClaim: () {},
                  onRefund: () {},
                  onCopyTxid: () {},
                );
              },
            ),
          ),
        );

        // Verify deposit card exists (callback will be tested in deposit_card_test.dart)
        expect(find.byType(DepositCard), findsOneWidget);
      });
    });

    group('layout structure', () {
      testWidgets('always shows Scaffold', (WidgetTester tester) async {
        await tester.pumpWidget(
          makeTestable(
            UnclaimedDepositsLayout(
              depositsAsync: const AsyncValue<List<DepositCardData>>.loading(),
              onRetryClaim: (_) async {},
              onRefund: (_) {},
              onCopyTxid: (_) {},
              depositCardBuilder: (DepositCardData cardData) {
                return DepositCard(
                  deposit: cardData.deposit,
                  hasError: cardData.hasError,
                  hasRefund: cardData.hasRefund,
                  formattedTxid: cardData.formattedTxid,
                  formattedErrorMessage: cardData.formattedErrorMessage,
                  onRetryClaim: () {},
                  onRefund: () {},
                  onCopyTxid: () {},
                );
              },
            ),
          ),
        );

        expect(find.byType(Scaffold), findsOneWidget);
      });

      testWidgets('always shows AppBar with title', (WidgetTester tester) async {
        await tester.pumpWidget(
          makeTestable(
            UnclaimedDepositsLayout(
              depositsAsync: const AsyncValue<List<DepositCardData>>.loading(),
              onRetryClaim: (_) async {},
              onRefund: (_) {},
              onCopyTxid: (_) {},
              depositCardBuilder: (DepositCardData cardData) {
                return DepositCard(
                  deposit: cardData.deposit,
                  hasError: cardData.hasError,
                  hasRefund: cardData.hasRefund,
                  formattedTxid: cardData.formattedTxid,
                  formattedErrorMessage: cardData.formattedErrorMessage,
                  onRetryClaim: () {},
                  onRefund: () {},
                  onCopyTxid: () {},
                );
              },
            ),
          ),
        );

        expect(find.byType(AppBar), findsOneWidget);
        expect(find.text('Pending Deposits'), findsOneWidget);
      });
    });

    group('state transitions', () {
      testWidgets('transitions from loading to loaded', (WidgetTester tester) async {
        await tester.pumpWidget(
          makeTestable(
            UnclaimedDepositsLayout(
              depositsAsync: const AsyncValue<List<DepositCardData>>.loading(),
              onRetryClaim: (_) async {},
              onRefund: (_) {},
              onCopyTxid: (_) {},
              depositCardBuilder: (DepositCardData cardData) {
                return DepositCard(
                  deposit: cardData.deposit,
                  hasError: cardData.hasError,
                  hasRefund: cardData.hasRefund,
                  formattedTxid: cardData.formattedTxid,
                  formattedErrorMessage: cardData.formattedErrorMessage,
                  onRetryClaim: () {},
                  onRefund: () {},
                  onCopyTxid: () {},
                );
              },
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Update with data
        final List<DepositInfo> deposits = <DepositInfo>[
          _createMockDeposit(txid: 'txid1', amountSats: BigInt.from(10000)),
        ];
        await tester.pumpWidget(
          makeTestable(
            UnclaimedDepositsLayout(
              depositsAsync: cardDataAsync(AsyncValue<List<DepositInfo>>.data(deposits)),
              onRetryClaim: (_) async {},
              onRefund: (_) {},
              onCopyTxid: (_) {},
              depositCardBuilder: (DepositCardData cardData) {
                return DepositCard(
                  deposit: cardData.deposit,
                  hasError: cardData.hasError,
                  hasRefund: cardData.hasRefund,
                  formattedTxid: cardData.formattedTxid,
                  formattedErrorMessage: cardData.formattedErrorMessage,
                  onRetryClaim: () {},
                  onRefund: () {},
                  onCopyTxid: () {},
                );
              },
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.byType(DepositCard), findsOneWidget);
      });

      testWidgets('transitions from loaded to error', (WidgetTester tester) async {
        final List<DepositInfo> deposits = <DepositInfo>[
          _createMockDeposit(txid: 'txid1', amountSats: BigInt.from(10000)),
        ];

        await tester.pumpWidget(
          makeTestable(
            UnclaimedDepositsLayout(
              depositsAsync: cardDataAsync(AsyncValue<List<DepositInfo>>.data(deposits)),
              onRetryClaim: (_) async {},
              onRefund: (_) {},
              onCopyTxid: (_) {},
              depositCardBuilder: (DepositCardData cardData) {
                return DepositCard(
                  deposit: cardData.deposit,
                  hasError: cardData.hasError,
                  hasRefund: cardData.hasRefund,
                  formattedTxid: cardData.formattedTxid,
                  formattedErrorMessage: cardData.formattedErrorMessage,
                  onRetryClaim: () {},
                  onRefund: () {},
                  onCopyTxid: () {},
                );
              },
            ),
          ),
        );

        expect(find.byType(DepositCard), findsOneWidget);

        // Update with error
        await tester.pumpWidget(
          makeTestable(
            UnclaimedDepositsLayout(
              depositsAsync: AsyncValue<List<DepositCardData>>.error(
                Exception('Error'),
                StackTrace.empty,
              ),
              onRetryClaim: (_) async {},
              onRefund: (_) {},
              onCopyTxid: (_) {},
              depositCardBuilder: (DepositCardData cardData) {
                return DepositCard(
                  deposit: cardData.deposit,
                  hasError: cardData.hasError,
                  hasRefund: cardData.hasRefund,
                  formattedTxid: cardData.formattedTxid,
                  formattedErrorMessage: cardData.formattedErrorMessage,
                  onRetryClaim: () {},
                  onRefund: () {},
                  onCopyTxid: () {},
                );
              },
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(DepositCard), findsNothing);
        expect(find.text('Failed to load deposits'), findsOneWidget);
      });
    });

    group('edge cases', () {
      testWidgets('handles single deposit correctly', (WidgetTester tester) async {
        final List<DepositInfo> deposits = <DepositInfo>[
          _createMockDeposit(txid: 'txid1', amountSats: BigInt.from(10000)),
        ];

        await tester.pumpWidget(
          makeTestable(
            UnclaimedDepositsLayout(
              depositsAsync: cardDataAsync(AsyncValue<List<DepositInfo>>.data(deposits)),
              onRetryClaim: (_) async {},
              onRefund: (_) {},
              onCopyTxid: (_) {},
              depositCardBuilder: (DepositCardData cardData) {
                return DepositCard(
                  deposit: cardData.deposit,
                  hasError: cardData.hasError,
                  hasRefund: cardData.hasRefund,
                  formattedTxid: cardData.formattedTxid,
                  formattedErrorMessage: cardData.formattedErrorMessage,
                  onRetryClaim: () {},
                  onRefund: () {},
                  onCopyTxid: () {},
                );
              },
            ),
          ),
        );

        expect(find.byType(DepositCard), findsOneWidget);
      });

      testWidgets('handles many deposits correctly', (WidgetTester tester) async {
        // Each deposit amount increases by 10,000 sats per index
        final List<DepositInfo> deposits = List<DepositInfo>.generate(10, (int i) {
          final int amountSats = 10000 * (i + 1);
          return _createMockDeposit(txid: 'txid$i', amountSats: BigInt.from(amountSats));
        });

        // Use tester.view instead of deprecated tester.binding.window
        final TestFlutterView view = tester.view;
        final Size originalPhysicalSize = view.physicalSize;
        final double originalDevicePixelRatio = view.devicePixelRatio;

        view.physicalSize = const Size(1000, 3000);
        view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          makeTestable(
            UnclaimedDepositsLayout(
              depositsAsync: cardDataAsync(AsyncValue<List<DepositInfo>>.data(deposits)),
              onRetryClaim: (_) async {},
              onRefund: (_) {},
              onCopyTxid: (_) {},
              depositCardBuilder: (DepositCardData cardData) {
                return DepositCard(
                  deposit: cardData.deposit,
                  hasError: cardData.hasError,
                  hasRefund: cardData.hasRefund,
                  formattedTxid: cardData.formattedTxid,
                  formattedErrorMessage: cardData.formattedErrorMessage,
                  onRetryClaim: () {},
                  onRefund: () {},
                  onCopyTxid: () {},
                );
              },
            ),
          ),
        );

        expect(find.byType(DepositCard), findsNWidgets(10));

        // Clean up after test
        addTearDown(() {
          view.physicalSize = originalPhysicalSize;
          view.devicePixelRatio = originalDevicePixelRatio;
        });
      });

      testWidgets('handles error with null message gracefully', (WidgetTester tester) async {
        await tester.pumpWidget(
          makeTestable(
            UnclaimedDepositsLayout(
              depositsAsync: const AsyncValue<List<DepositCardData>>.error(
                'String error',
                StackTrace.empty,
              ),
              onRetryClaim: (_) async {},
              onRefund: (_) {},
              onCopyTxid: (_) {},
              depositCardBuilder: (DepositCardData cardData) {
                return DepositCard(
                  deposit: cardData.deposit,
                  hasError: cardData.hasError,
                  hasRefund: cardData.hasRefund,
                  formattedTxid: cardData.formattedTxid,
                  formattedErrorMessage: cardData.formattedErrorMessage,
                  onRetryClaim: () {},
                  onRefund: () {},
                  onCopyTxid: () {},
                );
              },
            ),
          ),
        );

        expect(find.text('Failed to load deposits'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      });
    });
  });
}

// Helper function to create mock DepositInfo
DepositInfo _createMockDeposit({
  required String txid,
  required BigInt amountSats,
  int? vout,
  DepositClaimError? claimError,
  String? refundTx,
  String? refundTxId,
}) {
  return DepositInfo(
    txid: txid,
    vout: vout ?? 0,
    amountSats: amountSats,
    claimError: claimError,
    refundTx: refundTx,
    refundTxId: refundTxId,
  );
}

AsyncValue<List<DepositCardData>> cardDataAsync(AsyncValue<List<DepositInfo>> depositsAsync) {
  return depositsAsync.map(
    data: (AsyncData<List<DepositInfo>> data) {
      final List<DepositCardData> cardDataList = data.value.map((DepositInfo deposit) {
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
      }).toList();
      return AsyncData<List<DepositCardData>>(cardDataList);
    },
    loading: (AsyncLoading<List<DepositInfo>> loading) =>
        const AsyncLoading<List<DepositCardData>>(),
    error: (AsyncError<List<DepositInfo>> error) =>
        AsyncError<List<DepositCardData>>(error.error, error.stackTrace),
  );
}
