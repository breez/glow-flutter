import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/widgets/back_button.dart';
import 'package:glow/routing/app_routes.dart';
import 'package:glow/logging/logger_mixin.dart';
import 'package:glow/features/wallet/models/wallet_metadata.dart';
import 'package:glow/features/wallet/providers/wallet_provider.dart';
import 'package:glow/features/wallet/services/wallet_storage_service.dart';
import 'package:glow/features/wallet/widgets/empty_state.dart';
import 'package:glow/features/wallet_onboarding/providers/onboarding_state_provider.dart';
import 'package:glow/providers/sdk_provider.dart' show PasskeySeedCache;

/// Whether platform passkey PRF is available on this device.
final FutureProvider<bool> _isPrfAvailableProvider = FutureProvider<bool>((Ref ref) async {
  final PasskeyPrfProvider provider = PasskeyPrfProvider();
  return provider.isPrfAvailable();
});

class WalletListScreen extends ConsumerStatefulWidget {
  const WalletListScreen({super.key});

  @override
  ConsumerState<WalletListScreen> createState() => _WalletListScreenState();
}

class _WalletListScreenState extends ConsumerState<WalletListScreen> with LoggerMixin {
  String? _editingWalletId;
  final Map<String, TextEditingController> _editControllers = <String, TextEditingController>{};

