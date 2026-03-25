import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart' hide PaymentStatus;
import 'package:flutter/material.dart';
import 'package:glow/features/send_payment/models/bolt12_invoice_state.dart';
import 'package:glow/widgets/back_button.dart';
import 'package:glow/features/send_payment/widgets/payment_confirmation_view.dart';
import 'package:glow/features/send_payment/widgets/payment_status_view.dart';
import 'package:glow/features/send_payment/widgets/payment_bottom_nav.dart';
import 'package:glow/widgets/error_card.dart';

/// Layout for BOLT12 Invoice payment (rendering)
///
/// This widget handles only the UI rendering and receives
/// all state and callbacks from Bolt12InvoiceScreen.
class Bolt12InvoiceLayout extends StatelessWidget {
  final Bolt12InvoiceDetails invoiceDetails;
  final Bolt12InvoiceState state;
  final VoidCallback onSendPayment;
  final VoidCallback onRetry;
  final VoidCallback onCancel;

  const Bolt12InvoiceLayout({
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
  final Bolt12InvoiceDetails invoiceDetails;
  final Bolt12InvoiceState state;

  const _BodyContent({required this.invoiceDetails, required this.state});

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while preparing or on initial state (during zero-amount invoice check)
    if (state is Bolt12InvoiceInitial || state is Bolt12InvoicePreparing) {
      return Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor));
    }

    // Show status view when sending or completed
    if (state is Bolt12InvoiceSending) {
      return const PaymentStatusView(status: PaymentStatus.sending);
    }

    if (state is Bolt12InvoiceSuccess) {
      return const PaymentStatusView(status: PaymentStatus.success);
    }

    // Show scrollable content for other states
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Payment confirmation (when ready)
          if (state is Bolt12InvoiceReady)
            PaymentConfirmationView(
              recipientSubtitle: 'You are requested to pay:',
              amountSats: (state as Bolt12InvoiceReady).amountSats,
              feeSats: (state as Bolt12InvoiceReady).feeSats,
              description: 'BOLT12 invoice payment',
            )
          // Error display
          else if (state is Bolt12InvoiceError)
            ErrorCard(
              title: 'Failed to prepare payment',
              message: (state as Bolt12InvoiceError).message,
            ),
        ],
      ),
    );
  }
}
