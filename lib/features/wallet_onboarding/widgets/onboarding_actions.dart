import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:glow/features/wallet_onboarding/models/onboarding_state.dart';
import 'package:glow/logging/app_logger.dart';
import 'package:logger/logger.dart';

final Logger log = AppLogger.getLogger('SetupActions');
final AutoSizeGroup _autoSizeGroup = AutoSizeGroup();

/// Onboarding actions matching glow-web's UX:
/// - Default view: "Use Passkey" (primary) + "Use Recovery Phrase Instead" (text link)
/// - Mnemonic view: "LET'S GLOW!" (primary) + "RESTORE" (outlined) + "Use Passkey Instead" (text link)
class OnboardingActions extends StatefulWidget {
  final OnboardingState state;
  final bool isPrfAvailable;
  final VoidCallback onRegister;
  final VoidCallback onPasskey;
  final VoidCallback onRestore;

  const OnboardingActions({
    required this.state,
    required this.isPrfAvailable,
    required this.onRegister,
    required this.onPasskey,
    required this.onRestore,
    super.key,
  });

  @override
  State<OnboardingActions> createState() => _OnboardingActionsState();
}

class _OnboardingActionsState extends State<OnboardingActions> {
  /// null = use default based on isPrfAvailable
  bool? _forceShowMnemonicFlow;

  bool get _showMnemonicFlow => _forceShowMnemonicFlow ?? !widget.isPrfAvailable;

  @override
  Widget build(BuildContext context) {
    if (_showMnemonicFlow) {
      return _MnemonicActions(
        state: widget.state,
        onRegister: widget.onRegister,
        onRestore: widget.onRestore,
        // Only show "Use Passkey Instead" if the platform supports it
        onSwitchToPasskey: widget.isPrfAvailable
            ? () => setState(() => _forceShowMnemonicFlow = false)
            : null,
      );
    }

    return _PasskeyActions(
      state: widget.state,
      onPasskey: widget.onPasskey,
      onSwitchToMnemonic: () => setState(() => _forceShowMnemonicFlow = true),
    );
  }
}

/// Default view: passkey as the primary action.
class _PasskeyActions extends StatelessWidget {
  final OnboardingState state;
  final VoidCallback onPasskey;
  final VoidCallback onSwitchToMnemonic;

  const _PasskeyActions({
    required this.state,
    required this.onPasskey,
    required this.onSwitchToMnemonic,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    final Size screenSize = MediaQuery.of(context).size;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Primary: Use Passkey
        SizedBox(
          height: 48.0,
          width: min(screenSize.width * 0.5, 168),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: themeData.colorScheme.secondary,
              elevation: 0.0,
              disabledBackgroundColor: themeData.disabledColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
            ),
            onPressed: state.isLoading ? null : onPasskey,
            child: state.isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator())
                : Semantics(
                    button: true,
                    label: 'Use Passkey',
                    child: AutoSizeText(
                      'USE PASSKEY',
                      style: themeData.textTheme.labelLarge?.copyWith(color: themeData.primaryColor),
                      stepGranularity: 0.1,
                      group: _autoSizeGroup,
                      maxLines: 1,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        // Secondary: text link to switch to mnemonic flow
        TextButton(
          onPressed: state.isLoading ? null : onSwitchToMnemonic,
          child: Text(
            'Use Recovery Phrase Instead',
            style: themeData.textTheme.bodySmall?.copyWith(
              color: Colors.white70,
              decoration: TextDecoration.underline,
              decorationColor: Colors.white70,
            ),
          ),
        ),
      ],
    );
  }
}

/// Fallback view: mnemonic create/restore actions.
class _MnemonicActions extends StatelessWidget {
  final OnboardingState state;
  final VoidCallback onRegister;
  final VoidCallback onRestore;
  final VoidCallback? onSwitchToPasskey;

  const _MnemonicActions({
    required this.state,
    required this.onRegister,
    required this.onRestore,
    this.onSwitchToPasskey,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    final Size screenSize = MediaQuery.of(context).size;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Primary: Create new wallet
        SizedBox(
          height: 48.0,
          width: min(screenSize.width * 0.5, 168),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: themeData.colorScheme.secondary,
              elevation: 0.0,
              disabledBackgroundColor: themeData.disabledColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
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
                      group: _autoSizeGroup,
                      maxLines: 1,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        // Secondary: Restore from backup
        SizedBox(
          height: 48.0,
          width: min(screenSize.width * 0.5, 168),
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white),
              elevation: 0.0,
            ),
            onPressed: state.isLoading ? null : onRestore,
            child: Semantics(
              button: true,
              label: 'Restore from backup',
              child: AutoSizeText(
                'RESTORE',
                style: themeData.textTheme.labelLarge?.copyWith(color: Colors.white),
                stepGranularity: 0.1,
                group: _autoSizeGroup,
                maxLines: 1,
              ),
            ),
          ),
        ),
        if (onSwitchToPasskey != null) ...<Widget>[
          const SizedBox(height: 16),
          // Tertiary: text link to switch back to passkey flow
          TextButton(
            onPressed: state.isLoading ? null : onSwitchToPasskey,
            child: Text(
              'Use Passkey Instead',
              style: themeData.textTheme.bodySmall?.copyWith(
                color: Colors.white70,
                decoration: TextDecoration.underline,
                decorationColor: Colors.white70,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
