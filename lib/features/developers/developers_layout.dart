import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:glow/features/developers/widgets/developers_menu_button.dart';
import 'package:glow/widgets/back_button.dart';
import 'package:glow/features/developers/widgets/logs_card.dart';

class DevelopersLayout extends StatelessWidget {
  final Network network;
  final VoidCallback onManageWallets;
  final VoidCallback onShowNetworkSelector;
  final VoidCallback onShowMaxFee;
  final GestureTapCallback onShareCurrentSession;
  final GestureTapCallback onShareAllLogs;
  final VoidCallback onWipeAllData;

  const DevelopersLayout({
    required this.network,
    required this.onManageWallets,
    required this.onShowNetworkSelector,
    required this.onShowMaxFee,
    required this.onShareCurrentSession,
    required this.onShareAllLogs,
    required this.onWipeAllData,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const GlowBackButton(),
        title: const Text('Debug'),
        actions: <Widget>[
          DevelopersMenuButton(
            onManageWallets: kDebugMode ? onManageWallets : null,
            onShowNetworkSelector: kDebugMode ? onShowNetworkSelector : null,
            onShowMaxFee: onShowMaxFee,
            onWipeAllData: kDebugMode ? onWipeAllData : null,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            // Logs Card
            LogsCard(onShareCurrentSession: onShareCurrentSession, onShareAllLogs: onShareAllLogs),
          ],
        ),
      ),
    );
  }
}
