import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:glow/features/payment_details/models/payment_details_state.dart';
import 'package:glow/features/payment_details/utils/payment_helpers.dart';
import 'package:glow/features/payment_details/widgets/payment_details_widgets.dart';

/// Shows payment details as a modal bottom sheet.
void showPaymentDetailsSheet(BuildContext context, PaymentDetailsState state) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) => PaymentDetailsSheet(state: state),
  );
}

/// Payment details presented as a DraggableScrollableSheet.
class PaymentDetailsSheet extends StatelessWidget {
  const PaymentDetailsSheet({required this.state, super.key});

  final PaymentDetailsState state;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              children: <Widget>[
                const _DragHandle(),
                _PaymentHeader(state: state),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: <Widget>[
                      PaymentAmountDisplay(formattedAmount: state.formattedAmount),
                      PaymentDetailRow(label: 'Status', value: state.formattedStatus),
                      PaymentDetailRow(label: 'Type', value: state.formattedType),
                      PaymentDetailRow(label: 'Method', value: state.formattedMethod),
                      if (state.shouldShowFees)
                        PaymentDetailRow(label: 'Fee', value: '${state.formattedFees} sats'),
                      PaymentDetailRow(label: 'Date', value: state.formattedDate),
                      const Divider(height: 32),
                      PaymentDetailRow(
                        label: 'Payment ID',
                        value: state.payment.id,
                        copyable: true,
                      ),
                      if (state.payment.details != null) ...<Widget>[
                        const Divider(height: 32),
                        _PaymentSpecificDetails(details: state.payment.details!),
                      ],
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Drag handle indicator at the top of the sheet.
class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

/// Header section with payment type icon and title.
class _PaymentHeader extends StatelessWidget {
  const _PaymentHeader({required this.state});

  final PaymentDetailsState state;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String title = getPaymentTitle(state.payment);
    final bool isReceive = state.payment.paymentType == PaymentType.receive;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 20,
            backgroundColor: isReceive
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.secondaryContainer,
            child: Icon(
              isReceive ? Icons.arrow_downward : Icons.arrow_upward,
              color: isReceive
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSecondaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: theme.textTheme.titleMedium),
                Text(
                  state.formattedMethod,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          _StatusChip(status: state.payment.status),
        ],
      ),
    );
  }
}

/// Status chip for payment state indication.
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final PaymentStatus status;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg) = switch (status) {
      PaymentStatus.completed => (
        Theme.of(context).colorScheme.primaryContainer,
        Theme.of(context).colorScheme.onPrimaryContainer,
      ),
      PaymentStatus.pending => (
        Theme.of(context).colorScheme.tertiaryContainer,
        Theme.of(context).colorScheme.onTertiaryContainer,
      ),
      PaymentStatus.failed => (
        Theme.of(context).colorScheme.errorContainer,
        Theme.of(context).colorScheme.onErrorContainer,
      ),
    };

    final String label = switch (status) {
      PaymentStatus.completed => 'Completed',
      PaymentStatus.pending => 'Pending',
      PaymentStatus.failed => 'Failed',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: fg)),
    );
  }
}

/// Routes to the correct payment-specific details widget.
class _PaymentSpecificDetails extends StatelessWidget {
  const _PaymentSpecificDetails({required this.details});

  final PaymentDetails details;

  @override
  Widget build(BuildContext context) {
    return switch (details) {
      final PaymentDetails_Lightning d => LightningPaymentDetails(details: d),
      final PaymentDetails_Token d => TokenPaymentDetails(details: d),
      final PaymentDetails_Withdraw d => WithdrawPaymentDetails(details: d),
      final PaymentDetails_Deposit d => DepositPaymentDetails(details: d),
      PaymentDetails_Spark() => const SizedBox.shrink(),
    };
  }
}
