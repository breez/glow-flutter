import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Dedicated widget for displaying payment amount
class PaymentAmountDisplay extends StatelessWidget {
  const PaymentAmountDisplay({required this.formattedAmount, super.key});

  final String formattedAmount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        children: <Widget>[
          Text(
            formattedAmount,
            style: TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.w300,
              letterSpacing: -2,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'sats',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dedicated widget for displaying a detail row with optional copy functionality
class PaymentDetailRow extends StatelessWidget {
  const PaymentDetailRow({
    required this.label,
    required this.value,
    super.key,
    this.copyable = false,
  });

  final String label;
  final String value;
  final bool copyable;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
                if (copyable)
                  IconButton(
                    icon: const Icon(Icons.copy, size: 16),
                    onPressed: () => _copyToClipboard(context, value),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard'), duration: Duration(seconds: 2)),
    );
  }
}

/// Dedicated widget for Lightning payment details
class LightningPaymentDetails extends StatelessWidget {
  const LightningPaymentDetails({required this.details, super.key});

  final PaymentDetails_Lightning details;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        if (details.description?.isNotEmpty == true)
          PaymentDetailRow(label: 'Description', value: details.description!),
        PaymentDetailRow(label: 'Invoice', value: details.invoice, copyable: true),
        PaymentDetailRow(label: 'Payment Hash', value: details.htlcDetails.paymentHash, copyable: true),
        if (details.htlcDetails.preimage?.isNotEmpty == true)
          PaymentDetailRow(label: 'Preimage', value: details.htlcDetails.preimage!, copyable: true),
        PaymentDetailRow(label: 'Destination', value: details.destinationPubkey, copyable: true),
      ],
    );
  }
}

/// Dedicated widget for Token payment details
class TokenPaymentDetails extends StatelessWidget {
  const TokenPaymentDetails({required this.details, super.key});

  final PaymentDetails_Token details;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        PaymentDetailRow(label: 'Token', value: details.metadata.name),
        PaymentDetailRow(label: 'Ticker', value: details.metadata.ticker),
        PaymentDetailRow(label: 'TX Hash', value: details.txHash, copyable: true),
      ],
    );
  }
}

/// Dedicated widget for Withdraw payment details
class WithdrawPaymentDetails extends StatelessWidget {
  const WithdrawPaymentDetails({required this.details, super.key});

  final PaymentDetails_Withdraw details;

  @override
  Widget build(BuildContext context) {
    return PaymentDetailRow(label: 'TX ID', value: details.txId, copyable: true);
  }
}

/// Dedicated widget for Deposit payment details
class DepositPaymentDetails extends StatelessWidget {
  const DepositPaymentDetails({required this.details, super.key});

  final PaymentDetails_Deposit details;

  @override
  Widget build(BuildContext context) {
    return PaymentDetailRow(label: 'TX ID', value: details.txId, copyable: true);
  }
}
