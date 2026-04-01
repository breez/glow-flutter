import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/logging/app_logger.dart';
import 'package:glow/features/wallet/models/wallet_metadata.dart';
import 'package:glow/features/wallet/providers/wallet_provider.dart';
import 'package:glow/features/wallet_onboarding/models/onboarding_state.dart';
import 'package:glow/features/profile/models/profile.dart';
import 'package:glow/features/profile/provider/profile_provider.dart';
import 'package:glow/features/wallet/services/wallet_storage_service.dart';
import 'package:glow/providers/sdk_provider.dart' show PasskeySeedCache;
import 'package:logger/logger.dart';

final Logger _log = AppLogger.getLogger('PasskeyOnboarding');

class OnboardingStateNotifier extends Notifier<OnboardingState> {
  /// Reusable Passkey instance across phases (created once during detection).
  Passkey? _passkey;

  /// PRF provider kept alive for createPasskey + subsequent phases.
  PasskeyPrfProvider? _prfProvider;

  @override
  OnboardingState build() {
    return const OnboardingState();
  }

  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  // ---------------------------------------------------------------------------
  // Mnemonic wallet creation (unchanged)
  // ---------------------------------------------------------------------------

  Future<(WalletMetadata, String)> createWallet() async {
    if (state.isLoading) {
      throw Exception('Wallet creation already in progress');
    }

    setLoading(true);

    try {
      _log.i('Creating mnemonic wallet on mainnet');

      final (WalletMetadata wallet, String mnemonic) =
          await ref.read(walletListProvider.notifier).createWallet();

      await ref.read(activeWalletProvider.notifier).setActiveWallet(wallet.id);

      _log.i('Mnemonic wallet created and activated: ${wallet.id} (${wallet.displayName})');
      setLoading(false);
      return (wallet, mnemonic);
    } catch (e, stack) {
      _log.e('Failed to create mnemonic wallet', error: e, stackTrace: stack);
      setLoading(false);
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Passkey flow — phase-based, matching glow-web UX
  // ---------------------------------------------------------------------------

  PasskeyPrfProvider _ensurePrfProvider() {
    if (_prfProvider == null) {
      _log.d('Initializing PasskeyPrfProvider (rpName: Glow)');
      _prfProvider = PasskeyPrfProvider(
        const PasskeyPrfProviderOptions(
          rpName: 'Glow',
          userName: 'Glow',
          userDisplayName: 'Glow',
        ),
      );
    }
    return _prfProvider!;
  }

  Passkey _ensurePasskey() {
    if (_passkey == null) {
      _log.d('Initializing Passkey instance');
      final PasskeyPrfProvider prfProvider = _ensurePrfProvider();
      _passkey = Passkey(
        derivePrfSeed: prfProvider.derivePrfSeed,
        isPrfAvailable: prfProvider.isPrfAvailable,
      );
    }
    return _passkey!;
  }

  void _setPhase(PasskeyPhase phase, {bool loading = false}) {
    _log.d('Phase transition: ${state.passkeyPhase?.name ?? "none"} → ${phase.name}');
  }

  /// Phase: detecting — try listLabels() to see if user has an existing passkey.
  Future<void> startPasskeyFlow() async {
    if (state.isLoading) {
      _log.w('startPasskeyFlow called while loading, ignoring');
      return;
    }

    _log.i('Starting passkey onboarding flow');
    _setPhase(PasskeyPhase.detecting, loading: true);
    state = const OnboardingState(isLoading: true, passkeyPhase: PasskeyPhase.detecting);

    try {
      _log.i('[detecting] Calling listLabels to check for existing passkey');
      final Passkey passkey = _ensurePasskey();
      final Stopwatch sw = Stopwatch()..start();
      final List<String> found = await passkey.listLabels();
      sw.stop();
      _log.i('[detecting] listLabels completed in ${sw.elapsedMilliseconds}ms, found ${found.length} labels');

      if (found.isEmpty) {
        _log.i('[detecting] Passkey exists but no labels on Nostr → authPick (manual input)');
        state = const OnboardingState(
          passkeyPhase: PasskeyPhase.authPick,
          showManualInput: true,
          manualLabel: 'Default',
        );
      } else {
        final List<String> sorted = found.reversed.toList();
        final String defaultLabel = sorted.contains('Default') ? 'Default' : sorted.first;
        _log.i('[detecting] Found labels: $sorted, selecting "$defaultLabel" → authPick');
        state = OnboardingState(
          passkeyPhase: PasskeyPhase.authPick,
          labels: sorted,
          selectedLabel: defaultLabel,
        );
      }
    } on PasskeyError catch (e) {
      if (_isPasskeyCreationNeeded(e)) {
        _log.i('[detecting] No existing credential (${e.runtimeType}) → review (new user flow)');
        state = const OnboardingState(passkeyPhase: PasskeyPhase.review);
      } else {
        _log.e('[detecting] Unexpected PasskeyError → review with error', error: e);
        state = OnboardingState(passkeyPhase: PasskeyPhase.review, passkeyError: e.toString());
      }
    } catch (e, stack) {
      _log.e('[detecting] Unexpected error → review with error', error: e, stackTrace: stack);
      state = OnboardingState(passkeyPhase: PasskeyPhase.review, passkeyError: e.toString());
    }
  }

  /// Phase: creating — user confirmed "I understand", create new passkey.
  Future<void> confirmPasskeyCreation() async {
    _log.i('[review] User confirmed "I understand", starting passkey creation');
    _setPhase(PasskeyPhase.creating, loading: true);
    state = const OnboardingState(
      isLoading: true,
      passkeyPhase: PasskeyPhase.creating,
      isNewUser: true,
    );

    try {
      _log.i('[creating] Calling createPasskey (triggers platform prompt)');
      final PasskeyPrfProvider prfProvider = _ensurePrfProvider();
      final Stopwatch sw = Stopwatch()..start();
      await prfProvider.createPasskey();
      sw.stop();
      _log.i('[creating] Passkey created in ${sw.elapsedMilliseconds}ms → storing "Default"');

      state = const OnboardingState(
        isLoading: true,
        passkeyPhase: PasskeyPhase.storing,
        isNewUser: true,
        selectedLabel: 'Default',
      );
      await _storeLabel('Default');
    } catch (e, stack) {
      _log.e('[creating] Passkey creation failed', error: e, stackTrace: stack);
      state = const OnboardingState(
        passkeyPhase: PasskeyPhase.creating,
        passkeyError: 'Failed to create passkey',
        isNewUser: true,
      );
    }
  }

  /// Phase: storing — save label to Nostr relays.
  Future<void> _storeLabel(String label) async {
    _log.i('[storing] Saving label "$label" to Nostr relays');
    _setPhase(PasskeyPhase.storing, loading: true);
    state = OnboardingState(
      isLoading: true,
      passkeyPhase: PasskeyPhase.storing,
      isNewUser: state.isNewUser,
      labels: state.labels,
      selectedLabel: label,
    );

    try {
      final Passkey passkey = _ensurePasskey();
      final Stopwatch sw = Stopwatch()..start();
      await passkey.storeLabel(label: label);
      sw.stop();
      _log.i('[storing] Label "$label" stored in ${sw.elapsedMilliseconds}ms → connecting');

      final List<String> updatedLabels = state.labels.contains(label)
          ? state.labels
          : <String>[...state.labels, label];

      state = OnboardingState(
        isLoading: true,
        passkeyPhase: PasskeyPhase.connecting,
        isNewUser: state.isNewUser,
        labels: updatedLabels,
        selectedLabel: label,
      );
      await _connectWallet();
    } catch (e, stack) {
      _log.e('[storing] Failed to store label "$label"', error: e, stackTrace: stack);
      state = OnboardingState(
        passkeyPhase: PasskeyPhase.storing,
        passkeyError: 'Failed to save label to Nostr',
        isNewUser: state.isNewUser,
        labels: state.labels,
        selectedLabel: label,
      );
    }
  }

  /// Phase: connecting — derive wallet from passkey PRF.
  Future<WalletMetadata?> _connectWallet() async {
    final String label = state.selectedLabel ?? 'Default';
    _log.i('[connecting] Deriving wallet for label "$label"');
    _setPhase(PasskeyPhase.connecting, loading: true);
    state = OnboardingState(
      isLoading: true,
      passkeyPhase: PasskeyPhase.connecting,
      isNewUser: state.isNewUser,
      labels: state.labels,
      selectedLabel: label,
    );

    try {
      final Passkey passkey = _ensurePasskey();
      final Stopwatch sw = Stopwatch()..start();
      final Wallet wallet = await passkey.getWallet(label: label);
      sw.stop();
      final String walletId = wallet.computeId();
      _log.i('[connecting] Wallet derived in ${sw.elapsedMilliseconds}ms, id: $walletId');

      // Cache seed so sdkProvider can connect without a second passkey prompt
      PasskeySeedCache.put(wallet.seed);

      // Load current wallet list from storage (not cached provider state)
      final WalletStorageService storage = ref.read(walletStorageServiceProvider);
      final List<WalletMetadata> existingWallets = await storage.loadWallets();
      final WalletMetadata? existing =
          existingWallets.where((WalletMetadata w) => w.id == walletId).firstOrNull;

      final WalletMetadata metadata;
      if (existing != null) {
        _log.i('[connecting] Wallet already exists in storage: $walletId');
        metadata = existing;
      } else {
        final Profile profile = generateProfile();
        metadata = WalletMetadata(
          id: walletId,
          profile: profile,
          isVerified: true,
          authMethod: WalletAuthMethod.passkey,
          passkeyLabel: label,
        );

        _log.d('[connecting] Persisting new wallet metadata (no seed stored)');
        await storage.saveWallets(<WalletMetadata>[...existingWallets, metadata]);
      }

      // Reload wallet list from storage, then activate
      ref.invalidate(walletListProvider);
      await ref.read(walletListProvider.future);
      await ref.read(activeWalletProvider.notifier).setActiveWallet(metadata.id);

      _log.i('[connecting] Passkey wallet activated: $walletId (${metadata.displayName})');
      _cleanup();
      state = const OnboardingState();
      return metadata;
    } catch (e, stack) {
      _log.e('[connecting] Wallet derivation failed for label "$label"', error: e, stackTrace: stack);
      state = OnboardingState(
        passkeyPhase: PasskeyPhase.connecting,
        passkeyError: 'Failed to connect',
        isNewUser: state.isNewUser,
        labels: state.labels,
        selectedLabel: label,
      );
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Auth-pick actions
  // ---------------------------------------------------------------------------

  /// Select an existing label and go straight to connecting.
  Future<WalletMetadata?> selectLabel(String label) async {
    _log.i('[authPick] User selected existing label "$label" → connecting');
    state = state.copyWith(selectedLabel: label);
    return _connectWallet();
  }

  /// Select a new (manual) label — store it first, then connect.
  Future<WalletMetadata?> selectNewLabel(String label) async {
    _log.i('[authPick] User created new label "$label" → storing → connecting');
    state = state.copyWith(selectedLabel: label);
    await _storeLabel(label);
    if (state.passkeyPhase == null) {
      return ref.read(activeWalletProvider).value;
    }
    return null;
  }

  /// Update manual label text in auth-pick.
  void setManualLabel(String value) {
    state = state.copyWith(manualLabel: value);
  }

  /// Toggle manual input visibility in auth-pick.
  void setShowManualInput({required bool show}) {
    _log.d('[authPick] Manual input ${show ? "shown" : "hidden"}');
    state = state.copyWith(showManualInput: show);
  }

  /// Set selected label in auth-pick (for UI highlight, before Continue).
  void setSelectedLabel(String? label) {
    _log.d('[authPick] Label tapped: "$label"');
    state = state.copyWith(selectedLabel: label, showManualInput: false, manualLabel: '');
  }

  // ---------------------------------------------------------------------------
  // Retry & navigation
  // ---------------------------------------------------------------------------

  /// Re-run the current failed phase only (does not restart the whole flow).
  Future<WalletMetadata?> retryCurrentPhase() async {
    final PasskeyPhase? phase = state.passkeyPhase;
    final String label = state.selectedLabel ?? 'Default';
    _log.i('Retrying current phase: ${phase?.name ?? "none"} (label: "$label")');

    return switch (phase) {
      PasskeyPhase.creating => () async {
          await confirmPasskeyCreation();
          return state.passkeyPhase == null ? ref.read(activeWalletProvider).value : null;
        }(),
      PasskeyPhase.storing => () async {
          await _storeLabel(label);
          return state.passkeyPhase == null ? ref.read(activeWalletProvider).value : null;
        }(),
      PasskeyPhase.connecting => _connectWallet(),
      _ => null,
    };
  }

  /// Phase-aware "Go Back" from error states.
  void goBackFromError() {
    final PasskeyPhase? phase = state.passkeyPhase;
    final bool isNewUser = state.isNewUser;
    _log.i('Go back from error: phase=${phase?.name}, isNewUser=$isNewUser');

    switch (phase) {
      case PasskeyPhase.creating:
        _log.i('Creating error → cancelling flow');
        cancelPasskeyFlow();
      case PasskeyPhase.storing:
        if (isNewUser) {
          _log.i('Storing error (new user) → cancelling flow');
          cancelPasskeyFlow();
        } else {
          _log.i('Storing error (returning user) → back to authPick');
          state = OnboardingState(
            passkeyPhase: PasskeyPhase.authPick,
            labels: state.labels,
            selectedLabel: state.selectedLabel,
          );
        }
      case PasskeyPhase.connecting:
        if (isNewUser) {
          _log.i('Connecting error (new user) → cancelling flow');
          cancelPasskeyFlow();
        } else {
          _log.i('Connecting error (returning user) → back to authPick');
          state = OnboardingState(
            passkeyPhase: PasskeyPhase.authPick,
            labels: state.labels,
            selectedLabel: state.selectedLabel,
          );
        }
      default:
        _log.i('Default go back → cancelling flow');
        cancelPasskeyFlow();
    }
  }

  /// Exit passkey flow entirely.
  void cancelPasskeyFlow() {
    _log.i('Passkey flow cancelled, cleaning up');
    _cleanup();
    state = const OnboardingState();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _cleanup() {
    _log.d('Cleaning up Passkey and PRF provider instances');
    _passkey = null;
    _prfProvider = null;
  }

  bool _isPasskeyCreationNeeded(PasskeyError error) {
    return switch (error) {
      PasskeyError_PrfError(:final PasskeyPrfError field0) => switch (field0) {
          PasskeyPrfError_UserCancelled() => true,
          PasskeyPrfError_CredentialNotFound() => true,
          _ => false,
        },
      _ => false,
    };
  }
}

final NotifierProvider<OnboardingStateNotifier, OnboardingState> walletOnboardingStateProvider =
    NotifierProvider<OnboardingStateNotifier, OnboardingState>(OnboardingStateNotifier.new);
