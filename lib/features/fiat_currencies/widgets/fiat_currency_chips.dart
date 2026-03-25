import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';

/// Horizontal scrollable row of ChoiceChip widgets for preferred currencies.
class FiatCurrencyChips extends StatelessWidget {
  const FiatCurrencyChips({
    required this.preferredCurrencies,
    required this.selectedCurrencyId,
    required this.onCurrencySelected,
    super.key,
  });

  final List<FiatCurrency> preferredCurrencies;
  final String selectedCurrencyId;
  final ValueChanged<String> onCurrencySelected;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return SizedBox(
      height: 48.0,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: preferredCurrencies.length,
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(width: 8.0),
        itemBuilder: (BuildContext context, int index) {
          final FiatCurrency currency = preferredCurrencies[index];
          final bool isSelected = currency.id == selectedCurrencyId;

          return ChoiceChip(
            label: Text(currency.id),
            selected: isSelected,
            onSelected: (bool selected) {
              if (selected) {
                onCurrencySelected(currency.id);
              }
            },
            selectedColor: theme.colorScheme.primary,
            labelStyle: TextStyle(
              color: isSelected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            showCheckmark: false,
          );
        },
      ),
    );
  }
}
