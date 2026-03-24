import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glow/core/services/transaction_formatter.dart';
import 'package:glow/features/balance/balance_display_layout.dart';
import 'package:glow/features/balance/models/balance_state.dart';
import 'package:glow/features/balance/widgets/balance_display_shimmer.dart';
import 'package:glow/features/transactions/models/transaction_list_state.dart';
import 'package:glow/features/transactions/transaction_list_layout.dart';
import 'package:glow/features/transactions/widgets/transaction_list_shimmer.dart';

void main() {
  group('BalanceFormatter Unit Tests', () {
    const TransactionFormatter formatter = TransactionFormatter();

    test('formats sats with thousand separators', () {
      expect(formatter.formatSats(BigInt.from(1000)), '1,000');
      expect(formatter.formatSats(BigInt.from(1000000)), '1,000,000');
      expect(formatter.formatSats(BigInt.from(21000000)), '21,000,000');
    });

    test('formats BTC with 8 decimals', () {
      expect(formatter.formatBtc(BigInt.from(100000000)), '1.00000000');
      expect(formatter.formatBtc(BigInt.from(50000000)), '0.50000000');
      expect(formatter.formatBtc(BigInt.from(1000)), '0.00001000');
    });

    test('formats balance with unit', () {
      expect(formatter.formatBalance(BigInt.from(1000)), '1,000 sats');
      expect(
        formatter.formatBalance(BigInt.from(100000000), unit: BalanceUnit.btc),
        '1.00000000 BTC',
      );
    });

    test('formats fiat correctly', () {
      final String formatted = formatter.formatFiat(BigInt.from(100000000), 45000.0, '\$');
      expect(formatted, '\$45000.00');
    });
  });

  group('TransactionFormatter Unit Tests', () {
    const TransactionFormatter formatter = TransactionFormatter();

    test('formats sats with thousand separators', () {
      expect(formatter.formatSats(BigInt.from(50000)), '50,000');
      expect(formatter.formatSats(BigInt.from(123456)), '123,456');
    });

    test('formats payment status', () {
      expect(formatter.formatStatus(PaymentStatus.completed), 'Completed');
      expect(formatter.formatStatus(PaymentStatus.pending), 'Pending');
      expect(formatter.formatStatus(PaymentStatus.failed), 'Failed');
    });

    test('formats payment type', () {
      expect(formatter.formatType(PaymentType.send), 'Send');
      expect(formatter.formatType(PaymentType.receive), 'Receive');
    });

    test('formats payment method', () {
      expect(formatter.formatMethod(PaymentMethod.lightning), 'Lightning');
      expect(formatter.formatMethod(PaymentMethod.deposit), 'Deposit');
    });

    test('formats amount with sign', () {
      expect(formatter.formatAmountWithSign(BigInt.from(1000), PaymentType.send), '-1,000');
      expect(formatter.formatAmountWithSign(BigInt.from(1000), PaymentType.receive), '+1,000');
    });

    test('formats relative time', () {
      final DateTime now = DateTime.now();

      // Just now
      final BigInt justNow = BigInt.from(now.millisecondsSinceEpoch ~/ 1000);
      expect(formatter.formatRelativeTime(justNow), 'Just now');

      // Minutes ago
      final BigInt minutesAgo = BigInt.from(
        now.subtract(const Duration(minutes: 5)).millisecondsSinceEpoch ~/ 1000,
      );
      expect(formatter.formatRelativeTime(minutesAgo), '5m ago');

      // Hours ago
      final BigInt hoursAgo = BigInt.from(
        now.subtract(const Duration(hours: 2)).millisecondsSinceEpoch ~/ 1000,
      );
      expect(formatter.formatRelativeTime(hoursAgo), '2h ago');
    });
  });

  group('TransactionItemState Unit Tests', () {
    const TransactionFormatter formatter = TransactionFormatter();

    test('creates transaction item state with formatted values', () {
      final Payment payment = Payment(
        id: 'test_001',
        amount: BigInt.from(50000),
        fees: BigInt.from(100),
        status: PaymentStatus.completed,
        paymentType: PaymentType.receive,
        method: PaymentMethod.lightning,
        timestamp: BigInt.from(DateTime.now().millisecondsSinceEpoch ~/ 1000),
      );

      final TransactionItemState state = TransactionItemState(
        payment: payment,
        formattedAmount: formatter.formatSats(payment.amount),
        formattedAmountWithSign: formatter.formatAmountWithSign(
          payment.amount,
          payment.paymentType,
        ),
        formattedTime: formatter.formatRelativeTime(payment.timestamp),
        formattedStatus: formatter.formatStatus(payment.status),
        formattedMethod: formatter.formatMethod(payment.method),
        description: '',
        isReceive: payment.paymentType == PaymentType.receive,
      );

      expect(state.formattedAmount, '50,000');
      expect(state.formattedAmountWithSign, '+ 50,000');
      expect(state.isReceive, true);
      expect(state.formattedStatus, 'Completed');
    });
  });

  group('TransactionListState Unit Tests', () {
    test('creates loaded transaction list state', () {
      final Payment payment = Payment(
        id: 'test_001',
        amount: BigInt.from(50000),
        fees: BigInt.zero,
        status: PaymentStatus.completed,
        paymentType: PaymentType.receive,
        method: PaymentMethod.lightning,
        timestamp: BigInt.from(DateTime.now().millisecondsSinceEpoch ~/ 1000),
      );

      final TransactionItemState item = TransactionItemState(
        payment: payment,
        formattedAmount: '50,000',
        formattedAmountWithSign: '+ 50,000',
        formattedTime: 'Just now',
        formattedStatus: 'Completed',
        formattedMethod: 'Lightning',
        description: '',
        isReceive: true,
      );

      final TransactionListState state = TransactionListState.loaded(
        transactions: <TransactionItemState>[item],
        hasSynced: true,
      );

      expect(state.hasTransactions, true);
      expect(state.transactions.length, 1);
      expect(state.isLoading, false);
    });

    test('creates empty transaction list state', () {
      final TransactionListState state = TransactionListState.empty();

      expect(state.isEmpty, true);
      expect(state.hasTransactions, false);
    });
  });

  group('BalanceDisplayLayout Widget Tests', () {
    testWidgets('displays loading state', (WidgetTester tester) async {
      final BalanceState state = BalanceState.loading();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SafeArea(child: BalanceDisplayLayout(state: state)),
          ),
        ),
      );

      expect(find.byType(BalanceDisplayShimmer), findsOneWidget);
    });

    testWidgets('displays loaded balance', (WidgetTester tester) async {
      final BalanceState state = BalanceState.loaded(
        balance: BigInt.from(1000000),
        hasSynced: true,
        formattedBalance: '1,000,000',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SafeArea(child: BalanceDisplayLayout(state: state)),
          ),
        ),
      );

      expect(find.byType(RichText), findsOneWidget);
      final RichText richText = tester.widget<RichText>(find.byType(RichText));
      expect(richText.text.toPlainText(), contains('1,000,000'));
      expect(richText.text.toPlainText(), contains('sats'));
    });

    testWidgets('displays error state', (WidgetTester tester) async {
      final BalanceState state = BalanceState.error('Network error');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SafeArea(child: BalanceDisplayLayout(state: state)),
          ),
        ),
      );

      expect(find.text('Network error'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });
  });

  group('TransactionListLayout Widget Tests', () {
    testWidgets('displays loading state', (WidgetTester tester) async {
      final TransactionListState state = TransactionListState.loading();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SafeArea(child: TransactionListLayout(state: state)),
          ),
        ),
      );

      expect(find.byType(TransactionListShimmer), findsOneWidget);
    });

    testWidgets('displays empty state', (WidgetTester tester) async {
      final TransactionListState state = TransactionListState.empty();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SafeArea(child: TransactionListLayout(state: state)),
          ),
        ),
      );

      expect(find.text('Glow is ready to receive funds.'), findsOneWidget);
    });

    testWidgets('displays transaction list', (WidgetTester tester) async {
      final Payment mockPayment = Payment(
        id: 'test_001',
        amount: BigInt.from(50000),
        fees: BigInt.zero,
        status: PaymentStatus.completed,
        paymentType: PaymentType.receive,
        method: PaymentMethod.lightning,
        timestamp: BigInt.from(DateTime.now().millisecondsSinceEpoch ~/ 1000),
        details: PaymentDetails_Lightning(
          description: 'Test payment',
          invoice: 'lnbc...',
          htlcDetails: SparkHtlcDetails(paymentHash: 'hash...', preimage: 'pre...', expiryTime: BigInt.zero, status: SparkHtlcStatus.preimageShared),
          destinationPubkey: 'pub...',
        ),
      );

      final TransactionItemState transaction = TransactionItemState(
        payment: mockPayment,
        formattedAmount: '50,000',
        formattedAmountWithSign: '+ 50,000',
        formattedTime: '2h ago',
        formattedStatus: 'Completed',
        formattedMethod: 'Lightning',
        description: 'Test payment',
        isReceive: true,
      );

      final TransactionListState state = TransactionListState.loaded(
        transactions: <TransactionItemState>[transaction],
        hasSynced: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SafeArea(child: TransactionListLayout(state: state)),
          ),
        ),
      );

      expect(find.text('Test payment'), findsOneWidget);
      expect(find.text('+50,000'), findsOneWidget);
      expect(find.text('2h ago'), findsOneWidget);
    });
  });

  group('BalanceState Equality Tests', () {
    test('two states with same values are equal', () {
      final BalanceState state1 = BalanceState.loaded(
        balance: BigInt.from(1000),
        hasSynced: true,
        formattedBalance: '1,000',
      );

      final BalanceState state2 = BalanceState.loaded(
        balance: BigInt.from(1000),
        hasSynced: true,
        formattedBalance: '1,000',
      );

      expect(state1, equals(state2));
    });

    test('two states with different values are not equal', () {
      final BalanceState state1 = BalanceState.loaded(
        balance: BigInt.from(1000),
        hasSynced: true,
        formattedBalance: '1,000',
      );

      final BalanceState state2 = BalanceState.loaded(
        balance: BigInt.from(2000),
        hasSynced: true,
        formattedBalance: '2,000',
      );

      expect(state1, isNot(equals(state2)));
    });
  });
}
