import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart' hide PaymentStatus;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/widgets/back_button.dart';
import 'package:glow/features/developers/providers/network_provider.dart';
import 'package:glow/features/send_payment/models/spark_address_state.dart';
import 'package:glow/features/send_payment/widgets/network_mismatch_error.dart';
import 'package:glow/features/send_payment/widgets/payment_confirmation_view.dart';
import 'package:glow/features/send_payment/widgets/payment_status_view.dart';
import 'package:glow/features/send_payment/widgets/amount_input_form.dart';
import 'package:glow/features/send_payment/widgets/payment_bottom_nav.dart';
import 'package:glow/widgets/card_wrapper.dart';
import 'package:glow/widgets/error_card.dart';

/// Layout for Spark Address payment (rendering)
///
/// This widget handles only the UI rendering and receives
/// all state and callbacks from SparkAddressScreen.
///
/// Flow: Amount Input → Payment Preparation → Sending → Success
class SparkAddressLayout extends ConsumerStatefulWidget {
  final SparkAddressDetails addressDetails;
  final SparkAddressState state;
  final void Function(BigInt amount) onPreparePayment;
  final VoidCallback onSendPayment;
  final void Function(BigInt amount) onRetry;
  final VoidCallback onCancel;

  const SparkAddressLayout({
    required this.addressDetails,
    required this.state,
    required this.onPreparePayment,
    required this.onSendPayment,
    required this.onRetry,
    required this.onCancel,
    super.key,
  });

  @override
  ConsumerState<SparkAddressLayout> createState() => _SparkAddressLayoutState();
}

class _SparkAddressLayoutState extends ConsumerState<SparkAddressLayout> {
  final TextEditingController _amountController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FocusNode _amountFocusNode = FocusNode();

  BigInt? _lastAmountSats;

  @override
  void dispose() {
    _amountController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  void _handlePreparePayment() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final BigInt amountSats = BigInt.parse(_amountController.text);
    _lastAmountSats = amountSats;

    widget.onPreparePayment(amountSats);
  }

  void _handleRetry() {
    if (_lastAmountSats != null) {
      widget.onRetry(_lastAmountSats!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Network currentNetwork = ref.watch(networkProvider);
    // Check if networks match - SDK Network vs BitcoinNetwork
    final bool networkMismatch =
        (currentNetwork == Network.mainnet &&
            widget.addressDetails.network != BitcoinNetwork.bitcoin) ||
        (currentNetwork != Network.mainnet &&
            widget.addressDetails.network == BitcoinNetwork.bitcoin);

    return Scaffold(
      appBar: AppBar(leading: const GlowBackButton(), title: const Text('Send Payment'), centerTitle: false),
      body: SafeArea(
        child: _BodyContent(
          addressDetails: widget.addressDetails,
          state: widget.state,
          formKey: _formKey,
          amountController: _amountController,
          amountFocusNode: _amountFocusNode,
          networkMismatch: networkMismatch,
          currentNetwork: currentNetwork,
        ),
      ),
      bottomNavigationBar: PaymentBottomNav(
        state: widget.state,
        onRetry: _handleRetry,
        onCancel: widget.onCancel,
        onReady: networkMismatch ? null : widget.onSendPayment,
        onInitial: networkMismatch ? null : _handlePreparePayment,
      ),
    );
  }
}

/// Body content that switches between different states
class _BodyContent extends StatelessWidget {
  final SparkAddressDetails addressDetails;
  final SparkAddressState state;
  final GlobalKey<FormState> formKey;
  final TextEditingController amountController;
  final FocusNode amountFocusNode;
  final bool networkMismatch;
  final Network currentNetwork;

  const _BodyContent({
    required this.addressDetails,
    required this.state,
    required this.formKey,
    required this.amountController,
    required this.amountFocusNode,
    required this.networkMismatch,
    required this.currentNetwork,
  });

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while preparing
    if (state is SparkAddressPreparing) {
      return Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor));
    }

