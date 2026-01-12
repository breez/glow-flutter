import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:glow/features/transactions/models/transaction_list_state.dart';
import 'package:glow/features/transactions/widgets/transaction_list_shimmer.dart';
import 'package:glow/features/profile/widgets/profile_avatar.dart';

/// Individual transaction list item widget
class TransactionListItem extends StatelessWidget {
  const TransactionListItem({required this.transaction, super.key, this.onTap});

  final TransactionItemState transaction;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Container(
          color: Theme.of(context).colorScheme.surfaceContainer,
          child: ListTile(
            onTap: onTap,
            leading: _buildAvatarContainer(context),
            title: _buildTitle(),
            subtitle: _buildSubtitle(context),
            trailing: _buildAmount(context),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarContainer(BuildContext context) {
    return Container(
      height: 72.0,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: .1),
            offset: const Offset(0.5, 0.5),
            blurRadius: 5.0,
          ),
        ],
      ),
      // Show profile avatar for incoming payments with profile
      child: transaction.profile != null
          ? ProfileAvatar(profile: transaction.profile!)
          : CircleAvatar(radius: 16, backgroundColor: Colors.white, child: _buildIcon(context)),
    );
  }

  Widget _buildIcon(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final bool isCompleted = transaction.payment?.status == PaymentStatus.completed;
    final Color color = transaction.isReceive
        ? Colors.black
        : isCompleted
        ? colorScheme.surface
        : const Color(0xb3303234);

    final IconData icon = transaction.isReceive ? Icons.add_rounded : Icons.remove_rounded;
    return Icon(icon, size: 16, color: color);
  }

  Widget _buildTitle() {
    // For incoming payments without description, show profile name
    final String title = transaction.profile != null
        ? transaction.profile!.displayName
        : transaction.description.isEmpty
        ? transaction.formattedMethod
        : transaction.description;

    return Text(
      title,
      style: const TextStyle(
        fontSize: 12.25,
        fontWeight: FontWeight.w400,
        height: 1.2,
        letterSpacing: 0.25,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildSubtitle(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color subtitleColor = colorScheme.onSurface;
    final Color statusColor = _getStatusColor(transaction.payment?.status);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (transaction.formattedTime.isNotEmpty) ...<Widget>[
          Text(
            transaction.formattedTime,
            style: TextStyle(
              color: subtitleColor.withValues(alpha: .7),
              fontSize: 10.5,
              fontWeight: FontWeight.w400,
              height: 1.16,
              letterSpacing: 0.39,
            ),
          ),
          const SizedBox(width: 8),
        ],
        if (transaction.payment?.status != PaymentStatus.completed) ...<Widget>[
          Text(
            transaction.formattedStatus,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w400,
              height: 1.16,
              letterSpacing: 0.39,
              color: statusColor,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAmount(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color amountColor = colorScheme.onSurface;

    final bool hasFees = (transaction.payment?.fees ?? BigInt.zero) > BigInt.zero;
    final bool isPending = transaction.payment?.status == PaymentStatus.pending;

    return SizedBox(
      height: 44,
      child: Column(
        mainAxisAlignment: (hasFees && !isPending)
            ? MainAxisAlignment.spaceAround
            : MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Text(
            transaction.formattedAmountWithSign,
            style: TextStyle(
              color: amountColor,
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              height: 1.28,
              letterSpacing: 0.5,
            ),
          ),
          if (hasFees && !isPending)
            Text(
              'FEE ${transaction.payment?.fees ?? BigInt.zero}',
              style: TextStyle(
                color: amountColor.withValues(alpha: .7),
                fontSize: 10.5,
                fontWeight: FontWeight.w400,
                height: 1.16,
                letterSpacing: 0.39,
              ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(PaymentStatus? status) {
    if (status == null) {
      return const Color(0xff4D88EC); // Default to pending color for deposits
    }
    return switch (status) {
      PaymentStatus.completed => Colors.green,
      PaymentStatus.pending => const Color(0xff4D88EC),
      PaymentStatus.failed => Colors.red,
    };
  }
}

/// Empty state widget for transaction list
class TransactionListEmpty extends StatelessWidget {
  const TransactionListEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          'Glow is ready to receive funds.',
          style: TextStyle(fontSize: 16.4, letterSpacing: 0.15, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

/// Loading state widget for transaction list
class TransactionListLoading extends StatelessWidget {
  const TransactionListLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const TransactionListShimmer();
  }
}

/// Error state widget for transaction list
class TransactionListError extends StatelessWidget {
  const TransactionListError({required this.error, super.key, this.onRetry});

  final String error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Error loading transactions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            if (onRetry != null) ...<Widget>[
              const SizedBox(height: 16),
              ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}
