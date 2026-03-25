import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/widgets/back_button.dart';
import 'package:glow/features/deposits/models/unclaimed_deposits_state.dart';
import 'package:glow/features/deposits/widgets/empty_deposits_state.dart';

/// Pure presentation widget for unclaimed deposits screen
class UnclaimedDepositsLayout extends StatelessWidget {
  const UnclaimedDepositsLayout({
    required this.depositsAsync,
    required this.onRetryClaim,
    required this.onShowRefundInfo,
    required this.onCopyTxid,
    required this.depositCardBuilder,
    super.key,
  });

  final AsyncValue<List<DepositCardData>> depositsAsync;
  final Future<void> Function(DepositCardData) onRetryClaim;
  final void Function(DepositCardData) onShowRefundInfo;
  final void Function(DepositCardData) onCopyTxid;
  final Widget Function(DepositCardData) depositCardBuilder;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const GlowBackButton(), title: const Text('Pending Deposits')),
      body: SafeArea(
        child: switch (depositsAsync) {
          AsyncData<List<DepositCardData>>(:final List<DepositCardData> value) => _DepositsListView(
            deposits: value,
            depositCardBuilder: depositCardBuilder,
          ),
          AsyncLoading<List<DepositCardData>>() => const _LoadingView(),
          AsyncError<List<DepositCardData>>(:final Object error) => _ErrorView(error: error),
        },
      ),
    );
  }
}

/// Loading state view
class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

/// Deposits list view - handles both empty and non-empty states
class _DepositsListView extends StatelessWidget {
  const _DepositsListView({required this.deposits, required this.depositCardBuilder});

  final List<DepositCardData> deposits;
  final Widget Function(DepositCardData) depositCardBuilder;

  @override
  Widget build(BuildContext context) {
    if (deposits.isEmpty) {
      return const EmptyDepositsState();
    }

    // DepositCard now expects hasError, hasRefund, formattedTxid, formattedErrorMessage
    // These will be provided by the parent (screen) via a wrapper or by passing a list of models
    // For now, keep the signature and let the screen handle the mapping
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: deposits.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (BuildContext context, int index) => depositCardBuilder(deposits[index]),
    );
  }
}

/// Error state view
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text('Failed to load deposits', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(error.toString(), style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
