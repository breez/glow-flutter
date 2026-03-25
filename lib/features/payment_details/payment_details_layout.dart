import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:glow/features/payment_details/models/payment_details_state.dart';
import 'package:glow/widgets/back_button.dart';
import 'package:glow/features/payment_details/widgets/payment_details_widgets.dart';

/// Pure presentation widget for payment details
/// Only consumes provided state and renders widgets
/// No business logic, data mutation, or side effects.
class PaymentDetailsLayout extends StatelessWidget {
  const PaymentDetailsLayout({required this.state, super.key});

  final PaymentDetailsState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const GlowBackButton(), title: const Text('Payment Details')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            // Amount Section
            PaymentAmountDisplay(formattedAmount: state.formattedAmount),

            // Basic Details
            PaymentDetailRow(label: 'Status', value: state.formattedStatus),
            PaymentDetailRow(label: 'Type', value: state.formattedType),
            PaymentDetailRow(label: 'Method', value: state.formattedMethod),

            if (state.shouldShowFees)
              PaymentDetailRow(label: 'Fee', value: '${state.formattedFees} sats'),

            PaymentDetailRow(label: 'Date', value: state.formattedDate),

            const Divider(height: 32),

            PaymentDetailRow(label: 'Payment ID', value: state.payment.id, copyable: true),

            // Payment-specific details
            if (state.payment.details != null) ...<Widget>[
              const Divider(height: 32),
              _buildPaymentSpecificDetails(state.payment.details!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSpecificDetails(PaymentDetails details) {
    return switch (details) {
      PaymentDetails_Lightning() => LightningPaymentDetails(details: details),
      PaymentDetails_Token() => TokenPaymentDetails(details: details),
      PaymentDetails_Withdraw() => WithdrawPaymentDetails(details: details),
      PaymentDetails_Deposit() => DepositPaymentDetails(details: details),
      PaymentDetails_Spark() => const SizedBox.shrink(),
    };
  }
}
