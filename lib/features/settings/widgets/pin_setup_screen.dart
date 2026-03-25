import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/widgets/back_button.dart';
import 'package:glow/features/settings/models/pin_setup_state.dart';
import 'package:glow/features/settings/providers/pin_provider.dart';
import 'package:glow/features/settings/providers/pin_setup_notifier.dart';
import 'package:glow/features/settings/widgets/pin_setup_layout.dart';
import 'package:glow/logging/app_logger.dart';
import 'package:logger/logger.dart';

final Logger log = AppLogger.getLogger('PinSetupScreen');

/// PIN setup screen - creates new PIN
/// Uses PinSetupState and PinEntryWidget, configured in setup mode
class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key});

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  @override
  void initState() {
    super.initState();
    // Reset and configure notifier for setup mode
    Future<void>.microtask(() {
      ref.read(pinSetupNotifierProvider.notifier)
        ..initializeMode(PinMode.setup)
        ..reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final PinSetupState state = ref.watch(pinSetupNotifierProvider);
    log.d('PinSetupScreen building with state: ${state.runtimeType}');

    // Navigate back on success
    ref.listen<PinSetupState>(pinSetupNotifierProvider, (
      PinSetupState? previous,
      PinSetupState current,
    ) {
      log.d('State changed to ${current.runtimeType}');
      if (current is PinSetupSuccess) {
        // Refresh PIN status before popping
        // ignore: unawaited_futures, unused_result
        ref.refresh(pinStatusProvider);
        // Pop back to previous screen
        Navigator.pop(context);
      }
    });

    return Scaffold(
      appBar: AppBar(leading: const GlowBackButton()),
      body: SafeArea(
        child: PinSetupLayout(
          state: state,
          onPinEntered: (String pin) =>
              ref.read(pinSetupNotifierProvider.notifier).onPinEntered(pin),
          onInputStarted: () => ref.read(pinSetupNotifierProvider.notifier).clearError(),
        ),
      ),
    );
  }
}
