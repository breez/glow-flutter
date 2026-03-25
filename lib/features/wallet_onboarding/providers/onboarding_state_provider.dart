import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/logging/app_logger.dart';
import 'package:glow/features/wallet/models/wallet_metadata.dart';
import 'package:glow/features/wallet/providers/wallet_provider.dart';
import 'package:glow/features/wallet_onboarding/models/onboarding_state.dart';
import 'package:logger/logger.dart';

final Logger log = AppLogger.getLogger('OnboardingStateProvider');

/// Network selection state
class OnboardingStateNotifier extends Notifier<OnboardingState> {
  @override
  OnboardingState build() {
    return OnboardingState();
  }

  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  /// Creates a new wallet and sets it as active
  /// Returns (wallet, mnemonic) on success, throws on error
  Future<(WalletMetadata, String)> createWallet() async {
    if (state.isLoading) {
      throw Exception('Wallet creation already in progress');
    }

    setLoading(true);

    try {
      log.i('Creating wallet on mainnet');

      final (WalletMetadata wallet, String mnemonic) = await ref
          .read(walletListProvider.notifier)
          .createWallet();

      // Set as active wallet
      await ref.read(activeWalletProvider.notifier).setActiveWallet(wallet.id);

      log.i('Wallet created and activated: ${wallet.id} (${wallet.displayName})');
      setLoading(false);
      return (wallet, mnemonic);
    } catch (e, stack) {
      log.e('Failed to create wallet', error: e, stackTrace: stack);
      setLoading(false);
      rethrow;
    }
  }

  /// Creates a new passkey wallet and sets it as active
  Future<WalletMetadata> createWalletWithPasskey() async {
    if (state.isLoading) {
      throw Exception('Wallet creation already in progress');
    }

    setLoading(true);

    try {
      log.i('Creating passkey wallet');

      final WalletMetadata wallet = await ref
          .read(walletListProvider.notifier)
          .createWalletWithPasskey();

      await ref.read(activeWalletProvider.notifier).setActiveWallet(wallet.id);

      log.i('Passkey wallet created and activated: ${wallet.id} (${wallet.displayName})');
      setLoading(false);
      return wallet;
    } catch (e, stack) {
      log.e('Failed to create passkey wallet', error: e, stackTrace: stack);
      setLoading(false);
      rethrow;
    }
  }
}

final NotifierProvider<OnboardingStateNotifier, OnboardingState> walletOnboardingStateProvider =
    NotifierProvider<OnboardingStateNotifier, OnboardingState>(OnboardingStateNotifier.new);
