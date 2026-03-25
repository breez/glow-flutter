import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/widgets/back_button.dart';
import 'package:glow/logging/logger_mixin.dart';
import 'package:glow/features/wallet/models/wallet_metadata.dart';
import 'package:glow/features/wallet/providers/wallet_provider.dart';
import 'package:glow/features/wallet/widgets/network_selector.dart';
import 'package:glow/widgets/warning_box.dart';
import 'package:glow/routing/app_routes.dart';

class WalletCreateScreen extends ConsumerStatefulWidget {
  const WalletCreateScreen({super.key});

  @override
  ConsumerState<WalletCreateScreen> createState() => _WalletCreateScreenState();
}

class _WalletCreateScreenState extends ConsumerState<WalletCreateScreen> with LoggerMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  Network _selectedNetwork = Network.mainnet;
  bool _isCreating = false;

  Future<void> _createWallet() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isCreating = true);

    try {
      final (WalletMetadata wallet, String mnemonic) = await ref
          .read(walletListProvider.notifier)
          .createWallet(network: _selectedNetwork);

      // Set as active wallet
      await ref.read(activeWalletProvider.notifier).setActiveWallet(wallet.id);

      if (mounted) {
        // Go directly to home screen
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.homeScreen, (_) => false);

        // Show success message after navigation
        Future<void>.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Wallet "${wallet.displayName}" created!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        });
      }
    } catch (e) {
      log.e('Failed to create wallet', error: e);
      if (mounted) {
        setState(() => _isCreating = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const GlowBackButton(), title: const Text('Create Wallet')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: <Widget>[
              NetworkSelector(
                selectedNetwork: _selectedNetwork,
                onChanged: (Network v) => setState(() => _selectedNetwork = v),
              ),
              const SizedBox(height: 32),
              WarningBox.text(
                textColor: Colors.white,
                message:
                    'You will see a 12-word backup phrase after creating your wallet. Write it down securely. '
                    'Anyone with this phrase can access your funds.',
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _isCreating ? null : _createWallet,
                child: _isCreating
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator())
                    : const Text('Create Wallet'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
