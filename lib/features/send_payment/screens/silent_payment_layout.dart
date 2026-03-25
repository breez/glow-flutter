import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart' hide PaymentStatus;
import 'package:flutter/material.dart';
import 'package:glow/features/send_payment/models/silent_payment_state.dart';
import 'package:glow/widgets/back_button.dart';
import 'package:glow/features/send_payment/widgets/payment_confirmation_view.dart';
import 'package:glow/features/send_payment/widgets/payment_status_view.dart';
import 'package:glow/widgets/card_wrapper.dart';
import 'package:glow/features/send_payment/widgets/payment_bottom_nav.dart';
import 'package:glow/widgets/error_card.dart';

/// Layout for Silent Payment Address (rendering)
///
/// This widget handles only the UI rendering and receives
/// all state and callbacks from SilentPaymentScreen.
class SilentPaymentLayout extends StatelessWidget {
  final SilentPaymentAddressDetails addressDetails;
  final SilentPaymentState state;
  final VoidCallback onSendPayment;
  final VoidCallback onRetry;
  final VoidCallback onCancel;

  const SilentPaymentLayout({
    required this.addressDetails,
    required this.state,
    required this.onSendPayment,
    required this.onRetry,
    required this.onCancel,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const GlowBackButton(), title: const Text('Send Payment'), centerTitle: true),
      body: SafeArea(
        child: _BodyContent(addressDetails: addressDetails, state: state),
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
  final SilentPaymentAddressDetails addressDetails;
  final SilentPaymentState state;

  const _BodyContent({required this.addressDetails, required this.state});

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while preparing
    if (state is SilentPaymentPreparing) {
      return Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor));
    }

    // Show status view when sending or completed
    if (state is SilentPaymentSending) {
      return const PaymentStatusView(status: PaymentStatus.sending);
    }

    if (state is SilentPaymentSuccess) {
      return const PaymentStatusView(status: PaymentStatus.success);
    }

    // Show scrollable content for other states
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Address details
          AddressDetailsCard(addressDetails: addressDetails),
          const SizedBox(height: 16),

          // Payment summary (when ready)
          if (state is SilentPaymentReady)
            PaymentConfirmationView(
              amountSats: (state as SilentPaymentReady).amountSats,
              feeSats: (state as SilentPaymentReady).feeSats,
              description: 'Silent payment (privacy-enhanced)',
            )
          // Error display
          else if (state is SilentPaymentError)
            ErrorCard(
              title: 'Failed to prepare payment',
              message: (state as SilentPaymentError).message,
            ),
        ],
      ),
    );
  }
}

/// Card displaying Silent Payment Address details
class AddressDetailsCard extends StatelessWidget {
  final SilentPaymentAddressDetails addressDetails;

  const AddressDetailsCard({required this.addressDetails, super.key});

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return CardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Address Details',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),

          // Silent Payment Address
          _DetailRow(
            label: 'Silent Address',
            value: _formatAddress(addressDetails.address),
            monospace: true,
          ),
          const SizedBox(height: 12),

          // Network
          _DetailRow(label: 'Network', value: addressDetails.network.name.toUpperCase()),

          // Optional BIP21 URI
          if (addressDetails.source.bip21Uri != null) ...<Widget>[
            const SizedBox(height: 12),
            _DetailRow(
              label: 'BIP21 URI',
              value: _formatAddress(addressDetails.source.bip21Uri!),
              monospace: true,
            ),
          ],

          // Optional BIP353 Address
          if (addressDetails.source.bip353Address != null) ...<Widget>[
            const SizedBox(height: 12),
            _DetailRow(label: 'BIP353 Address', value: addressDetails.source.bip353Address!),
          ],

          const SizedBox(height: 16),

          // Privacy info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  Icons.privacy_tip_outlined,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Silent payments enhance privacy by preventing address reuse',
                    style: textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatAddress(String address) {
    // Show first 16 and last 16 characters for long addresses
    if (address.length > 36) {
      return '${address.substring(0, 16)}...${address.substring(address.length - 16)}';
    }
    return address;
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
