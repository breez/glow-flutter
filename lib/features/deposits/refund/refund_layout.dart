import 'package:auto_size_text/auto_size_text.dart';
import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart' hide PaymentStatus;
import 'package:flutter/material.dart';
import 'package:glow/features/deposits/refund/refund_state.dart';
import 'package:glow/features/send_payment/widgets/payment_bottom_nav.dart';
import 'package:glow/features/send_payment/widgets/payment_status_view.dart';
import 'package:glow/utils/formatters.dart';
import 'package:glow/widgets/card_wrapper.dart';
import 'package:glow/widgets/error_card.dart';

/// Layout for deposit refund flow (rendering)
///
/// This widget handles only the UI rendering and receives
/// all state and callbacks from RefundScreen.
///
/// Flow: Address Input → Fee Selection → Sending → Success
class RefundLayout extends StatefulWidget {
  final RefundState state;
  final void Function(String address) onPrepareRefund;
  final void Function(RefundFeeSpeed speed) onSelectFeeSpeed;
  final VoidCallback onSendRefund;
  final void Function(String address) onRetry;
  final VoidCallback onCancel;

  const RefundLayout({
    required this.state,
    required this.onPrepareRefund,
    required this.onSelectFeeSpeed,
    required this.onSendRefund,
    required this.onRetry,
    required this.onCancel,
    super.key,
  });

  @override
  State<RefundLayout> createState() => _RefundLayoutState();
}

class _RefundLayoutState extends State<RefundLayout> {
  final TextEditingController _addressController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FocusNode _addressFocusNode = FocusNode();

  String? _lastAddress;

  @override
  void dispose() {
    _addressController.dispose();
    _addressFocusNode.dispose();
    super.dispose();
  }

  void _handlePrepareRefund() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final String address = _addressController.text.trim();
    _lastAddress = address;

    widget.onPrepareRefund(address);
  }

  void _handleRetry() {
    if (_lastAddress != null) {
      widget.onRetry(_lastAddress!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
        centerTitle: false, // Left-aligned
      ),
      body: SafeArea(
        child: _BodyContent(
          state: widget.state,
          formKey: _formKey,
          addressController: _addressController,
          addressFocusNode: _addressFocusNode,
          onSelectFeeSpeed: widget.onSelectFeeSpeed,
        ),
      ),
      bottomNavigationBar: PaymentBottomNav(
        state: widget.state,
        onRetry: _handleRetry,
        onCancel: widget.onCancel,
        onReady: widget.onSendRefund,
        onInitial: _handlePrepareRefund,
        readyLabel: 'CONFIRM',
      ),
    );
  }

  String _getTitle() {
    if (widget.state is RefundReady) {
      return 'Choose Processing Speed';
    }
    return 'Get Refund';
  }
}

/// Body content that switches between different states
class _BodyContent extends StatelessWidget {
  final RefundState state;
  final GlobalKey<FormState> formKey;
  final TextEditingController addressController;
  final FocusNode addressFocusNode;
  final void Function(RefundFeeSpeed speed) onSelectFeeSpeed;

  const _BodyContent({
    required this.state,
    required this.formKey,
    required this.addressController,
    required this.addressFocusNode,
    required this.onSelectFeeSpeed,
  });

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while preparing
    if (state is RefundPreparing) {
      return Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor));
    }

    // Show status view when sending or completed
    if (state is RefundSending) {
      return const PaymentStatusView(status: PaymentStatus.sending);
    }

    if (state is RefundSuccess) {
      return const PaymentStatusView(status: PaymentStatus.success);
    }

    // Show scrollable content for other states
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Address input (initial state)
          if (state is RefundInitial)
            _AddressInputForm(
              formKey: formKey,
              controller: addressController,
              focusNode: addressFocusNode,
              deposit: (state as RefundInitial).deposit,
            )
          // Fee selection (when ready)
          else if (state is RefundReady)
            _FeeSelectionView(state: state as RefundReady, onSelectFeeSpeed: onSelectFeeSpeed)
          // Error display
          else if (state is RefundError)
            ErrorCard(
              title: (state as RefundError).message,
              message: (state as RefundError).technicalDetails ?? '',
            ),
        ],
      ),
    );
  }
}

