import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Notifier to track which deposits are expanded
/// Key is the transaction ID + vout (e.g., "txid:0")
class DepositExpansionNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => <String>{};

  void toggle(String depositKey) {
    if (state.contains(depositKey)) {
      state = Set<String>.from(state)..remove(depositKey);
    } else {
      state = Set<String>.from(state)..add(depositKey);
    }
  }
}

/// Provider for deposit expansion state
final NotifierProvider<DepositExpansionNotifier, Set<String>> depositExpansionProvider =
    NotifierProvider<DepositExpansionNotifier, Set<String>>(DepositExpansionNotifier.new);

/// Helper to generate deposit key
String getDepositKey(String txid, int vout) => '$txid:$vout';
