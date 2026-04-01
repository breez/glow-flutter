import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class DevelopersMenuButton extends StatelessWidget {
  final VoidCallback? onManageWallets;
  final VoidCallback? onShowNetworkSelector;
  final VoidCallback? onShowMaxFee;
  final VoidCallback? onWipeAllData;

  const DevelopersMenuButton({
    this.onManageWallets,
    this.onShowNetworkSelector,
    this.onShowMaxFee,
    this.onWipeAllData,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final List<PopupMenuEntry<String>> items = <PopupMenuEntry<String>>[];

    // Manage Wallets - debug only
    if (kDebugMode && onManageWallets != null) {
      items.add(
        const PopupMenuItem<String>(
          value: 'wallets',
          child: Row(
            children: <Widget>[
              Icon(Icons.account_balance_wallet, size: 20),
              SizedBox(width: 12),
              Text('Manage Wallets'),
            ],
          ),
        ),
      );
    }

    // Network - debug only
    if (kDebugMode && onShowNetworkSelector != null) {
      items.add(
        const PopupMenuItem<String>(
          value: 'network',
          child: Row(
            children: <Widget>[
              Icon(Icons.swap_horiz, size: 20),
              SizedBox(width: 12),
              Text('Switch Network'),
            ],
          ),
        ),
      );
    }

    // Deposit Claim Fee - available in both debug and release
    if (onShowMaxFee != null) {
      items.add(
        const PopupMenuItem<String>(
          value: 'max_fee',
          child: Row(
            children: <Widget>[
              Icon(Icons.speed, size: 20),
              SizedBox(width: 12),
              Text('Deposit Claim Fee'),
            ],
          ),
        ),
      );
    }

    // Wipe All Data - debug only, destructive
    if (kDebugMode && onWipeAllData != null) {
      items.add(const PopupMenuDivider());
      items.add(
        PopupMenuItem<String>(
          value: 'wipe',
          child: Row(
            children: <Widget>[
              Icon(Icons.delete_forever, size: 20, color: Colors.red.shade300),
              const SizedBox(width: 12),
              Text('Wipe All Data', style: TextStyle(color: Colors.red.shade300)),
            ],
          ),
        ),
      );
    }

    // Don't show menu if no items
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return PopupMenuButton<String>(
      onSelected: (String value) {
        switch (value) {
          case 'wallets':
            onManageWallets?.call();
            break;
          case 'network':
            onShowNetworkSelector?.call();
            break;
          case 'max_fee':
            onShowMaxFee?.call();
            break;
          case 'wipe':
            onWipeAllData?.call();
            break;
        }
      },
      itemBuilder: (BuildContext context) => items,
    );
  }
}
