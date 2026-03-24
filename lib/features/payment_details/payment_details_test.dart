import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glow/features/payment_details/models/payment_details_state.dart';
import 'package:glow/features/payment_details/payment_details_layout.dart';
import 'package:glow/features/payment_details/services/payment_formatter.dart';
import 'package:glow/features/payment_details/widgets/payment_details_widgets.dart';

/// Example tests demonstrating the testability benefits of SoC
///
/// These tests show how SoC makes testing:
/// - Easier: No complex setup needed
/// - Focused: Test one thing at a time
/// - Fast: No framework overhead for unit tests
/// - Reliable: No flaky UI interactions for logic tests

void main() {
  group('PaymentFormatter Unit Tests', () {
    const PaymentFormatter formatter = PaymentFormatter();

    test('formats sats with thousand separators', () {
      expect(formatter.formatSats(BigInt.from(1000)), '1,000');
      expect(formatter.formatSats(BigInt.from(1000000)), '1,000,000');
      expect(formatter.formatSats(BigInt.from(123456789)), '123,456,789');
    });

    test('formats payment status correctly', () {
      expect(formatter.formatStatus(PaymentStatus.completed), 'Completed');
      expect(formatter.formatStatus(PaymentStatus.pending), 'Pending');
      expect(formatter.formatStatus(PaymentStatus.failed), 'Failed');
    });

    test('formats payment type correctly', () {
      expect(formatter.formatType(PaymentType.send), 'Send');
      expect(formatter.formatType(PaymentType.receive), 'Receive');
    });

    test('formats payment method correctly', () {
      expect(formatter.formatMethod(PaymentMethod.lightning), 'Lightning');
      expect(formatter.formatMethod(PaymentMethod.spark), 'Spark');
      expect(formatter.formatMethod(PaymentMethod.token), 'Token');
    });

    test('formats date correctly', () {
      // Unix timestamp for 2024-01-15 12:30:00
      final BigInt timestamp = BigInt.from(1705321800);
      final String formatted = formatter.formatDate(timestamp);
      expect(formatted, contains('15/1/2024'));
    });
  });

  group('PaymentDetailsStateFactory Unit Tests', () {
    const PaymentFormatter formatter = PaymentFormatter();
    const PaymentDetailsStateFactory factory = PaymentDetailsStateFactory(formatter);

    test('creates state with formatted values', () {
      final Payment payment = Payment(
        id: 'test_001',
        amount: BigInt.from(100000),
        fees: BigInt.from(500),
        status: PaymentStatus.completed,
        paymentType: PaymentType.send,
        method: PaymentMethod.lightning,
        timestamp: BigInt.from(1705321800),
      );

      final PaymentDetailsState state = factory.createState(payment);

      expect(state.formattedAmount, '100,000');
      expect(state.formattedFees, '500');
      expect(state.formattedStatus, 'Completed');
      expect(state.formattedType, 'Send');
      expect(state.formattedMethod, 'Lightning');
      expect(state.shouldShowFees, true);
    });

    test('sets shouldShowFees to false when fees are zero', () {
      final Payment payment = Payment(
        id: 'test_002',
        amount: BigInt.from(50000),
        fees: BigInt.zero,
        status: PaymentStatus.pending,
        paymentType: PaymentType.receive,
        method: PaymentMethod.lightning,
        timestamp: BigInt.from(1705321800),
      );

      final PaymentDetailsState state = factory.createState(payment);

      expect(state.shouldShowFees, false);
    });
  });

  group('PaymentAmountDisplay Widget Tests', () {
    testWidgets('displays formatted amount correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SafeArea(child: PaymentAmountDisplay(formattedAmount: '1,234,567')),
          ),
        ),
      );

      expect(find.text('1,234,567'), findsOneWidget);
      expect(find.text('sats'), findsOneWidget);
    });
  });

  group('PaymentDetailRow Widget Tests', () {
    testWidgets('displays label and value', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SafeArea(
              child: PaymentDetailRow(label: 'Status', value: 'Completed'),
            ),
          ),
        ),
      );

      expect(find.text('Status'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
    });

    testWidgets('shows copy icon when copyable is true', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SafeArea(
              child: PaymentDetailRow(label: 'Invoice', value: 'lnbc123...', copyable: true),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.copy), findsOneWidget);
    });

    testWidgets('does not show copy icon when copyable is false', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SafeArea(
              child: PaymentDetailRow(label: 'Status', value: 'Completed'),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.copy), findsNothing);
    });
  });

  group('PaymentDetailsLayout Widget Tests', () {
    testWidgets('displays all basic payment information', (WidgetTester tester) async {
      final Payment payment = Payment(
        id: 'test_payment_123',
        amount: BigInt.from(50000),
        fees: BigInt.from(100),
        status: PaymentStatus.completed,
        paymentType: PaymentType.send,
        method: PaymentMethod.lightning,
        timestamp: BigInt.from(1705321800),
      );

      final PaymentDetailsState state = PaymentDetailsState(
        payment: payment,
        formattedAmount: '50,000',
        formattedFees: '100',
        formattedStatus: 'Completed',
        formattedType: 'Send',
        formattedMethod: 'Lightning',
        formattedDate: '15/1/2024 at 12:30',
        shouldShowFees: true,
      );

      await tester.pumpWidget(MaterialApp(home: PaymentDetailsLayout(state: state)));

      // Verify all fields are displayed
      expect(find.text('50,000'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Send'), findsOneWidget);
      expect(find.text('Lightning'), findsOneWidget);
      expect(find.text('100 sats'), findsOneWidget);
      expect(find.text('15/1/2024 at 12:30'), findsOneWidget);
      expect(find.text('test_payment_123'), findsOneWidget);
    });

    testWidgets('hides fees when shouldShowFees is false', (WidgetTester tester) async {
      final Payment payment = Payment(
        id: 'test_payment_456',
        amount: BigInt.from(25000),
        fees: BigInt.zero,
        status: PaymentStatus.pending,
        paymentType: PaymentType.receive,
        method: PaymentMethod.lightning,
        timestamp: BigInt.from(1705321800),
      );

      final PaymentDetailsState state = PaymentDetailsState(
        payment: payment,
        formattedAmount: '25,000',
        formattedFees: '0',
        formattedStatus: 'Pending',
        formattedType: 'Receive',
        formattedMethod: 'Lightning',
        formattedDate: '15/1/2024 at 12:30',
        shouldShowFees: false,
      );

      await tester.pumpWidget(MaterialApp(home: PaymentDetailsLayout(state: state)));

      expect(find.text('Fee'), findsNothing);
      expect(find.text('0 sats'), findsNothing);
    });

    testWidgets('displays Lightning payment details', (WidgetTester tester) async {
      final Payment payment = Payment(
        id: 'lightning_test',
        amount: BigInt.from(10000),
        fees: BigInt.from(50),
        status: PaymentStatus.completed,
        paymentType: PaymentType.send,
        method: PaymentMethod.lightning,
        timestamp: BigInt.from(1705321800),
        details: PaymentDetails_Lightning(
          description: 'Test payment',
          invoice: 'lnbc100n1...',
          htlcDetails: SparkHtlcDetails(paymentHash: 'abc123...', preimage: 'def456...', expiryTime: BigInt.zero, status: SparkHtlcStatus.preimageShared),
          destinationPubkey: '03xyz...',
        ),
      );

      final PaymentDetailsState state = PaymentDetailsState(
        payment: payment,
        formattedAmount: '10,000',
        formattedFees: '50',
        formattedStatus: 'Completed',
        formattedType: 'Send',
        formattedMethod: 'Lightning',
        formattedDate: '15/1/2024 at 12:30',
        shouldShowFees: true,
      );

      await tester.pumpWidget(MaterialApp(home: PaymentDetailsLayout(state: state)));

      expect(find.text('Test payment'), findsOneWidget);
      expect(find.text('lnbc100n1...'), findsOneWidget);
      expect(find.text('abc123...'), findsOneWidget);
      expect(find.text('def456...'), findsOneWidget);
      expect(find.text('03xyz...'), findsOneWidget);
    });
  });

  group('PaymentDetailsState Equality Tests', () {
    test('two states with same values are equal', () {
      final Payment payment = Payment(
        id: 'test_001',
        amount: BigInt.from(100000),
        fees: BigInt.zero,
        status: PaymentStatus.completed,
        paymentType: PaymentType.send,
        method: PaymentMethod.lightning,
        timestamp: BigInt.from(1705321800),
      );

      final PaymentDetailsState state1 = PaymentDetailsState(
        payment: payment,
        formattedAmount: '100,000',
        formattedFees: '0',
        formattedStatus: 'Completed',
        formattedType: 'Send',
        formattedMethod: 'Lightning',
        formattedDate: '15/1/2024 at 12:30',
        shouldShowFees: false,
      );

      final PaymentDetailsState state2 = PaymentDetailsState(
        payment: payment,
        formattedAmount: '100,000',
        formattedFees: '0',
        formattedStatus: 'Completed',
        formattedType: 'Send',
        formattedMethod: 'Lightning',
        formattedDate: '15/1/2024 at 12:30',
        shouldShowFees: false,
      );

      expect(state1, equals(state2));
      expect(state1.hashCode, equals(state2.hashCode));
    });

    test('two states with different formatted values are not equal', () {
      final Payment payment = Payment(
        id: 'test_001',
        amount: BigInt.from(100000),
        fees: BigInt.zero,
        status: PaymentStatus.completed,
        paymentType: PaymentType.send,
        method: PaymentMethod.lightning,
        timestamp: BigInt.from(1705321800),
      );

      final PaymentDetailsState state1 = PaymentDetailsState(
        payment: payment,
        formattedAmount: '100,000',
        formattedFees: '0',
        formattedStatus: 'Completed',
        formattedType: 'Send',
        formattedMethod: 'Lightning',
        formattedDate: '15/1/2024 at 12:30',
        shouldShowFees: false,
      );

      final PaymentDetailsState state2 = PaymentDetailsState(
        payment: payment,
        formattedAmount: '200,000', // Different!
        formattedFees: '0',
        formattedStatus: 'Completed',
        formattedType: 'Send',
        formattedMethod: 'Lightning',
        formattedDate: '15/1/2024 at 12:30',
        shouldShowFees: false,
      );

      expect(state1, isNot(equals(state2)));
    });
  });
}
