import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart' hide PaymentStatus;
import 'package:flutter/material.dart';
import 'package:glow/features/send_payment/models/bitcoin_address_state.dart';
import 'package:glow/widgets/back_button.dart';
import 'package:glow/features/send_payment/widgets/amount_input_form.dart';
import 'package:glow/features/send_payment/widgets/payment_bottom_nav.dart';
import 'package:glow/features/send_payment/widgets/payment_status_view.dart';
import 'package:glow/utils/formatters.dart';
import 'package:glow/widgets/card_wrapper.dart';
import 'package:glow/widgets/error_card.dart';

/// Layout for Bitcoin Address (onchain) payment (rendering)
///
/// This widget handles only the UI rendering and receives
/// all state and callbacks from BitcoinAddressScreen.
///
/// Flow: Amount Input → Fee Selection → Sending → Success
class BitcoinAddressLayout extends StatefulWidget {
  final BitcoinAddressDetails addressDetails;
  final BitcoinAddressState state;
  final Map<FeeSpeed, bool>? affordability;
  final void Function(BigInt amount) onPreparePayment;
  final void Function(FeeSpeed speed) onSelectFeeSpeed;
  final VoidCallback onSendPayment;
  final void Function(BigInt amount) onRetry;
  final VoidCallback onCancel;

  const BitcoinAddressLayout({
    required this.addressDetails,
    required this.state,
    required this.onPreparePayment,
    required this.onSelectFeeSpeed,
    required this.onSendPayment,
    required this.onRetry,
    required this.onCancel,
    this.affordability,
    super.key,
  });

  @override
  State<BitcoinAddressLayout> createState() => _BitcoinAddressLayoutState();
}

class _BitcoinAddressLayoutState extends State<BitcoinAddressLayout> {
  final TextEditingController _amountController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FocusNode _amountFocusNode = FocusNode();

  BigInt? _lastAmountSats;

  @override
  void dispose() {
    _amountController.dispose();
    _amountFocusNode.dispose();
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
      appBar: AppBar(
        leading: const GlowBackButton(),
        title: Text(_getTitle()),
        centerTitle: false, // Left-aligned
      ),
      body: SafeArea(
        child: _BodyContent(
          addressDetails: widget.addressDetails,
          state: widget.state,
          affordability: widget.affordability,
          formKey: _formKey,
          amountController: _amountController,
          amountFocusNode: _amountFocusNode,
          onSelectFeeSpeed: widget.onSelectFeeSpeed,
        ),
      ),
      bottomNavigationBar: PaymentBottomNav(
        state: widget.state,
        onRetry: _handleRetry,
        onCancel: widget.onCancel,
        onReady: widget.onSendPayment,
        onInitial: _handlePreparePayment,
        readyLabel: 'CONFIRM',
      ),
    );
  }

  String _getTitle() {
    if (widget.state is BitcoinAddressReady) {
      return 'Choose Processing Speed';
    }
    return 'Send to BTC Address';
  }
}

/// Body content that switches between different states
class _BodyContent extends StatelessWidget {
  final BitcoinAddressDetails addressDetails;
  final BitcoinAddressState state;
  final Map<FeeSpeed, bool>? affordability;
  final GlobalKey<FormState> formKey;
  final TextEditingController amountController;
  final FocusNode amountFocusNode;
  final void Function(FeeSpeed speed) onSelectFeeSpeed;

