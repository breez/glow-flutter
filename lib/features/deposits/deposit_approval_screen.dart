import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/features/deposits/deposit_approval_layout.dart';
import 'package:glow/features/deposits/models/pending_deposit_payment.dart';
import 'package:glow/features/deposits/providers/pending_deposits_provider.dart';
import 'package:glow/features/deposits/providers/rejected_deposits_provider.dart';
import 'package:glow/logging/app_logger.dart';
import 'package:glow/providers/sdk_provider.dart';
import 'package:glow/routing/app_routes.dart';
import 'package:glow/utils/error_parser.dart';
import 'package:logger/logger.dart';

final Logger _log = AppLogger.getLogger('DepositApprovalScreen');

/// Screen for approving or rejecting deposit claims
/// Watches for fee updates via SDK events
class DepositApprovalScreen extends ConsumerWidget {
  const DepositApprovalScreen({required this.pendingDeposit, super.key});

  final PendingDepositPayment pendingDeposit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch pending deposits to get live fee updates
    final AsyncValue<List<PendingDepositPayment>> pendingDepositsAsync = ref.watch(
      pendingDepositsProvider,
    );

    return pendingDepositsAsync.when(
      data: (List<PendingDepositPayment> deposits) {
        // Find the current deposit with potentially updated fees
        final PendingDepositPayment updatedDeposit = deposits.firstWhere(
          (PendingDepositPayment d) => d.id == pendingDeposit.id,
          orElse: () => pendingDeposit, // Fallback to original if not found
        );

        return DepositApprovalLayout(
          pendingDeposit: updatedDeposit,
          onAccept: updatedDeposit.hasFeeRequirement
              ? () => _handleApprove(context, ref, updatedDeposit)
              : null,
          onReject: updatedDeposit.hasFeeRequirement
              ? () => _handleReject(context, ref, updatedDeposit)
              : null,
        );
      },
      loading: () => DepositApprovalLayout(
        pendingDeposit: pendingDeposit,
        onAccept: pendingDeposit.hasFeeRequirement
            ? () => _handleApprove(context, ref, pendingDeposit)
            : null,
        onReject: pendingDeposit.hasFeeRequirement
            ? () => _handleReject(context, ref, pendingDeposit)
            : null,
      ),
      error: (Object error, StackTrace stack) {
        _log.e('Error loading pending deposits', error: error, stackTrace: stack);
        // Show original deposit even on error
        return DepositApprovalLayout(
          pendingDeposit: pendingDeposit,
          onAccept: pendingDeposit.hasFeeRequirement
              ? () => _handleApprove(context, ref, pendingDeposit)
              : null,
          onReject: pendingDeposit.hasFeeRequirement
              ? () => _handleReject(context, ref, pendingDeposit)
              : null,
        );
      },
    );
  }

  /// Handle approve action - claim deposit with per-request fee limit
  Future<void> _handleApprove(
    BuildContext context,
    WidgetRef ref,
    PendingDepositPayment deposit,
  ) async {
    _log.i('User approved deposit ${deposit.id}');

    try {
      // Show claiming dialog
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );
      }

      final BreezSdk sdk = await ref.read(sdkProvider.future);

      // Claim deposit with per-request maxFee
      final ClaimDepositRequest claimRequest = ClaimDepositRequest(
        txid: deposit.deposit.txid,
        vout: deposit.deposit.vout,
        maxFee: MaxFee.fixed(amount: deposit.requiredFeeSats),
      );

      await sdk.claimDeposit(request: claimRequest);

      _log.i('Deposit claimed successfully: ${deposit.id}');

      // Refresh deposits
      ref.invalidate(unclaimedDepositsProvider);
      ref.invalidate(paymentsProvider);

      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        Navigator.of(context).pop(); // Close approval screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Deposit claimed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, stack) {
      _log.e('Failed to claim deposit: ${deposit.id}', error: e, stackTrace: stack);

      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        final String errorMessage = ErrorParser.parseError(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  /// Handle reject action - mark as rejected and show refund option
  Future<void> _handleReject(
    BuildContext context,
    WidgetRef ref,
    PendingDepositPayment deposit,
  ) async {
    _log.i('User rejected deposit ${deposit.id}');

    try {
      // Mark deposit as rejected
      await ref
          .read(rejectedDepositsProvider.notifier)
          .markAsRejected(deposit.deposit.txid, deposit.deposit.vout);

      _log.i('Deposit marked as rejected: ${deposit.id}');

      if (context.mounted) {
        Navigator.of(context).pop(); // Close approval screen

        // Show confirmation and option to refund
        final bool? shouldRefund = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('Deposit Rejected'),
            content: const Text(
              'This deposit has been marked as rejected. Would you like to refund it to an on-chain address?',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('LATER'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('REFUND NOW'),
              ),
            ],
          ),
        );

        if (shouldRefund == true && context.mounted) {
          // Navigate to refunds screen
          Navigator.of(context).pushNamed(AppRoutes.depositRefund, arguments: deposit.deposit);
        }
      }
    } catch (e, stack) {
      _log.e('Failed to reject deposit: ${deposit.id}', error: e, stackTrace: stack);

      if (context.mounted) {
        final String errorMessage = ErrorParser.parseError(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark deposit as rejected: $errorMessage'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
}
