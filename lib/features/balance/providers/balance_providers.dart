import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/core/services/transaction_formatter.dart';
import 'package:glow/features/balance/models/balance_state.dart';
import 'package:glow/features/fiat_currencies/models/fiat_state.dart';
import 'package:glow/features/fiat_currencies/providers/fiat_currency_provider.dart';
import 'package:glow/providers/sdk_provider.dart';

/// Provider for BalanceState
/// Converts raw balance from sdk_provider to formatted BalanceState
final Provider<BalanceState> balanceStateProvider = Provider<BalanceState>((Ref ref) {
  final TransactionFormatter formatter = const TransactionFormatter();
  final AsyncValue<BigInt> balanceAsync = ref.watch(balanceProvider);

  final AsyncValue<bool> shouldWaitAsync = ref.watch(shouldWaitForInitialSyncProvider);
  final bool hasSynced = ref.watch(hasSyncedProvider);

  // Watch fiat currency state for conversion
  final AsyncValue<FiatCurrencyState> fiatAsync = ref.watch(fiatCurrencyProvider);

  return balanceAsync.when(
    data: (BigInt balance) {
      // If balance is loaded, show it immediately
      // Only check sync status if we're still determining whether to wait
      final bool shouldWait = shouldWaitAsync.hasValue ? shouldWaitAsync.value! : false;

      final String formattedBalance = formatter.formatSats(balance);

      // Format fiat using the fiat currency provider
      String? formattedFiat;
      if (fiatAsync.hasValue) {
        formattedFiat = ref.read(fiatCurrencyProvider.notifier).formatSatsAsFiat(balance);
      }

      return BalanceState.loaded(
        balance: balance,
        hasSynced: shouldWait ? hasSynced : true,
        formattedBalance: formattedBalance,
        formattedFiat: formattedFiat,
      );
    },
    loading: () => BalanceState.loading(),
    error: (Object error, _) => BalanceState.error(error.toString()),
  );
});
