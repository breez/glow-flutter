import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/features/deposits/providers/refund_provider.dart';
import 'package:glow/features/deposits/refund/refund_layout.dart';
import 'package:glow/features/deposits/refund/refund_state.dart';
import 'package:glow/logging/app_logger.dart';
import 'package:logger/logger.dart';

final Logger _log = AppLogger.getLogger('RefundScreen');

/// Screen for deposit refund (wiring)
///
/// This screen handles the business logic and state management
/// for deposit refunds. The actual UI is in RefundLayout.
class RefundScreen extends ConsumerWidget {
  final DepositInfo deposit;

  const RefundScreen({required this.deposit, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final RefundState state = ref.watch(refundProvider(deposit));

    // Listen for success state and navigate home
    ref.listen<RefundState>(refundProvider(deposit), (RefundState? previous, RefundState next) {
      if (next is RefundSuccess) {
        _log.i('Refund successful, navigating home');
        // Wait a moment to show success animation
        Future<void>.delayed(const Duration(seconds: 2), () {
          if (context.mounted) {
            Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
          }
        });
      }
    });

    return RefundLayout(
      state: state,
      onPrepareRefund: (String address) {
        ref.read(refundProvider(deposit).notifier).prepareRefund(address);
      },
      onSelectFeeSpeed: (RefundFeeSpeed speed) {
        ref.read(refundProvider(deposit).notifier).selectFeeSpeed(speed);
      },
      onSendRefund: () => ref.read(refundProvider(deposit).notifier).sendRefund(),
      onRetry: (String address) =>
          ref.read(refundProvider(deposit).notifier).prepareRefund(address),
      onCancel: () => Navigator.of(context).pop(),
    );
  }
}
