import 'package:flutter/material.dart';

/// List tile for the "Bitcoin (sats)" option in fiat currency selection.
class BitcoinSatsTile extends StatelessWidget {
  const BitcoinSatsTile({
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.currency_bitcoin),
      title: const Text('Bitcoin (sats)'),
      subtitle: const Text('BTC'),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.green) : null,
      onTap: onTap,
    );
  }
}
