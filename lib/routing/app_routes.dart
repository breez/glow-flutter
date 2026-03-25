import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/features/deposits/unclaimed_deposits_screen.dart';
import 'package:glow/features/developers/developers_screen.dart';
import 'package:glow/features/lnurl/screens/lnurl_auth_screen.dart';
import 'package:glow/features/lnurl/screens/lnurl_pay_screen.dart';
import 'package:glow/features/lnurl/screens/lnurl_withdraw_screen.dart';

import 'package:glow/features/qr_scan/qr_scan_view.dart';
import 'package:glow/features/receive/receive_screen.dart';
import 'package:glow/features/send/send_screen.dart';
import 'package:glow/features/send_payment/screens/bip21_screen.dart';
import 'package:glow/features/send_payment/screens/bitcoin_address_screen.dart';
import 'package:glow/features/send_payment/screens/bolt11_payment_screen.dart';
import 'package:glow/features/send_payment/screens/bolt12_invoice_request_screen.dart';
import 'package:glow/features/send_payment/screens/bolt12_invoice_screen.dart';
import 'package:glow/features/send_payment/screens/bolt12_offer_screen.dart';
import 'package:glow/features/send_payment/screens/silent_payment_screen.dart';
import 'package:glow/features/send_payment/screens/spark_address_screen.dart';
import 'package:glow/features/send_payment/screens/spark_invoice_screen.dart';
import 'package:glow/features/settings/providers/pin_provider.dart';
import 'package:glow/features/settings/security_backup_screen.dart';
import 'package:glow/features/settings/services/pin_service.dart';
import 'package:glow/features/settings/widgets/pin_lock_screen.dart';
import 'package:glow/features/settings/widgets/pin_setup_screen.dart';
import 'package:glow/features/wallet/create_screen.dart';
import 'package:glow/features/wallet/list_screen.dart';
import 'package:glow/features/wallet_onboarding/onboarding_screen.dart';
import 'package:glow/features/wallet_phrase/phrase_screen.dart';
import 'package:glow/features/wallet_restore/restore_screen.dart';

/// Handles navigation for payment flows and feature screens
///
/// This works alongside _AppRouter which handles initial wallet-state-based routing.
/// _AppRouter determines if user sees WalletSetupScreen or HomeScreen.
/// AppRoutes handles navigation WITHIN the app (QR scan, payments, settings, etc.)
class AppRoutes {
  // Core routes
  static const String homeScreen = '/';
  static const String qrScan = '/qr_scan';

  // Wallet routes
  static const String walletSetup = '/wallet/setup';
  static const String walletCreate = '/wallet/create';
  static const String walletImport = '/wallet/import';
  static const String walletList = '/wallet/list';
  static const String walletPhrase = '/wallet/phrase';

  // Send payment routes
  static const String sendScreen = '/send';
  static const String sendBitcoinAddress = '/send/bitcoin_address';
  static const String sendBolt11 = '/send/bolt11';
  static const String sendBolt12Invoice = '/send/bolt12_invoice';
  static const String sendBolt12Offer = '/send/bolt12_offer';
  static const String sendLightningAddress = '/send/lightning_address';
  static const String sendLnurlPay = '/send/lnurl_pay';
  static const String sendSilentPayment = '/send/silent_payment';
  static const String sendBip21 = '/send/bip21';
  static const String sendBolt12InvoiceRequest = '/send/bolt12_invoice_request';
  static const String sendSparkAddress = '/send/spark/address';
  static const String sendSparkInvoice = '/send/spark/invoice';

  // Deposit claim routes
  static const String unclaimedDeposits = '/deposit/list';

  // Receive payment routes
  static const String receiveScreen = '/receive';
  static const String receiveLnurlWithdraw = '/receive/lnurl_withdraw';

  // Auth routes
  static const String lnurlAuth = '/lnurl_auth';

  // Settings routes
  static const String appSettings = '/settings';
  static const String pinSetup = '/settings/pin_setup';

  // Developers routes
  static const String developersScreen = '/developers';

  /// Generate routes for named navigation
  ///
  /// This is called by MaterialApp.onGenerateRoute when you use Navigator.pushNamed()
  static Route<dynamic>? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // QR Scanner
      case qrScan:
        return MaterialPageRoute<String>(builder: (_) => const QRScanView());

      // Wallet routes
      case walletSetup:
        return MaterialPageRoute<String>(builder: (_) => const WalletSetupScreen());

      case walletCreate:
        return MaterialPageRoute<String>(builder: (_) => const WalletCreateScreen());

      case walletImport:
        return MaterialPageRoute<String>(builder: (_) => const RestoreScreen());

      case walletList:
        return MaterialPageRoute<String>(builder: (_) => const WalletListScreen());

      case walletPhrase:
        final Map<String, dynamic> args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute<PhraseScreen>(
          builder: (_) => PhraseScreen(wallet: args['wallet'], mnemonic: args['mnemonic']),
          settings: settings,
        );

      // Send payment routes
      case AppRoutes.sendScreen:
        return MaterialPageRoute<SendScreen>(
          builder: (_) => const SendScreen(),
          settings: settings,
        );

      case sendBitcoinAddress:
        final BitcoinAddressDetails args = settings.arguments as BitcoinAddressDetails;
        return MaterialPageRoute<Widget>(
          builder: (_) => BitcoinAddressScreen(addressDetails: args),
          settings: settings,
        );

