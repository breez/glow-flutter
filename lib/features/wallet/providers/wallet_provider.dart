import 'dart:typed_data';

import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/logging/app_logger.dart';
import 'package:glow/features/wallet/models/wallet_metadata.dart';
import 'package:glow/features/wallet/services/mnemonic_service.dart';
import 'package:glow/features/wallet/services/wallet_storage_service.dart';
import 'package:glow/features/profile/models/profile.dart';
import 'package:glow/features/profile/provider/profile_provider.dart';
import 'package:logger/logger.dart';

final Logger log = AppLogger.getLogger('WalletProvider');

class WalletListNotifier extends AsyncNotifier<List<WalletMetadata>> {
  WalletStorageService? _storage;
  MnemonicService? _mnemonicService;

  @override
  Future<List<WalletMetadata>> build() async {
    _storage ??= ref.read(walletStorageServiceProvider);
    _mnemonicService ??= ref.read(mnemonicServiceProvider);

    log.i('Loading wallet list from storage');
    final List<WalletMetadata> wallets = await _storage!.loadWallets();
    log.i('Loaded ${wallets.length} wallets');
    return wallets;
  }

  Future<(WalletMetadata, String)> createWallet({
    Profile? profile,
    Network network = Network.mainnet,
  }) async {
    try {
      // Auto-generate profile if not provided
      final Profile walletProfile = profile ?? generateProfile();
      log.i('Creating new wallet: ${walletProfile.displayName} on ${network.name}');

      final String mnemonic = _mnemonicService!.generateMnemonic();
      final String walletId = WalletStorageService.generateWalletId(mnemonic);
      final WalletMetadata wallet = WalletMetadata(id: walletId, profile: walletProfile);

      await _storage!.addWallet(wallet, mnemonic);
      state = AsyncValue<List<WalletMetadata>>.data(<WalletMetadata>[
        ...state.value ?? <WalletMetadata>[],
        wallet,
      ]);

      log.i('Created wallet: $walletId (${walletProfile.displayName})');
      return (wallet, mnemonic);
    } catch (e, stack) {
      log.e('Failed to create wallet', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Create a wallet using platform passkey PRF.
  ///
  /// Uses [PasskeyPrfProvider] to derive a seed from the device passkey.
  /// If no passkey exists for the RP ID, one is registered automatically.
  Future<WalletMetadata> createWalletWithPasskey({Profile? profile}) async {
    try {
      final Profile walletProfile = profile ?? generateProfile();
      log.i('Creating passkey wallet: ${walletProfile.displayName}');

      final PasskeyPrfProvider prfProvider = PasskeyPrfProvider(
        const PasskeyPrfProviderOptions(rpName: 'Glow', userName: 'Glow', userDisplayName: 'Glow'),
      );
      final Passkey passkey = Passkey(
        derivePrfSeed: prfProvider.derivePrfSeed,
        isPrfAvailable: prfProvider.isPrfAvailable,
      );

      final Wallet wallet = await passkey.getWallet(label: 'Default');

      // Extract entropy bytes from the seed
      final Seed seed = wallet.seed;
      final Uint8List seedBytes;
      switch (seed) {
        case Seed_Entropy(:final Uint8List field0):
          seedBytes = field0;
        case Seed_Mnemonic():
          throw Exception('Passkey wallet returned mnemonic seed unexpectedly');
      }

      final String walletId = WalletStorageService.generateWalletIdFromBytes(seedBytes);

      // Check for duplicate
      final List<WalletMetadata> existingWallets = state.value ?? <WalletMetadata>[];
      if (existingWallets.any((WalletMetadata w) => w.id == walletId)) {
        log.i('Passkey wallet already exists: $walletId');
        return existingWallets.firstWhere((WalletMetadata w) => w.id == walletId);
      }

      final WalletMetadata metadata = WalletMetadata(
        id: walletId,
        profile: walletProfile,
        isVerified: true,
        authMethod: WalletAuthMethod.passkey,
      );

      await _storage!.addPasskeyWallet(metadata, seedBytes);
      state = AsyncValue<List<WalletMetadata>>.data(<WalletMetadata>[...existingWallets, metadata]);

      log.i('Created passkey wallet: $walletId (${walletProfile.displayName})');
      return metadata;
    } catch (e, stack) {
      log.e('Failed to create passkey wallet', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<WalletMetadata> restoreWallet({required String mnemonic, required Network network}) async {
    try {
      // Auto-generate profile if not provided
      final Profile walletProfile = generateProfile();
      log.i('Restoring wallet: ${walletProfile.displayName} on ${network.name}');

      final String normalized = _mnemonicService!.normalizeMnemonic(mnemonic);
      final (bool isValid, String? error) = _mnemonicService!.validateMnemonic(normalized);

      if (!isValid) {
        log.w('Invalid mnemonic: $error');
        throw Exception('Invalid mnemonic: $error');
      }

      final String walletId = WalletStorageService.generateWalletId(normalized);
      final List<WalletMetadata> existingWallets = state.value ?? <WalletMetadata>[];

      if (existingWallets.any((WalletMetadata w) => w.id == walletId)) {
        log.w('Wallet already exists: $walletId');
        throw Exception('This wallet already exists');
      }

      // Restored wallets are marked as verified (user already has the phrase)
      final WalletMetadata wallet = WalletMetadata(
        id: walletId,
        profile: walletProfile,
        isVerified: true,
      );
      await _storage!.addWallet(wallet, normalized);

      state = AsyncValue<List<WalletMetadata>>.data(<WalletMetadata>[...existingWallets, wallet]);

      log.i('Restored wallet: $walletId (${walletProfile.displayName})');
      return wallet;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateWalletProfile(String walletId, {String? customName}) async {
    try {
      log.i('Updating wallet profile: $walletId');

      final List<WalletMetadata> wallets = state.value ?? <WalletMetadata>[];
      final int index = wallets.indexWhere((WalletMetadata w) => w.id == walletId);
      if (index == -1) {
        throw Exception('Wallet not found: $walletId');
      }

      final Profile updatedProfile = wallets[index].profile.copyWith(customName: customName);
      final WalletMetadata updated = wallets[index].copyWith(profile: updatedProfile);
      await _storage!.updateWallet(updated);

      state = AsyncValue<List<WalletMetadata>>.data(
        <WalletMetadata>[...wallets]..[index] = updated,
      );
      log.i('Wallet profile updated: $walletId');
    } catch (e, stack) {
      log.e('Failed to update wallet profile', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<void> markWalletAsVerified(String walletId) async {
    try {
      log.i('Marking wallet as verified: $walletId');

      final List<WalletMetadata> wallets = state.value ?? <WalletMetadata>[];
      final int index = wallets.indexWhere((WalletMetadata w) => w.id == walletId);
      if (index == -1) {
        throw Exception('Wallet not found: $walletId');
      }

      final WalletMetadata updated = wallets[index].copyWith(isVerified: true);
      await _storage!.updateWallet(updated);

      state = AsyncValue<List<WalletMetadata>>.data(
        <WalletMetadata>[...wallets]..[index] = updated,
      );
      log.i('Wallet marked as verified: $walletId');
    } catch (e, stack) {
      log.e('Failed to mark wallet as verified', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<void> deleteWallet(String walletId) async {
    try {
      log.w('Deleting wallet: $walletId');
      await _storage!.deleteWallet(walletId);

      state = AsyncValue<List<WalletMetadata>>.data(
        (state.value ?? <WalletMetadata>[]).where((WalletMetadata w) => w.id != walletId).toList(),
      );
      log.i('Wallet deleted: $walletId');
    } catch (e, stack) {
      log.e('Failed to delete wallet', error: e, stackTrace: stack);
      rethrow;
    }
  }
}

final AsyncNotifierProvider<WalletListNotifier, List<WalletMetadata>> walletListProvider =
    AsyncNotifierProvider<WalletListNotifier, List<WalletMetadata>>(WalletListNotifier.new);

// ============================================================================
// Active Wallet Management
// ============================================================================

class ActiveWalletNotifier extends AsyncNotifier<WalletMetadata?> {
  WalletStorageService? _storage;
  String? _activeWalletId;

  @override
  Future<WalletMetadata?> build() async {
    _storage ??= ref.read(walletStorageServiceProvider);
    log.i('Loading active wallet');

    _activeWalletId ??= await _storage!.getActiveWalletId();
    log.d('Active wallet ID: $_activeWalletId');

    if (_activeWalletId == null) {
      log.i('No active wallet set');
      return null;
    }

    final List<WalletMetadata> wallets = await ref.read(walletListProvider.future);
    log.d('Wallets loaded for active wallet lookup: ${wallets.length}');
    final WalletMetadata? wallet = wallets
        .where((WalletMetadata w) => w.id == _activeWalletId)
        .firstOrNull;

    if (wallet != null) {
      log.i('Active wallet: ${wallet.id} (${wallet.displayName})');

      // Listen for wallet list changes to update metadata without rebuilding
      ref.listen(walletListProvider, (
        AsyncValue<List<WalletMetadata>>? previous,
        AsyncValue<List<WalletMetadata>> next,
      ) {
        next.whenData((List<WalletMetadata> updatedWallets) {
          if (_activeWalletId != null) {
            final WalletMetadata? updatedWallet = updatedWallets
                .where((WalletMetadata w) => w.id == _activeWalletId)
                .firstOrNull;
            if (updatedWallet != null && updatedWallet != state.value) {
              log.d('Active wallet metadata updated');
              state = AsyncValue<WalletMetadata?>.data(updatedWallet);
            }
          }
        });
      });

      return wallet;
    }

    log.w('Active wallet not found in list: $_activeWalletId');
    await _storage!.clearActiveWallet();
    _activeWalletId = null;
    return null;
  }

  Future<void> switchWallet(String walletId) async {
    try {
      log.i('Switching to wallet: $walletId');

      final List<WalletMetadata> wallets = await ref.read(walletListProvider.future);
      final WalletMetadata? wallet = wallets
          .where((WalletMetadata w) => w.id == walletId)
          .firstOrNull;
      if (wallet == null) {
        throw Exception('Wallet not found: $walletId');
      }

      await _storage!.setActiveWalletId(walletId);
      _activeWalletId = walletId;
      state = AsyncValue<WalletMetadata?>.data(wallet);

      log.i('Switched to wallet: $walletId (${wallet.displayName})');
    } catch (e, stack) {
      log.e('Failed to switch wallet', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<void> setActiveWallet(String walletId) => switchWallet(walletId);

  Future<void> clearActiveWallet() async {
    try {
      log.i('Clearing active wallet');
      await _storage!.clearActiveWallet();
      _activeWalletId = null;
      state = const AsyncValue<WalletMetadata?>.data(null);
      log.i('Active wallet cleared');
    } catch (e, stack) {
      log.e('Failed to clear active wallet', error: e, stackTrace: stack);
      rethrow;
    }
  }
}

final AsyncNotifierProvider<ActiveWalletNotifier, WalletMetadata?> activeWalletProvider =
    AsyncNotifierProvider<ActiveWalletNotifier, WalletMetadata?>(ActiveWalletNotifier.new);

// ============================================================================
// Derived Providers
// ============================================================================

/// Provides only the active wallet ID - prevents SDK reconnection on metadata changes
final Provider<String?> activeWalletIdProvider = Provider<String?>((Ref ref) {
  final WalletMetadata? wallet = ref.watch(activeWalletProvider).value;
  return wallet?.id;
});

final Provider<AsyncValue<bool>> hasWalletsProvider = Provider<AsyncValue<bool>>((Ref ref) {
  final AsyncValue<List<WalletMetadata>> wallets = ref.watch(walletListProvider);
  return wallets.when(
    data: (List<WalletMetadata> list) {
      log.d('Wallets count for hasWalletsProvider: ${list.length}');
      return AsyncValue<bool>.data(list.isNotEmpty);
    },
    loading: () {
      log.d('hasWalletsProvider loading');
      return const AsyncValue<bool>.loading();
    },
    error: (Object err, StackTrace stack) {
      log.e('hasWalletsProvider error: $err');
      return AsyncValue<bool>.error(err, stack);
    },
  );
});

final Provider<int> walletCountProvider = Provider<int>((Ref ref) {
  log.d('walletCountProvider called');
  final AsyncValue<List<WalletMetadata>> wallets = ref.watch(walletListProvider);
  return wallets.when(
    data: (List<WalletMetadata> list) {
      log.d('Wallet count: ${list.length}');
      return list.length;
    },
    loading: () {
      log.d('walletCountProvider loading');
      return 0;
    },
    error: (Object err, StackTrace stack) {
      log.e('walletCountProvider error: $err');
      return 0;
    },
  );
});
