import 'dart:async';

import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:glow/features/payments/models/payment_tracking_state.dart';
import 'package:glow/features/payments/providers/payment_tracker_provider.dart';
import 'package:glow/features/receive/models/receive_method.dart';
import 'package:glow/features/receive/models/receive_state.dart';
import 'package:glow/logging/app_logger.dart';
import 'package:glow/providers/sdk_provider.dart';
import 'package:glow/services/breez_sdk_service.dart';
import 'package:logger/logger.dart';

final Logger _log = AppLogger.getLogger('ReceiveProvider');

class ReceiveNotifier extends Notifier<ReceiveState> {
  @override
  ReceiveState build() {
    // Listen to payment tracker state changes
    ref.listen<PaymentTrackingState>(paymentTrackerProvider, (
      PaymentTrackingState? previous,
      PaymentTrackingState next,
    ) {
      // Early exit if provider is already disposed
      if (!ref.mounted) {
        return;
      }

      if (next is PaymentReceived) {
        // Schedule state update after current build cycle to avoid lifecycle violation
        Future<void>.microtask(() {
          if (!ref.mounted) {
            return;
          }
          state = state.copyWith(
            flowStep: AmountInputFlowStep.paymentReceived,
            amountSats: BigInt.from(next.payment.amount.toInt()),
          );
        });
      }
    }, weak: true);

    // Schedule payment tracking to start after build completes
    Future<void>.microtask(() {
      if (!ref.mounted) {
        return;
      }
      ref.read(paymentTrackerProvider.notifier).startTracking();
    });

    return ReceiveState.initial();
  }

  void changeMethod(ReceiveMethod method) {
    // Stop payment tracking when changing methods
    ref.read(paymentTrackerProvider.notifier).stopTracking();

    state = state.copyWith(
      method: method,
      isLoading: false,
      hasError: false,
      flowStep: AmountInputFlowStep.initial,
    );

    // Restart tracking if switching to Lightning Address
    if (method == ReceiveMethod.lightning) {
      ref.read(paymentTrackerProvider.notifier).startTracking();
    }
  }

  void setLoading() => state = state.copyWith(isLoading: true);

  void setError(String error) => state = state.copyWith(hasError: true, error: error);

  /// Initiate amount input flow
  void startAmountInput() {
    state = state.copyWith(flowStep: AmountInputFlowStep.inputAmount, hasError: false);
  }

  /// Store amount and transition to payment display
  Future<void> generatePaymentRequest(BigInt amount, {String description = 'Payment'}) async {
    state = state.copyWith(
      amountSats: amount,
      flowStep: AmountInputFlowStep.displayPayment,
      isLoading: true,
    );

    try {
      if (state.method == ReceiveMethod.lightning) {
        final ReceivePaymentResponse response = await ref.watch(
          receivePaymentProvider(
            ReceivePaymentRequest(
              paymentMethod: ReceivePaymentMethod.bolt11Invoice(
                description: description,
                amountSats: amount,
              ),
            ),
          ).future,
        );
        state = state.copyWith(receivePaymentResponse: response, isLoading: false);

        // Extract payment hash from the invoice and start tracking
        final String? paymentHash = await _extractPaymentHashFromInvoice(response.paymentRequest);
        ref.read(paymentTrackerProvider.notifier).startTracking(expectedPaymentHash: paymentHash);
      }
      // Bitcoin address handling is done via provider watchers in UI layer
    } catch (err) {
      state = state.copyWith(hasError: true, error: err.toString(), isLoading: false);
    }
  }

  /// Extract payment hash from BOLT11 invoice using SDK
  Future<String?> _extractPaymentHashFromInvoice(String invoice) async {
    try {
      final BreezSdk sdk = await ref.read(sdkProvider.future);
      final InputType inputType = await sdk.parse(input: invoice);

      return inputType.when(
        bolt11Invoice: (Bolt11InvoiceDetails details) {
          _log.d('Extracted payment hash from invoice: ${details.paymentHash}');
          return details.paymentHash;
        },
        bolt12Offer: (_) => null,
        bolt12Invoice: (_) => null,
        lightningAddress: (_) => null,
        lnurlPay: (_) => null,
        silentPaymentAddress: (_) => null,
        lnurlAuth: (_) => null,
        url: (_) => null,
        bip21: (_) => null,
        bolt12InvoiceRequest: (_) => null,
        lnurlWithdraw: (_) => null,
        bitcoinAddress: (_) => null,
        sparkAddress: (_) => null,
        sparkInvoice: (_) => null,
      );
    } catch (e) {
      _log.e('Failed to extract payment hash from invoice: $e');
      return null;
    }
  }

  /// Reset to initial view (close amount input modal/screen)
  void resetAmountFlow() {
    state = state.copyWith(flowStep: AmountInputFlowStep.initial, hasError: false);
  }

  /// Go back one step in the flow
  void goBackInFlow() {
    if (state.flowStep == AmountInputFlowStep.displayPayment) {
      state = state.copyWith(flowStep: AmountInputFlowStep.inputAmount);
    } else if (state.flowStep == AmountInputFlowStep.inputAmount) {
      resetAmountFlow();
    }
  }
}

final NotifierProvider<ReceiveNotifier, ReceiveState> receiveProvider =
    NotifierProvider.autoDispose<ReceiveNotifier, ReceiveState>(ReceiveNotifier.new);

/// Generate payment request
final FutureProviderFamily<ReceivePaymentResponse, ReceivePaymentRequest> receivePaymentProvider =
    FutureProvider.autoDispose.family<ReceivePaymentResponse, ReceivePaymentRequest>((
      Ref ref,
      ReceivePaymentRequest request,
    ) async {
      log.d('receivePaymentProvider called with request: ${request.paymentMethod}');
      final BreezSdk sdk = await ref.watch(sdkProvider.future);
      final BreezSdkService service = ref.read(breezSdkServiceProvider);
      final ReceivePaymentResponse response = await service.receivePayment(sdk, request);
      log.d('Payment request generated: ${response.paymentRequest}');
      return response;
    });
