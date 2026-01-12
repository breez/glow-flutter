import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:glow/features/deposits/refund/refund_state.dart';
import 'package:glow/logging/app_logger.dart';
import 'package:glow/providers/sdk_provider.dart';
import 'package:logger/logger.dart';

final Logger log = AppLogger.getLogger('RefundProvider');

/// Provider for refund state management
final NotifierProviderFamily<RefundNotifier, RefundState, DepositInfo> refundProvider =
    NotifierProvider.autoDispose.family<RefundNotifier, RefundState, DepositInfo>(
      RefundNotifier.new,
    );

/// Provider for recommended fees with caching
final FutureProvider<RecommendedFees> recommendedFeesProvider =
    FutureProvider.autoDispose<RecommendedFees>((Ref ref) async {
      final BreezSdk sdk = await ref.watch(sdkProvider.future);
      return sdk.recommendedFees();
    });

/// Notifier for managing refund flow state
class RefundNotifier extends Notifier<RefundState> {
  RefundNotifier(this.arg);
  final DepositInfo arg;

  @override
  RefundState build() {
    // Start with initial state - user needs to input address
    return RefundInitial(deposit: arg);
  }

  DepositInfo get deposit => arg;

  /// Prepare refund by fetching fees for the given address
  Future<void> prepareRefund(String destinationAddress) async {
    try {
      state = RefundPreparing(deposit: deposit, destinationAddress: destinationAddress);
      log.i('Preparing refund for deposit ${deposit.txid}:${deposit.vout} to $destinationAddress');

      // Fetch recommended fees
      final BreezSdk sdk = await ref.read(sdkProvider.future);
      final RecommendedFees fees = await sdk.recommendedFees();

      log.i(
        'Fetched fees - fastest: ${fees.fastestFee}, half hour: ${fees.halfHourFee}, hour: ${fees.hourFee}',
      );

      // Check if any fee speed is affordable
      final RefundReady readyState = RefundReady(
        deposit: deposit,
        destinationAddress: destinationAddress,
        fees: fees,
      );

      final Map<RefundFeeSpeed, bool> affordability = readyState.getAffordability();
      final bool anyAffordable = affordability.values.any((bool affordable) => affordable);

      if (!anyAffordable) {
        state = const RefundError(
          message: 'Insufficient funds',
          technicalDetails:
              'The deposit amount is too small to cover the current network fees. Please try again later when fees are lower.',
        );
        return;
      }

      state = readyState;
    } catch (e, stackTrace) {
      log.e('Failed to prepare refund', error: e, stackTrace: stackTrace);
      state = RefundError(message: 'Failed to fetch fees', technicalDetails: e.toString());
    }
  }

  /// Select a different fee speed
  void selectFeeSpeed(RefundFeeSpeed speed) {
    if (state is RefundReady) {
      state = (state as RefundReady).copyWith(selectedSpeed: speed);
      log.i('Selected fee speed: $speed');
    }
  }

  /// Execute the refund transaction
  Future<void> sendRefund() async {
    if (state is! RefundReady) {
      log.w('Cannot send refund - not in ready state');
      return;
    }

    final RefundReady readyState = state as RefundReady;

    try {
      state = RefundSending(
        deposit: deposit,
        destinationAddress: readyState.destinationAddress,
        selectedSpeed: readyState.selectedSpeed,
      );

      log.i('Sending refund with fee speed: ${readyState.selectedSpeed}');

      final BreezSdk sdk = await ref.read(sdkProvider.future);

      // Create fee object
      final Fee fee = Fee.rate(satPerVbyte: readyState.selectedFeeRate);

      // Execute refund
      final RefundDepositRequest request = RefundDepositRequest(
        txid: deposit.txid,
        vout: deposit.vout,
        destinationAddress: readyState.destinationAddress,
        fee: fee,
      );

      final RefundDepositResponse response = await sdk.refundDeposit(request: request);

      log.i('Refund successful! TX ID: ${response.txId}');
      state = RefundSuccess(txId: response.txId);
    } catch (e, stackTrace) {
      log.e('Failed to send refund', error: e, stackTrace: stackTrace);
      state = RefundError(message: 'Failed to send refund', technicalDetails: e.toString());
    }
  }

  /// Validate Bitcoin address format
  bool isValidBitcoinAddress(String address) {
    final RefundService service = RefundService(ref);
    return service.isValidBitcoinAddress(address);
  }
}

/// Service for handling deposit refunds
class RefundService {
  final Ref ref;

