import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/widgets/back_button.dart';
import 'package:glow/features/send_payment/models/bip21_state.dart';
import 'package:glow/features/send_payment/providers/bip21_provider.dart';
import 'package:glow/features/send_payment/screens/bip21_layout.dart';
import 'package:glow/logging/app_logger.dart';
import 'package:glow/routing/input_handlers.dart';
import 'package:logger/logger.dart';

final Logger _log = AppLogger.getLogger('Bip21Screen');

/// Screen for BIP21 unified payment (wiring layer)
///
/// This widget handles the business logic and state management,
/// delegating rendering to Bip21Layout.
class Bip21Screen extends ConsumerWidget {
  final Bip21Details bip21Details;

  const Bip21Screen({required this.bip21Details, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Bip21State state = ref.watch(bip21Provider(bip21Details));
    final InputHandler inputHandler = ref.read(inputHandlerProvider);

    _log.i(
      'Building BIP21 screen - state: ${state.runtimeType}, methods: ${bip21Details.paymentMethods.map((InputType e) => e.runtimeType).toList()}',
    );

    // Handle method selection changes
    ref.listen<Bip21State>(bip21Provider(bip21Details), (Bip21State? previous, Bip21State next) {
      _log.d('State changed from ${previous.runtimeType} to ${next.runtimeType}');

      if (next is Bip21MethodSelected) {
        _log.i('Method selected: ${next.selectedMethod.runtimeType}');
        inputHandler.navigateToPaymentScreen(context, next.selectedMethod, replace: true);
      }
    });

    // Auto-navigate if there's only one payment method (check on every build)
    if (state is Bip21Initial && state.paymentMethods.length == 1) {
      _log.i(
        'Single payment method detected, auto-navigating to: ${state.paymentMethods.first.runtimeType}',
      );

      // Schedule navigation for after this frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          inputHandler.navigateToPaymentScreen(context, state.paymentMethods.first, replace: true);
        } else {
          _log.w('Context not mounted, cannot navigate');
        }
      });

      // Show loading while navigating
      _log.d('Showing processing screen for single payment method');
      return Scaffold(
        appBar: AppBar(leading: const GlowBackButton(), title: const Text('Send Payment')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Bip21Layout(
      bip21Details: bip21Details,
      state: state,
      onSelectMethod: (InputType method) {
        ref.read(bip21Provider(bip21Details).notifier).selectMethod(method);
      },
      onCancel: () {
        Navigator.of(context).pop();
      },
    );
  }
}
