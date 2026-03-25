import 'package:flutter/material.dart';
import 'package:glow/core/services/transaction_formatter.dart';

/// Displays the satoshi equivalent of a fiat amount in real-time.
class SatEquivalentLabel extends StatelessWidget {
  const SatEquivalentLabel({
    required this.satAmount,
    super.key,
  });

  /// The current sat equivalent (null if conversion unavailable).
  final BigInt? satAmount;

  static const TransactionFormatter _formatter = TransactionFormatter();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String displayText = satAmount != null && satAmount! > BigInt.zero
        ? '${_formatter.formatSats(satAmount!)} sats'
        : '0 sats';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        displayText,
        style: TextStyle(
          fontSize: 16.0,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}
