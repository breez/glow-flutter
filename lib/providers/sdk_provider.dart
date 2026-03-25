import 'dart:async';

import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:glow/logging/app_logger.dart';
import 'package:glow/features/wallet/models/wallet_metadata.dart';
import 'package:glow/features/wallet/providers/wallet_provider.dart';
import 'package:glow/services/breez_sdk_service.dart';
import 'package:glow/services/config_service.dart';
import 'package:glow/features/wallet/services/wallet_storage_service.dart';
import 'package:glow/features/developers/providers/max_deposit_fee_provider.dart';
import 'package:glow/features/developers/providers/network_provider.dart';
import 'package:logger/logger.dart';

final Logger log = AppLogger.getLogger('SdkProvider');

/// Track if Lightning Address was manually deleted (to prevent auto-registration)
class LightningAddressManuallyDeletedNotifier extends Notifier<bool> {
  @override
  bool build() {
    log.d('LightningAddressManuallyDeletedNotifier initialized');
    // Reset when wallet changes
    ref.listen(activeWalletProvider, (
      AsyncValue<WalletMetadata?>? previous,
      AsyncValue<WalletMetadata?> next,
    ) {
      if (previous?.value?.id != next.value?.id) {
        log.d('Wallet changed, resetting LightningAddressManuallyDeleted state');
        state = false;
      }
    });
    return false;
  }

  void markAsDeleted() {
    log.d('Lightning address manually marked as deleted');
    state = true;
  }

  void reset() {
    log.d('Lightning address manual delete state reset');
    state = false;
  }
}

final NotifierProvider<LightningAddressManuallyDeletedNotifier, bool>
lightningAddressManuallyDeletedProvider =
    NotifierProvider<LightningAddressManuallyDeletedNotifier, bool>(
      LightningAddressManuallyDeletedNotifier.new,
    );

/// Connected SDK instance - auto-reconnects on wallet/network changes
final FutureProvider<BreezSdk> sdkProvider = FutureProvider<BreezSdk>((Ref ref) async {
  final String? walletId = ref.watch(activeWalletIdProvider);
  log.d('Active wallet id: $walletId');
  final Network network = ref.watch(networkProvider);
  log.d('Network: $network');

  final MaxFee maxDepositClaimFee = ref.watch(maxDepositClaimFeeProvider);
  log.d('Max deposit claim fee: $maxDepositClaimFee');

  if (walletId == null) {
    log.e('No active wallet selected');
    throw Exception('No active wallet selected');
  }

  final WalletStorageService storage = ref.read(walletStorageServiceProvider);

  // Determine auth method from wallet metadata
  final List<WalletMetadata> wallets = await ref.read(walletListProvider.future);
  final WalletMetadata? walletMeta = wallets.firstWhereOrNull((WalletMetadata w) => w.id == walletId);
  final WalletAuthMethod authMethod = walletMeta?.authMethod ?? WalletAuthMethod.mnemonic;
  log.d('Wallet auth method: ${authMethod.name}');

  final Seed seed;
  switch (authMethod) {
    case WalletAuthMethod.mnemonic:
      final String? mnemonic = await storage.loadMnemonic(walletId);
      if (mnemonic == null) {
        log.e('Wallet mnemonic not found');
        throw Exception('Wallet mnemonic not found');
      }
      seed = Seed.mnemonic(mnemonic: mnemonic);
    case WalletAuthMethod.passkey:
      // Re-derive seed from passkey on each connect — no secrets stored
      log.i('Re-deriving seed from passkey');
      final PasskeyPrfProvider prfProvider = PasskeyPrfProvider(
        const PasskeyPrfProviderOptions(rpName: 'Glow', userName: 'Glow', userDisplayName: 'Glow'),
      );
      final Passkey passkey = Passkey(
        derivePrfSeed: prfProvider.derivePrfSeed,
        isPrfAvailable: prfProvider.isPrfAvailable,
      );
      final Wallet wallet = await passkey.getWallet(label: 'Default');
      seed = wallet.seed;
  }

  // Create config with app settings and user preferences
  final ConfigService configService = ref.read(configServiceProvider);
  final Config config = configService.createConfig(
    network: network,
    maxDepositClaimFee: maxDepositClaimFee,
  );

  final BreezSdkService service = ref.read(breezSdkServiceProvider);
  return await service.connect(walletId: walletId, seed: seed, config: config);
});

