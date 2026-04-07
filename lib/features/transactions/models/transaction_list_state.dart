import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:equatable/equatable.dart';
import 'package:glow/features/deposits/models/pending_deposit_payment.dart';
import 'package:glow/features/profile/models/profile.dart';

/// State representation for a single transaction item
/// Can represent either a Payment or a PendingDepositPayment
class TransactionItemState extends Equatable {
  const TransactionItemState({
    required this.formattedAmount,
    required this.formattedAmountWithSign,
    required this.formattedTime,
    required this.formattedStatus,
    required this.formattedMethod,
    required this.description,
    required this.isReceive,
    this.payment,
    this.pendingDeposit,
    this.profile,
  }) : assert(
         payment != null || pendingDeposit != null,
         'Either payment or pendingDeposit must be provided',
       );

  final Payment? payment;
  final PendingDepositPayment? pendingDeposit;
  final String formattedAmount;
  final String formattedAmountWithSign;
  final String formattedTime;
  final String formattedStatus;
  final String formattedMethod;
  final String description;
  final bool isReceive;
  final Profile? profile;

  /// Check if this is a pending deposit transaction
  bool get isPendingDeposit => pendingDeposit != null;

  /// Get unique identifier (payment ID or deposit ID)
  String get id => payment?.id ?? pendingDeposit!.id;

  @override
  List<Object?> get props => <Object?>[
    payment?.id,
    pendingDeposit?.id,
    formattedAmount,
    formattedAmountWithSign,
    formattedTime,
    formattedStatus,
    formattedMethod,
    description,
    isReceive,
    profile,
  ];
}

/// State representation for transaction list
class TransactionListState extends Equatable {
  const TransactionListState({
    required this.transactions,
    required this.hasSynced,
    this.error,
    this.hasActiveFilter = false,
  });

  final List<TransactionItemState> transactions;
  final bool hasSynced;
  final String? error;
  final bool hasActiveFilter;

  /// Factory for loading state
  factory TransactionListState.loading() {
    return const TransactionListState(transactions: <TransactionItemState>[], hasSynced: false);
  }

  /// Factory for loaded state
  factory TransactionListState.loaded({
    required List<TransactionItemState> transactions,
    required bool hasSynced,
    bool hasActiveFilter = false,
  }) {
    return TransactionListState(
      transactions: transactions,
      hasSynced: hasSynced,
      hasActiveFilter: hasActiveFilter,
    );
  }

  /// Factory for error state
  factory TransactionListState.error(String error) {
    return TransactionListState(
      transactions: const <TransactionItemState>[],
      hasSynced: false,
      error: error,
    );
  }

  /// Factory for empty state (synced but no transactions)
  factory TransactionListState.empty({bool hasActiveFilter = false}) {
    return TransactionListState(
      transactions: <TransactionItemState>[],
      hasSynced: true,
      hasActiveFilter: hasActiveFilter,
    );
  }

  bool get hasTransactions => transactions.isNotEmpty;
  bool get hasError => error != null;
  bool get isLoading => transactions.isEmpty && !hasSynced && error == null;
  bool get isEmpty => !hasTransactions && hasSynced;

  TransactionListState copyWith({
    List<TransactionItemState>? transactions,
    bool? hasSynced,
    String? error,
    bool? hasActiveFilter,
  }) {
    return TransactionListState(
      transactions: transactions ?? this.transactions,
      hasSynced: hasSynced ?? this.hasSynced,
      error: error ?? this.error,
      hasActiveFilter: hasActiveFilter ?? this.hasActiveFilter,
    );
  }

  @override
  List<Object?> get props => <Object?>[transactions, hasSynced, error, hasActiveFilter];
}
