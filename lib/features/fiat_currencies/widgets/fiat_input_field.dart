import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Text input field for entering fiat amounts with currency symbol prefix.
class FiatInputField extends StatelessWidget {
  const FiatInputField({
    required this.controller,
    required this.currencySymbol,
    required this.fractionSize,
    super.key,
  });

  final TextEditingController controller;
  final String currencySymbol;
  final int fractionSize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: <TextInputFormatter>[
          _FiatInputFormatter(fractionSize: fractionSize),
        ],
        autofocus: true,
        style: const TextStyle(fontSize: 24.0, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          prefixText: '$currencySymbol ',
          prefixStyle: const TextStyle(
            fontSize: 24.0,
            fontWeight: FontWeight.w500,
          ),
          hintText: '0',
          hintStyle: TextStyle(
            fontSize: 24.0,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface.withValues(
              alpha: 0.3,
            ),
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

/// Input formatter that validates fiat amounts with correct decimal places.
class _FiatInputFormatter extends TextInputFormatter {
  _FiatInputFormatter({required this.fractionSize});

  final int fractionSize;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String text = newValue.text.replaceAll(',', '.');

    if (text.isEmpty) {
      return newValue;
    }

    // Allow digits, single decimal point
    final RegExp pattern = fractionSize > 0
        ? RegExp(r'^\d*\.?\d{0,' + fractionSize.toString() + r'}$')
        : RegExp(r'^\d*$');

    if (pattern.hasMatch(text)) {
      return newValue.copyWith(text: text);
    }

    return oldValue;
  }
}
