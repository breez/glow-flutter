import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart' hide PaymentStatus;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/widgets/back_button.dart';
import 'package:glow/features/developers/providers/network_provider.dart';
import 'package:glow/features/send_payment/models/spark_invoice_state.dart';
import 'package:glow/features/send_payment/widgets/network_mismatch_error.dart';
import 'package:glow/features/send_payment/widgets/payment_confirmation_view.dart';
import 'package:glow/features/send_payment/widgets/amount_input_form.dart';
import 'package:glow/features/send_payment/widgets/payment_bottom_nav.dart';
import 'package:glow/features/send_payment/widgets/payment_status_view.dart';
import 'package:glow/widgets/error_card.dart';

/// Layout for Spark Invoice payment (rendering)
///
/// This widget handles only the UI rendering and receives
/// all state and callbacks from SparkInvoiceScreen.
class SparkInvoiceLayout extends ConsumerStatefulWidget {
  final SparkInvoiceDetails invoiceDetails;
  final SparkInvoiceState state;
  final void Function(BigInt amountSats) onPreparePayment;
  final VoidCallback onSendPayment;
  final void Function(BigInt amountSats) onRetry;
  final VoidCallback onCancel;

  const SparkInvoiceLayout({
    required this.invoiceDetails,
    required this.state,
    required this.onPreparePayment,
    required this.onSendPayment,
    required this.onRetry,
    required this.onCancel,
    super.key,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SparkInvoiceLayoutState();
}

class _SparkInvoiceLayoutState extends ConsumerState<SparkInvoiceLayout> {
  final TextEditingController _amountController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  BigInt? _lastAmountSats;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _handlePreparePayment() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final BigInt amountSats = BigInt.parse(_amountController.text);
    _lastAmountSats = amountSats;

    widget.onPreparePayment(amountSats);
  }

  void _handleRetry() {
    if (_lastAmountSats != null) {
      widget.onRetry(_lastAmountSats!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Network currentNetwork = ref.watch(networkProvider);
    // Check if networks match - SDK Network vs BitcoinNetwork
    final bool networkMismatch =
        (currentNetwork == Network.mainnet &&
            widget.invoiceDetails.network != BitcoinNetwork.bitcoin) ||
        (currentNetwork != Network.mainnet &&
            widget.invoiceDetails.network == BitcoinNetwork.bitcoin);

    return Scaffold(
      appBar: AppBar(
        leading: const GlowBackButton(),
        title: const Text('Send Payment'),
        centerTitle: false, // Left-aligned
      ),
      body: SafeArea(
        child: _BodyContent(
          invoiceDetails: widget.invoiceDetails,
          state: widget.state,
          formKey: _formKey,
          amountController: _amountController,
          networkMismatch: networkMismatch,
          currentNetwork: currentNetwork,
        ),
      ),
      bottomNavigationBar: PaymentBottomNav(
        state: widget.state,
        onRetry: _handleRetry,
        onCancel: widget.onCancel,
        onReady: networkMismatch ? null : widget.onSendPayment,
        onInitial: networkMismatch ? null : _handlePreparePayment,
      ),
    );
  }
}

/// Body content that switches between different states
class _BodyContent extends StatelessWidget {
  final SparkInvoiceDetails invoiceDetails;
  final SparkInvoiceState state;
  final GlobalKey<FormState> formKey;
  final TextEditingController amountController;
  final bool networkMismatch;
  final Network currentNetwork;

  const _BodyContent({
    required this.invoiceDetails,
    required this.state,
    required this.formKey,
    required this.amountController,
    required this.networkMismatch,
    required this.currentNetwork,
  });

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while preparing
    if (state is SparkInvoicePreparing) {
      return Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor));
    }

    // Show status view when sending or completed
    if (state is SparkInvoiceSending) {
      return const PaymentStatusView(status: PaymentStatus.sending);
    }

    if (state is SparkInvoiceSuccess) {
      return const PaymentStatusView(status: PaymentStatus.success);
    }

    // Show network mismatch error
    if (networkMismatch) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: NetworkMismatchError(
          currentNetwork: currentNetwork,
          addressNetwork: invoiceDetails.network,
        ),
      );
    }

    // Show scrollable content for other states
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Amount input form (initial state)
          if (state is SparkInvoiceInitial)
            AmountInputForm(
              formKey: formKey,
              controller: amountController,
              header: invoiceDetails.description != null
                  ? _buildDescriptionHeader(context, invoiceDetails.description!)
                  : null,
              validator: (String? value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an amount';
                }

                final BigInt? amount = BigInt.tryParse(value);
                if (amount == null) {
                  return 'Invalid amount';
                }

                if (amount <= BigInt.zero) {
                  return 'Amount must be greater than 0';
                }

                return null;
              },
              onPaymentLimitTapped: (BigInt amount) {
                amountController.text = amount.toString();
              },
            )
          // Payment confirmation (when ready)
          else if (state is SparkInvoiceReady)
            PaymentConfirmationView(
              recipientSubtitle: 'You are requested to pay:',
              amountSats: (state as SparkInvoiceReady).amountSats,
              feeSats: (state as SparkInvoiceReady).feeSats,
              description: (state as SparkInvoiceReady).description,
            )
          // Error display
          else if (state is SparkInvoiceError)
            ErrorCard(
              title: 'Failed to prepare payment',
              message: (state as SparkInvoiceError).message,
            ),
        ],
      ),
    );
  }

  Widget _buildDescriptionHeader(BuildContext context, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Description:',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.0,
            letterSpacing: 0.0,
            height: 1.28,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.left,
          maxLines: 1,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColorLight.withValues(alpha: .1),
              border: Border.all(color: Theme.of(context).primaryColorLight.withValues(alpha: .7)),
              borderRadius: const BorderRadius.all(Radius.circular(4.0)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            width: MediaQuery.of(context).size.width,
            child: Text(
              description,
              style: const TextStyle(
                fontSize: 14.0,
                letterSpacing: 0.0,
                height: 1.156,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