/// Node info - only updates when data actually changes
class NodeInfoNotifier extends AsyncNotifier<GetInfoResponse> {
  @override
  Future<GetInfoResponse> build() async {
    final BreezSdk sdk = await ref.watch(sdkProvider.future);
    final BreezSdkService service = ref.read(breezSdkServiceProvider);
    return await service.getNodeInfo(sdk);
  }

  Future<void> refreshIfChanged() async {
    if (!state.hasValue) {
      return;
    }

    final BreezSdk sdk = await ref.read(sdkProvider.future);
    final BreezSdkService service = ref.read(breezSdkServiceProvider);
    final GetInfoResponse newInfo = await service.getNodeInfo(sdk);

    // Only update if balance actually changed
    if (state.requireValue.balanceSats != newInfo.balanceSats) {
      log.d('Balance changed: ${state.requireValue.balanceSats} -> ${newInfo.balanceSats}');
      state = AsyncValue<GetInfoResponse>.data(newInfo);
    } else {
      log.t('Node info unchanged, skipping update');
    }
  }
}

final AsyncNotifierProvider<NodeInfoNotifier, GetInfoResponse> nodeInfoProvider =
    AsyncNotifierProvider<NodeInfoNotifier, GetInfoResponse>(() {
      return NodeInfoNotifier();
    });

/// Payments list - only updates when payments actually change
class PaymentsNotifier extends AsyncNotifier<List<Payment>> {
  @override
  Future<List<Payment>> build() async {
    final BreezSdk sdk = await ref.watch(sdkProvider.future);
    final BreezSdkService service = ref.read(breezSdkServiceProvider);
    final List<Payment> payments = await service.listPayments(sdk, const ListPaymentsRequest());
    return payments;
  }

  Future<void> refreshIfChanged() async {
    if (!state.hasValue) {
      return;
    }

    final BreezSdk sdk = await ref.read(sdkProvider.future);
    final BreezSdkService service = ref.read(breezSdkServiceProvider);
    final List<Payment> newPayments = await service.listPayments(sdk, const ListPaymentsRequest());

    // Check if payment list actually changed using deep equality
    final List<Payment> currentPayments = state.requireValue;
    const ListEquality<Payment> listEquality = ListEquality<Payment>();

    if (!listEquality.equals(currentPayments, newPayments)) {
      log.d('Payments changed');
      state = AsyncValue<List<Payment>>.data(newPayments);
    } else {
      log.t('Payments unchanged, skipping update');
    }
  }
}

final AsyncNotifierProvider<PaymentsNotifier, List<Payment>> paymentsProvider =
    AsyncNotifierProvider<PaymentsNotifier, List<Payment>>(PaymentsNotifier.new);

/// Balance - derived from node info
final Provider<AsyncValue<BigInt>> balanceProvider = Provider<AsyncValue<BigInt>>((Ref ref) {
  final AsyncValue<GetInfoResponse> nodeInfo = ref.watch(nodeInfoProvider);
  return nodeInfo.when(
    data: (GetInfoResponse info) {
      log.t('Balance: ${info.balanceSats}');
      return AsyncValue<BigInt>.data(info.balanceSats);
    },
    loading: () => const AsyncValue<BigInt>.loading(),
    error: (Object error, StackTrace stack) => AsyncValue<BigInt>.error(error, stack),
  );
});

/// Lightning address - with optional auto-registration
final FutureProviderFamily<LightningAddressInfo?, bool> lightningAddressProvider = FutureProvider
    .autoDispose
    .family<LightningAddressInfo?, bool>((Ref ref, bool autoRegister) async {
      log.d('lightningAddressProvider called, autoRegister=$autoRegister');
      final BreezSdk sdk = await ref.watch(sdkProvider.future);
      final BreezSdkService service = ref.read(breezSdkServiceProvider);

      // Don't auto-register if user manually deleted their address
      final bool manuallyDeleted = ref.watch(lightningAddressManuallyDeletedProvider);
      log.d('Lightning address manually deleted: $manuallyDeleted');
      final bool shouldAutoRegister = autoRegister && !manuallyDeleted;
      log.d('Should auto-register lightning address: $shouldAutoRegister');

      // Get profile name for Lightning Address username - wait for wallet to load
      final WalletMetadata? wallet = await ref.watch(activeWalletProvider.future);
      final String? profileName = wallet?.displayName;
      log.d('Profile display name for LN address: $profileName');

      final LightningAddressInfo? info = await service.getLightningAddress(
        sdk,
        autoRegister: shouldAutoRegister,
        profileName: profileName,
      );
      log.d('Lightning address info fetched: ${info?.lightningAddress}');
      return info;
    });

