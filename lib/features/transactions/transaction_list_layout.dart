import 'package:flutter/material.dart';
import 'package:glow/features/transactions/models/transaction_list_state.dart';
import 'package:glow/features/transactions/widgets/transaction_list_widgets.dart';

/// Pure presentation widget for transaction list
class TransactionListLayout extends StatelessWidget {
  const TransactionListLayout({
    required this.state,
    super.key,
    this.onTransactionTap,
    this.onRetry,
    this.hasSynced,
    this.scrollController,
  });

  final TransactionListState state;
  final Function(TransactionItemState item)? onTransactionTap;
  final VoidCallback? onRetry;
  final bool? hasSynced;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading || (hasSynced != null && !hasSynced! && state.isEmpty)) {
      return const TransactionListLoading();
    }

    if (state.hasError) {
      return TransactionListError(error: state.error!, onRetry: onRetry);
    }

    if (state.isEmpty) {
      return ListView(
        controller: scrollController,
        physics: const NeverScrollableScrollPhysics(),
        children: <Widget>[
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.4,
            child: state.hasActiveFilter
                ? const Center(child: Text('No transactions match your filter'))
                : const TransactionListEmpty(),
          ),
        ],
      );
    }

    return _buildTransactionList(context);
  }

  Widget _buildTransactionList(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.only(bottom: 16.0),
      itemCount: state.transactions.length,
      itemBuilder: (BuildContext context, int index) {
        final TransactionItemState transaction = state.transactions[index];
        return TransactionListItem(
          transaction: transaction,
          onTap: onTransactionTap != null ? () => onTransactionTap!(transaction) : null,
        );
      },
    );
  }
}
