// ignore_for_file: always_specify_types

import 'package:flutter/material.dart';
import 'package:glow/features/settings/models/pin_setup_state.dart';
import 'package:glow/features/settings/widgets/pin_entry_widget.dart';

/// Pure presentation widget for PIN setup/lock screen
/// Works for both PIN setup and PIN lock flows
class PinSetupLayout extends StatelessWidget {
  final PinSetupState state;
  final ValueChanged<String> onPinEntered;
  final VoidCallback onInputStarted;
  final String? label; // Optional custom label, defaults based on state

  const PinSetupLayout({
    required this.state,
    required this.onPinEntered,
    required this.onInputStarted,
    this.label,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const Expanded(flex: 20, child: _PinLogoWidget()),
        Expanded(
          flex: 80,
          child: PinEntryWidget(
            key: const ValueKey<String>('pinEntry'),
            onPinComplete: onPinEntered,
            onInputStarted: onInputStarted,
            label: label ?? _getDefaultLabel(),
            errorMessage: state is PinSetupError ? (state as PinSetupError).message : null,
          ),
        ),
      ],
    );
  }

  String _getDefaultLabel() {
    if (state is PinSetupAwaitingConfirmation) {
      return 'Re-enter your new PIN';
    }
    return 'Enter your new PIN';
  }
}

class _PinLogoWidget extends StatelessWidget {
  const _PinLogoWidget();

  @override
  Widget build(BuildContext context) {
    final logoSize = MediaQuery.of(context).size.width / 3;

    return Image.asset('assets/icon/glow_transparent.png', width: logoSize, height: logoSize);
  }
}
