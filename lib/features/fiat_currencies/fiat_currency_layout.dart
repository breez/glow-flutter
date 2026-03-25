import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:glow/features/fiat_currencies/models/fiat_state.dart';
import 'package:glow/features/fiat_currencies/widgets/bitcoin_sats_tile.dart';
import 'package:glow/features/fiat_currencies/widgets/fiat_currency_tile.dart';
import 'package:glow/widgets/back_button.dart';

/// Pure presentation widget for fiat currency selection.
class FiatCurrencyLayout extends StatelessWidget {
  const FiatCurrencyLayout({
    required this.state,
    required this.onCurrencySelected,
    super.key,
  });

  final FiatCurrencyState state;
  final ValueChanged<String?> onCurrencySelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const GlowBackButton(),
        title: const Text('Fiat Currency'),
      ),
      body: SafeArea(
        child: ListView.builder(
          itemCount: state.availableCurrencies.length + 1,
          itemBuilder: (BuildContext context, int index) {
            if (index == 0) {
              return BitcoinSatsTile(
                isSelected: state.preferredCurrencyId == null,
                onTap: () => onCurrencySelected(null),
              );
            }

            final FiatCurrency currency =
                state.availableCurrencies[index - 1];
            final bool isSelected =
                state.preferredCurrencyId == currency.id;

            return FiatCurrencyTile(
              currency: currency,
              isSelected: isSelected,
              onTap: () => onCurrencySelected(currency.id),
            );
          },
        ),
      ),
    );
  }
}
