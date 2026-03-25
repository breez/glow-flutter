import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/features/fiat_currencies/fiat_currency_layout.dart';
import 'package:glow/features/fiat_currencies/models/fiat_state.dart';
import 'package:glow/features/fiat_currencies/providers/fiat_currency_provider.dart';

/// Container widget for fiat currency selection screen.
/// Reads the fiat currency provider and passes state to the layout.
class FiatCurrencyScreen extends ConsumerWidget {
  const FiatCurrencyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<FiatCurrencyState> fiatState = ref.watch(
      fiatCurrencyProvider,
    );

    return fiatState.when(
      data: (FiatCurrencyState state) => FiatCurrencyLayout(
        state: state,
        onCurrencySelected: (String? currencyId) {
          ref
              .read(fiatCurrencyProvider.notifier)
              .setPreferredCurrency(currencyId);
        },
      ),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (Object error, StackTrace stackTrace) => Scaffold(
        body: Center(child: Text('Error loading currencies: $error')),
      ),
    );
  }
}
