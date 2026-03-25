import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:glow/features/lnurl/models/lnurl_auth_state.dart';
import 'package:glow/widgets/back_button.dart';
import 'package:glow/features/send_payment/widgets/payment_bottom_nav.dart';
import 'package:glow/widgets/card_wrapper.dart';
import 'package:glow/widgets/error_card.dart';

/// Layout for LNURL Auth (rendering)
///
/// This widget handles only the UI rendering and receives
/// all state and callbacks from LnurlAuthScreen.
class LnurlAuthLayout extends StatelessWidget {
  final LnurlAuthRequestDetails authDetails;
  final LnurlAuthState state;
  final VoidCallback onAuthenticate;
  final VoidCallback onRetry;
  final VoidCallback onCancel;

  const LnurlAuthLayout({
    required this.authDetails,
    required this.state,
    required this.onAuthenticate,
    required this.onRetry,
    required this.onCancel,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const GlowBackButton(), title: const Text('Authenticate'), centerTitle: true),
      body: SafeArea(
        child: _BodyContent(authDetails: authDetails, state: state),
      ),
      bottomNavigationBar: PaymentBottomNav(
        state: state,
        onRetry: onRetry,
        onCancel: onCancel,
        onInitial: onAuthenticate,
        initialLabel: 'AUTHENTICATE',
      ),
    );
  }
}

/// Body content that switches between different states
class _BodyContent extends StatelessWidget {
  final LnurlAuthRequestDetails authDetails;
  final LnurlAuthState state;

  const _BodyContent({required this.authDetails, required this.state});

  @override
  Widget build(BuildContext context) {
    // Show status view when processing or completed
    if (state is LnurlAuthProcessing) {
      return const _ProcessingView();
    }

    if (state is LnurlAuthSuccess) {
      return const _SuccessView();
    }

    // Show scrollable content for other states
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Auth details
          _AuthDetailsCard(authDetails: authDetails),

          // Error display
          if (state is LnurlAuthError) ...<Widget>[
            const SizedBox(height: 16),
            ErrorCard(title: 'Authentication Failed', message: (state as LnurlAuthError).message),
          ],
        ],
      ),
    );
  }
}

/// Card displaying auth details
class _AuthDetailsCard extends StatelessWidget {
  final LnurlAuthRequestDetails authDetails;

  const _AuthDetailsCard({required this.authDetails});

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return CardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Authentication Request',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),

          // Domain
          _DetailRow(label: 'Domain', value: authDetails.domain),

          // Action (if present)
          if (authDetails.action != null) ...<Widget>[
            const SizedBox(height: 12),
            _DetailRow(label: 'Action', value: authDetails.action!),
          ],

          const SizedBox(height: 16),

          // Info box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  Icons.security_outlined,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'This service is requesting to authenticate your wallet',
                    style: textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A detail row showing label and value
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          label,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

/// Processing view
class _ProcessingView extends StatelessWidget {
  const _ProcessingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          CircularProgressIndicator(),
          SizedBox(height: 24),
          Text('Authenticating...', style: TextStyle(fontSize: 18)),
        ],
      ),
    );
  }
}

/// Success view
class _SuccessView extends StatelessWidget {
  const _SuccessView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.check_circle_outline, size: 80, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 24),
          const Text(
            'Authentication Successful!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