      case sendBolt11:
        final Bolt11InvoiceDetails args = settings.arguments as Bolt11InvoiceDetails;
        return MaterialPageRoute<Widget>(
          builder: (_) => Bolt11PaymentScreen(invoiceDetails: args),
          settings: settings,
        );

      case sendBolt12Invoice:
        final Bolt12InvoiceDetails args = settings.arguments as Bolt12InvoiceDetails;
        return MaterialPageRoute<Widget>(
          builder: (_) => Bolt12InvoiceScreen(invoiceDetails: args),
          settings: settings,
        );

      case sendBolt12Offer:
        final Bolt12OfferDetails args = settings.arguments as Bolt12OfferDetails;
        return MaterialPageRoute<Widget>(
          builder: (_) => Bolt12OfferScreen(offerDetails: args),
          settings: settings,
        );

      case sendLightningAddress:
        final LightningAddressDetails args = settings.arguments as LightningAddressDetails;
        // Lightning Address uses LNURL-Pay under the hood
        return MaterialPageRoute<Widget>(
          builder: (_) => LnurlPayScreen(payRequestDetails: args.payRequest),
          settings: settings,
        );

      case sendLnurlPay:
        final LnurlPayRequestDetails args = settings.arguments as LnurlPayRequestDetails;
        return MaterialPageRoute<Widget>(
          builder: (_) => LnurlPayScreen(payRequestDetails: args),
          settings: settings,
        );

      case sendSilentPayment:
        final SilentPaymentAddressDetails args = settings.arguments as SilentPaymentAddressDetails;
        return MaterialPageRoute<Widget>(
          builder: (_) => SilentPaymentScreen(addressDetails: args),
          settings: settings,
        );

      case sendBip21:
        final Bip21Details args = settings.arguments as Bip21Details;
        return MaterialPageRoute<Widget>(
          builder: (_) => Bip21Screen(bip21Details: args),
          settings: settings,
        );

      case sendBolt12InvoiceRequest:
        final Bolt12InvoiceRequestDetails args = settings.arguments as Bolt12InvoiceRequestDetails;
        return MaterialPageRoute<Widget>(
          builder: (_) => Bolt12InvoiceRequestScreen(requestDetails: args),
          settings: settings,
        );

      case sendSparkAddress:
        final SparkAddressDetails args = settings.arguments as SparkAddressDetails;
        return MaterialPageRoute<Widget>(
          builder: (_) => SparkAddressScreen(addressDetails: args),
          settings: settings,
        );

      case sendSparkInvoice:
        final SparkInvoiceDetails args = settings.arguments as SparkInvoiceDetails;
        return MaterialPageRoute<Widget>(
          builder: (_) => SparkInvoiceScreen(invoiceDetails: args),
          settings: settings,
        );

      // Deposit claim routes
      case AppRoutes.unclaimedDeposits:
        return MaterialPageRoute<UnclaimedDepositsScreen>(
          builder: (_) => const UnclaimedDepositsScreen(),
          settings: settings,
        );

      // Receive routes
      case receiveLnurlWithdraw:
        final LnurlWithdrawRequestDetails args = settings.arguments as LnurlWithdrawRequestDetails;
        return MaterialPageRoute<Widget>(
          builder: (_) => LnurlWithdrawScreen(withdrawDetails: args),
          settings: settings,
        );

      case AppRoutes.receiveScreen:
        return MaterialPageRoute<ReceiveScreen>(
          builder: (_) => const ReceiveScreen(),
          settings: settings,
        );

      // Auth routes
      case lnurlAuth:
        final LnurlAuthRequestDetails args = settings.arguments as LnurlAuthRequestDetails;
        return MaterialPageRoute<Widget>(
          builder: (_) => LnurlAuthScreen(authDetails: args),
          settings: settings,
        );

      // Security & Backup routes
      case appSettings:
        return MaterialPageRoute<Widget>(
          builder: (BuildContext context) {
            return Consumer(
              builder: (BuildContext context, WidgetRef ref, Widget? child) {
                final PinService pinService = ref.read(pinServiceProvider);

                // Use FutureBuilder to check PIN status once without listening to provider changes
                return FutureBuilder<bool>(
                  future: pinService.hasPin(),
                  builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Scaffold(body: Center(child: CircularProgressIndicator()));
                    }

                    final bool isPinEnabled = snapshot.data ?? false;

                    if (isPinEnabled) {
                      return PinLockScreen(
                        popOnSuccess: false,
                        onUnlocked: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute<SecurityBackupScreen>(
                              builder: (_) => const SecurityBackupScreen(),
                            ),
                          );
                        },
                      );
                    }

                    return const SecurityBackupScreen();
                  },
                );
              },
            );
          },
          settings: settings,
        );

      case pinSetup:
        return MaterialPageRoute<PinSetupScreen>(
          builder: (_) => const PinSetupScreen(),
          settings: settings,
        );

      // Developers routes
      case developersScreen:
        return MaterialPageRoute<DevelopersScreen>(
          builder: (_) => const DevelopersScreen(),
          settings: settings,
        );

      default:
        // Route not found
        return MaterialPageRoute<_RouteNotFoundScreen>(
          builder: (_) => _RouteNotFoundScreen(settings.name ?? 'unknown'),
          settings: settings,
        );
    }
  }
}

/// Screen shown when route is not found
class _RouteNotFoundScreen extends StatelessWidget {
  final String routeName;

  const _RouteNotFoundScreen(this.routeName);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Route Not Found')),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
                const SizedBox(height: 16),
                Text('Route Not Found', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  'No route defined for: $routeName',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.home),
                  label: const Text('Go Home'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