/// Listen for SDK events (all events)
final StreamProvider<SdkEvent> sdkEventsStreamProvider = StreamProvider<SdkEvent>((Ref ref) async* {
  final BreezSdk sdk = await ref.watch(sdkProvider.future);

  await for (final SdkEvent event in sdk.addEventListener()) {
    log.d('SDK event received: ${event.runtimeType}');
    yield event;
  }
});

/// Keep the SDK event stream alive and handle events
final Provider<void> sdkEventListenerProvider = Provider<void>((Ref ref) {
  // Keep this provider alive
  ref.keepAlive();

  // Watch the stream and handle events
  ref.listen<AsyncValue<SdkEvent>>(sdkEventsStreamProvider, (
    AsyncValue<SdkEvent>? previous,
    AsyncValue<SdkEvent> next,
  ) {
    next.whenData((SdkEvent event) async {
      // Handle events that need conditional provider updates
      event.when(
        synced: () async {
          log.i('Wallet synced');
          await ref.read(nodeInfoProvider.notifier).refreshIfChanged();
          await ref.read(paymentsProvider.notifier).refreshIfChanged();
        },
        paymentSucceeded: (Payment payment) async {
          log.i('Payment succeeded: ${payment.id}');
          await ref.read(nodeInfoProvider.notifier).refreshIfChanged();
          await ref.read(paymentsProvider.notifier).refreshIfChanged();
        },
        paymentPending: (Payment payment) async {
          log.i('Payment pending: ${payment.id}');
          await ref.read(nodeInfoProvider.notifier).refreshIfChanged();
          await ref.read(paymentsProvider.notifier).refreshIfChanged();
        },
        paymentFailed: (Payment payment) async {
          log.e('Payment failed: ${payment.id}');
          await ref.read(paymentsProvider.notifier).refreshIfChanged();
        },
        unclaimedDeposits: (List<DepositInfo> unclaimedDeposits) {
          log.i('Unclaimed Deposits: ${unclaimedDeposits.length}');
        },
        claimedDeposits: (List<DepositInfo> claimedDeposits) {
          log.i('Claimed Deposits: ${claimedDeposits.length}');
        },
        optimization: (OptimizationEvent optimizationEvent) {
          log.i('Optimization event: ${optimizationEvent.runtimeType}');
          // TODO(erdemyerebasmaz): handle optimization events
        },
        lightningAddressChanged: (LightningAddressInfo? lightningAddress) {
<<<<<<< HEAD
          log.i('Lightning address changed: ${lightningAddress?.lightningAddress}');
=======
          log.i('Lightning address changed');
        },
        newDeposits: (List<DepositInfo> newDeposits) {
          log.i('New deposits: ${newDeposits.length}');
>>>>>>> 8b78b5e (Add passkey wallet creation and entropy-based SDK connection)
        },
      );
    });
  });
});

/// Provider to list unclaimed deposits
final FutureProvider<List<DepositInfo>> unclaimedDepositsProvider =
    FutureProvider<List<DepositInfo>>((Ref ref) async {
      final BreezSdk sdk = await ref.watch(sdkProvider.future);
      final BreezSdkService service = ref.read(breezSdkServiceProvider);

      // Watch the event stream to know when to refresh
      // This creates a dependency on the stream but doesn't create circular invalidation
      ref.watch(sdkEventsStreamProvider);

      final List<DepositInfo> deposits = await service.listUnclaimedDeposits(sdk);
      if (deposits.isNotEmpty) {
        log.d('Unclaimed deposits: ${deposits.length}');
      }
      return deposits;
    });

/// Check if there are any unclaimed deposits that need attention
final Provider<AsyncValue<bool>> hasUnclaimedDepositsProvider = Provider<AsyncValue<bool>>((
  Ref ref,
) {
  return ref.watch(unclaimedDepositsProvider).whenData((List<DepositInfo> deposits) {
    final bool hasUnclaimed = deposits.isNotEmpty;
    if (hasUnclaimed) {
      log.w('User has ${deposits.length} unclaimed deposits');
    }
    return hasUnclaimed;
  });
});

/// Get count of unclaimed deposits for UI display
final Provider<AsyncValue<int>> unclaimedDepositsCountProvider = Provider<AsyncValue<int>>((
  Ref ref,
) {
  return ref
      .watch(unclaimedDepositsProvider)
      .whenData((List<DepositInfo> deposits) => deposits.length);
});

