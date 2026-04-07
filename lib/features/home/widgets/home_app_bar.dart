import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:glow/features/deposits/models/pending_deposit_payment.dart';
import 'package:glow/features/deposits/providers/pending_deposits_provider.dart';
import 'package:glow/features/wallet/models/wallet_metadata.dart';
import 'package:glow/routing/app_routes.dart';
import 'package:glow/features/wallet/providers/wallet_provider.dart';
import 'package:glow/features/wallet/services/wallet_storage_service.dart';

class HomeAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const HomeAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<WalletMetadata?> activeWallet = ref.watch(activeWalletProvider);
    final ThemeData themeData = Theme.of(context);

    return AppBar(
      leading: IconButton(
        icon: SvgPicture.asset(
          'assets/svg/hamburger.svg',
          height: 24.0,
          width: 24.0,
          colorFilter: ColorFilter.mode(themeData.appBarTheme.iconTheme!.color!, BlendMode.srcATop),
        ),
        onPressed: () => Scaffold.of(context).openDrawer(),
      ),
      backgroundColor: Colors.transparent,
      actions: <Widget>[
        const _UnclaimedDepositsWarning(),
        _VerificationWarning(activeWallet: activeWallet, ref: ref),
      ],
    );
  }
}

class _UnclaimedDepositsWarning extends ConsumerWidget {
  const _UnclaimedDepositsWarning();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Show warning icon for deposits needing attention (rejected or no fee requirement)
    final AsyncValue<List<PendingDepositPayment>> depositsNeedingAttentionAsync = ref.watch(
      depositsNeedingAttentionProvider,
    );

    return depositsNeedingAttentionAsync.when(
      data: (List<PendingDepositPayment> deposits) {
        if (deposits.isEmpty) {
          return const SizedBox.shrink();
        }

        return IconButton(
          icon: Icon(
            Icons.warning_amber_rounded,
            color: Theme.of(context).appBarTheme.iconTheme?.color,
          ),
          onPressed: () => Navigator.pushNamed(context, AppRoutes.refunds),
          tooltip: 'Deposits need attention - ${deposits.length}',
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _VerificationWarning extends StatelessWidget {
  final AsyncValue<WalletMetadata?> activeWallet;
  final WidgetRef ref;

  const _VerificationWarning({required this.activeWallet, required this.ref});

  @override
  Widget build(BuildContext context) {
    return activeWallet.when(
      data: (WalletMetadata? wallet) => wallet != null && !wallet.isVerified
          ? IconButton(
              onPressed: () => _handleVerification(context, wallet),
              icon: Icon(
                Icons.warning_amber_rounded,
                color: Theme.of(context).appBarTheme.iconTheme?.color,
              ),
              tooltip: 'Verify backup phrase',
            )
          : const SizedBox.shrink(),
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Future<void> _handleVerification(BuildContext context, WalletMetadata wallet) async {
    final String? mnemonic = await ref.read(walletStorageServiceProvider).loadMnemonic(wallet.id);

    if (mnemonic != null && context.mounted) {
      Navigator.pushNamed(
        context,
        AppRoutes.walletPhrase,
        arguments: <String, dynamic>{'wallet': wallet, 'mnemonic': mnemonic},
      );
    }
  }
}
