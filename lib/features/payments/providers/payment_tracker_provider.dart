import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/features/payments/models/payment_tracking_state.dart';
import 'package:glow/logging/app_logger.dart';
import 'package:glow/providers/sdk_provider.dart';
import 'package:logger/logger.dart';

final Logger _log = AppLogger.getLogger('PaymentTracker');

/// Provider that tracks incoming payment events
///
/// Supports two tracking modes:
/// 1. Lightning Invoice: Tracks a specific payment by payment hash
/// 2. Lightning Address: Tracks any incoming payment
final NotifierProvider<PaymentTrackerNotifier, PaymentTrackingState> paymentTrackerProvider =
    NotifierProvider<PaymentTrackerNotifier, PaymentTrackingState>(PaymentTrackerNotifier.new);

/// Notifier for tracking incoming payment events
class PaymentTrackerNotifier extends Notifier<PaymentTrackingState> {
  @override
  PaymentTrackingState build() {
    _log.d('PaymentTrackerNotifier initialized');

    // Listen to SDK events for payment updates
    ref.listen<AsyncValue<SdkEvent>>(sdkEventsStreamProvider, (
      AsyncValue<SdkEvent>? previous,
      AsyncValue<SdkEvent> next,
    ) {
      next.whenData((SdkEvent event) {
        event.when(
          synced: () {},
          paymentSucceeded: (Payment payment) {
            _handlePaymentEvent(payment);
          },
          paymentPending: (Payment payment) {
            _handlePaymentEvent(payment);
          },
          paymentFailed: (Payment payment) {
            _log.e('Payment failed: ${payment.id}');
          },
          unclaimedDeposits: (List<DepositInfo> unclaimedDeposits) {},
          claimedDeposits: (List<DepositInfo> claimedDeposits) {},
          optimization: (OptimizationEvent optimizationEvent) {},
          lightningAddressChanged: (LightningAddressInfo? lightningAddress) {},
          newDeposits: (List<DepositInfo> newDeposits) {},
        );
      });
    }, weak: true);

    return const NotTrackingPayment();
  }

  /// Handle payment event (pending or succeeded)
  void _handlePaymentEvent(Payment payment) {
    // Only process incoming payments
    if (payment.paymentType != PaymentType.receive) {
      return;
    }

    // Only process if we're actively tracking
    if (state is! TrackingPayment) {
      return;
    }

    final TrackingPayment trackingState = state as TrackingPayment;

    // For Lightning Invoice: match by payment hash
    if (trackingState.expectedPaymentHash != null) {
      final String? paymentHash = _extractPaymentHash(payment);

      if (paymentHash != trackingState.expectedPaymentHash) {
        _log.d('Payment hash mismatch, ignoring payment ${payment.id}');
        return;
      }

      _log.i('Matched invoice payment: ${payment.id}, amount: ${payment.amount} sats');
    } else {
      // For Lightning Address: accept any incoming payment
      _log.i('Received Lightning Address payment: ${payment.id}, amount: ${payment.amount} sats');
    }

    state = PaymentReceived(payment: payment);
  }

  /// Extract payment hash from payment details
  String? _extractPaymentHash(Payment payment) {
    final PaymentDetails? details = payment.details;
    if (details is PaymentDetails_Lightning) {
      return details.htlcDetails.paymentHash;
    }
    return null;
  }

  /// Start tracking payments
  ///
  /// - For Lightning Invoice: provide expectedPaymentHash to match specific payment
  /// - For Lightning Address: pass null to accept any incoming payment
  void startTracking({String? expectedPaymentHash}) {
    _log.d(
      'Starting payment tracking${expectedPaymentHash != null ? ' for hash: $expectedPaymentHash' : ' (any payment)'}',
    );
    state = TrackingPayment(expectedPaymentHash: expectedPaymentHash);
  }

  /// Stop tracking payments
  void stopTracking() {
    _log.d('Stopping payment tracking');
    state = const NotTrackingPayment();
  }
}
