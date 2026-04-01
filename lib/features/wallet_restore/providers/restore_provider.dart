import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/logging/logger_mixin.dart';
import 'package:glow/features/wallet/models/wallet_metadata.dart';
import 'package:glow/features/wallet/providers/wallet_provider.dart';
import 'package:glow/features/wallet/services/mnemonic_service.dart';
import 'package:glow/features/wallet_restore/models/restore_state.dart';

class RestoreNotifier extends Notifier<RestoreState> with LoggerMixin {
  @override
  RestoreState build() {
    return const RestoreState();
  }

  void validateMnemonic(String mnemonic) {
    if (mnemonic.split(' ').length != 12) {
      state = state.copyWith();
      return;
    }

    final (bool isValid, String? error) = ref
        .read(mnemonicServiceProvider)
        .validateMnemonic(mnemonic);
    state = state.copyWith(mnemonicError: isValid ? null : error);
  }

  Future<WalletMetadata?> restoreWallet(String mnemonic, Network network) async {
    // Reset errors at the start of each restore attempt
    state = const RestoreState();

    final MnemonicService mnemonicService = ref.read(mnemonicServiceProvider);
    final String normalized = mnemonicService.normalizeMnemonic(mnemonic);
    final (bool isValid, String? error) = mnemonicService.validateMnemonic(normalized);

    if (!isValid) {
      state = state.copyWith(mnemonicError: error);
      return null;
    }

    state = state.copyWith(isLoading: true);

    try {
      final WalletMetadata wallet = await ref
          .read(walletListProvider.notifier)
          .restoreWallet(mnemonic: normalized, network: network);

      await ref.read(activeWalletProvider.notifier).setActiveWallet(wallet.id);

      if (!ref.mounted) {
        return wallet;
      }
      state = state.copyWith(isLoading: false);
      return wallet;
    } catch (e) {
      log.e('Failed to restore wallet: ', error: e);
      if (!ref.mounted) {
        return null;
      }
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        mnemonicError: 'Failed to restore wallet: ${e.toString()}',
      );
      return null;
    }
  }
}

final NotifierProvider<RestoreNotifier, RestoreState> restoreWalletProvider =
    NotifierProvider.autoDispose<RestoreNotifier, RestoreState>(RestoreNotifier.new);
