import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/features/deposits/services/rejected_deposits_storage.dart';
import 'package:glow/logging/app_logger.dart';
import 'package:logger/logger.dart';

final Logger _log = AppLogger.getLogger('RejectedDepositsProvider');

/// Provider for managing rejected deposits state
final AsyncNotifierProvider<RejectedDepositsNotifier, Set<String>> rejectedDepositsProvider =
    AsyncNotifierProvider<RejectedDepositsNotifier, Set<String>>(RejectedDepositsNotifier.new);

/// Notifier for managing rejected deposits
class RejectedDepositsNotifier extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() async {
    final RejectedDepositsStorage storage = ref.read(rejectedDepositsStorageProvider);
    final Set<String> rejected = await storage.loadRejectedDeposits();
    _log.d('Loaded ${rejected.length} rejected deposits');
    return rejected;
  }

  /// Format deposit identifier
  String _formatDepositId(String txid, int vout) => '$txid:$vout';

  /// Mark a deposit as rejected
  Future<void> markAsRejected(String txid, int vout) async {
    final String depositId = _formatDepositId(txid, vout);
    _log.i('Marking deposit as rejected: $depositId');

    final RejectedDepositsStorage storage = ref.read(rejectedDepositsStorageProvider);
    await storage.markAsRejected(txid, vout);

    // Update state
    state = await AsyncValue.guard(() async {
      final Set<String> current = state.value ?? <String>{};
      return <String>{...current, depositId};
    });
  }

  /// Check if a deposit is rejected
  bool isRejected(String txid, int vout) {
    final String depositId = _formatDepositId(txid, vout);
    return state.value?.contains(depositId) ?? false;
  }

  /// Remove rejection (after claim or refund)
  Future<void> removeRejection(String txid, int vout) async {
    final String depositId = _formatDepositId(txid, vout);
    _log.i('Removing rejection for deposit: $depositId');

    final RejectedDepositsStorage storage = ref.read(rejectedDepositsStorageProvider);
    await storage.removeRejection(txid, vout);

    // Update state
    state = await AsyncValue.guard(() async {
      final Set<String> current = state.value ?? <String>{};
      final Set<String> updated = Set<String>.from(current);
      updated.remove(depositId);
      return updated;
    });
  }

  /// Clear all rejections
  Future<void> clearAll() async {
    _log.i('Clearing all rejected deposits');

    final RejectedDepositsStorage storage = ref.read(rejectedDepositsStorageProvider);
    await storage.clearAll();

    // Update state
    state = const AsyncValue<Set<String>>.data(<String>{});
  }
}
