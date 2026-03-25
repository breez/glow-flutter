import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:glow/features/send_payment/models/bip21_state.dart';
import 'package:glow/widgets/back_button.dart';
import 'package:glow/widgets/bottom_nav_button.dart';
import 'package:glow/widgets/card_wrapper.dart';

/// Layout for BIP21 unified payment (rendering)
///
/// This widget handles only the UI rendering and receives
/// all state and callbacks from Bip21Screen.
class Bip21Layout extends StatelessWidget {
  final Bip21Details bip21Details;
  final Bip21State state;
  final void Function(InputType method) onSelectMethod;
  final VoidCallback onCancel;

  const Bip21Layout({
    required this.bip21Details,
    required this.state,
    required this.onSelectMethod,
    required this.onCancel,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const GlowBackButton(), title: const Text('Choose Payment Method'), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // BIP21 details
              _Bip21DetailsCard(bip21Details: bip21Details),
              const SizedBox(height: 16),

              // Payment methods selection
              _PaymentMethodsCard(
                paymentMethods: bip21Details.paymentMethods,
                onSelectMethod: onSelectMethod,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavButton(
        stickToBottom: true,
        text: 'CANCEL',
        onPressed: onCancel,
      ),
    );
  }
}

/// Card displaying BIP21 details
class _Bip21DetailsCard extends StatelessWidget {
  final Bip21Details bip21Details;

  const _Bip21DetailsCard({required this.bip21Details});

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return CardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Payment Request',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),

          // Amount (if specified)
          if (bip21Details.amountSat != null)
            _DetailRow(label: 'Amount', value: '${bip21Details.amountSat} sats'),

          // Label (if specified)
          if (bip21Details.label != null) ...<Widget>[
            const SizedBox(height: 12),
            _DetailRow(label: 'Label', value: bip21Details.label!),
          ],

          // Message (if specified)
          if (bip21Details.message != null) ...<Widget>[
            const SizedBox(height: 12),
            _DetailRow(label: 'Message', value: bip21Details.message!),
          ],

          const SizedBox(height: 16),

          // Info box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: <Widget>[
                Icon(Icons.info_outline, size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'This is a unified payment request with multiple payment options',
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
}

/// Card displaying payment methods
class _PaymentMethodsCard extends StatelessWidget {
  final List<InputType> paymentMethods;
  final void Function(InputType method) onSelectMethod;

  const _PaymentMethodsCard({required this.paymentMethods, required this.onSelectMethod});

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return CardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Available Payment Methods',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          ...paymentMethods.map((InputType method) {
            return _PaymentMethodTile(method: method, onTap: () => onSelectMethod(method));
          }),
        ],
      ),
    );
  }
}

/// Tile for a payment method
class _PaymentMethodTile extends StatelessWidget {
  final InputType method;
  final VoidCallback onTap;

  const _PaymentMethodTile({required this.method, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    final String methodName = _getMethodName(method);
    final IconData methodIcon = _getMethodIcon(method);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: <Widget>[
            Icon(methodIcon, color: colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                methodName,
                style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
            Icon(Icons.chevron_right, color: colorScheme.onSurface.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }

  String _getMethodName(InputType method) {
    return method.when(
      bolt11Invoice: (_) => 'Lightning Invoice (BOLT11)',
      bitcoinAddress: (_) => 'Bitcoin Address',
      bolt12Invoice: (_) => 'BOLT12 Invoice',
      bolt12Offer: (_) => 'BOLT12 Offer',
      lightningAddress: (_) => 'Lightning Address',
      lnurlPay: (_) => 'LNURL Pay',
      silentPaymentAddress: (_) => 'Silent Payment',
      lnurlAuth: (_) => 'LNURL Auth',
      url: (_) => 'URL',
      bip21: (_) => 'BIP21',
      bolt12InvoiceRequest: (_) => 'BOLT12 Invoice Request',
      lnurlWithdraw: (_) => 'LNURL Withdraw',
      sparkAddress: (_) => 'Spark Address',
      sparkInvoice: (_) => 'Spark Invoice',
    );
  }

  IconData _getMethodIcon(InputType method) {
    return method.when(
      bolt11Invoice: (_) => Icons.bolt,
      bitcoinAddress: (_) => Icons.account_balance_wallet,
      bolt12Invoice: (_) => Icons.receipt,
      bolt12Offer: (_) => Icons.local_offer,
      lightningAddress: (_) => Icons.alternate_email,
      lnurlPay: (_) => Icons.link,
      silentPaymentAddress: (_) => Icons.privacy_tip,
      lnurlAuth: (_) => Icons.security,
      url: (_) => Icons.language,
      bip21: (_) => Icons.qr_code,
      bolt12InvoiceRequest: (_) => Icons.request_page,
      lnurlWithdraw: (_) => Icons.download,
      sparkAddress: (_) => Icons.offline_bolt,
      sparkInvoice: (_) => Icons.receipt_long,
    );
  }
}

/// A detail row showing label and value
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

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
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
