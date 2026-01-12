import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:glow/config/environment.dart';
import 'package:glow/logging/logger_mixin.dart';

/// Manages persistent storage of rejected deposit identifiers.
///
/// Deposits are uniquely identified by "txid:vout" format.
/// This allows tracking which deposits the user has rejected across app sessions.
class RejectedDepositsStorage with LoggerMixin {
  /// Storage key for rejected deposits list
  static const String _rejectedDepositsKey = 'rejected_deposits';

  /// Get environment-aware storage configuration
  static FlutterSecureStorage _createStorage() {
    final Environment env = Environment.current;
    final String suffix = env.storageSuffix;

    return FlutterSecureStorage(
      aOptions: AndroidOptions(
        sharedPreferencesName: 'glow_prefs$suffix',
        preferencesKeyPrefix: 'glow${suffix}_',
      ),
      iOptions: IOSOptions(
        accountName: 'Glow$suffix',
        accessibility: KeychainAccessibility.first_unlock,
      ),
      mOptions: MacOsOptions(
        accountName: 'Glow$suffix',
        accessibility: KeychainAccessibility.first_unlock,
      ),
    );
  }

  final FlutterSecureStorage _storage = _createStorage();

  /// Format deposit identifier from txid and vout
  String _formatDepositId(String txid, int vout) => '$txid:$vout';

  /// Load all rejected deposit identifiers
  Future<Set<String>> loadRejectedDeposits() async {
    try {
      final String? json = await _storage.read(key: _rejectedDepositsKey);
      if (json == null || json.isEmpty) {
        log.d('No rejected deposits found in storage');
        return <String>{};
      }

      final List<dynamic> list = jsonDecode(json) as List<dynamic>;
      final Set<String> rejected = list.cast<String>().toSet();
      log.d('Loaded ${rejected.length} rejected deposits');
      return rejected;
    } catch (e, stack) {
      log.e('Failed to load rejected deposits', error: e, stackTrace: stack);
      return <String>{};
    }
  }

  /// Save rejected deposit identifiers
  Future<void> _saveRejectedDeposits(Set<String> rejected) async {
    try {
      await _storage.write(key: _rejectedDepositsKey, value: jsonEncode(rejected.toList()));
      log.d('Saved ${rejected.length} rejected deposits to storage');
    } catch (e, stack) {
      log.e('Failed to save rejected deposits', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Mark a deposit as rejected
  Future<void> markAsRejected(String txid, int vout) async {
    final String depositId = _formatDepositId(txid, vout);
    log.i('Marking deposit as rejected: $depositId');

    final Set<String> rejected = await loadRejectedDeposits();
    rejected.add(depositId);
    await _saveRejectedDeposits(rejected);
  }

  /// Check if a deposit has been rejected
  Future<bool> isRejected(String txid, int vout) async {
    final String depositId = _formatDepositId(txid, vout);
    final Set<String> rejected = await loadRejectedDeposits();
    return rejected.contains(depositId);
  }

  /// Remove a deposit from rejected list (e.g., after successful claim or refund)
  Future<void> removeRejection(String txid, int vout) async {
    final String depositId = _formatDepositId(txid, vout);
    log.i('Removing rejection for deposit: $depositId');

    final Set<String> rejected = await loadRejectedDeposits();
    if (rejected.remove(depositId)) {
      await _saveRejectedDeposits(rejected);
    }
  }

  /// Clear all rejected deposits (useful for testing or reset)
  Future<void> clearAll() async {
    log.i('Clearing all rejected deposits');
    await _storage.delete(key: _rejectedDepositsKey);
  }
}

/// Provider for rejected deposits storage service
final Provider<RejectedDepositsStorage> rejectedDepositsStorageProvider =
    Provider<RejectedDepositsStorage>((Ref ref) {
      return RejectedDepositsStorage();
    });
