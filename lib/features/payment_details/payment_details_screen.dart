import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:glow/features/payment_details/models/payment_details_state.dart';
import 'package:glow/features/payment_details/payment_details_layout.dart';
import 'package:glow/features/payment_details/services/payment_formatter.dart';
import 'package:glow/logging/app_logger.dart';
import 'package:glow/providers/sdk_provider.dart';
import 'package:logger/logger.dart';

final Logger log = AppLogger.getLogger('PaymentDetailsScreen');

/// Provider for PaymentFormatter service
final Provider<PaymentFormatter> paymentFormatterProvider = Provider<PaymentFormatter>((Ref ref) {
  return const PaymentFormatter();
});

/// Provider for PaymentDetailsState factory
final Provider<PaymentDetailsStateFactory> paymentDetailsStateFactoryProvider =
    Provider<PaymentDetailsStateFactory>((Ref ref) {
      final PaymentFormatter formatter = ref.watch(paymentFormatterProvider);
      return PaymentDetailsStateFactory(formatter);
    });

/// Provider for PaymentDetailsState based on payment ID
/// Watches paymentsProvider to get real-time updates when payment status changes
final ProviderFamily<PaymentDetailsState?, String> paymentDetailsStateByIdProvider =
    Provider.family<PaymentDetailsState?, String>((Ref ref, String paymentId) {
      final AsyncValue<List<Payment>> paymentsAsync = ref.watch(paymentsProvider);
      final PaymentDetailsStateFactory factory = ref.watch(paymentDetailsStateFactoryProvider);

      return paymentsAsync.when(
        data: (List<Payment> payments) {
          Payment? payment;
          try {
            payment = payments.firstWhere((Payment p) => p.id == paymentId);
            log.d('Found payment $paymentId with status: ${payment.status}');
          } catch (e) {
            log.w('Payment $paymentId not found in list');
            payment = null;
          }

          return payment != null ? factory.createState(payment) : null;
        },
        loading: () {
          log.d('Payments loading for payment $paymentId');
          return null;
        },
        error: (_, _) {
          log.e('Error loading payments for payment $paymentId');
          return null;
        },
      );
    });

/// Shows the payment details bottom sheet for a given payment.
void showPaymentDetails(BuildContext context, WidgetRef ref, Payment payment) {
  final PaymentDetailsState? state = ref.read(paymentDetailsStateByIdProvider(payment.id));
  if (state == null) {
    return;
  }

  showPaymentDetailsSheet(context, state);
}