  const _BodyContent({
    required this.addressDetails,
    required this.state,
    required this.formKey,
    required this.amountController,
    required this.amountFocusNode,
    required this.onSelectFeeSpeed,
    this.affordability,
  });

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while preparing
    if (state is BitcoinAddressPreparing) {
      return Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor));
    }

    // Show status view when sending or completed
    if (state is BitcoinAddressSending) {
      return const PaymentStatusView(status: PaymentStatus.sending);
    }

    if (state is BitcoinAddressSuccess) {
      return const PaymentStatusView(status: PaymentStatus.success);
    }

    // Show scrollable content for other states
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Amount input (initial state)
          if (state is BitcoinAddressInitial)
            AmountInputForm(
              formKey: formKey,
              controller: amountController,
              header: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'BTC Address',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.0,
                      letterSpacing: 0.0,
                      height: 1.28,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColorLight.withValues(alpha: .1),
                      border: Border.all(
                        color: Theme.of(context).primaryColorLight.withValues(alpha: .7),
                      ),
                      borderRadius: const BorderRadius.all(Radius.circular(4.0)),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    width: MediaQuery.of(context).size.width,
                    child: Text(
                      addressDetails.address,
                      style: const TextStyle(
                        fontSize: 14.0,
                        letterSpacing: 0.0,
                        height: 1.156,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              minAmount: BigInt.from(25000),
              maxAmount: BigInt.from(2500000000000000),
              onPaymentLimitTapped: (BigInt amount) {
                amountController.text = amount.toString();
              },
            )
          // Fee selection (when ready)
          else if (state is BitcoinAddressReady)
            _FeeSelectionView(
              addressDetails: addressDetails,
              state: state as BitcoinAddressReady,
              affordability: affordability,
              onSelectFeeSpeed: onSelectFeeSpeed,
            )
          // Error display
          else if (state is BitcoinAddressError)
            ErrorCard(
              title: 'Failed to prepare payment',
              message: (state as BitcoinAddressError).message,
            ),
        ],
      ),
    );
  }
}

/// Fee selection view
class _FeeSelectionView extends StatelessWidget {
  final BitcoinAddressDetails addressDetails;
  final BitcoinAddressReady state;
  final Map<FeeSpeed, bool>? affordability;
  final void Function(FeeSpeed speed) onSelectFeeSpeed;

  const _FeeSelectionView({
    required this.addressDetails,
    required this.state,
    required this.onSelectFeeSpeed,
    this.affordability,
  });

  @override
  Widget build(BuildContext context) {
    // Use provided affordability or default to all enabled
    final Map<FeeSpeed, bool> feeAffordability =
        affordability ??
        <FeeSpeed, bool>{FeeSpeed.slow: true, FeeSpeed.medium: true, FeeSpeed.fast: true};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Fee speed selector tabs
        _FeeSpeedTabs(
          selectedSpeed: state.selectedSpeed,
          feeQuote: state.feeQuote,
          affordability: feeAffordability,
          onSelectSpeed: onSelectFeeSpeed,
        ),
        const SizedBox(height: 8),
        // Estimated delivery
        Text(
          'Estimated Delivery: ${_getDeliveryEstimate(state.selectedSpeed)}',
          style: const TextStyle(fontSize: 13.0, color: Colors.white60, letterSpacing: 0.4),
        ),
        const SizedBox(height: 24),
        // Payment breakdown card
        _PaymentBreakdownCard(
          amountSats: state.amountSats,
          feeSats: state.selectedFeeSats,
          feeQuote: state.feeQuote,
          selectedSpeed: state.selectedSpeed,
        ),
      ],
    );
  }

  String _getDeliveryEstimate(FeeSpeed speed) {
    switch (speed) {
      case FeeSpeed.slow:
        return '~1 hour';
      case FeeSpeed.medium:
        return '~30 minutes';
      case FeeSpeed.fast:
        return '~10 minutes';
    }
  }
}

/// Fee speed tabs (Economy/Regular/Priority)
class _FeeSpeedTabs extends StatelessWidget {
  final FeeSpeed selectedSpeed;
  final SendOnchainFeeQuote feeQuote;
  final Map<FeeSpeed, bool> affordability;
  final void Function(FeeSpeed speed) onSelectSpeed;

