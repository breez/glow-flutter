import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart' hide PaymentStatus;
import 'package:flutter/material.dart';
import 'package:glow/features/send_payment/models/bolt11_payment_state.dart';
import 'package:glow/widgets/back_button.dart';
import 'package:glow/features/send_payment/widgets/payment_confirmation_view.dart';
import 'package:glow/features/send_payment/widgets/payment_status_view.dart';
import 'package:glow/features/send_payment/widgets/payment_bottom_nav.dart';
import 'package:glow/widgets/error_card.dart';

/// Layout for BOLT11 invoice payment (rendering)
///
/// This widget handles only the UI rendering and receives
/// all state and callbacks from Bolt11PaymentScreen.
class Bolt11PaymentLayout extends StatelessWidget {
  final Bolt11InvoiceDetails invoiceDetails;
  final Bolt11PaymentState state;
  final VoidCallback onSendPayment;
  final VoidCallback onRetry;
  final VoidCallback onCancel;

  const Bolt11PaymentLayout({
    required this.invoiceDetails,
    required this.state,
    required this.onSendPayment,
    required this.onRetry,
    required this.onCancel,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const GlowBackButton(),
        title: const Text('Send Payment'),
        centerTitle: false, // Left-aligned
      ),
      body: SafeArea(
        child: _BodyContent(invoiceDetails: invoiceDetails, state: state),
      ),
      bottomNavigationBar: PaymentBottomNav(
        state: state,
        onRetry: onRetry,
        onCancel: onCancel,
        onReady: onSendPayment,
      ),
    );
  }
}

/// Body content that switches between different states
class _BodyContent extends StatelessWidget {
  final Bolt11InvoiceDetails invoiceDetails;
  final Bolt11PaymentState state;

  const _BodyContent({required this.invoiceDetails, required this.state});

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while preparing or on initial state (during zero-amount invoice check)
    if (state is Bolt11PaymentInitial || state is Bolt11PaymentPreparing) {
      return Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor));
    }

    // Show status view when sending or completed
    if (state is Bolt11PaymentSending) {
      return const PaymentStatusView(status: PaymentStatus.sending);
    }

    if (state is Bolt11PaymentSuccess) {
      return const PaymentStatusView(status: PaymentStatus.success);
    }

    // Show scrollable content for other states
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Payment confirmation (when ready)
          if (state is Bolt11PaymentReady)
            PaymentConfirmationView(
              recipientSubtitle: 'You are requested to pay:',
              amountSats: (state as Bolt11PaymentReady).amountSats,
              feeSats: (state as Bolt11PaymentReady).feeSats,
              description: (state as Bolt11PaymentReady).description,
            )
          // Error display
          else if (state is Bolt11PaymentError)
            ErrorCard(
              title: 'Failed to prepare payment',
              message: (state as Bolt11PaymentError).message,
            ),
        ],
      ),
    );
  }
}
