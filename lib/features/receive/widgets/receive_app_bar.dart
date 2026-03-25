import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:glow/features/receive/models/receive_method.dart';
import 'package:glow/widgets/back_button.dart';
import 'package:glow/features/receive/models/receive_state.dart';

class ReceiveAppBar extends StatelessWidget implements PreferredSizeWidget {
  final ReceiveState state;
  final VoidCallback? onRequest;
  final ValueChanged<ReceiveMethod> onChangeMethod;
  final VoidCallback goBackInFlow;

  const ReceiveAppBar({
    required this.state,
    required this.onRequest,
    required this.onChangeMethod,
    required this.goBackInFlow,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final bool showAppBarControls =
        (!state.isLoading && !state.hasError) || state.flowStep != AmountInputFlowStep.initial;

    return AppBar(
      leading: showAppBarControls
          ? GlowBackButton(onPressed: goBackInFlow)
          : const GlowBackButton(),
      centerTitle: showAppBarControls,
      title: showAppBarControls
          ? ReceiveMethodDropdown(selectedMethod: state.method, onChanged: onChangeMethod)
          : const Text('Receive'),
      actions: showAppBarControls && state.method != ReceiveMethod.bitcoin
          ? <Widget>[StaticAmountRequestIcon(showAmountInput: onRequest)]
          : null,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Dropdown widget for selecting receive method
class ReceiveMethodDropdown extends StatelessWidget {
  final ReceiveMethod selectedMethod;
  final ValueChanged<ReceiveMethod> onChanged;

  const ReceiveMethodDropdown({required this.selectedMethod, required this.onChanged, super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Size screenSize = MediaQuery.of(context).size;

    return PopupMenuButton<ReceiveMethod>(
      initialValue: selectedMethod,
      onSelected: (ReceiveMethod? method) {
        if (method != null) {
          onChanged(method);
        }
      },
      color: theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      constraints: const BoxConstraints(minHeight: 48, maxWidth: 180),
      elevation: 12.0,

      position: PopupMenuPosition.under,
      offset: selectedMethod == ReceiveMethod.lightning ? const Offset(-20, 0) : const Offset(0, 0),
      itemBuilder: (BuildContext context) => ReceiveMethod.values
          .where((ReceiveMethod method) => method != selectedMethod)
          .map(
            (ReceiveMethod method) => PopupMenuItem<ReceiveMethod>(
              value: method,
              child: Container(
                width: min(screenSize.width * 0.5, 168),
                constraints: const BoxConstraints(minHeight: 48, maxWidth: 180),
                alignment: Alignment.center,
                child: AutoSizeText(
                  method.label.toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 18.0, letterSpacing: 0.22),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  stepGranularity: 0.1,
                ),
              ),
            ),
          )
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(selectedMethod.label.toUpperCase(), style: theme.appBarTheme.titleTextStyle),
            const SizedBox(width: 4.0),
            Icon(Icons.arrow_drop_down, color: theme.colorScheme.secondary),
          ],
        ),
      ),
    );
  }
}

/// Icon button widget for requesting a specific amount payment
class StaticAmountRequestIcon extends StatelessWidget {
  final VoidCallback? showAmountInput;

  const StaticAmountRequestIcon({required this.showAmountInput, super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      alignment: Alignment.center,
      icon: const Icon(Icons.edit_note_rounded, size: 24.0),
      tooltip: 'Specify amount for payment request',
      onPressed: showAmountInput,
    );
  }
}