    // Show status view when sending or completed
    if (state is SparkAddressSending) {
      return const PaymentStatusView(status: PaymentStatus.sending);
    }

    if (state is SparkAddressSuccess) {
      return const PaymentStatusView(status: PaymentStatus.success);
    }

    // Show network mismatch error
    if (networkMismatch) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: NetworkMismatchError(
          currentNetwork: currentNetwork,
          addressNetwork: addressDetails.network,
        ),
      );
    }

    // Show scrollable content for other states
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Amount input (initial state)
          if (state is SparkAddressInitial)
            AmountInputForm(
              formKey: formKey,
              controller: amountController,
              focusNode: amountFocusNode,
              header: _buildAddressHeader(context, addressDetails.address),
              minAmount: BigInt.from(25000),
              maxAmount: BigInt.from(2500000000000000),
              showUseAllFunds: false,
              onPaymentLimitTapped: (BigInt amount) {
                amountController.text = amount.toString();
              },
            )
          // Payment summary (when ready)
          else if (state is SparkAddressReady)
            PaymentConfirmationView(
              recipientSubtitle: 'You are requested to pay:',
              amountSats: (state as SparkAddressReady).amountSats,
              feeSats: (state as SparkAddressReady).feeSats,
              description: _buildDescription(state as SparkAddressReady),
            )
          // Error display
          else if (state is SparkAddressError)
            ErrorCard(
              title: 'Failed to prepare payment',
              message: (state as SparkAddressError).message,
            ),
        ],
      ),
    );
  }

  String _buildDescription(SparkAddressReady state) {
    final List<String> parts = <String>['Spark payment'];

    if (state.tokenIdentifier != null) {
      parts.add('Token: ${state.tokenIdentifier}');
    }

    return parts.join(' • ');
  }

  Widget _buildAddressHeader(BuildContext context, String address) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Address',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.0,
            letterSpacing: 0.0,
            height: 1.28,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColorLight.withValues(alpha: .1),
            border: Border.all(color: Theme.of(context).primaryColorLight.withValues(alpha: .7)),
            borderRadius: const BorderRadius.all(Radius.circular(4.0)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          width: MediaQuery.of(context).size.width,
          child: Text(
            address,
            style: const TextStyle(
              fontSize: 14.0,
              letterSpacing: 0.0,
              height: 1.156,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

/// Card displaying Spark Address details
class AddressDetailsCard extends StatelessWidget {
  final SparkAddressDetails addressDetails;

  const AddressDetailsCard({required this.addressDetails, super.key});

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return CardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Address Details',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),

          // Spark Address
          _DetailRow(
            label: 'Spark Address',
            value: _formatAddress(addressDetails.address),
            monospace: true,
          ),
          const SizedBox(height: 12),

          // Identity Public Key
          _DetailRow(
            label: 'Identity Key',
            value: _formatKey(addressDetails.identityPublicKey),
            monospace: true,
          ),
          const SizedBox(height: 12),

          // Network
          _DetailRow(label: 'Network', value: addressDetails.network.name.toUpperCase()),

          // Optional BIP353 Address
          if (addressDetails.source.bip353Address != null) ...<Widget>[
            const SizedBox(height: 12),
            _DetailRow(label: 'BIP353 Address', value: addressDetails.source.bip353Address!),
          ],
        ],
      ),
    );
  }

  String _formatAddress(String address) {
    // Show first 16 and last 16 characters for long addresses
    if (address.length > 36) {
      return '${address.substring(0, 16)}...${address.substring(address.length - 16)}';
    }
    return address;
  }

  String _formatKey(String key) {
    // Show first 12 and last 12 characters for keys
    if (key.length > 28) {
      return '${key.substring(0, 12)}...${key.substring(key.length - 12)}';
    }
    return key;
  }
}

/// A detail row showing label and value
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool monospace;

  const _DetailRow({required this.label, required this.value, this.monospace = false});

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
            style: textTheme.bodyMedium?.copyWith(
              fontFamily: monospace ? 'monospace' : null,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
