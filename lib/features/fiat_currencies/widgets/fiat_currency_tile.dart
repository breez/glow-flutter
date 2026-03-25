import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';

/// CheckboxListTile for a single fiat currency in the settings screen.
/// Shows currency name, ID with symbol, and a checkbox for selection.
class FiatCurrencyTile extends StatelessWidget {
  const FiatCurrencyTile({
    required this.currency,
    required this.isPreferred,
    required this.onToggle,
    this.isLastPreferred = false,
    super.key,
  });

  final FiatCurrency currency;
  final bool isPreferred;
  final VoidCallback onToggle;

  /// If true, this is the last preferred currency and cannot be unchecked.
  final bool isLastPreferred;

  @override
  Widget build(BuildContext context) {
    final String symbolText = currency.info.symbol?.grapheme ??
        currency.info.uniqSymbol?.grapheme ??
        '';

    final String titleText = symbolText.isNotEmpty
        ? '${currency.id} ($symbolText)'
        : currency.id;

    return CheckboxListTile(
      value: isPreferred,
      onChanged: (bool? value) {
        if (isLastPreferred && isPreferred) {
          // Prevent unchecking the last preferred currency
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('At least one currency must be selected'),
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
        onToggle();
      },
      title: Text(
        titleText,
        style: const TextStyle(
          fontSize: 16.3,
          letterSpacing: 0.25,
        ),
      ),
      subtitle: Text(
        currency.info.name,
        style: TextStyle(
          fontSize: 14.3,
          color: Theme.of(context).colorScheme.onSurface.withValues(
            alpha: 0.6,
          ),
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}
