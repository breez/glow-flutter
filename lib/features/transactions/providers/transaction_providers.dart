import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/core/services/transaction_formatter.dart';
import 'package:glow/features/transaction_filter/models/transaction_filter_state.dart';
import 'package:glow/features/transaction_filter/providers/transaction_filter_provider.dart';
import 'package:glow/features/transactions/models/transaction_list_state.dart';
import 'package:glow/features/profile/models/profile.dart';
import 'package:glow/features/wallet/models/wallet_metadata.dart';
import 'package:glow/features/wallet/providers/wallet_provider.dart';
import 'package:glow/providers/sdk_provider.dart';

/// Provider for filtered payments
final Provider<AsyncValue<List<Payment>>> filteredPaymentsProvider =
    Provider<AsyncValue<List<Payment>>>((Ref ref) {
      final AsyncValue<List<Payment>> paymentsAsync = ref.watch(paymentsProvider);
      final TransactionFilterState filterState = ref.watch(transactionFilterProvider);

      return paymentsAsync.whenData((List<Payment> payments) {
        return payments.where((Payment payment) {
          // Convert payment timestamp to DateTime for comparison
          final DateTime paymentDate = DateTime.fromMillisecondsSinceEpoch(
            payment.timestamp.toInt() * 1000,
          );

          final bool afterStartDate =
              filterState.startDate == null || !paymentDate.isBefore(filterState.startDate!);
          final bool beforeEndDate =
              filterState.endDate == null || !paymentDate.isAfter(filterState.endDate!);
          final bool ofPaymentType =
              filterState.paymentTypes.isEmpty ||
              filterState.paymentTypes.contains(payment.paymentType);

          return afterStartDate && beforeEndDate && ofPaymentType;
        }).toList();
      });
    });

/// Provider for TransactionListState
/// Converts raw payments from sdk_provider to formatted TransactionListState
final Provider<TransactionListState> transactionListStateProvider = Provider<TransactionListState>((
  Ref ref,
) {
  final TransactionFormatter formatter = const TransactionFormatter();
  final AsyncValue<List<Payment>> filteredPaymentsAsync = ref.watch(filteredPaymentsProvider);
  final AsyncValue<WalletMetadata?> activeWallet = ref.watch(activeWalletProvider);
  final TransactionFilterState filterState = ref.watch(transactionFilterProvider);

  final AsyncValue<bool> shouldWaitAsync = ref.watch(shouldWaitForInitialSyncProvider);
  final bool hasSynced = ref.watch(hasSyncedProvider);

  return filteredPaymentsAsync.when(
    data: (List<Payment> filteredPayments) {
      final bool hasActiveFilter =
          filterState.paymentTypes.isNotEmpty ||
          filterState.startDate != null ||
          filterState.endDate != null;

      final bool shouldWait = shouldWaitAsync.hasValue ? shouldWaitAsync.value! : false;
      final Profile? profile = activeWallet.value?.profile;
      final bool effectiveHasSynced = hasActiveFilter ? true : (shouldWait ? hasSynced : true);

      // If no payments, return empty state
      if (filteredPayments.isEmpty) {
        return TransactionListState.empty(hasActiveFilter: hasActiveFilter);
      }

      // Map payments to transaction items
      final List<TransactionItemState> transactionItems = filteredPayments.map((Payment payment) {
        return _createTransactionItemState(payment, formatter, profile: profile);
      }).toList();

      return TransactionListState.loaded(
        transactions: transactionItems,
        hasSynced: effectiveHasSynced,
        hasActiveFilter: hasActiveFilter,
      );
    },
    loading: () => TransactionListState.loading(),
    error: (Object error, _) => TransactionListState.error(error.toString()),
  );
});

/// Creates TransactionItemState from Payment
TransactionItemState _createTransactionItemState(
  Payment payment,
  TransactionFormatter formatter, {
  Profile? profile,
}) {
  final bool isReceive = payment.paymentType == PaymentType.receive;
  final String description = formatter.getShortDescription(payment.details);

  // Show profile for incoming payments without custom description
  final bool hasCustomDescription = _hasCustomDescription(payment.details);

  return TransactionItemState(
    payment: payment,
    formattedAmount: formatter.formatSats(payment.amount),
    formattedAmountWithSign: formatter.formatAmountWithSign(payment.amount, payment.paymentType),
    formattedTime: formatter.formatRelativeTime(payment.timestamp),
    formattedStatus: formatter.formatStatus(payment.status),
    formattedMethod: formatter.formatMethod(payment.method),
    description: description,
    isReceive: isReceive,
    profile: (isReceive && !hasCustomDescription) ? profile : null,
  );
}

/// Checks if payment has a custom user-provided description
bool _hasCustomDescription(PaymentDetails? details) {
  if (details == null) {
    return false;
  }

  return switch (details) {
    PaymentDetails_Lightning(:final String? description) =>
      description != null && description.isNotEmpty && description != 'Payment',
    PaymentDetails_Token() => true, // Token name is meaningful
    PaymentDetails_Deposit() => false, // Generic deposit
    PaymentDetails_Withdraw() => false, // Generic withdrawal
    PaymentDetails_Spark() => false, // Generic spark payment
  };
}
