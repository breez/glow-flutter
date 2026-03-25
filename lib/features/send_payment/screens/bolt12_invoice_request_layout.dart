import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:glow/features/send_payment/models/bolt12_invoice_request_state.dart';
import 'package:glow/widgets/back_button.dart';
import 'package:glow/widgets/bottom_nav_button.dart';
import 'package:glow/widgets/card_wrapper.dart';
import 'package:glow/widgets/error_card.dart';

/// Layout for BOLT12 Invoice Request (rendering)
///
/// This widget handles only the UI rendering and receives
/// all state and callbacks from Bolt12InvoiceRequestScreen.
///
/// Note: This feature is not fully supported as Bolt12InvoiceRequestDetails
/// is an empty class in the SDK.
class Bolt12InvoiceRequestLayout extends StatelessWidget {
  final Bolt12InvoiceRequestDetails requestDetails;
  final Bolt12InvoiceRequestState state;
  final VoidCallback onCancel;

  const Bolt12InvoiceRequestLayout({
    required this.requestDetails,
    required this.state,
    required this.onCancel,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const GlowBackButton(), title: const Text('BOLT12 Invoice Request'), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Info card explaining the limitation
              CardWrapper(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Not Yet Supported',
                            style: Theme.of(
                              context,
                            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'BOLT12 Invoice Request payments are not yet supported.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Error display
              if (state is Bolt12InvoiceRequestError)
                ErrorCard(
                  title: 'Failed to prepare payment',
                  message: (state as Bolt12InvoiceRequestError).message,
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavButton(stickToBottom: true, text: 'CLOSE', onPressed: onCancel),
    );
  }
}
