import 'package:flutter/material.dart';
import 'package:glow/features/wallet_onboarding/models/onboarding_state.dart';
import 'package:glow/features/wallet_onboarding/widgets/animated_logo.dart';
import 'package:glow/features/wallet_onboarding/widgets/breez_sdk_footer.dart';
import 'package:glow/features/wallet_onboarding/widgets/onboarding_actions.dart';

class OnboardingLayout extends StatelessWidget {
  final OnboardingState state;
  final bool isPrfAvailable;
  final VoidCallback onRegister;
  final VoidCallback onPasskey;
  final VoidCallback onRestore;

  const OnboardingLayout({
    required this.state,
    required this.isPrfAvailable,
    required this.onRegister,
    required this.onPasskey,
    required this.onRestore,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            children: <Widget>[
              const Spacer(flex: 3),
              const AnimatedLogo(),
              const Spacer(flex: 3),
              OnboardingActions(state: state, isPrfAvailable: isPrfAvailable, onRegister: onRegister, onPasskey: onPasskey, onRestore: onRestore),
              const Spacer(),
              const BreezSdkFooter(),
            ],
          ),
        ),
      ),
    );
  }
}
