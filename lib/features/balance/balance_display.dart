import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/features/balance/balance_display_layout.dart';
import 'package:glow/features/balance/models/balance_state.dart';
import 'package:glow/features/balance/providers/balance_providers.dart';
import 'package:glow/features/fiat_currencies/providers/fiat_currency_provider.dart';

/// BalanceDisplay widget - handles setup and dependency injection
/// - BalanceDisplay: handles setup
/// - BalanceDisplayLayout: pure presentation widget
class BalanceDisplay extends ConsumerWidget {
  const BalanceDisplay({super.key, this.scrollOffsetFactor = 0.0});

  final double scrollOffsetFactor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get formatted state from provider
    final BalanceState state = ref.watch(balanceStateProvider);

    // Return pure presentation widget
    return BalanceDisplayLayout(
      state: state,
      onBalanceTap: _onBalanceTap,
      onFiatBalanceTap: () => _onFiatBalanceTap(ref),
      scrollOffsetFactor: scrollOffsetFactor,
    );
  }

  /// Handle tap on balance area
  void _onBalanceTap() {
    // TODO(erdemyerebasmaz): Change preferred Currency to the next one
    // (e.g., from BTC to SAT or vice versa, or hide balance)
  }

  /// Handle tap on fiat conversion area - cycle to next preferred currency
  void _onFiatBalanceTap(WidgetRef ref) {
    ref.read(fiatCurrencyProvider.notifier).cycleDashboardCurrency();
  }
}