/// Address input form for the initial state
class _AddressInputForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController controller;
  final FocusNode focusNode;
  final DepositInfo deposit;

  const _AddressInputForm({
    required this.formKey,
    required this.controller,
    required this.focusNode,
    required this.deposit,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);

    return CardWrapper(
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:
              <Widget>[
                  // Address input section
                  TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      prefixIconConstraints: BoxConstraints.tight(const Size(16, 56)),
                      prefixIcon: const SizedBox.shrink(),
                      contentPadding: const EdgeInsets.only(left: 16, top: 16, bottom: 16),
                      border: const OutlineInputBorder(),
                      labelText: 'BTC Address',
                      hintText: 'bc1q...',
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18.0,
                      letterSpacing: 0.15,
                      height: 1.234,
                    ),
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a Bitcoin address';
                      }
                      // Basic validation - more detailed validation happens in the provider
                      if (!_isValidBitcoinAddressFormat(value.trim())) {
                        return 'Invalid Bitcoin address format';
                      }
                      return null;
                    },
                  ),

                  // Amount display (read-only)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: <Widget>[
                        const Padding(
                          padding: EdgeInsets.only(right: 8.0),
                          child: AutoSizeText(
                            'Amount:',
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
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            reverse: true,
                            child: Text(
                              '${formatSats(deposit.amountSats)} sats',
                              style: const TextStyle(fontSize: 18.0, color: Colors.white),
                              textAlign: TextAlign.right,
                              maxLines: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
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
      ),
    );
  }

  bool _isValidBitcoinAddressFormat(String address) {
    // Basic format validation
    if (address.isEmpty) {
      return false;
    }

    // Check for common patterns
    return address.startsWith('bc1') || address.startsWith('1') || address.startsWith('3');
  }
}

/// Fee selection view
class _FeeSelectionView extends StatelessWidget {
  final RefundReady state;
  final void Function(RefundFeeSpeed speed) onSelectFeeSpeed;

  const _FeeSelectionView({required this.state, required this.onSelectFeeSpeed});

  @override
  Widget build(BuildContext context) {
    final Map<RefundFeeSpeed, bool> affordability = state.getAffordability();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Fee speed selector tabs
        _FeeSpeedTabs(
          selectedSpeed: state.selectedSpeed,
          affordability: affordability,
          onSelectSpeed: onSelectFeeSpeed,
        ),
        const SizedBox(height: 8),
        // Estimated delivery
        Text(
          'Estimated Delivery: ${_getDeliveryEstimate(state.selectedSpeed)}',
          style: const TextStyle(fontSize: 13.0, color: Colors.white60, letterSpacing: 0.4),
        ),
        const SizedBox(height: 24),
        // Refund breakdown card
        _RefundBreakdownCard(
          deposit: state.deposit,
          feeSats: state.estimatedFeeSats,
          selectedSpeed: state.selectedSpeed,
        ),
      ],
    );
  }

  String _getDeliveryEstimate(RefundFeeSpeed speed) {
    switch (speed) {
      case RefundFeeSpeed.economy:
        return '~1 hour';
      case RefundFeeSpeed.regular:
        return '~30 minutes';
      case RefundFeeSpeed.priority:
        return '~10 minutes';
    }
  }
}

/// Fee speed tabs (Economy/Regular/Priority)
class _FeeSpeedTabs extends StatelessWidget {
  final RefundFeeSpeed selectedSpeed;
  final Map<RefundFeeSpeed, bool> affordability;
  final void Function(RefundFeeSpeed speed) onSelectSpeed;

  const _FeeSpeedTabs({
    required this.selectedSpeed,
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
              isSelected: selectedSpeed == RefundFeeSpeed.economy,
              isEnabled: affordability[RefundFeeSpeed.economy] ?? true,
              onTap: () => onSelectSpeed(RefundFeeSpeed.economy),
              position: _TabPosition.left,
            ),
          ),
          Expanded(
            child: _FeeSpeedTab(
              label: 'REGULAR',
              isSelected: selectedSpeed == RefundFeeSpeed.regular,
              isEnabled: affordability[RefundFeeSpeed.regular] ?? true,
              onTap: () => onSelectSpeed(RefundFeeSpeed.regular),
              position: _TabPosition.middle,
            ),
          ),
          Expanded(
            child: _FeeSpeedTab(
              label: 'PRIORITY',
              isSelected: selectedSpeed == RefundFeeSpeed.priority,
              isEnabled: affordability[RefundFeeSpeed.priority] ?? true,
              onTap: () => onSelectSpeed(RefundFeeSpeed.priority),
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
        border = Border.all(color: borderColor);
        break;
      case _TabPosition.middle:
        borderRadius = BorderRadius.zero;
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

/// Refund breakdown card showing amounts and fees
class _RefundBreakdownCard extends StatelessWidget {
  final DepositInfo deposit;
  final BigInt feeSats;
  final RefundFeeSpeed selectedSpeed;

  const _RefundBreakdownCard({
    required this.deposit,
    required this.feeSats,
    required this.selectedSpeed,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final BigInt recipientReceives = deposit.amountSats - feeSats;

    return CardWrapper(
      border: Border.all(color: colorScheme.outline.withValues(alpha: 0.4)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            <Widget>[
                // Deposit amount
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const Text(
                      'Deposit amount:',
                      style: TextStyle(color: Colors.white, fontSize: 18.0),
                    ),
                    Text(
                      '${formatSats(deposit.amountSats)} sats (\$${_formatUSD(deposit.amountSats)})',
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
                      'You receive:',
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
