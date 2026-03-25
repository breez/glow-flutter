import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.homeScreen, (_) => false);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to register wallet: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void onPasskey(BuildContext context, WidgetRef ref) async {
    final OnboardingState state = ref.read(walletOnboardingStateProvider);
    if (state.isLoading) {
      return;
    }

    try {
      await ref.read(walletOnboardingStateProvider.notifier).createWalletWithPasskey();

      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.homeScreen, (_) => false);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Passkey wallet creation failed: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
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
    );
  }
}
