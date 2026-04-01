import 'dart:io';

import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/features/developers/developers_layout.dart';
import 'package:glow/features/developers/providers/max_deposit_fee_provider.dart';
import 'package:glow/features/developers/providers/network_provider.dart';
import 'package:glow/features/developers/widgets/max_fee_bottom_sheet.dart';
import 'package:glow/features/developers/widgets/network_bottom_sheet.dart';
import 'package:glow/features/wallet/providers/wallet_provider.dart';
import 'package:glow/features/wallet/services/wallet_storage_service.dart';
import 'package:glow/logging/app_logger.dart';
import 'package:glow/providers/sdk_provider.dart';
import 'package:glow/routing/app_routes.dart';
import 'package:share_plus/share_plus.dart';

class DevelopersScreen extends ConsumerWidget {
  const DevelopersScreen({super.key});

  void _showNetworkBottomSheet(BuildContext context, WidgetRef ref, Network currentNetwork) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => NetworkBottomSheet(
        currentNetwork: currentNetwork,
        onNetworkChanged: (Network network) async {
          try {
            ref.read(networkProvider.notifier).setNetwork(network);

            // Invalidate SDK to reconnect with new network
            ref.invalidate(sdkProvider);

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Network changed to ${network == Network.mainnet ? 'Mainnet' : 'Regtest'}',
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to change network: $e'),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _showMaxFeeBottomSheet(BuildContext context, WidgetRef ref, MaxFee currentFee) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => MaxFeeBottomSheet(
        currentFee: currentFee,
        onSave: (MaxFee fee) async {
          try {
            await ref.read(maxDepositClaimFeeProvider.notifier).setFee(fee);

            // Invalidate SDK to reconnect with new fee
            ref.invalidate(sdkProvider);

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fee updated.'), duration: Duration(seconds: 2)),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to update: $e'),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            }
          }
        },
        onReset: () async {
          await ref.read(maxDepositClaimFeeProvider.notifier).reset();
          ref.invalidate(sdkProvider);

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Reset to default.'), duration: Duration(seconds: 2)),
            );
          }
        },
      ),
    );
  }

  Future<void> _shareCurrentSession(BuildContext context) async {
    try {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Preparing logs...')));
      }

      final File? zipFile = await AppLogger.createCurrentSessionZip();

      if (zipFile == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('No logs to share')));
        }
        return;
      }

      await SharePlus.instance.share(
        ShareParams(
          subject: 'Glow - Current Session Logs',
          text: 'Debug logs from current session',
          files: <XFile>[XFile(zipFile.path)],
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to share logs: $e')));
      }
    }
  }

  Future<void> _shareAllLogs(BuildContext context) async {
    try {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Preparing logs...')));
      }

      final File? zipFile = await AppLogger.createAllLogsZip();

      if (zipFile == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('No logs to share')));
        }
        return;
      }

      await SharePlus.instance.share(
        ShareParams(
          subject: 'Glow - All Session Logs',
          text: 'Debug logs from all sessions',
          files: <XFile>[XFile(zipFile.path)],
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to share logs: $e')));
      }
    }
  }

  Future<void> _wipeAllData(BuildContext context, WidgetRef ref) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        final ThemeData theme = Theme.of(dialogContext);
        return AlertDialog(
          title: Row(
            children: <Widget>[
              Icon(Icons.warning_rounded, color: theme.colorScheme.error),
              const SizedBox(width: 8),
              const Text('Wipe All Data'),
            ],
          ),
          content: const Text(
            'This will permanently delete:\n\n'
            '\u2022 All wallet metadata\n'
            '\u2022 All stored mnemonics\n'
            '\u2022 Active wallet selection\n'
            '\u2022 First-sync tracking\n'
            '\u2022 PIN settings\n\n'
            'The SDK will be disconnected and you will be '
            'returned to the onboarding screen.\n\n'
            'This action cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text('Wipe Everything', style: TextStyle(color: theme.colorScheme.error)),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    try {
      // Clear all secure storage
      final WalletStorageService storage = ref.read(walletStorageServiceProvider);
      await storage.deleteAllData();

      // Clear active wallet to stop SDK
      await ref.read(activeWalletProvider.notifier).clearActiveWallet();

      // Invalidate all providers to reset state
      ref.invalidate(walletListProvider);
      ref.invalidate(activeWalletProvider);
      ref.invalidate(sdkProvider);

      if (context.mounted) {
        // Navigate to onboarding and clear the stack
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.walletSetup, (_) => false);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to wipe data: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Network network = ref.watch(networkProvider);
    final MaxFee maxDepositClaimFee = ref.watch(maxDepositClaimFeeProvider);

    return DevelopersLayout(
      network: network,
      onManageWallets: () => Navigator.pushNamed(context, AppRoutes.walletList),
      onShowNetworkSelector: () => _showNetworkBottomSheet(context, ref, network),
      onShowMaxFee: () => _showMaxFeeBottomSheet(context, ref, maxDepositClaimFee),
      onShareCurrentSession: () => _shareCurrentSession(context),
      onShareAllLogs: () => _shareAllLogs(context),
      onWipeAllData: () => _wipeAllData(context, ref),
    );
  }
}
