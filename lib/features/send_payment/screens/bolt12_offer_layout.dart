import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart' hide PaymentStatus;
import 'package:flutter/material.dart';
import 'package:glow/features/send_payment/models/bolt12_offer_state.dart';
import 'package:glow/widgets/back_button.dart';
import 'package:glow/features/send_payment/widgets/payment_confirmation_view.dart';
import 'package:glow/features/send_payment/widgets/payment_status_view.dart';
import 'package:glow/features/send_payment/widgets/amount_input_form.dart';
import 'package:glow/widgets/card_wrapper.dart';
import 'package:glow/widgets/error_card.dart';
import 'package:glow/features/send_payment/widgets/payment_bottom_nav.dart';

/// Layout for BOLT12 Offer payment (rendering)
///
/// This widget handles only the UI rendering and receives
/// all state and callbacks from Bolt12OfferScreen.
class Bolt12OfferLayout extends StatefulWidget {
  final Bolt12OfferDetails offerDetails;
  final Bolt12OfferState state;
  final void Function(BigInt amountSats) onPreparePayment;
  final VoidCallback onSendPayment;
  final void Function(BigInt amountSats) onRetry;
  final VoidCallback onCancel;

  const Bolt12OfferLayout({
    required this.offerDetails,
    required this.state,
    required this.onPreparePayment,
    required this.onSendPayment,
    required this.onRetry,
    required this.onCancel,
    super.key,
  });

  @override
  State<Bolt12OfferLayout> createState() => _Bolt12OfferLayoutState();
}

class _Bolt12OfferLayoutState extends State<Bolt12OfferLayout> {
  final TextEditingController _amountController = TextEditingController();
  final FocusNode _amountFocusNode = FocusNode();
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
    return Scaffold(
      appBar: AppBar(leading: const GlowBackButton(), title: const Text('Send Payment'), centerTitle: true),
      body: SafeArea(
        child: _BodyContent(
          offerDetails: widget.offerDetails,
          state: widget.state,
          formKey: _formKey,
          amountController: _amountController,
          amountFocusNode: _amountFocusNode,
        ),
      ),
      bottomNavigationBar: PaymentBottomNav(
        state: widget.state,
        onRetry: _handleRetry,
        onCancel: widget.onCancel,
        onReady: widget.onSendPayment,
        onInitial: _handlePreparePayment,
        initialLabel: 'CONTINUE',
      ),
    );
  }
}

/// Body content that switches between different states
class _BodyContent extends StatelessWidget {
  final Bolt12OfferDetails offerDetails;
  final Bolt12OfferState state;
  final GlobalKey<FormState> formKey;
  final TextEditingController amountController;
  final FocusNode amountFocusNode;

  const _BodyContent({
    required this.offerDetails,
    required this.state,
    required this.formKey,
    required this.amountController,
    required this.amountFocusNode,
  });

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while preparing
    if (state is Bolt12OfferPreparing) {
      return Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor));
    }
    // Show status view when sending or completed
    if (state is Bolt12OfferSending) {
      return const PaymentStatusView(status: PaymentStatus.sending);
    }

    if (state is Bolt12OfferSuccess) {
      return const PaymentStatusView(status: PaymentStatus.success);
    }

    // Show scrollable content for other states
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Offer details
          OfferDetailsCard(offerDetails: offerDetails),
          const SizedBox(height: 16),

          // Amount input (for initial state)
          if (state is Bolt12OfferInitial)
            AmountInputForm(
              formKey: formKey,
              controller: amountController,
              focusNode: amountFocusNode,
              minAmount: (state as Bolt12OfferInitial).minAmountMsat != null
                  ? (state as Bolt12OfferInitial).minAmountMsat! ~/ BigInt.from(1000)
                  : null,
              showUseAllFunds: false,
              onPaymentLimitTapped: (BigInt amount) {
                amountController.text = amount.toString();
              },
            )
          // Payment summary (when ready)
          else if (state is Bolt12OfferReady)
            PaymentConfirmationView(
              amountSats: (state as Bolt12OfferReady).amountSats,
              feeSats: (state as Bolt12OfferReady).feeSats,
              description: _buildDescription(offerDetails),
            )
          // Error display
          else if (state is Bolt12OfferError)
            ErrorCard(
              title: 'Failed to prepare payment',
              message: (state as Bolt12OfferError).message,
            ),
        ],
      ),
    );
  }

  String _buildDescription(Bolt12OfferDetails offerDetails) {
    final List<String> parts = <String>[];

    if (offerDetails.description != null) {
      parts.add(offerDetails.description!);
    } else {
      parts.add('BOLT12 offer payment');
    }

    if (offerDetails.issuer != null) {
      parts.add('Issuer: ${offerDetails.issuer}');
    }

    return parts.join(' • ');
  }
}

/// Card displaying BOLT12 Offer details
class OfferDetailsCard extends StatelessWidget {
  final Bolt12OfferDetails offerDetails;

  const OfferDetailsCard({required this.offerDetails, super.key});

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return CardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Offer Details', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),

          // Offer
          _DetailRow(
            label: 'Offer',
            value: _formatOffer(offerDetails.offer.offer),
            monospace: true,
          ),

          if (offerDetails.description != null) ...<Widget>[
            const SizedBox(height: 12),
            _DetailRow(label: 'Description', value: offerDetails.description!),
          ],

          if (offerDetails.issuer != null) ...<Widget>[
            const SizedBox(height: 12),
            _DetailRow(label: 'Issuer', value: offerDetails.issuer!),
          ],

          if (offerDetails.minAmount != null) ...<Widget>[
            const SizedBox(height: 12),
            _DetailRow(label: 'Minimum Amount', value: _formatAmountType(offerDetails.minAmount!)),
          ],

          if (offerDetails.absoluteExpiry != null) ...<Widget>[
            const SizedBox(height: 12),
            _DetailRow(label: 'Expires', value: _formatExpiry(offerDetails.absoluteExpiry!)),
          ],
        ],
      ),
    );
  }

  String _formatOffer(String offer) {
    // Show first 16 and last 16 characters for long offers
    if (offer.length > 36) {
      return '${offer.substring(0, 16)}...${offer.substring(offer.length - 16)}';
    }
    return offer;
  }

  String _formatAmountType(Amount amount) {
    return amount.when(
      bitcoin: (BigInt amountMsat) {
        final String sats = (amountMsat ~/ BigInt.from(1000)).toString();
        return '$sats sats';
      },
      currency: (String iso4217Code, BigInt fractionalAmount) => '$iso4217Code $fractionalAmount',
    );
  }

  String _formatExpiry(BigInt expiryTime) {
    final DateTime expiry = DateTime.fromMillisecondsSinceEpoch(expiryTime.toInt() * 1000);
    return expiry.toLocal().toString();
  }
}

/// A detail row showing label and value
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool monospace;

  const _DetailRow({required this.label, required this.value, this.monospace = false});

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          label,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            style: textTheme.bodyMedium?.copyWith(
              fontFamily: monospace ? 'monospace' : null,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
