import 'package:auto_size_text/auto_size_text.dart';
import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/features/deposits/providers/deposit_expansion_provider.dart';
import 'package:glow/widgets/data_action_button.dart';
import 'package:glow/widgets/expandable_detail_row.dart';
import 'package:glow/widgets/warning_box.dart';

final AutoSizeGroup _labelGroup = AutoSizeGroup();
final AutoSizeGroup _buttonGroup = AutoSizeGroup();

/// Individual deposit card widget - Expandable/collapsible design
/// Collapsed by default to save space when multiple deposits exist
/// Expansion state is preserved across rebuilds using depositExpansionProvider
class DepositCard extends ConsumerWidget {
  final DepositInfo deposit;
  final bool hasError;
  final bool hasRefund;
  final String formattedTxid;
  final String? formattedErrorMessage;
  final VoidCallback onRetryClaim;
  final VoidCallback onRefund;
  final VoidCallback onCopyTxid;

  const DepositCard({
    required this.deposit,
    required this.hasError,
    required this.hasRefund,
    required this.formattedTxid,
    required this.onRetryClaim,
    required this.onRefund,
    required this.onCopyTxid,
    super.key,
    this.formattedErrorMessage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final Set<String> expandedDeposits = ref.watch(depositExpansionProvider);
    final String depositKey = getDepositKey(deposit.txid, deposit.vout);
    final bool isExpanded = expandedDeposits.contains(depositKey);

    void toggleExpansion() {
      ref.read(depositExpansionProvider.notifier).toggle(depositKey);
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Transaction header with alternate background - always visible and tappable
          InkWell(
            onTap: toggleExpansion,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                color: Color.lerp(theme.colorScheme.surfaceContainer, theme.primaryColorLight, 0.1),
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(12.0),
                  bottom: Radius.circular(isExpanded ? 0.0 : 12.0),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      formattedTxid,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 18.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: isExpanded ? 0.5 : 0.0,
                    child: const Icon(Icons.expand_more, size: 24),
                  ),
                ],
              ),
            ),
          ),
          // Expanded content with smooth slide-down animation
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return SizeTransition(sizeFactor: animation, axisAlignment: -1.0, child: child);
            },
            child: isExpanded
                ? Padding(
                    key: const ValueKey<String>('expanded'),
                    padding: const EdgeInsets.all(16.0),
                    child: DepositContent(
                      content: _DepositDetailsContent(
                        txid: deposit.txid,
                        formattedTxid: formattedTxid,
                        amountSats: deposit.amountSats,
                        vout: deposit.vout,
                        labelAutoSizeGroup: _labelGroup,
                        onCopyTxid: onCopyTxid,
                        hasError: hasError,
                        formattedErrorMessage: formattedErrorMessage,
                      ),
                      actions: _DepositActions(
                        hasRefund: hasRefund,
                        onRetryClaim: onRetryClaim,
                        onRefund: onRefund,
                      ),
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey<String>('collapsed')),
          ),
        ],
      ),
    );
  }
}

/// Transaction details with blockchain explorer link - shown in expanded view
class _TransactionDetails extends StatelessWidget {
  final String txid;
  final String formattedTxid;
  final VoidCallback onCopyTxid;

  const _TransactionDetails({
    required this.txid,
    required this.formattedTxid,
    required this.onCopyTxid,
  });

  @override
  Widget build(BuildContext context) {
    return ExpandableDetailRow(
      title: 'Transaction',
      value: txid,
      linkUrl: 'https://mempool.space/tx/$txid',
      copyTooltip: 'Copy transaction ID',
      linkTooltip: 'View on block explorer',
    );
  }
}

/// Amount row with label-value formatting
class _AmountRow extends StatelessWidget {
  final BigInt amountSats;
  final AutoSizeGroup? labelAutoSizeGroup;

  const _AmountRow({required this.amountSats, this.labelAutoSizeGroup});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: AutoSizeText(
            'Amount:',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18.0,
              letterSpacing: 0.0,
              height: 1.28,
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
              '$amountSats sats',
              style: const TextStyle(fontSize: 18.0, color: Colors.white),
              textAlign: TextAlign.right,
              maxLines: 1,
            ),
          ),
        ),
      ],
    );
  }
}

/// Output row with label-value formatting
class _OutputRow extends StatelessWidget {
  final int vout;
  final AutoSizeGroup? labelAutoSizeGroup;

  const _OutputRow({required this.vout, this.labelAutoSizeGroup});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Row(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: AutoSizeText(
            'Output:',
            style: theme.textTheme.titleMedium?.copyWith(fontSize: 18.0),
            textAlign: TextAlign.left,
            maxLines: 1,
            group: labelAutoSizeGroup,
          ),
        ),
        Expanded(
          child: Text(
            '$vout',
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 18.0,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}

/// Action buttons section - horizontal layout
class _ActionButtons extends StatelessWidget {
  final bool hasRefund;
  final VoidCallback onRetryClaim;
  final VoidCallback onRefund;

  const _ActionButtons({
    required this.hasRefund,
    required this.onRetryClaim,
    required this.onRefund,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Expanded(
          child: DataActionButton(label: 'CLAIM', onPressed: onRetryClaim, textGroup: _buttonGroup),
        ),
        const SizedBox(width: DataActionButtonTheme.spacing),
        Expanded(
          child: DataActionButton(label: 'REFUND', onPressed: onRefund, textGroup: _buttonGroup),
        ),
      ],
    );
  }
}

/// A container widget that separates deposit content from actions
class DepositContent extends StatelessWidget {
  const DepositContent({required this.content, required this.actions, super.key});

  final Widget content;
  final Widget actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[content, actions],
    );
  }
}

/// The content section containing transaction details, amount, vout, and error
class _DepositDetailsContent extends StatelessWidget {
  final String txid;
  final String formattedTxid;
  final BigInt amountSats;
  final int vout;
  final AutoSizeGroup labelAutoSizeGroup;
  final VoidCallback onCopyTxid;
  final bool hasError;
  final String? formattedErrorMessage;

  const _DepositDetailsContent({
    required this.txid,
    required this.formattedTxid,
    required this.amountSats,
    required this.vout,
    required this.labelAutoSizeGroup,
    required this.onCopyTxid,
    this.hasError = false,
    this.formattedErrorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          <Widget>[
              _TransactionDetails(txid: txid, formattedTxid: formattedTxid, onCopyTxid: onCopyTxid),
              _AmountRow(amountSats: amountSats, labelAutoSizeGroup: labelAutoSizeGroup),
              if (vout > 0) ...<Widget>[
                _OutputRow(vout: vout, labelAutoSizeGroup: labelAutoSizeGroup),
              ],
              if (hasError && formattedErrorMessage != null) ...<Widget>[
                WarningBox.text(message: formattedErrorMessage!),
              ],
            ].expand((Widget widget) sync* {
              yield widget;
              yield const Divider(
                height: 32.0,
                color: Color.fromRGBO(40, 59, 74, 0.5),
                indent: 0.0,
                endIndent: 0.0,
              );
            }).toList()
            ..removeLast(),
    );
  }
}

/// The actions section containing retry and refund buttons
class _DepositActions extends StatelessWidget {
  const _DepositActions({
    required this.hasRefund,
    required this.onRetryClaim,
    required this.onRefund,
  });

  final bool hasRefund;
  final VoidCallback onRetryClaim;
  final VoidCallback onRefund;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: _ActionButtons(hasRefund: hasRefund, onRetryClaim: onRetryClaim, onRefund: onRefund),
    );
  }
}
