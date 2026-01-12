import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/features/deposits/models/pending_deposit_payment.dart';
import 'package:glow/features/deposits/providers/pending_deposits_provider.dart';
import 'package:glow/logging/app_logger.dart';
import 'package:glow/routing/app_routes.dart';
import 'package:glow/utils/formatters.dart';
import 'package:glow/widgets/card_wrapper.dart';
import 'package:glow/widgets/expandable_detail_row.dart';
import 'package:logger/logger.dart';

final Logger _log = AppLogger.getLogger('RefundsScreen');
final AutoSizeGroup _labelGroup = AutoSizeGroup();

/// Refunds Screen - shows deposits needing attention (rejected or no fee requirement)
class RefundsScreen extends ConsumerWidget {
  const RefundsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<PendingDepositPayment>> depositsAsync = ref.watch(
      depositsNeedingAttentionProvider,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Get Refund'),
        centerTitle: false, // Left-aligned like Misty Breez
      ),
      body: depositsAsync.when(
        data: (List<PendingDepositPayment> deposits) {
          if (deposits.isEmpty) {
            return const Center(child: Text('No refundable items'));
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: deposits.length,
              itemBuilder: (BuildContext context, int index) {
                final PendingDepositPayment deposit = deposits[index];
                return _RefundItemCard(
                  deposit: deposit,
                  onAction: () => _handleAction(context, ref, deposit),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error loading deposits:\n$error', textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleAction(BuildContext context, WidgetRef ref, PendingDepositPayment deposit) {
    // Only rejected deposits have actions (refund)
    if (deposit.isRejected) {
      _log.i('Handling refund for deposit: ${deposit.id}');
      Navigator.of(context).pushNamed(AppRoutes.depositRefund, arguments: deposit.deposit);
    }
  }
}

/// Card widget for a deposit needing action - Misty Breez style
class _RefundItemCard extends StatelessWidget {
  const _RefundItemCard({required this.deposit, required this.onAction});

  final PendingDepositPayment deposit;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return CardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Transaction row with expandable detail
          ExpandableDetailRow(
            title: 'Transaction',
            value: deposit.txid,
            isExpanded: true,
            labelAutoSizeGroup: _labelGroup,
            linkUrl: _getBlockchainExplorerUrl(deposit.txid),
            linkTooltip: 'View on blockchain explorer',
          ),
          const Divider(
            height: 32.0,
            color: Color.fromRGBO(40, 59, 74, 0.5),
            indent: 0.0,
            endIndent: 0.0,
          ),

          // Amount row
          _RefundItemCardAmount(amountSats: deposit.amountSats, labelAutoSizeGroup: _labelGroup),
          const Divider(
            height: 32.0,
            color: Color.fromRGBO(40, 59, 74, 0.5),
            indent: 0.0,
            endIndent: 0.0,
          ),

          // Action button only for rejected deposits
          if (deposit.isRejected) _RefundItemCardAction(deposit: deposit, onAction: onAction),
        ],
      ),
    );
  }

  String _getBlockchainExplorerUrl(String txid) {
    // Using mempool.space as the default blockchain explorer
    return 'https://mempool.space/tx/$txid';
  }
}

/// Amount display widget
class _RefundItemCardAmount extends StatelessWidget {
  final BigInt amountSats;
  final AutoSizeGroup? labelAutoSizeGroup;

  const _RefundItemCardAmount({required this.amountSats, this.labelAutoSizeGroup});

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    return Row(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: AutoSizeText(
            'Amount:',
            style: themeData.textTheme.titleMedium?.copyWith(
              fontSize: 18.0,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.left,
            maxLines: 1,
            group: labelAutoSizeGroup,
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Text(
              '${formatSats(amountSats)} sats',
              style: themeData.textTheme.displaySmall?.copyWith(
                fontSize: 18.0,
                color: Colors.white,
              ),
              textAlign: TextAlign.right,
              maxLines: 1,
            ),
          ),
        ),
      ],
    );
  }
}

/// Action button widget
class _RefundItemCardAction extends StatelessWidget {
  final PendingDepositPayment deposit;
  final VoidCallback onAction;

  const _RefundItemCardAction({required this.deposit, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Center(
        child: ElevatedButton(
          onPressed: onAction,
          child: Text('CONTINUE', style: themeData.textTheme.labelLarge),
        ),
      ),
    );
  }
}