  const _FeeSpeedTabs({
    required this.selectedSpeed,
    required this.feeQuote,
    required this.affordability,
    required this.onSelectSpeed,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _FeeSpeedTab(
              label: 'ECONOMY',
              isSelected: selectedSpeed == FeeSpeed.slow,
              isEnabled: affordability[FeeSpeed.slow] ?? true,
              onTap: () => onSelectSpeed(FeeSpeed.slow),
              position: _TabPosition.left,
            ),
          ),
          Expanded(
            child: _FeeSpeedTab(
              label: 'REGULAR',
              isSelected: selectedSpeed == FeeSpeed.medium,
              isEnabled: affordability[FeeSpeed.medium] ?? true,
              onTap: () => onSelectSpeed(FeeSpeed.medium),
              position: _TabPosition.middle,
            ),
          ),
          Expanded(
            child: _FeeSpeedTab(
              label: 'PRIORITY',
              isSelected: selectedSpeed == FeeSpeed.fast,
              isEnabled: affordability[FeeSpeed.fast] ?? true,
              onTap: () => onSelectSpeed(FeeSpeed.fast),
              position: _TabPosition.right,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tab position enum for border radius handling
enum _TabPosition { left, middle, right }

/// Individual fee speed tab
class _FeeSpeedTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback onTap;
  final _TabPosition position;

  const _FeeSpeedTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.position,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color borderColor = colorScheme.outline.withValues(alpha: 0.4);

    // Calculate border radius and borders based on position
    BorderRadius borderRadius;
    Border border;

    switch (position) {
      case _TabPosition.left:
        borderRadius = const BorderRadius.only(
          topLeft: Radius.circular(5),
          bottomLeft: Radius.circular(5),
        );
        // Left tab: top, left, bottom borders (no right border to avoid doubling)
        border = Border.all(color: borderColor);
        break;
      case _TabPosition.middle:
        borderRadius = BorderRadius.zero;
        // Middle tab: top, bottom borders only
        border = Border(
          top: BorderSide(color: borderColor),
          bottom: BorderSide(color: borderColor),
        );
        break;
      case _TabPosition.right:
        borderRadius = const BorderRadius.only(
          topRight: Radius.circular(5),
          bottomRight: Radius.circular(5),
        );
        // Right tab: all borders
        border = Border.all(color: borderColor);
        break;
    }

    return InkWell(
      onTap: isEnabled ? onTap : null,
      borderRadius: borderRadius,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isEnabled
              ? (isSelected ? Theme.of(context).primaryColor : Colors.transparent)
              : Colors.grey,
          border: border,
          borderRadius: borderRadius,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isEnabled ? (isSelected ? Colors.white : Colors.white70) : Colors.white38,
            fontSize: 14.0,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

/// Payment breakdown card showing estimated delivery, amounts, and fees
class _PaymentBreakdownCard extends StatelessWidget {
  final BigInt amountSats;
  final BigInt feeSats;
  final SendOnchainFeeQuote feeQuote;
  final FeeSpeed selectedSpeed;

  const _PaymentBreakdownCard({
    required this.amountSats,
    required this.feeSats,
    required this.feeQuote,
    required this.selectedSpeed,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final BigInt recipientReceives = amountSats - feeSats;

    return CardWrapper(
      border: Border.all(color: colorScheme.outline.withValues(alpha: 0.4)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            <Widget>[
                // To send
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const Text('To send:', style: TextStyle(color: Colors.white, fontSize: 18.0)),
                    Text(
                      '${formatSats(amountSats)} sats (\$${_formatUSD(amountSats)})',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 14.0,
                        letterSpacing: 0.0,
                        height: 1.28,
                      ),
                    ),
                  ],
                ),

                // Transaction fee
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const Text(
                      'Transaction fee:',
                      style: TextStyle(color: Colors.white60, fontSize: 18.0),
                    ),
                    Text(
                      '-${formatSats(feeSats)} sats',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error.withValues(alpha: .4),
                        fontSize: 14.0,
                      ),
                    ),
                  ],
                ),

                // To receive
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const Text(
                      'To receive:',
                      style: TextStyle(color: Colors.white, fontSize: 18.0),
                    ),
                    Text(
                      '${formatSats(recipientReceives)} sats (\$${_formatUSD(recipientReceives)})',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 14.0,
                        letterSpacing: 0.0,
                        height: 1.28,
                      ),
                    ),
                  ],
                ),
              ].expand((Widget widget) sync* {
                yield widget;
                yield const Divider(
                  height: 32.0,
                  color: Color.fromRGBO(40, 59, 74, 0.5),
                  indent: 0.0,
                  endIndent: 0.0,
                );
              }).toList()
              ..removeLast(),
      ),
    );
  }

  String _formatUSD(BigInt sats) {
    // Placeholder - this should use actual exchange rate
    // For now, approximating $1 = 1000 sats for demo
    final double usd = sats.toDouble() / 1000;
    return usd.toStringAsFixed(2);
  }
}
