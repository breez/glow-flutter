import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:glow/features/lnurl/models/lnurl_withdraw_state.dart';
import 'package:glow/widgets/back_button.dart';
import 'package:glow/features/send_payment/widgets/amount_input_form.dart';
import 'package:glow/features/send_payment/widgets/payment_bottom_nav.dart';
import 'package:glow/widgets/card_wrapper.dart';
import 'package:glow/widgets/error_card.dart';

/// Layout for LNURL Withdraw (rendering)
///
/// This widget handles only the UI rendering and receives
/// all state and callbacks from LnurlWithdrawScreen.
class LnurlWithdrawLayout extends StatefulWidget {
  final LnurlWithdrawRequestDetails withdrawDetails;
  final LnurlWithdrawState state;
  final void Function(BigInt amountSats) onWithdraw;
  final void Function(BigInt amountSats) onRetry;
  final VoidCallback onCancel;

  const LnurlWithdrawLayout({
    required this.withdrawDetails,
    required this.state,
    required this.onWithdraw,
    required this.onRetry,
    required this.onCancel,
    super.key,
  });

  @override
  State<LnurlWithdrawLayout> createState() => _LnurlWithdrawLayoutState();
}

class _LnurlWithdrawLayoutState extends State<LnurlWithdrawLayout> {
  final TextEditingController _amountController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Pre-fill with max withdrawable amount
    final BigInt maxSats = widget.withdrawDetails.maxWithdrawable ~/ BigInt.from(1000);
    _amountController.text = maxSats.toString();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const GlowBackButton(), title: const Text('Withdraw Funds'), centerTitle: true),
      body: SafeArea(
        child: _BodyContent(
          withdrawDetails: widget.withdrawDetails,
          state: widget.state,
          amountController: _amountController,
          formKey: _formKey,
        ),
      ),
      bottomNavigationBar: PaymentBottomNav(
        state: widget.state,
        onRetry: () {
          final BigInt amountSats = BigInt.from(int.parse(_amountController.text));
          widget.onRetry(amountSats);
        },
        onCancel: widget.onCancel,
        onInitial: () {
          if (_formKey.currentState?.validate() ?? false) {
            final BigInt amountSats = BigInt.from(int.parse(_amountController.text));
            widget.onWithdraw(amountSats);
          }
        },
        initialLabel: 'WITHDRAW',
      ),
    );
  }
}

/// Body content that switches between different states
class _BodyContent extends StatelessWidget {
  final LnurlWithdrawRequestDetails withdrawDetails;
  final LnurlWithdrawState state;
  final TextEditingController amountController;
  final GlobalKey<FormState> formKey;

  const _BodyContent({
    required this.withdrawDetails,
    required this.state,
    required this.amountController,
    required this.formKey,
  });

  @override
  Widget build(BuildContext context) {
    // Show status view when processing or completed
    if (state is LnurlWithdrawProcessing) {
      return const _ProcessingView();
    }

    if (state is LnurlWithdrawSuccess) {
      return const _SuccessView();
    }

    // Show scrollable content for other states
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Withdraw details
          _WithdrawDetailsCard(withdrawDetails: withdrawDetails),
          const SizedBox(height: 16),

          // Amount input
          if (state is LnurlWithdrawInitial || state is LnurlWithdrawError)
            AmountInputForm(
              controller: amountController,
              formKey: formKey,
              minAmount: withdrawDetails.minWithdrawable ~/ BigInt.from(1000),
              maxAmount: withdrawDetails.maxWithdrawable ~/ BigInt.from(1000),
              showUseAllFunds: false,
            ),

          // Error display
          if (state is LnurlWithdrawError) ...<Widget>[
            const SizedBox(height: 16),
            ErrorCard(title: 'Withdrawal Failed', message: (state as LnurlWithdrawError).message),
          ],
        ],
      ),
    );
  }
}

/// Card displaying withdraw details
class _WithdrawDetailsCard extends StatelessWidget {
  final LnurlWithdrawRequestDetails withdrawDetails;

  const _WithdrawDetailsCard({required this.withdrawDetails});

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final BigInt minSats = withdrawDetails.minWithdrawable ~/ BigInt.from(1000);
    final BigInt maxSats = withdrawDetails.maxWithdrawable ~/ BigInt.from(1000);

    return CardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Withdraw Details',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),

          // Description
          _DetailRow(label: 'Description', value: withdrawDetails.defaultDescription),
          const SizedBox(height: 12),

          // Amount range
          _DetailRow(label: 'Amount Range', value: '$minSats - $maxSats sats'),

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
                    'Withdraw funds from this service to your wallet',
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

/// Processing view
class _ProcessingView extends StatelessWidget {
  const _ProcessingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          CircularProgressIndicator(),
          SizedBox(height: 24),
          Text('Withdrawing funds...', style: TextStyle(fontSize: 18)),
        ],
      ),
    );
  }
}

/// Success view
class _SuccessView extends StatelessWidget {
  const _SuccessView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.check_circle_outline, size: 80, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 24),
          const Text(
            'Withdrawal Successful!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'Funds are being received',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
