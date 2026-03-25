import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/routing/app_routes.dart';
import 'package:glow/logging/app_logger.dart';
import 'package:glow/routing/input_parser_provider.dart';
import 'package:glow/theme/dark_theme.dart';
import 'package:logger/logger.dart';

final Logger _log = AppLogger.getLogger('InputHandler');

/// Provider for input handling
final Provider<InputHandler> inputHandlerProvider = Provider<InputHandler>((Ref ref) {
  return InputHandler(ref);
});

/// Handles parsed payment inputs and routes to appropriate screens
class InputHandler {
  final Ref _ref;
  bool _isProcessing = false;

  InputHandler(this._ref);

  /// Handle a payment input string and navigate to the appropriate screen
  Future<void> handleInput(BuildContext context, String input) async {
    if (_isProcessing) {
      _log.w('Already processing input, ignoring duplicate');
      return;
    }
    _isProcessing = true;
    _log.i('Handling input');

    try {
      // Parse the input
      final InputParser parser = _ref.read(inputParserProvider);
      final ParseResult result = await parser.parse(input);

      if (!context.mounted) {
        return;
      }

      // Handle the parsed result
      result.when(
        success: (InputType inputType) {
          _log.i('Successfully parsed input as ${inputType.runtimeType}');
          _navigateToPaymentScreen(context, inputType);
        },
        error: (String message) {
          _log.e('Failed to parse input: $message');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Invalid payment info: $message'),
              padding: kHomeScreenSnackBarPadding,
            ),
          );
        },
      );
    } catch (e) {
      _log.e('Error handling input: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing payment: $e'),
            padding: kHomeScreenSnackBarPadding,
          ),
        );
      }
    } finally {
      _isProcessing = false;
    }
  }

  /// Navigate to the appropriate payment screen based on input type
  /// with optional replacement of the current route
  void navigateToPaymentScreen(BuildContext context, InputType inputType, {bool replace = false}) {
    if (replace) {
      _navigateToPaymentScreenReplacement(context, inputType);
    } else {
      _navigateToPaymentScreen(context, inputType);
    }
  }

  /// Navigate to the appropriate payment screen based on input type
  void _navigateToPaymentScreen(BuildContext context, InputType inputType) {
    inputType.when(
      bitcoinAddress: (BitcoinAddressDetails details) {
        _log.i('Navigating to Bitcoin Address screen');
        Navigator.pushNamed(context, AppRoutes.sendBitcoinAddress, arguments: details);
      },
      bolt11Invoice: (Bolt11InvoiceDetails details) {
        _log.i('Navigating to BOLT11 screen');
        Navigator.pushNamed(context, AppRoutes.sendBolt11, arguments: details);
      },
      bolt12Invoice: (Bolt12InvoiceDetails details) {
        _log.i('Navigating to BOLT12 Invoice screen');
        Navigator.pushNamed(context, AppRoutes.sendBolt12Invoice, arguments: details);
      },
      bolt12Offer: (Bolt12OfferDetails details) {
        _log.i('Navigating to BOLT12 Offer screen');
        Navigator.pushNamed(context, AppRoutes.sendBolt12Offer, arguments: details);
      },
      lightningAddress: (LightningAddressDetails details) {
        _log.i('Navigating to Lightning Address screen');
        Navigator.pushNamed(context, AppRoutes.sendLightningAddress, arguments: details);
      },
      lnurlPay: (LnurlPayRequestDetails details) {
        _log.i('Navigating to LNURL-Pay screen');
        Navigator.pushNamed(context, AppRoutes.sendLnurlPay, arguments: details);
      },
      silentPaymentAddress: (SilentPaymentAddressDetails details) {
        _log.i('Navigating to Silent Payment screen');
        Navigator.pushNamed(context, AppRoutes.sendSilentPayment, arguments: details);
      },
      lnurlAuth: (LnurlAuthRequestDetails details) {
        _log.w('LNURL-Auth input type not supported');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unsupported input'),
            padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0),
          ),
        );
      },
      url: (_) {
        _log.w('URL input type not supported');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('URL payments are not supported'),
            padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0),
          ),
        );
      },
      bip21: (Bip21Details details) {
        _log.i('Navigating to BIP21 screen');
        Navigator.pushNamed(context, AppRoutes.sendBip21, arguments: details);
      },
      bolt12InvoiceRequest: (Bolt12InvoiceRequestDetails details) {
        _log.w('BOLT12 Invoice Request input type not supported');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unsupported input'),
            padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0),
          ),
        );
      },
      lnurlWithdraw: (LnurlWithdrawRequestDetails details) {
        _log.i('Navigating to LNURL-Withdraw screen');
        Navigator.pushNamed(context, AppRoutes.receiveLnurlWithdraw, arguments: details);
      },
      sparkAddress: (SparkAddressDetails details) {
        _log.i('Navigating to Spark Address screen');
        Navigator.pushNamed(context, AppRoutes.sendSparkAddress, arguments: details);
      },
      sparkInvoice: (SparkInvoiceDetails details) {
        _log.i('Navigating to Spark Invoice screen');
        Navigator.pushNamed(context, AppRoutes.sendSparkInvoice, arguments: details);
      },
    );
  }

  /// Navigate with replacement (for BIP21 auto-navigation)
  void _navigateToPaymentScreenReplacement(BuildContext context, InputType inputType) {
    inputType.when(
      bitcoinAddress: (BitcoinAddressDetails details) {
        _log.i('Replacing with Bitcoin Address screen');
        Navigator.pushReplacementNamed(context, AppRoutes.sendBitcoinAddress, arguments: details);
      },
      bolt11Invoice: (Bolt11InvoiceDetails details) {
        _log.i('Replacing with BOLT11 screen');
        Navigator.pushReplacementNamed(context, AppRoutes.sendBolt11, arguments: details);
      },
      bolt12Invoice: (Bolt12InvoiceDetails details) {
        _log.i('Replacing with BOLT12 Invoice screen');
        Navigator.pushReplacementNamed(context, AppRoutes.sendBolt12Invoice, arguments: details);
      },
      bolt12Offer: (Bolt12OfferDetails details) {
        _log.i('Replacing with BOLT12 Offer screen');
        Navigator.pushReplacementNamed(context, AppRoutes.sendBolt12Offer, arguments: details);
      },
      lightningAddress: (LightningAddressDetails details) {
        _log.i('Replacing with Lightning Address screen');
        Navigator.pushReplacementNamed(context, AppRoutes.sendLightningAddress, arguments: details);
      },
      lnurlPay: (LnurlPayRequestDetails details) {
        _log.i('Replacing with LNURL-Pay screen');
        Navigator.pushReplacementNamed(context, AppRoutes.sendLnurlPay, arguments: details);
      },
      silentPaymentAddress: (SilentPaymentAddressDetails details) {
        _log.i('Replacing with Silent Payment screen');
        Navigator.pushReplacementNamed(context, AppRoutes.sendSilentPayment, arguments: details);
      },
      lnurlAuth: (LnurlAuthRequestDetails details) {
        _log.w('LNURL-Auth input type not supported');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unsupported input'),
            padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0),
          ),
        );
      },
      url: (_) {
        _log.w('URL input type not supported');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('URL payments are not supported'),
            padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0),
          ),
        );
      },
      bip21: (Bip21Details details) {
        _log.i('Replacing with BIP21 screen');
        Navigator.pushReplacementNamed(context, AppRoutes.sendBip21, arguments: details);
      },
      bolt12InvoiceRequest: (Bolt12InvoiceRequestDetails details) {
        _log.w('BOLT12 Invoice Request input type not supported');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unsupported input'),
            padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0),
          ),
        );
      },
      lnurlWithdraw: (LnurlWithdrawRequestDetails details) {
        _log.i('Replacing with LNURL-Withdraw screen');
        Navigator.pushReplacementNamed(context, AppRoutes.receiveLnurlWithdraw, arguments: details);
      },
      sparkAddress: (SparkAddressDetails details) {
        _log.i('Replacing with Spark Address screen');
        Navigator.pushReplacementNamed(context, AppRoutes.sendSparkAddress, arguments: details);
      },
      sparkInvoice: (SparkInvoiceDetails details) {
        _log.i('Replacing with Spark Invoice screen');
        Navigator.pushReplacementNamed(context, AppRoutes.sendSparkInvoice, arguments: details);
      },
    );
  }
}
