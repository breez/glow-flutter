import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glow/features/deposits/refund/refund_layout.dart';
import 'package:glow/features/deposits/refund/refund_state.dart';

void main() {
  group('RefundLayout Widget Tests', () {
    late DepositInfo mockDeposit;
    late RecommendedFees mockFees;

    setUp(() {
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

    Widget makeTestableWidget(RefundState state) {
      return MaterialApp(
        home: RefundLayout(
          state: state,
          onPrepareRefund: (_) {},
          onSelectFeeSpeed: (_) {},
          onSendRefund: () {},
          onRetry: (_) {},
          onCancel: () {},
        ),
      );
    }

    group('Address Input Phase (RefundInitial)', () {
      testWidgets('Displays address input field', (WidgetTester tester) async {
        final RefundState state = RefundInitial(deposit: mockDeposit);
        await tester.pumpWidget(makeTestableWidget(state));

        expect(find.byType(TextFormField), findsOneWidget);
        expect(find.text('BTC Address'), findsOneWidget);
        expect(find.text('bc1q...'), findsOneWidget);
      });

      testWidgets('Displays deposit amount', (WidgetTester tester) async {
        final RefundState state = RefundInitial(deposit: mockDeposit);
        await tester.pumpWidget(makeTestableWidget(state));

        expect(find.textContaining('10,000 sats'), findsOneWidget);
        expect(find.text('Amount:'), findsOneWidget);
      });

      testWidgets('Shows "Get Refund" title', (WidgetTester tester) async {
        final RefundState state = RefundInitial(deposit: mockDeposit);
        await tester.pumpWidget(makeTestableWidget(state));

        expect(find.text('Get Refund'), findsOneWidget);
      });

      testWidgets('Validates empty address', (WidgetTester tester) async {
        final RefundState state = RefundInitial(deposit: mockDeposit);
        bool prepareCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: RefundLayout(
              state: state,
              onPrepareRefund: (_) {
                prepareCalled = true;
              },
              onSelectFeeSpeed: (_) {},
              onSendRefund: () {},
              onRetry: (_) {},
              onCancel: () {},
            ),
          ),
        );

        // Find and tap the GET REFUND button
        await tester.tap(find.text('GET REFUND'));
        await tester.pumpAndSettle();

        expect(find.text('Please enter a Bitcoin address'), findsOneWidget);
        expect(prepareCalled, isFalse);
      });

      testWidgets('Validates invalid address format', (WidgetTester tester) async {
        final RefundState state = RefundInitial(deposit: mockDeposit);
        bool prepareCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: RefundLayout(
              state: state,
              onPrepareRefund: (_) {
                prepareCalled = true;
              },
              onSelectFeeSpeed: (_) {},
              onSendRefund: () {},
              onRetry: (_) {},
              onCancel: () {},
            ),
          ),
        );

        // Enter invalid address
        await tester.enterText(find.byType(TextFormField), 'invalid_address');
        await tester.tap(find.text('GET REFUND'));
        await tester.pumpAndSettle();

        expect(find.text('Invalid Bitcoin address format'), findsOneWidget);
        expect(prepareCalled, isFalse);
      });

      testWidgets('Calls onPrepareRefund with valid address', (WidgetTester tester) async {
        final RefundState state = RefundInitial(deposit: mockDeposit);
        String? capturedAddress;

        await tester.pumpWidget(
          MaterialApp(
            home: RefundLayout(
              state: state,
              onPrepareRefund: (String address) {
                capturedAddress = address;
              },
              onSelectFeeSpeed: (_) {},
              onSendRefund: () {},
              onRetry: (_) {},
              onCancel: () {},
            ),
          ),
        );

        // Enter valid address
        await tester.enterText(find.byType(TextFormField), 'bc1qtest');
        await tester.tap(find.text('GET REFUND'));
        await tester.pumpAndSettle();

        expect(capturedAddress, equals('bc1qtest'));
      });
    });

    group('Loading Phase (RefundPreparing)', () {
      testWidgets('Shows loading indicator', (WidgetTester tester) async {
        final RefundState state = RefundPreparing(
          deposit: mockDeposit,
          destinationAddress: 'bc1qtest',
        );
        await tester.pumpWidget(makeTestableWidget(state));

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('Still shows "Get Refund" title', (WidgetTester tester) async {
        final RefundState state = RefundPreparing(
          deposit: mockDeposit,
          destinationAddress: 'bc1qtest',
        );
        await tester.pumpWidget(makeTestableWidget(state));

        expect(find.text('Get Refund'), findsOneWidget);
      });
    });

    group('Fee Selection Phase (RefundReady)', () {
      late RefundReady readyState;

      setUp(() {
        readyState = RefundReady(
          deposit: mockDeposit,
          destinationAddress: 'bc1qtest',
          fees: mockFees,
        );
      });

      testWidgets('Shows "Choose Processing Speed" title', (WidgetTester tester) async {
        await tester.pumpWidget(makeTestableWidget(readyState));

        expect(find.text('Choose Processing Speed'), findsOneWidget);
      });

      testWidgets('Displays 3 fee speed tabs', (WidgetTester tester) async {
        await tester.pumpWidget(makeTestableWidget(readyState));

        expect(find.text('ECONOMY'), findsOneWidget);
        expect(find.text('REGULAR'), findsOneWidget);
        expect(find.text('PRIORITY'), findsOneWidget);
      });

      testWidgets('Displays delivery time estimate', (WidgetTester tester) async {
        await tester.pumpWidget(makeTestableWidget(readyState));

        expect(find.textContaining('Estimated Delivery'), findsOneWidget);
        expect(find.textContaining('~30 minutes'), findsOneWidget); // Default is regular
      });

      testWidgets('Displays fee breakdown card', (WidgetTester tester) async {
        await tester.pumpWidget(makeTestableWidget(readyState));

        expect(find.text('Deposit amount:'), findsOneWidget);
        expect(find.text('Transaction fee:'), findsOneWidget);
        expect(find.text('You receive:'), findsOneWidget);
        expect(find.textContaining('10,000 sats'), findsAtLeastNWidgets(1));
        expect(find.textContaining('-900 sats'), findsOneWidget); // Regular fee
      });

      testWidgets('Shows CONFIRM button', (WidgetTester tester) async {
        await tester.pumpWidget(makeTestableWidget(readyState));

        expect(find.text('CONFIRM'), findsOneWidget);
      });

      testWidgets('Calls onSelectFeeSpeed when tab tapped', (WidgetTester tester) async {
        RefundFeeSpeed? capturedSpeed;

        await tester.pumpWidget(
          MaterialApp(
            home: RefundLayout(
              state: readyState,
              onPrepareRefund: (_) {},
              onSelectFeeSpeed: (RefundFeeSpeed speed) {
                capturedSpeed = speed;
              },
              onSendRefund: () {},
              onRetry: (_) {},
              onCancel: () {},
            ),
          ),
        );

        await tester.tap(find.text('ECONOMY'));
        await tester.pumpAndSettle();

        expect(capturedSpeed, equals(RefundFeeSpeed.economy));
      });

      testWidgets('Disabled tabs show reduced opacity', (WidgetTester tester) async {
        final DepositInfo smallDeposit = DepositInfo(
          txid: 'test_txid',
          vout: 0,
          amountSats: BigInt.from(500), // Only economy affordable
        );

        final RefundReady stateWithLimitedFunds = RefundReady(
          deposit: smallDeposit,
          destinationAddress: 'bc1qtest',
          fees: mockFees,
        );

        await tester.pumpWidget(makeTestableWidget(stateWithLimitedFunds));

        // Find the tabs by text
        final Finder economyTab = find.text('ECONOMY');
        final Finder regularTab = find.text('REGULAR');
        final Finder priorityTab = find.text('PRIORITY');

        expect(economyTab, findsOneWidget);
        expect(regularTab, findsOneWidget);
        expect(priorityTab, findsOneWidget);

        // Verify disabled tabs have grey background
        final Container regularContainer =
            tester.widget<InkWell>(find.ancestor(of: regularTab, matching: find.byType(InkWell))).child! as Container;
        expect(regularContainer.decoration, isA<BoxDecoration>());
        final BoxDecoration regularDecoration = regularContainer.decoration! as BoxDecoration;
        expect(regularDecoration.color, equals(Colors.grey));
      });

      testWidgets('Updates delivery estimate for different speeds', (WidgetTester tester) async {
        final RefundReady economyState = readyState.copyWith(selectedSpeed: RefundFeeSpeed.economy);
        await tester.pumpWidget(makeTestableWidget(economyState));
        expect(find.textContaining('~1 hour'), findsOneWidget);

        final RefundReady priorityState = readyState.copyWith(selectedSpeed: RefundFeeSpeed.priority);
        await tester.pumpWidget(makeTestableWidget(priorityState));
        expect(find.textContaining('~10 minutes'), findsOneWidget);
      });
    });

    group('Error Phase (RefundError)', () {
      testWidgets('Displays error message', (WidgetTester tester) async {
        const RefundState state = RefundError(
          message: 'Network error',
          technicalDetails: 'Connection timeout',
        );
        await tester.pumpWidget(makeTestableWidget(state));

        expect(find.text('Network error'), findsOneWidget);
        expect(find.text('Connection timeout'), findsOneWidget);
      });
    });

    group('Success Phase (RefundSuccess)', () {
      testWidgets('Shows success status view', (WidgetTester tester) async {
        const RefundState state = RefundSuccess(txId: 'success_tx_123');
        await tester.pumpWidget(makeTestableWidget(state));

        // PaymentStatusView should be displayed
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.byType(TextFormField), findsNothing);
      });
    });

    group('Sending Phase (RefundSending)', () {
      testWidgets('Shows sending status view', (WidgetTester tester) async {
        final RefundState state = RefundSending(
          deposit: mockDeposit,
          destinationAddress: 'bc1qtest',
          selectedSpeed: RefundFeeSpeed.regular,
        );
        await tester.pumpWidget(makeTestableWidget(state));

        // PaymentStatusView should be displayed
        expect(find.byType(TextFormField), findsNothing);
      });
    });
  });
}