  RefundService(this.ref);

  /// Fetch recommended fees from the network
  Future<RecommendedFees> getRecommendedFees() async {
    try {
      final BreezSdk sdk = await ref.read(sdkProvider.future);
      final RecommendedFees fees = await sdk.recommendedFees();
      log.i('Fetched recommended fees: fastest=${fees.fastestFee}, economy=${fees.economyFee}');
      return fees;
    } catch (e) {
      log.e('Failed to fetch recommended fees', error: e);
      rethrow;
    }
  }

  /// Refund a deposit to an external Bitcoin address
  Future<RefundDepositResponse> refundDeposit({
    required DepositInfo deposit,
    required String destinationAddress,
    required Fee fee,
  }) async {
    try {
      log.i('Refunding deposit ${deposit.txid}:${deposit.vout} to $destinationAddress');

      final BreezSdk sdk = await ref.read(sdkProvider.future);

      final RefundDepositRequest request = RefundDepositRequest(
        txid: deposit.txid,
        vout: deposit.vout,
        destinationAddress: destinationAddress,
        fee: fee,
      );

      final RefundDepositResponse response = await sdk.refundDeposit(request: request);

      log.i('Refund successful! TX ID: ${response.txId}');
      return response;
    } catch (e) {
      log.e('Failed to refund deposit ${deposit.txid}:${deposit.vout}', error: e);
      rethrow;
    }
  }

  /// Validate Bitcoin address format (basic validation)
  bool isValidBitcoinAddress(String address) {
    // Basic validation - check for common Bitcoin address patterns
    // Legacy: starts with 1, length 26-35
    // P2SH: starts with 3, length 26-35
    // Bech32: starts with bc1, length 42-62
    // Bech32m (Taproot): starts with bc1p, length 62

    if (address.isEmpty) {
      return false;
    }

    // Legacy address (P2PKH)
    if (address.startsWith('1') && address.length >= 26 && address.length <= 35) {
      return _isBase58(address);
    }

    // P2SH address
    if (address.startsWith('3') && address.length >= 26 && address.length <= 35) {
      return _isBase58(address);
    }

    // Bech32 (SegWit v0)
    if (address.startsWith('bc1') && !address.startsWith('bc1p')) {
      return address.length >= 42 && address.length <= 62 && _isBech32(address);
    }

    // Bech32m (Taproot)
    if (address.startsWith('bc1p')) {
      return address.length == 62 && _isBech32(address);
    }

    return false;
  }

  bool _isBase58(String str) {
    final RegExp base58Regex = RegExp(
      r'^[123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz]+$',
    );
    return base58Regex.hasMatch(str);
  }

  bool _isBech32(String str) {
    final RegExp bech32Regex = RegExp(r'^bc1[a-z0-9]+$');
    return bech32Regex.hasMatch(str);
  }

  /// Calculate fee options with estimated total fees
  List<FeeOption> calculateFeeOptions(RecommendedFees fees, BigInt depositAmount) {
    // Estimate transaction size (typical refund tx is ~150-200 vbytes)
    const int estimatedTxSize = 180; // vbytes

    return <FeeOption>[
      FeeOption(
        label: 'Fastest',
        description: '~10 minutes',
        satPerVbyte: fees.fastestFee,
        estimatedTotalSats: fees.fastestFee * BigInt.from(estimatedTxSize),
      ),
      FeeOption(
        label: 'Half Hour',
        description: '~30 minutes',
        satPerVbyte: fees.halfHourFee,
        estimatedTotalSats: fees.halfHourFee * BigInt.from(estimatedTxSize),
      ),
      FeeOption(
        label: 'Hour',
        description: '~1 hour',
        satPerVbyte: fees.hourFee,
        estimatedTotalSats: fees.hourFee * BigInt.from(estimatedTxSize),
      ),
      FeeOption(
        label: 'Economy',
        description: '~4+ hours',
        satPerVbyte: fees.economyFee,
        estimatedTotalSats: fees.economyFee * BigInt.from(estimatedTxSize),
      ),
    ];
  }

  /// Check if deposit amount can cover the fee
  bool canAffordFee(BigInt depositAmount, BigInt estimatedFee) {
    return depositAmount > estimatedFee;
  }
}

/// Fee option for display
class FeeOption {
  final String label;
  final String description;
  final BigInt satPerVbyte;
  final BigInt estimatedTotalSats;

  FeeOption({
    required this.label,
    required this.description,
    required this.satPerVbyte,
    required this.estimatedTotalSats,
  });
}
