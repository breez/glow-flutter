import 'dart:io';
import 'dart:math' show Random;

import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart' as breez_sdk_spark show connect;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/logging/breez_sdk_logger.dart';
import 'package:glow/logging/logger_mixin.dart';
import 'package:path_provider/path_provider.dart';

/// SDK connection and lifecycle management
class BreezSdkService with LoggerMixin {
  /// Connect to Breez SDK with wallet-specific storage
  Future<BreezSdk> connect({
    required String walletId,
    required Seed seed,
    required Config config,
  }) async {
    log.i('Connecting SDK for wallet: $walletId on ${config.network.name}');

    final Directory appDir = await getApplicationDocumentsDirectory();
    final String storageDir = '${appDir.path}/wallets/$walletId';

    try {
      final BreezSdk sdk = await breez_sdk_spark.connect(
        request: ConnectRequest(
          config: config,
          seed: seed,
          storageDir: storageDir,
        ),
      );

      log.i('SDK connected for wallet: $walletId');
      BreezSdkLogger.register(sdk);
      return sdk;
    } catch (e, stack) {
      log.e('Failed to connect SDK', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Get node info (balance, tokens)
  Future<GetInfoResponse> getNodeInfo(BreezSdk sdk) async {
    return sdk.getInfo(request: const GetInfoRequest());
  }

  /// List payments with filters
  Future<List<Payment>> listPayments(BreezSdk sdk, ListPaymentsRequest request) async {
    final ListPaymentsResponse response = await sdk.listPayments(request: request);
    return response.payments;
  }

  /// Generate payment request
  Future<ReceivePaymentResponse> receivePayment(BreezSdk sdk, ReceivePaymentRequest request) async {
    return sdk.receivePayment(request: request);
  }

  /// Get lightning address, with automatic registration if none exists
  Future<LightningAddressInfo?> getLightningAddress(
    BreezSdk sdk, {
    bool autoRegister = false,
    String? profileName,
  }) async {
    final LightningAddressInfo? existing = await sdk.getLightningAddress();

    if (existing != null || !autoRegister) {
      return existing;
    }

    // Auto-register if none exists
    log.i('No Lightning Address found, attempting auto-registration');

    try {
      final bool registered = await _autoRegisterLightningAddress(sdk, profileName: profileName);
      if (registered) {
        return await sdk.getLightningAddress();
      }
    } catch (e, stack) {
      log.e('Auto-registration failed', error: e, stackTrace: stack);
    }

    return null;
  }

  /// Automatically register a Lightning Address with profile name as base
  Future<bool> _autoRegisterLightningAddress(BreezSdk sdk, {String? profileName}) async {
    // Normalize profile name to valid username format (lowercase, no spaces)
    final String baseName = _normalizeUsername(profileName ?? 'glow');

    // First try the normalized base name
    String username = baseName;
    bool available = await checkLightningAddressAvailable(sdk, username);

    if (available) {
      log.i('Registering Lightning Address: $username');
      await registerLightningAddress(sdk, username);
      return true;
    }

    // Try with 4-digit suffix (up to 10 attempts)
    final Random random = Random();
    int attempts = 0;
    const int maxAttempts = 10;

    while (attempts < maxAttempts) {
      attempts++;
      // Generate 4-digit number (1000-9999)
      final int suffix = random.nextInt(9000) + 1000;
      username = '$baseName$suffix';

      log.i('Checking availability for: $username (attempt $attempts)');
      available = await checkLightningAddressAvailable(sdk, username);

      if (available) {
        log.i('Registering Lightning Address: $username');
        await registerLightningAddress(sdk, username);
        return true;
      }
    }

    log.e('Failed to find available Lightning Address after $maxAttempts attempts');
    return false;
  }

  /// Normalize profile name to valid Lightning Address username
  /// - Lowercase
  /// - Replace spaces with empty string or hyphen
  /// - Remove special characters
  /// - Max length enforcement if needed
  String _normalizeUsername(String profileName) {
    return profileName
        .toLowerCase()
        .replaceAll(' ', '') // Remove spaces: "Blue Fox" -> "bluefox"
        .replaceAll(RegExp(r'[^a-z0-9]'), ''); // Remove non-alphanumeric
  }

  /// Check if a Lightning Address username is available
  Future<bool> checkLightningAddressAvailable(BreezSdk sdk, String username) async {
    try {
      return await sdk.checkLightningAddressAvailable(
        request: CheckLightningAddressRequest(username: username),
      );
    } catch (e, stack) {
      log.e('Failed to check Lightning Address availability', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Register a Lightning Address
  Future<void> registerLightningAddress(BreezSdk sdk, String username) async {
    try {
      await sdk.registerLightningAddress(
        request: RegisterLightningAddressRequest(username: username),
      );
      log.i('Lightning Address registered: $username');
    } catch (e, stack) {
      log.e('Failed to register Lightning Address', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Delete Lightning Address
  Future<void> deleteLightningAddress(BreezSdk sdk) async {
    try {
      await sdk.deleteLightningAddress();
      log.i('Lightning Address deleted');
    } catch (e, stack) {
      log.e('Failed to delete Lightning Address', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Claim a pending deposit (for manual retry)
  Future<ClaimDepositResponse> claimDeposit(BreezSdk sdk, ClaimDepositRequest request) async {
    try {
      log.i('Manually claiming deposit: ${request.txid}:${request.vout}');
      final ClaimDepositResponse response = await sdk.claimDeposit(request: request);
      log.i('Deposit claimed successfully');
      return response;
    } catch (e, stack) {
      log.e('Failed to claim deposit', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// List unclaimed deposits
  Future<List<DepositInfo>> listUnclaimedDeposits(BreezSdk sdk) async {
    try {
      final ListUnclaimedDepositsResponse response = await sdk.listUnclaimedDeposits(
        request: const ListUnclaimedDepositsRequest(),
      );
      if (response.deposits.isNotEmpty) {
        log.i('Found ${response.deposits.length} unclaimed deposits');
      }
      return response.deposits;
    } catch (e, stack) {
      log.e('Failed to list unclaimed deposits', error: e, stackTrace: stack);
      rethrow;
    }
  }
}

final Provider<BreezSdkService> breezSdkServiceProvider = Provider<BreezSdkService>(
  (Ref ref) => BreezSdkService(),
);
