import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';

/// List tile for a single fiat currency option.
class FiatCurrencyTile extends StatelessWidget {
  const FiatCurrencyTile({
    required this.currency,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final FiatCurrency currency;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String symbolText = currency.info.symbol?.grapheme ??
        currency.info.uniqSymbol?.grapheme ??
        '';

    return ListTile(
      title: Text(currency.info.name),
      subtitle: Text(currency.id),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (symbolText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Text(
                symbolText,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          if (isSelected) const Icon(Icons.check, color: Colors.green),
        ],
      ),
      onTap: onTap,
    );
  }
}
