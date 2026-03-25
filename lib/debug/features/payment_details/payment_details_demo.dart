import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:glow/features/payment_details/models/payment_details_state.dart';
import 'package:glow/features/payment_details/payment_details_layout.dart';
import 'package:glow/features/payment_details/services/payment_formatter.dart';

/// Demo screen examples showing the benefits of SoC
///
/// 1. Create demo instances of any payment state
/// 2. Test different UI states without real data
/// 3. Build UI catalogs or walkthroughs
/// 4. Write widget tests for specific states

class PaymentDetailsDemoScreen extends StatelessWidget {
  const PaymentDetailsDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Details Demos')),
      body: SafeArea(
        child: ListView(
          children: <Widget>[
            ListTile(
              title: const Text('Completed Lightning Send'),
              subtitle: const Text('Demo: Successful Lightning payment'),
              onTap: () => _openDemo(context, _createCompletedLightningState()),
            ),
            ListTile(
              title: const Text('Pending Lightning Receive'),
              subtitle: const Text('Demo: Pending incoming payment'),
              onTap: () => _openDemo(context, _createPendingLightningState()),
            ),
            ListTile(
              title: const Text('Failed Lightning Payment'),
              subtitle: const Text('Demo: Failed payment attempt'),
              onTap: () => _openDemo(context, _createFailedLightningState()),
            ),
            ListTile(
              title: const Text('Token Payment'),
              subtitle: const Text('Demo: Token transfer'),
              onTap: () => _openDemo(context, _createTokenPaymentState()),
            ),
            ListTile(
              title: const Text('Deposit'),
              subtitle: const Text('Demo: On-chain deposit'),
              onTap: () => _openDemo(context, _createDepositState()),
            ),
            ListTile(
              title: const Text('Withdraw'),
              subtitle: const Text('Demo: On-chain withdrawal'),
              onTap: () => _openDemo(context, _createWithdrawState()),
            ),
          ],
        ),
      ),
    );
  }

  void _openDemo(BuildContext context, PaymentDetailsState state) {
    showPaymentDetailsSheet(context, state);
  }

  // Demo state factories
  PaymentDetailsState _createCompletedLightningState() {
    const PaymentFormatter formatter = PaymentFormatter();
    final Payment payment = Payment(
      id: 'demo_lightning_001',
      amount: BigInt.from(50000),
      fees: BigInt.from(100),
      status: PaymentStatus.completed,
      paymentType: PaymentType.send,
      method: PaymentMethod.lightning,
      timestamp: BigInt.from(DateTime.now().millisecondsSinceEpoch ~/ 1000),
      details: PaymentDetails_Lightning(
        description: 'Coffee at Satoshi Cafe',
        invoice: 'lnbc500n1pj9x8z7pp5...',
        htlcDetails: SparkHtlcDetails(paymentHash: '1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef', preimage: 'fedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321', expiryTime: BigInt.zero, status: SparkHtlcStatus.preimageShared),
        destinationPubkey: '03abcd1234...',
      ),
    );

    return PaymentDetailsState(
      payment: payment,
      formattedAmount: formatter.formatSats(payment.amount),
      formattedFees: formatter.formatSats(payment.fees),
      formattedStatus: formatter.formatStatus(payment.status),
      formattedType: formatter.formatType(payment.paymentType),
      formattedMethod: formatter.formatMethod(payment.method),
      formattedDate: formatter.formatDate(payment.timestamp),
      shouldShowFees: true,
    );
  }

  PaymentDetailsState _createPendingLightningState() {
    const PaymentFormatter formatter = PaymentFormatter();
    final Payment payment = Payment(
      id: 'demo_lightning_002',
      amount: BigInt.from(100000),
      fees: BigInt.zero,
      status: PaymentStatus.pending,
      paymentType: PaymentType.receive,
      method: PaymentMethod.lightning,
      timestamp: BigInt.from(DateTime.now().millisecondsSinceEpoch ~/ 1000),
      details: PaymentDetails_Lightning(
        description: 'Invoice for services',
        invoice: 'lnbc1m1pj9x8z7pp5...',
        htlcDetails: SparkHtlcDetails(paymentHash: 'abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890', expiryTime: BigInt.zero, status: SparkHtlcStatus.waitingForPreimage),
        destinationPubkey: '03xyz9876...',
      ),
    );

    return PaymentDetailsState(
      payment: payment,
      formattedAmount: formatter.formatSats(payment.amount),
      formattedFees: formatter.formatSats(payment.fees),
      formattedStatus: formatter.formatStatus(payment.status),
      formattedType: formatter.formatType(payment.paymentType),
      formattedMethod: formatter.formatMethod(payment.method),
      formattedDate: formatter.formatDate(payment.timestamp),
      shouldShowFees: false,
    );
  }

  PaymentDetailsState _createFailedLightningState() {
    const PaymentFormatter formatter = PaymentFormatter();
    final Payment payment = Payment(
      id: 'demo_lightning_003',
      amount: BigInt.from(25000),
      fees: BigInt.zero,
      status: PaymentStatus.failed,
      paymentType: PaymentType.send,
      method: PaymentMethod.lightning,
      timestamp: BigInt.from(DateTime.now().millisecondsSinceEpoch ~/ 1000),
      details: PaymentDetails_Lightning(
        description: 'Failed payment',
        invoice: 'lnbc250n1pj9x8z7pp5...',
        htlcDetails: SparkHtlcDetails(paymentHash: '9876543210fedcba9876543210fedcba9876543210fedcba9876543210fedcba', expiryTime: BigInt.zero, status: SparkHtlcStatus.returned),
        destinationPubkey: '03def5678...',
      ),
    );

    return PaymentDetailsState(
      payment: payment,
      formattedAmount: formatter.formatSats(payment.amount),
      formattedFees: formatter.formatSats(payment.fees),
      formattedStatus: formatter.formatStatus(payment.status),
      formattedType: formatter.formatType(payment.paymentType),
      formattedMethod: formatter.formatMethod(payment.method),
      formattedDate: formatter.formatDate(payment.timestamp),
      shouldShowFees: false,
    );
  }

  PaymentDetailsState _createTokenPaymentState() {
    const PaymentFormatter formatter = PaymentFormatter();
    final Payment payment = Payment(
      id: 'demo_token_001',
      amount: BigInt.from(1000),
      fees: BigInt.from(50),
      status: PaymentStatus.completed,
      paymentType: PaymentType.receive,
      method: PaymentMethod.token,
      timestamp: BigInt.from(DateTime.now().millisecondsSinceEpoch ~/ 1000),
      details: PaymentDetails_Token(
        metadata: TokenMetadata(
          identifier: 'demo_asset_123',
          name: 'Demo Token',
          ticker: 'DEMO',
          decimals: 8,
          issuerPublicKey: '',
          maxSupply: BigInt.from(1000000),
          isFreezable: true,
        ),
        txHash: 'abc123def456...',
        txType: TokenTransactionType.transfer,
      ),
    );

    return PaymentDetailsState(
      payment: payment,
      formattedAmount: formatter.formatSats(payment.amount),
      formattedFees: formatter.formatSats(payment.fees),
      formattedStatus: formatter.formatStatus(payment.status),
      formattedType: formatter.formatType(payment.paymentType),
      formattedMethod: formatter.formatMethod(payment.method),
      formattedDate: formatter.formatDate(payment.timestamp),
      shouldShowFees: true,
    );
  }

  PaymentDetailsState _createDepositState() {
    const PaymentFormatter formatter = PaymentFormatter();
    final Payment payment = Payment(
      id: 'demo_deposit_001',
      amount: BigInt.from(500000),
      fees: BigInt.zero,
      status: PaymentStatus.completed,
      paymentType: PaymentType.receive,
      method: PaymentMethod.deposit,
      timestamp: BigInt.from(DateTime.now().millisecondsSinceEpoch ~/ 1000),
      details: const PaymentDetails_Deposit(
        txId: '1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef',
      ),
    );

    return PaymentDetailsState(
      payment: payment,
      formattedAmount: formatter.formatSats(payment.amount),
      formattedFees: formatter.formatSats(payment.fees),
      formattedStatus: formatter.formatStatus(payment.status),
      formattedType: formatter.formatType(payment.paymentType),
      formattedMethod: formatter.formatMethod(payment.method),
      formattedDate: formatter.formatDate(payment.timestamp),
      shouldShowFees: false,
    );
  }

  PaymentDetailsState _createWithdrawState() {
    const PaymentFormatter formatter = PaymentFormatter();
    final Payment payment = Payment(
      id: 'demo_withdraw_001',
      amount: BigInt.from(300000),
      fees: BigInt.from(2000),
      status: PaymentStatus.completed,
      paymentType: PaymentType.send,
      method: PaymentMethod.withdraw,
      timestamp: BigInt.from(DateTime.now().millisecondsSinceEpoch ~/ 1000),
      details: const PaymentDetails_Withdraw(
        txId: 'fedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321',
      ),
    );

    return PaymentDetailsState(
      payment: payment,
      formattedAmount: formatter.formatSats(payment.amount),
      formattedFees: formatter.formatSats(payment.fees),
      formattedStatus: formatter.formatStatus(payment.status),
      formattedType: formatter.formatType(payment.paymentType),
      formattedMethod: formatter.formatMethod(payment.method),
      formattedDate: formatter.formatDate(payment.timestamp),
      shouldShowFees: true,
    );
  }
}
