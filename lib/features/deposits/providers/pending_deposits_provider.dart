import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/features/deposits/models/pending_deposit_payment.dart';
import 'package:glow/features/deposits/providers/rejected_deposits_provider.dart';
import 'package:glow/features/deposits/providers/unclaimed_deposits_provider.dart';
import 'package:glow/logging/app_logger.dart';
import 'package:logger/logger.dart';

final Logger _log = AppLogger.getLogger('PendingDepositsProvider');

/// Provider that combines unclaimed deposits with rejection state
/// Returns deposits mapped to PendingDepositPayment objects for display in payment list
final Provider<AsyncValue<List<PendingDepositPayment>>>
pendingDepositsProvider = Provider<AsyncValue<List<PendingDepositPayment>>>((Ref ref) {
  final AsyncValue<List<DepositInfo>> unclaimedDepositsAsync = ref.watch(unclaimedDepositsProvider);
  final AsyncValue<Set<String>> rejectedDepositsAsync = ref.watch(rejectedDepositsProvider);

  // Wait for both providers to have data
  if (!unclaimedDepositsAsync.hasValue || !rejectedDepositsAsync.hasValue) {
    return unclaimedDepositsAsync.whenData((List<DepositInfo> _) => <PendingDepositPayment>[]);
  }

  return unclaimedDepositsAsync.whenData((List<DepositInfo> deposits) {
    final Set<String> rejectedIds = rejectedDepositsAsync.value ?? <String>{};

    final List<PendingDepositPayment> pendingDeposits = deposits
        .map((DepositInfo deposit) {
          final String depositId = '${deposit.txid}:${deposit.vout}';
          final bool isRejected = rejectedIds.contains(depositId);

          return PendingDepositPayment.fromDepositInfo(deposit, isRejected: isRejected);
        })
        .whereType<PendingDepositPayment>() // Filter out nulls if any
        .toList();

    _log.d('Mapped ${pendingDeposits.length} pending deposits (${rejectedIds.length} rejected)');
    return pendingDeposits;
  });
});

/// Provider that filters only non-rejected pending deposits (for main payment list)
/// All unclaimed deposits are shown, regardless of fee requirements
final Provider<AsyncValue<List<PendingDepositPayment>>> nonRejectedPendingDepositsProvider =
    Provider<AsyncValue<List<PendingDepositPayment>>>((Ref ref) {
      final AsyncValue<List<PendingDepositPayment>> pendingDepositsAsync = ref.watch(
        pendingDepositsProvider,
      );

      return pendingDepositsAsync.whenData((List<PendingDepositPayment> deposits) {
        return deposits.where((PendingDepositPayment deposit) => !deposit.isRejected).toList();
      });
    });

/// Provider that filters only rejected pending deposits (for refunds screen)
final Provider<AsyncValue<List<PendingDepositPayment>>> rejectedPendingDepositsProvider =
    Provider<AsyncValue<List<PendingDepositPayment>>>((Ref ref) {
      final AsyncValue<List<PendingDepositPayment>> pendingDepositsAsync = ref.watch(
        pendingDepositsProvider,
      );

      return pendingDepositsAsync.whenData((List<PendingDepositPayment> deposits) {
        return deposits.where((PendingDepositPayment deposit) => deposit.isRejected).toList();
      });
    });

/// Provider that shows rejected deposits needing refund
final Provider<AsyncValue<List<PendingDepositPayment>>> depositsNeedingAttentionProvider =
    Provider<AsyncValue<List<PendingDepositPayment>>>((Ref ref) {
      final AsyncValue<List<PendingDepositPayment>> pendingDepositsAsync = ref.watch(
        pendingDepositsProvider,
      );

      return pendingDepositsAsync.whenData((List<PendingDepositPayment> deposits) {
        return deposits.where((PendingDepositPayment deposit) => deposit.isRejected).toList();
      });
    });
