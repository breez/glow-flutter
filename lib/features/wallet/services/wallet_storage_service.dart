import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:glow/config/environment.dart';
import 'package:glow/logging/logger_mixin.dart';
import 'package:glow/features/wallet/models/wallet_metadata.dart';

/// Manages secure storage of wallet metadata and mnemonics.
class WalletStorageService with LoggerMixin {
  /// Storage Keys:
  /// - `wallet_list`: JSON array of wallet metadata
  /// - `active_wallet_id`: ID of currently active wallet
  /// - `wallet_mnemonic_{id}`: Encrypted mnemonic for wallet {id}
  static const String _walletListKey = 'wallet_list';
  static const String _activeWalletKey = 'active_wallet_id';
  static const String _mnemonicPrefix = 'wallet_mnemonic_';

  /// Secure Storage Options
  static const String _accountName = 'Glow';
  static const KeychainAccessibility _keychainAccessibility = KeychainAccessibility.first_unlock;

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
        accountName: '$_accountName$suffix',
        accessibility: _keychainAccessibility,
      ),
      mOptions: MacOsOptions(
        accountName: '$_accountName$suffix',
        accessibility: _keychainAccessibility,
      ),
    );
  }

  final FlutterSecureStorage _storage = _createStorage();

  // ============================================================================
  // Wallet List Management
  // ============================================================================

  /// Load all wallets from secure storage
  ///
  /// Returns empty list if no wallets exist or on error
  Future<List<WalletMetadata>> loadWallets() async {
    try {
      final String? json = await _storage.read(key: _walletListKey);
      if (json == null || json.isEmpty) {
        log.d('No wallets found in storage');
        return <WalletMetadata>[];
      }

      final List<WalletMetadata> wallets = (jsonDecode(json) as List<dynamic>)
          .map((dynamic e) => WalletMetadata.fromJson(e as Map<String, dynamic>))
          .toList();
      if (wallets.isEmpty) {
        log.d('Wallet list is empty after decoding');
        return <WalletMetadata>[];
      }
      return wallets;
    } catch (e, stack) {
      log.e('Failed to load wallets', error: e, stackTrace: stack);
      return <WalletMetadata>[];
    }
  }

  /// Save wallet list to secure storage
  Future<void> saveWallets(List<WalletMetadata> wallets) async {
    try {
      await _storage.write(
        key: _walletListKey,
        value: jsonEncode(wallets.map((WalletMetadata w) => w.toJson()).toList()),
      );
      log.i('Saved ${wallets.length} wallets to storage');
    } catch (e, stack) {
      log.e('Failed to save wallets', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Add a new mnemonic wallet to storage
  ///
  /// SECURITY: Also stores the mnemonic encrypted separately
  Future<void> addWallet(WalletMetadata wallet, String mnemonic) async {
    try {
      await _saveMnemonic(wallet.id, mnemonic);
      final List<WalletMetadata> wallets = await loadWallets();
      await saveWallets(<WalletMetadata>[...wallets, wallet]);
      log.i('Added wallet: ${wallet.id} (${wallet.displayName})');
    } catch (e, stack) {
      log.e('Failed to add wallet: ${wallet.id}', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Update an existing wallet's metadata
  ///
  /// Does NOT update mnemonic (mnemonics are immutable)
  Future<void> updateWallet(WalletMetadata wallet) async {
    try {
      final List<WalletMetadata> wallets = await loadWallets();
      final int index = wallets.indexWhere((WalletMetadata w) => w.id == wallet.id);
      if (index == -1) {
        throw Exception('Wallet not found: ${wallet.id}');
      }

      await saveWallets(<WalletMetadata>[...wallets]..[index] = wallet);
      log.i('Updated wallet: ${wallet.id}');
    } catch (e, stack) {
      log.e('Failed to update wallet: ${wallet.id}', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Delete a wallet and its secrets (mnemonic or seed)
  Future<void> deleteWallet(String walletId) async {
    try {
      await _deleteMnemonic(walletId);
      final List<WalletMetadata> wallets = await loadWallets();
      await saveWallets(wallets.where((WalletMetadata w) => w.id != walletId).toList());

      if (await getActiveWalletId() == walletId) {
        await _storage.delete(key: _activeWalletKey);
        log.i('Cleared active wallet reference');
      }
      log.i('Deleted wallet: $walletId');
    } catch (e, stack) {
      log.e('Failed to delete wallet: $walletId', error: e, stackTrace: stack);
      rethrow;
    }
  }

  // ============================================================================
  // First Sync Tracking
  // ============================================================================

  static const String _firstSyncPrefix = 'wallet_first_sync_done_';

  /// Mark that the wallet has completed its first sync.
  Future<void> markFirstSyncDone(String walletId) async {
    try {
      await _storage.write(key: '$_firstSyncPrefix$walletId', value: 'true');
      log.d('Marked first sync done for wallet: $walletId');
    } catch (e, stack) {
      log.e('Failed to mark first sync done for wallet: $walletId', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Check whether the wallet has already completed its first sync.
  Future<bool> hasCompletedFirstSync(String walletId) async {
    try {
      final String? value = await _storage.read(key: '$_firstSyncPrefix$walletId');
      return value == 'true';
    } catch (e, stack) {
      log.e('Failed to read first sync state for wallet: $walletId', error: e, stackTrace: stack);
      return false;
    }
  }

  // ============================================================================
  // Active Wallet Management
  // ============================================================================

  /// Get the ID of the currently active wallet
  Future<String?> getActiveWalletId() async {
    try {
      final String? id = await _storage.read(key: _activeWalletKey);
      if (id == null) {
        log.d('No active wallet set');
      }
      return id;
    } catch (e, stack) {
      log.e('Failed to get active wallet ID', error: e, stackTrace: stack);
      return null;
    }
  }

  /// Set the currently active wallet
  Future<void> setActiveWalletId(String walletId) async {
    try {
      await _storage.write(key: _activeWalletKey, value: walletId);
      log.i('Set active wallet: $walletId');
    } catch (e, stack) {
      log.e('Failed to set active wallet: $walletId', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Clear the active wallet reference
  Future<void> clearActiveWallet() async {
    try {
      await _storage.delete(key: _activeWalletKey);
      log.i('Cleared active wallet');
    } catch (e, stack) {
      log.e('Failed to clear active wallet', error: e, stackTrace: stack);
      rethrow;
    }
  }

  // ============================================================================
  // Mnemonic Management
  // ============================================================================

  /// Load mnemonic for a specific wallet
  Future<String?> loadMnemonic(String walletId) async {
    try {
      final String? mnemonic = await _storage.read(key: '$_mnemonicPrefix$walletId');
      if (mnemonic != null) {
        log.d('Loaded mnemonic for wallet: $walletId');
      } else {
        log.w('Mnemonic not found for wallet: $walletId');
      }
      return mnemonic;
    } catch (e) {
      // SECURITY: Do NOT log the error details as they might contain mnemonic
      log.e('Failed to load mnemonic for wallet: $walletId (details hidden for security)');
      return null;
    }
  }

  /// Save mnemonic for a specific wallet
  Future<void> _saveMnemonic(String walletId, String mnemonic) async {
    try {
      await _storage.write(key: '$_mnemonicPrefix$walletId', value: mnemonic);
      log.d('Saved mnemonic for wallet: $walletId (content not logged)');
    } catch (e) {
      // SECURITY: Do NOT log the error details as they might contain mnemonic
      log.e('Failed to save mnemonic for wallet: $walletId (details hidden for security)');
      rethrow;
    }
  }

  /// Delete mnemonic for a specific wallet
  Future<void> _deleteMnemonic(String walletId) async {
    try {
      await _storage.delete(key: '$_mnemonicPrefix$walletId');
      log.d('Deleted mnemonic for wallet: $walletId');
    } catch (e) {
      // SECURITY: Do NOT log the error details as they might contain mnemonic
      log.e('Failed to delete mnemonic for wallet: $walletId (details hidden for security)');
      rethrow;
    }
  }

  // ============================================================================
  // Utilities
  // ============================================================================

}

final Provider<WalletStorageService> walletStorageServiceProvider = Provider<WalletStorageService>((
  Ref ref,
) {
  return WalletStorageService();
});
