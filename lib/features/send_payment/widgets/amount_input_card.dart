import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/core/services/transaction_formatter.dart';
import 'package:glow/features/fiat_currencies/providers/fiat_currency_provider.dart';
import 'package:glow/features/fiat_currencies/widgets/currency_converter_bottom_sheet.dart';
import 'package:glow/providers/sdk_provider.dart';

/// Widget for entering payment amount
class AmountInputCard extends ConsumerStatefulWidget {
  final TransactionFormatter formatter = const TransactionFormatter();

  final TextEditingController controller;
  final FocusNode focusNode;
  final String? Function(String?)? validator;
  final BigInt? minAmount;
  final BigInt? maxAmount;
  final VoidCallback? onChanged;
  final bool showBalance;
  final bool showUseAllFunds;
  final void Function(BigInt)? onPaymentLimitTapped;

  const AmountInputCard({
    required this.controller,
    required this.focusNode,
    this.validator,
    this.minAmount,
    this.maxAmount,
    this.onChanged,
    this.showBalance = true,
    this.showUseAllFunds = true,
    this.onPaymentLimitTapped,
    super.key,
  });

  @override
  ConsumerState<AmountInputCard> createState() => _AmountInputCardState();
}

class _AmountInputCardState extends ConsumerState<AmountInputCard> {
  bool _useAllFunds = false;

  void _toggleUseAllFunds(bool value, BigInt balance) {
    setState(() {
      _useAllFunds = value;
      if (_useAllFunds) {
        widget.controller.text = balance.toString();
      } else {
        widget.controller.text = '';
      }
      widget.onChanged?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<BigInt> balanceAsync = ref.watch(balanceProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          <Widget>[
              // Amount input field
              Column(
                children: <Widget>[
                  const SizedBox(height: 8.0),
                  TextFormField(
                    controller: widget.controller,
                    focusNode: widget.focusNode,
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                    textInputAction: TextInputAction.done,
                    autofocus: true,
                    enabled: !_useAllFunds,
                    style: const TextStyle(fontSize: 18.0, letterSpacing: 0.15, height: 1.234),
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      prefixIconConstraints: BoxConstraints.tight(const Size(16, 56)),
                      prefixIcon: const SizedBox.shrink(),
                      label: const Text('Amount in sats'),
                      contentPadding: EdgeInsets.zero,
                      suffixIcon: _FiatConverterButton(
                        onSatAmountReceived: (BigInt sats) {
                          widget.controller.text = sats.toString();
                          widget.onChanged?.call();
                        },
                      ),
                      errorStyle: TextStyle(
                        fontSize: 18.0,
                        color: Theme.of(context).colorScheme.error,
                        letterSpacing: 0.4,
                      ),
                      errorMaxLines: 3,
                    ),
                    validator: widget.validator ?? _defaultValidator,
                    onChanged: (_) {
                      widget.onChanged?.call();
                    },
                  ),
                  const SizedBox(height: 8.0),
                  _PaymentLimitsHelper(
                    minAmount: widget.minAmount,
                    maxAmount: widget.maxAmount,
                    onTap: (BigInt value) => widget.onPaymentLimitTapped?.call(value),
                  ),
                ],
              ),

              // Balance display and Use All Funds toggle
              if (widget.showBalance && balanceAsync.hasValue) ...<Widget>[
                ListTile(
                  dense: true,
                  minTileHeight: 0,
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Use All Funds',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.0,
                      height: 1.208,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Balance: ${widget.formatter.formatBalance(balanceAsync.value!)}',

                      style: const TextStyle(
                        color: Color.fromRGBO(182, 188, 193, 1),
                        fontSize: 16.0,
                        height: 1.182,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  trailing: Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Switch(
                      value: _useAllFunds,
                      onChanged: (bool value) => _toggleUseAllFunds(value, balanceAsync.value!),
                    ),
                  ),
                ),
              ],
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
    );
  }

  String? _defaultValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter an amount';
    }

    final BigInt? amount = BigInt.tryParse(value);
    if (amount == null) {
      return 'Invalid amount';
    }

    if (widget.minAmount != null && amount < widget.minAmount!) {
      return 'Payment is below the limit ${widget.formatter.formatBalance(widget.minAmount!)}';
    }

    if (widget.maxAmount != null && amount > widget.maxAmount!) {
      return 'Payment exceeds the limit ${widget.formatter.formatBalance(widget.maxAmount!)}.';
    }

    // Validate against current balance
    final AsyncValue<BigInt> balanceAsync = ref.read(balanceProvider);
    if (balanceAsync.hasValue && amount > balanceAsync.value!) {
      return 'Insufficient balance';
    }

    return null;
  }
}

class _PaymentLimitsHelper extends StatelessWidget {
  final BigInt? minAmount;
  final BigInt? maxAmount;
  final void Function(BigInt amountSat) onTap;

  const _PaymentLimitsHelper({
    required this.minAmount,
    required this.maxAmount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (minAmount == null) {
      return const SizedBox.shrink();
    }

    if (maxAmount == null) {
      return RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 14.3, color: Color(0x99ffffff), letterSpacing: 0.4),
          children: <TextSpan>[
            const TextSpan(text: 'Enter an amount of at least'),
            TextSpan(
              text: ' ${minAmount.toString()} sats ',
              recognizer: TapGestureRecognizer()..onTap = () => onTap(minAmount!),
            ),
          ],
        ),
      );
    }
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 14.3, color: Color(0x99ffffff), letterSpacing: 0.4),
        children: <TextSpan>[
          const TextSpan(text: 'Enter an amount between'),
          TextSpan(
            text: ' ${minAmount.toString()} sats ',
            recognizer: TapGestureRecognizer()..onTap = () => onTap(minAmount!),
          ),
          const TextSpan(text: 'and'),
          TextSpan(
            text: ' ${maxAmount.toString()} sats',
            recognizer: TapGestureRecognizer()..onTap = () => onTap(maxAmount!),
          ),
        ],
      ),
    );
  }
}

/// Fiat converter icon button shown as suffix in the amount input field.
/// Opens the currency converter bottom sheet and populates the amount.
class _FiatConverterButton extends ConsumerWidget {
  const _FiatConverterButton({required this.onSatAmountReceived});

  final ValueChanged<BigInt> onSatAmountReceived;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool hasFiat = ref.watch(
      fiatCurrencyProvider.select(
        (AsyncValue<dynamic> state) =>
            state.hasValue && state.value != null,
      ),
    );

    if (!hasFiat) {
      return const SizedBox.shrink();
    }

    return IconButton(
      icon: Image.asset(
        'assets/icon/btc_convert.png',
        width: 24,
        height: 24,
        color: IconTheme.of(context).color,
      ),
      onPressed: () async {
        final BigInt? result = await showCurrencyConverterSheet(context);
        if (result != null) {
          onSatAmountReceived(result);
        }
      },
    );
  }
}
