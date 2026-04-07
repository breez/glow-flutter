import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:equatable/equatable.dart';
import 'package:glow/features/send_payment/models/payment_flow_state.dart';

/// Fee speed options for refund transactions
enum RefundFeeSpeed { economy, regular, priority }

/// State for deposit refund flows
sealed class RefundState extends Equatable implements PaymentFlowState {
  const RefundState();

  @override
  bool get isInitial => this is RefundInitial;
  @override
  bool get isPreparing => this is RefundPreparing;
  @override
  bool get isReady => this is RefundReady;
  @override
  bool get isSending => this is RefundSending;
  @override
  bool get isSuccess => this is RefundSuccess;
  @override
  bool get isError => this is RefundError;
  @override
  String? get errorMessage => this is RefundError ? (this as RefundError).message : null;

  @override
  List<Object?> get props => <Object?>[];
}

/// Initial state - showing address input
class RefundInitial extends RefundState {
  final DepositInfo deposit;

  const RefundInitial({required this.deposit});

  @override
  List<Object?> get props => <Object?>[deposit];
}

/// Preparing the refund (fetching fees) after address is entered
class RefundPreparing extends RefundState {
  final DepositInfo deposit;
  final String destinationAddress;

  const RefundPreparing({required this.deposit, required this.destinationAddress});

  @override
  List<Object?> get props => <Object?>[deposit, destinationAddress];
}

/// Refund is prepared and ready to send with fee options
class RefundReady extends RefundState {
  final DepositInfo deposit;
  final String destinationAddress;
  final RecommendedFees fees;
  final RefundFeeSpeed selectedSpeed;

  const RefundReady({
    required this.deposit,
    required this.destinationAddress,
    required this.fees,
    this.selectedSpeed = RefundFeeSpeed.regular,
  });

  /// Get the fee rate for the currently selected speed
  BigInt get selectedFeeRate {
    switch (selectedSpeed) {
      case RefundFeeSpeed.economy:
        return fees.hourFee;
      case RefundFeeSpeed.regular:
        return fees.halfHourFee;
      case RefundFeeSpeed.priority:
        return fees.fastestFee;
    }
  }

  /// Get estimated total fee in sats (180 vbytes typical tx size)
  BigInt get estimatedFeeSats {
    const int estimatedTxSize = 180;
    return selectedFeeRate * BigInt.from(estimatedTxSize);
  }

  /// Get fee for specific speed
  BigInt getFeeRateForSpeed(RefundFeeSpeed speed) {
    switch (speed) {
      case RefundFeeSpeed.economy:
        return fees.hourFee;
      case RefundFeeSpeed.regular:
        return fees.halfHourFee;
      case RefundFeeSpeed.priority:
        return fees.fastestFee;
    }
  }

  /// Get estimated total fee for specific speed
  BigInt getEstimatedFeeSatsForSpeed(RefundFeeSpeed speed) {
    const int estimatedTxSize = 180;
    return getFeeRateForSpeed(speed) * BigInt.from(estimatedTxSize);
  }

  /// Calculate affordability for each fee speed given deposit amount
  Map<RefundFeeSpeed, bool> getAffordability() {
    return <RefundFeeSpeed, bool>{
      RefundFeeSpeed.economy:
          deposit.amountSats > getEstimatedFeeSatsForSpeed(RefundFeeSpeed.economy),
      RefundFeeSpeed.regular:
          deposit.amountSats > getEstimatedFeeSatsForSpeed(RefundFeeSpeed.regular),
      RefundFeeSpeed.priority:
          deposit.amountSats > getEstimatedFeeSatsForSpeed(RefundFeeSpeed.priority),
    };
  }

  RefundReady copyWith({RefundFeeSpeed? selectedSpeed}) {
    return RefundReady(
      deposit: deposit,
      destinationAddress: destinationAddress,
      fees: fees,
      selectedSpeed: selectedSpeed ?? this.selectedSpeed,
    );
  }

  @override
  List<Object?> get props => <Object?>[deposit, destinationAddress, fees, selectedSpeed];
}

/// Sending the refund
class RefundSending extends RefundState {
  final DepositInfo deposit;
  final String destinationAddress;
  final RefundFeeSpeed selectedSpeed;

  const RefundSending({
    required this.deposit,
    required this.destinationAddress,
    required this.selectedSpeed,
  });

  @override
  List<Object?> get props => <Object?>[deposit, destinationAddress, selectedSpeed];
}

/// Refund sent successfully
class RefundSuccess extends RefundState {
  final String txId;

  const RefundSuccess({required this.txId});

  @override
  List<Object?> get props => <Object?>[txId];
}

/// Refund failed
class RefundError extends RefundState {
  final String message;
  final String? technicalDetails;

  const RefundError({required this.message, this.technicalDetails});

  @override
  List<Object?> get props => <Object?>[message, technicalDetails];
}
