import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/features/wallet/models/wallet_metadata.dart';
import 'package:glow/features/wallet_onboarding/models/onboarding_state.dart';
import 'package:glow/features/wallet_onboarding/onboarding_layout.dart';
import 'package:glow/features/wallet_onboarding/providers/onboarding_state_provider.dart';
import 'package:glow/routing/app_routes.dart';

/// Whether platform passkey PRF is available on this device.
final FutureProvider<bool> _isPrfAvailableProvider = FutureProvider<bool>((Ref ref) async {
  final PasskeyPrfProvider provider = PasskeyPrfProvider();
  return provider.isPrfAvailable();
});

class WalletSetupScreen extends ConsumerWidget {
  const WalletSetupScreen({super.key});

  void _goHome(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.homeScreen, (_) => false);
  }

  void onRestore(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.walletImport);
  }

  void onRegister(BuildContext context, WidgetRef ref) async {
    final OnboardingState state = ref.read(walletOnboardingStateProvider);
    if (state.isLoading) {
      return;
    }

    try {
      await ref.read(walletOnboardingStateProvider.notifier).createWallet();
      if (context.mounted) {
        _goHome(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to register wallet: $e'), duration: const Duration(seconds: 3)),
        );
      }
    }
  }

  /// Kick off the passkey flow: detecting → review/auth-pick → ...
  void onPasskey(BuildContext context, WidgetRef ref) async {
    await ref.read(walletOnboardingStateProvider.notifier).startPasskeyFlow();
    // If detection found an existing passkey that worked, flow is cleared
    // and we should be at home — but startPasskeyFlow doesn't auto-connect,
    // it goes to auth-pick. Navigation happens from selectLabel/selectNewLabel.
  }

  /// User confirmed "I understand" on the review screen.
  void onPasskeyConfirm(BuildContext context, WidgetRef ref) async {
    await ref.read(walletOnboardingStateProvider.notifier).confirmPasskeyCreation();
    if (context.mounted && ref.read(walletOnboardingStateProvider).passkeyPhase == null) {
      _goHome(context);
    }
  }

  /// Exit passkey flow entirely.
  void onPasskeyBack(WidgetRef ref) {
    ref.read(walletOnboardingStateProvider.notifier).cancelPasskeyFlow();
  }

  /// Retry the current failed phase.
  void onPasskeyRetry(BuildContext context, WidgetRef ref) async {
    final WalletMetadata? wallet =
        await ref.read(walletOnboardingStateProvider.notifier).retryCurrentPhase();
    if (wallet != null && context.mounted) {
      _goHome(context);
    }
  }

  /// Phase-aware go-back from error.
  void onPasskeyGoBackFromError(WidgetRef ref) {
    ref.read(walletOnboardingStateProvider.notifier).goBackFromError();
  }

  /// Select an existing label → connect.
  void onSelectLabel(BuildContext context, WidgetRef ref, String label) async {
    final WalletMetadata? wallet =
        await ref.read(walletOnboardingStateProvider.notifier).selectLabel(label);
    if (wallet != null && context.mounted) {
      _goHome(context);
    }
  }

  /// Select a new (manual) label → store → connect.
  void onSelectNewLabel(BuildContext context, WidgetRef ref, String label) async {
    final WalletMetadata? wallet =
        await ref.read(walletOnboardingStateProvider.notifier).selectNewLabel(label);
    if (wallet != null && context.mounted) {
      _goHome(context);
    }
  }

  void onManualLabelChanged(WidgetRef ref, String value) {
    ref.read(walletOnboardingStateProvider.notifier).setManualLabel(value);
  }

  void onShowManualInput(WidgetRef ref) {
    ref.read(walletOnboardingStateProvider.notifier).setShowManualInput(show: true);
  }

  void onLabelTapped(WidgetRef ref, String? label) {
    ref.read(walletOnboardingStateProvider.notifier).setSelectedLabel(label);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final OnboardingState state = ref.watch(walletOnboardingStateProvider);
    final bool isPrfAvailable = ref.watch(_isPrfAvailableProvider).value ?? false;
    return OnboardingLayout(
      state: state,
      isPrfAvailable: isPrfAvailable,
      onRegister: () => onRegister(context, ref),
      onPasskey: () => onPasskey(context, ref),
      onRestore: () => onRestore(context),
      onPasskeyConfirm: () => onPasskeyConfirm(context, ref),
      onPasskeyBack: () => onPasskeyBack(ref),
      onPasskeyRetry: () => onPasskeyRetry(context, ref),
      onPasskeyGoBackFromError: () => onPasskeyGoBackFromError(ref),
      onSelectLabel: (String label) => onSelectLabel(context, ref, label),
      onSelectNewLabel: (String label) => onSelectNewLabel(context, ref, label),
      onManualLabelChanged: (String value) => onManualLabelChanged(ref, value),
      onShowManualInput: () => onShowManualInput(ref),
      onLabelTapped: (String? label) => onLabelTapped(ref, label),
    );
  }
}