  @override
  void dispose() {
    for (TextEditingController c in _editControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _startEditing(WalletMetadata wallet) {
    setState(() {
      _editingWalletId = wallet.id;
      _editControllers[wallet.id] = TextEditingController(text: wallet.displayName);
    });
  }

  void _cancelEditing() {
    if (_editingWalletId != null) {
      _editControllers[_editingWalletId]?.dispose();
      _editControllers.remove(_editingWalletId);
      setState(() => _editingWalletId = null);
    }
  }

  Future<void> _saveEdit(WalletMetadata wallet) async {
    final String newName = _editControllers[wallet.id]?.text.trim() ?? '';

    if (newName.length < 2) {
      _showSnackBar('Name must be at least 2 characters', Colors.orange);
      return;
    }

    if (newName == wallet.displayName) {
      _cancelEditing();
      return;
    }

    try {
      await ref
          .read(walletListProvider.notifier)
          .updateWalletProfile(wallet.id, customName: newName);
      _cancelEditing();
      if (mounted) {
        _showSnackBar('Renamed to "$newName"', Colors.green);
      }
    } catch (e) {
      log.e('Failed to rename wallet', error: e);
      if (mounted) {
        _showSnackBar('Failed to rename: $e', Colors.red);
      }
    }
  }

  Future<void> _showVerification(WalletMetadata wallet) async {
    String? mnemonic;

    if (wallet.isPasskey) {
      // Derive mnemonic on demand via passkey prompt
      mnemonic = await _derivePasskeyMnemonic(wallet);
    } else {
      mnemonic = await ref.read(walletStorageServiceProvider).loadMnemonic(wallet.id);
    }

    if (mnemonic == null) {
      if (mounted) {
        _showSnackBar('Failed to load recovery phrase', Colors.red);
      }
      return;
    }

    if (mounted) {
      Navigator.pushNamed(
        context,
        AppRoutes.walletPhrase,
        arguments: <String, Object>{'wallet': wallet, 'mnemonic': mnemonic},
      );
    }
  }

  /// Start the passkey label flow — detects existing passkey and opens
  /// the onboarding flow at the label picker (auth-pick) phase.
  /// On completion, switches to the new wallet and navigates home.
  Future<void> _startPasskeyLabelFlow() async {
    // Use the onboarding provider to run detection → auth-pick
    await ref.read(walletOnboardingStateProvider.notifier).startPasskeyFlow();

    if (!mounted) {
      return;
    }

    // Navigate to the onboarding screen which will show the auth-pick UI
    Navigator.pushNamed(context, AppRoutes.walletSetup);
  }

  /// Derive mnemonic from passkey PRF on demand (triggers platform prompt).
  Future<String?> _derivePasskeyMnemonic(WalletMetadata wallet) async {
    try {
      log.i('Deriving mnemonic for passkey wallet: ${wallet.id}');
      final PasskeyPrfProvider prfProvider = PasskeyPrfProvider(
        const PasskeyPrfProviderOptions(rpName: 'Glow', userName: 'Glow', userDisplayName: 'Glow'),
      );
      final Passkey passkey = Passkey(
        derivePrfSeed: prfProvider.derivePrfSeed,
        isPrfAvailable: prfProvider.isPrfAvailable,
      );
      final Wallet derived = await passkey.getWallet(label: wallet.passkeyLabel ?? 'Default');
      return switch (derived.seed) {
        Seed_Mnemonic(:final String mnemonic) => mnemonic,
        _ => null,
      };
    } on PasskeyError catch (e) {
      log.e('Passkey derivation failed', error: e);
      if (mounted) {
        // Don't show error for user cancellation
        final bool cancelled = switch (e) {
          PasskeyError_PrfError(:final PasskeyPrfError field0) => switch (field0) {
              PasskeyPrfError_UserCancelled() => true,
              _ => false,
            },
          _ => false,
        };
        if (!cancelled) {
          _showSnackBar('Passkey authentication failed', Colors.red);
        }
      }
      return null;
    } catch (e) {
      log.e('Failed to derive passkey mnemonic', error: e);
      return null;
    }
  }

  Future<void> _switchWallet(WalletMetadata wallet) async {
    if (wallet.isPasskey) {
      await _switchToPasskeyWallet(wallet);
    } else {
      await _switchToMnemonicWallet(wallet);
    }
  }

  Future<void> _switchToMnemonicWallet(WalletMetadata wallet) async {
    try {
      await ref.read(activeWalletProvider.notifier).switchWallet(wallet.id);
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.homeScreen, (_) => false);
        Future<void>.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _showSnackBar('Switched to ${wallet.displayName}', Colors.green);
          }
        });
      }
    } catch (e) {
      log.e('Failed to switch wallet', error: e);
      if (mounted) {
        _showSnackBar('Failed to switch wallet', Colors.red);
      }
    }
  }

  /// Switch to a passkey wallet: derive the seed first (triggers platform
  /// prompt), cache it, then activate the wallet. If the user cancels the
  /// prompt, nothing changes — the active wallet stays as-is.
  Future<void> _switchToPasskeyWallet(WalletMetadata wallet) async {
    try {
      log.i('Deriving seed for passkey wallet before switching: ${wallet.id}');
      final PasskeyPrfProvider prfProvider = PasskeyPrfProvider(
        const PasskeyPrfProviderOptions(rpName: 'Glow', userName: 'Glow', userDisplayName: 'Glow'),
      );
      final Passkey passkey = Passkey(
        derivePrfSeed: prfProvider.derivePrfSeed,
        isPrfAvailable: prfProvider.isPrfAvailable,
      );
      final Wallet derived = await passkey.getWallet(label: wallet.passkeyLabel ?? 'Default');

      // Seed derived successfully — cache it so sdkProvider doesn't prompt again
      PasskeySeedCache.put(derived.seed);

      await ref.read(activeWalletProvider.notifier).switchWallet(wallet.id);
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.homeScreen, (_) => false);
        Future<void>.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _showSnackBar('Switched to ${wallet.displayName}', Colors.green);
          }
        });
      }
    } on PasskeyError catch (e) {
      // User cancelled — silently stay on wallet list
      final bool cancelled = switch (e) {
        PasskeyError_PrfError(:final PasskeyPrfError field0) => switch (field0) {
            PasskeyPrfError_UserCancelled() => true,
            _ => false,
          },
        _ => false,
      };
      if (cancelled) {
        log.d('Wallet switch cancelled by user');
        if (mounted) {
          _showSnackBar('Wallet switch cancelled', Colors.orange);
        }
      } else {
        log.e('Passkey auth failed during wallet switch', error: e);
        if (mounted) {
          _showSnackBar('Passkey authentication failed', Colors.red);
        }
      }
    } catch (e) {
      log.e('Failed to switch wallet', error: e);
      if (mounted) {
        _showSnackBar('Failed to switch wallet', Colors.red);
      }
    }
  }

  Future<void> _removeWallet(WalletMetadata wallet) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('Remove ${wallet.displayName}?'),
        content: const Text(
          'This will remove the wallet from the app. You can re-import it later using your backup phrase.',
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await ref.read(walletListProvider.notifier).deleteWallet(wallet.id);

      final List<WalletMetadata> wallets = ref.read(walletListProvider).value ?? <WalletMetadata>[];
      final WalletMetadata? activeWallet = ref.read(activeWalletProvider).value;

      if (activeWallet?.id == wallet.id) {
        if (wallets.isNotEmpty) {
          await ref.read(activeWalletProvider.notifier).switchWallet(wallets.first.id);
        } else {
          await ref.read(activeWalletProvider.notifier).clearActiveWallet();
        }
      }

      if (mounted) {
        _showSnackBar('Removed ${wallet.displayName}', Colors.orange);
      }

      // Reroute if no wallets remain
      if (wallets.isEmpty && mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.walletSetup);
      }
    } catch (e) {
      log.e('Failed to remove wallet', error: e);
      if (mounted) {
        _showSnackBar('Failed to remove: $e', Colors.red);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<WalletMetadata>> wallets = ref.watch(walletListProvider);
    final AsyncValue<WalletMetadata?> activeWallet = ref.watch(activeWalletProvider);
    // Eagerly resolve so it's ready when the add-wallet sheet opens
    ref.watch(_isPrfAvailableProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const GlowBackButton(),
        title: const Text('My Wallets'),
        actions: <Widget>[
          IconButton(icon: const Icon(Icons.add), onPressed: () => _showAddWalletSheet()),
        ],
      ),
      body: SafeArea(
        child: wallets.when(
          data: (List<WalletMetadata> list) =>
              list.isEmpty ? _buildEmptyState() : _buildWalletList(list, activeWallet.value),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object err, _) => _buildErrorState(err),
        ),
      ),
    );
  }

  void _showAddWalletSheet() {
    final bool isPrfAvailable = ref.read(_isPrfAvailableProvider).value ?? false;
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (isPrfAvailable)
              ListTile(
                leading: const Icon(Icons.key),
                title: const Text('Create with Passkey'),
                subtitle: const Text('Add a new label to your passkey'),
                onTap: () {
                  Navigator.pop(context);
                  _startPasskeyLabelFlow();
                },
              ),
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('Create New Wallet'),
              subtitle: const Text('Generate a recovery phrase'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.walletCreate);
              },
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Import Wallet'),
              subtitle: const Text('Restore from recovery phrase'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.walletImport);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletList(List<WalletMetadata> wallets, WalletMetadata? active) {
    return ListView.builder(
      itemCount: wallets.length,
      itemBuilder: (BuildContext context, int index) {
        final WalletMetadata wallet = wallets[index];
        final bool isActive = active?.id == wallet.id;
        final bool isEditing = _editingWalletId == wallet.id;

        return ListTile(
          subtitle: wallet.isPasskey && wallet.passkeyLabel != null
              ? Text(
                  'Label: ${wallet.passkeyLabel}',
                  style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: .5)),
                )
              : null,
          title: isEditing
              ? TextField(
                  controller: _editControllers[wallet.id],
                  autofocus: true,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                )
              : Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        wallet.displayName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ),
                    if (wallet.isPasskey) ...<Widget>[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(Icons.key, size: 10, color: Colors.amber),
                            SizedBox(width: 4),
                            Text(
                              'PASSKEY',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (isActive) ...<Widget>[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'ACTIVE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
          trailing: isEditing
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () => _saveEdit(wallet),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: _cancelEditing,
                    ),
                  ],
                )
              : PopupMenuButton<String>(
                  itemBuilder: (_) => <PopupMenuItem<String>>[
                    if (!isActive)
                      const PopupMenuItem<String>(
                        value: 'switch',
                        child: Row(
                          children: <Widget>[
                            Icon(Icons.swap_horiz, size: 20),
                            SizedBox(width: 12),
                            Text('Switch'),
                          ],
                        ),
                      ),
                    const PopupMenuItem<String>(
                      value: 'rename',
                      child: Row(
                        children: <Widget>[
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 12),
                          Text('Rename'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'view',
                      child: Row(
                        children: <Widget>[
                          Icon(Icons.visibility, size: 20),
                          SizedBox(width: 12),
                          Text('View phrase'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'remove',
                      child: Row(
                        children: <Widget>[
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 12),
                          Text('Remove', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (String value) {
                    switch (value) {
                      case 'switch':
                        _switchWallet(wallet);
                      case 'rename':
                        _startEditing(wallet);
                      case 'view':
                        _showVerification(wallet);
                      case 'remove':
                        _removeWallet(wallet);
                    }
                  },
                ),
          onTap: isActive || isEditing ? null : () => _switchWallet(wallet),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return EmptyState(
      icon: Icons.account_balance_wallet_outlined,
      title: 'No Wallets',
      subtitle: 'Create a new wallet or import an existing one',
      actions: <Widget>[
        FilledButton.icon(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.walletCreate),
          icon: const Icon(Icons.add),
          label: const Text('Create Wallet'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.walletImport),
          icon: const Icon(Icons.download),
          label: const Text('Import Wallet'),
        ),
      ],
    );
  }

  Widget _buildErrorState(Object err) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Failed to load wallets', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text(
              err.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