/// Provider that ensures SDK is connected and initial data is loaded before showing HomeScreen
/// This prevents showing loading placeholders on subsequent runs
final FutureProvider<void> sdkReadyProvider = FutureProvider<void>((Ref ref) async {
  log.d('Waiting for SDK connection and initial data load...');

  // Wait for SDK to connect
  await ref.watch(sdkProvider.future);
  log.d('SDK connected');

  // Wait for initial data to load (payments and node info)
  // Use read() instead of watch() to avoid rebuilding when payments/nodeInfo update
  await ref.read(paymentsProvider.future);
  log.d('Payments loaded');

  await ref.read(nodeInfoProvider.future);
  log.d('Node info loaded');

  log.i('SDK ready with initial data loaded');
});

/// Manual deposit claiming provider (for retrying failed claims)
final FutureProviderFamily<ClaimDepositResponse, DepositInfo> claimDepositProvider = FutureProvider
    .autoDispose
    .family<ClaimDepositResponse, DepositInfo>((Ref ref, DepositInfo deposit) async {
      log.d('Manually claiming deposit: ${deposit.txid}:${deposit.vout}');
      final BreezSdk sdk = await ref.watch(sdkProvider.future);
      final BreezSdkService service = ref.read(breezSdkServiceProvider);
      final MaxFee maxDepositClaimFee = ref.watch(maxDepositClaimFeeProvider);

      final ClaimDepositResponse response = await service.claimDeposit(
        sdk,
        ClaimDepositRequest(txid: deposit.txid, vout: deposit.vout, maxFee: maxDepositClaimFee),
      );

      // Refresh UI only if data changed
      await ref.read(nodeInfoProvider.notifier).refreshIfChanged();
      await ref.read(paymentsProvider.notifier).refreshIfChanged();
      ref.invalidate(unclaimedDepositsProvider);

      return response;
    });

// Track first sync state
class HasSyncedNotifier extends Notifier<bool> {
  @override
  bool build() {
    _initialize();
    return false;
  }

  Future<void> _initialize() async {
    log.d('HasSyncedNotifier: Waiting for SDK to connect...');
    await ref.read(sdkProvider.future);
    log.d('HasSyncedNotifier: SDK connected, now waiting for first sync...');

    ref.listen(sdkEventsStreamProvider, (
      AsyncValue<SdkEvent>? previous,
      AsyncValue<SdkEvent> next,
    ) {
      (next as AsyncValue<SdkEvent>?)?.whenData((SdkEvent event) async {
        if (event is SdkEvent_Synced) {
          final WalletMetadata? wallet = ref.read(activeWalletProvider).value;
          if (wallet == null) {
            return;
          }

          final WalletStorageService storage = ref.read(walletStorageServiceProvider);
          final bool alreadyMarked = await storage.hasCompletedFirstSync(wallet.id);

          if (!alreadyMarked) {
            await storage.markFirstSyncDone(wallet.id);
            log.i('First sync completed and marked for wallet: ${wallet.id}');
            state = true;
          } else if (!state) {
            // Only log once when state transitions from false to true
            log.d('Sync completed after SDK connection for wallet: ${wallet.id}');
            state = true;
          }
        }
      });
    });
  }
}

final NotifierProvider<HasSyncedNotifier, bool> hasSyncedProvider =
    NotifierProvider<HasSyncedNotifier, bool>(() {
      return HasSyncedNotifier();
    });

/// Whether to wait for initial sync before showing balance/payments
/// Returns true if this is the first run and we should wait for sync
/// Returns false if the wallet has already synced before (show cached data immediately)
final FutureProvider<bool> shouldWaitForInitialSyncProvider = FutureProvider<bool>((Ref ref) async {
  final WalletMetadata? wallet = await ref.watch(activeWalletProvider.future);
  if (wallet == null) {
    log.d('No active wallet, not waiting for sync');
    return false;
  }

  final WalletStorageService storage = ref.read(walletStorageServiceProvider);
  final bool hasCompletedFirstSync = await storage.hasCompletedFirstSync(wallet.id);

  // If wallet has already synced before, don't wait (return false)
  // If this is first time, wait for sync (return true)
  final bool shouldWait = !hasCompletedFirstSync;
  log.d('Wallet ${wallet.id} hasCompletedFirstSync=$hasCompletedFirstSync, shouldWait=$shouldWait');

  return shouldWait;
});
