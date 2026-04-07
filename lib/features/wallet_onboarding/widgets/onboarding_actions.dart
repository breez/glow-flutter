import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:glow/features/wallet_onboarding/models/onboarding_state.dart';
import 'package:glow/logging/app_logger.dart';
import 'package:logger/logger.dart';

final Logger log = AppLogger.getLogger('SetupActions');
final AutoSizeGroup _autoSizeGroup = AutoSizeGroup();

class OnboardingActions extends StatelessWidget {
  final OnboardingState state;
  final VoidCallback onRegister;
  final VoidCallback onRestore;

  const OnboardingActions({
    required this.state,
    required this.onRegister,
    required this.onRestore,
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _RegisterButton(autoSizeGroup: _autoSizeGroup, onRegister: onRegister, state: state),
        const SizedBox(height: 24),
        _RestoreButton(autoSizeGroup: _autoSizeGroup, onRestore: onRestore),
      ],
    );
  }
}

class _RegisterButton extends StatelessWidget {
  final OnboardingState state;
  final AutoSizeGroup autoSizeGroup;
  final VoidCallback onRegister;

  const _RegisterButton({
    required this.state,
    required this.autoSizeGroup,
    required this.onRegister,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    final Size screenSize = MediaQuery.of(context).size;

    return SizedBox(
      height: 48.0,
      width: min(screenSize.width * 0.5, 168),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: themeData.colorScheme.secondary,
          disabledBackgroundColor: themeData.disabledColor,
        ),
        onPressed: state.isLoading ? null : onRegister,
        child: state.isLoading
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator())
            : Semantics(
                button: true,
                label: "LET'S GLOW!",
                child: AutoSizeText(
                  "LET'S GLOW!",
                  style: themeData.textTheme.labelLarge?.copyWith(color: themeData.primaryColor),
                  stepGranularity: 0.1,
                  group: autoSizeGroup,
                  maxLines: 1,
                ),
              ),
      ),
    );
  }
}

class _RestoreButton extends StatelessWidget {
  final AutoSizeGroup autoSizeGroup;
  final VoidCallback onRestore;

  const _RestoreButton({required this.autoSizeGroup, required this.onRestore});

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    final Size screenSize = MediaQuery.of(context).size;

    return SizedBox(
      height: 48.0,
      width: min(screenSize.width * 0.5, 168),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.white),
          elevation: 0.0,
        ),
        onPressed: onRestore,
        child: Semantics(
          button: true,
          label: 'Restore using mnemonics',
          child: AutoSizeText(
            'RESTORE',
            style: themeData.textTheme.labelLarge?.copyWith(color: Colors.white),
            stepGranularity: 0.1,
            group: autoSizeGroup,
            maxLines: 1,
          ),
        ),
      ),
    );
  }
}
