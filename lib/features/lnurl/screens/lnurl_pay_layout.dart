import 'package:auto_size_text/auto_size_text.dart';
import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart' hide PaymentStatus;
import 'package:flutter/material.dart';
import 'package:glow/core/services/transaction_formatter.dart';
import 'package:glow/widgets/back_button.dart';
import 'package:glow/features/lnurl/models/lnurl_pay_state.dart';
import 'package:glow/features/send_payment/widgets/amount_input_card.dart';
import 'package:glow/features/send_payment/widgets/payment_bottom_nav.dart';
import 'package:glow/features/send_payment/widgets/payment_confirmation_view.dart';
import 'package:glow/features/send_payment/widgets/payment_status_view.dart';
import 'package:glow/widgets/card_wrapper.dart';
import 'package:glow/widgets/error_card.dart';
import 'package:keyboard_actions/keyboard_actions.dart';

/// Layout for LNURL-Pay / Lightning Address payment (rendering)
///
/// This widget handles only the UI rendering and receives
/// all state and callbacks from LnurlPayScreen.
class LnurlPayLayout extends StatefulWidget {
  final LnurlPayRequestDetails payRequestDetails;
  final LnurlPayState state;
  final void Function(BigInt amount, String? comment) onPreparePayment;
  final VoidCallback onSendPayment;
  final void Function(BigInt amount, String? comment) onRetry;
  final VoidCallback onCancel;

  const LnurlPayLayout({
    required this.payRequestDetails,
    required this.state,
    required this.onPreparePayment,
    required this.onSendPayment,
    required this.onRetry,
    required this.onCancel,
    super.key,
  });

  @override
  State<LnurlPayLayout> createState() => _LnurlPayLayoutState();
}

class _LnurlPayLayoutState extends State<LnurlPayLayout> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  BigInt? _lastAmountSats;
  String? _lastComment;

  @override
  void dispose() {
    _amountController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _handlePreparePayment() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final BigInt amountSats = BigInt.parse(_amountController.text);
    final String? comment = _commentController.text.isNotEmpty ? _commentController.text : null;

    _lastAmountSats = amountSats;
    _lastComment = comment;

    widget.onPreparePayment(amountSats, comment);
  }

  void _handleRetry() {
    if (_lastAmountSats != null) {
      widget.onRetry(_lastAmountSats!, _lastComment);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use address if available, otherwise domain
    final String title = 'Pay to ${widget.payRequestDetails.domain}';

    return Scaffold(
      appBar: AppBar(
        leading: const GlowBackButton(),
        title: Text(title),
        centerTitle: false, // Left-aligned
      ),
      body: SafeArea(
        child: _BodyContent(
          payRequestDetails: widget.payRequestDetails,
          state: widget.state,
          formKey: _formKey,
          amountController: _amountController,
          commentController: _commentController,
        ),
      ),
      bottomNavigationBar: PaymentBottomNav(
        state: widget.state,
        onRetry: _handleRetry,
        onCancel: widget.onCancel,
        onReady: widget.onSendPayment,
        onInitial: _handlePreparePayment,
      ),
    );
  }
}

/// Body content that switches between different states
class _BodyContent extends StatelessWidget {
  final LnurlPayRequestDetails payRequestDetails;
  final LnurlPayState state;
  final GlobalKey<FormState> formKey;
  final TextEditingController amountController;
  final TextEditingController commentController;

  const _BodyContent({
    required this.payRequestDetails,
    required this.state,
    required this.formKey,
    required this.amountController,
    required this.commentController,
  });

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while preparing
    if (state is LnurlPayPreparing) {
      return Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor));
    }

    // Show status view when sending or completed
    if (state is LnurlPaySending) {
      return const PaymentStatusView(status: PaymentStatus.sending);
    }

    if (state is LnurlPaySuccess) {
      return const PaymentStatusView(status: PaymentStatus.success);
    }

    // Show scrollable content for other states
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Amount and comment input (for initial state)
          if (state is LnurlPayInitial)
            _AmountAndCommentForm(
              formKey: formKey,
              amountController: amountController,
              commentController: commentController,
              minSendable: (state as LnurlPayInitial).minSendable,
              maxSendable: (state as LnurlPayInitial).maxSendable,
              commentAllowed: (state as LnurlPayInitial).commentAllowed,
              payRequestDetails: payRequestDetails,
            )
          // Payment summary (when ready)
          else if (state is LnurlPayReady)
            _ConfirmationCard(payRequestDetails: payRequestDetails, state: state)
          // Error display
          else if (state is LnurlPayError)
            ErrorCard(title: 'Payment Failed', message: (state as LnurlPayError).message),
        ],
      ),
    );
  }
}

/// Form for amount and optional comment input
class _AmountAndCommentForm extends StatefulWidget {
  final TransactionFormatter formatter = const TransactionFormatter();
  final GlobalKey<FormState> formKey;
  final TextEditingController amountController;
  final TextEditingController commentController;
  final BigInt minSendable;
  final BigInt maxSendable;
  final int commentAllowed;
  final LnurlPayRequestDetails payRequestDetails;

  const _AmountAndCommentForm({
    required this.formKey,
    required this.amountController,
    required this.commentController,
    required this.minSendable,
    required this.maxSendable,
    required this.commentAllowed,
    required this.payRequestDetails,
  });

  @override
  State<_AmountAndCommentForm> createState() => _AmountAndCommentFormState();
}

class _AmountAndCommentFormState extends State<_AmountAndCommentForm> {
  final ScrollController _scrollController = ScrollController();
  final FocusNode _amountFocusNode = FocusNode();

  @override
  void dispose() {
    _amountFocusNode.dispose();
    super.dispose();
  }

  String _extractDescription(String metadataStr) {
    // Try to extract description from metadata JSON
    // Format is typically: [["text/plain", "description"]]
    try {
      if (metadataStr.contains('"text/plain"')) {
        final RegExp descRegex = RegExp(r'"text/plain"\s*,\s*"([^"]+)"');
        final Match? match = descRegex.firstMatch(metadataStr);
        if (match != null && match.groupCount >= 1) {
          return match.group(1)!;
        }
      }
    } catch (_) {}
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final String description = _extractDescription(widget.payRequestDetails.metadataStr);
    final BigInt minSats = widget.minSendable ~/ BigInt.from(1000);
    final BigInt maxSats = widget.maxSendable ~/ BigInt.from(1000);

    return KeyboardActions(
      tapOutsideBehavior: TapOutsideBehavior.translucentDismiss,
      disableScroll: true,
      config: KeyboardActionsConfig(
        keyboardActionsPlatform: KeyboardActionsPlatform.IOS,
        keyboardBarColor: Theme.of(context).colorScheme.surfaceContainer,
        actions: <KeyboardActionsItem>[
          KeyboardActionsItem(
            focusNode: _amountFocusNode,
            toolbarButtons: <ButtonBuilder>[
              (FocusNode node) {
                return TextButton(
                  style: TextButton.styleFrom(padding: const EdgeInsets.only(right: 16.0)),
                  onPressed: () {
                    node.unfocus();
                  },
                  child: const Text('DONE', style: TextStyle(color: Colors.white)),
                );
              },
            ],
          ),
        ],
      ),
      child: Form(
        key: widget.formKey,
        child: CardWrapper(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:
                <Widget>[
                    // Description (if available)
                    if (description.isNotEmpty) ...<Widget>[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            'Description:',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18.0,
                              letterSpacing: 0.0,
                              height: 1.28,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.left,
                            maxLines: 1,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 16, bottom: 8.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColorLight.withValues(alpha: .1),
                                border: Border.all(
                                  color: Theme.of(context).primaryColorLight.withValues(alpha: .7),
                                ),
                                borderRadius: const BorderRadius.all(Radius.circular(4.0)),
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                width: MediaQuery.of(context).size.width,
                                child: Container(
                                  constraints: const BoxConstraints(
                                    maxHeight: 120,
                                    minWidth: double.infinity,
                                  ),
                                  child: Scrollbar(
                                    controller: _scrollController,
                                    radius: const Radius.circular(16.0),
                                    thumbVisibility: true,
                                    child: SingleChildScrollView(
                                      controller: _scrollController,
                                      child: AutoSizeText(
                                        description,
                                        style: const TextStyle(
                                          fontSize: 14.0,
                                          letterSpacing: 0.0,
                                          height: 1.156,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Amount input with balance and use all funds
                    AmountInputCard(
                      controller: widget.amountController,
                      focusNode: _amountFocusNode,
                      minAmount: minSats,
                      maxAmount: maxSats,
                      validator: (String? value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an amount';
                        }

                        final BigInt? amount = BigInt.tryParse(value);
                        if (amount == null) {
                          return 'Invalid amount';
                        }

                        final BigInt amountMsat = amount * BigInt.from(1000);
                        if (amountMsat < widget.minSendable) {
                          return 'Payment is below the limit ${widget.formatter.formatBalance(minSats)}';
                        }

                        if (amountMsat > widget.maxSendable) {
                          return 'Payment exceeds the limit ${widget.formatter.formatBalance(maxSats)}';
                        }

                        return null;
                      },
                      onPaymentLimitTapped: (BigInt amount) {
                        setState(() {
                          widget.amountController.text = amount.toString();
                        });
                      },
                    ),

                    // Comment input (if allowed)
                    if (widget.commentAllowed > 0) ...<Widget>[
                      TextFormField(
                        controller: widget.commentController,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.done,
                        maxLength: widget.commentAllowed,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          label: const Text('Comment (optional)'),
                          prefixIconConstraints: BoxConstraints.tight(const Size(16, 56)),
                          prefixIcon: const SizedBox.shrink(),
                          contentPadding: const EdgeInsets.only(left: 16, top: 16, bottom: 16),
                          counterStyle: const TextStyle(
                            color: Colors.white54,
                            fontSize: 14.0,
                            height: 1.182,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        validator: (String? value) {
                          if (value != null && value.length > widget.commentAllowed) {
                            return 'Comment must be ${widget.commentAllowed} characters or less';
                          }
                          return null;
                        },
                      ),
                    ],
                  ].expand((Widget widget) sync* {
                    yield widget;
                    yield const Divider(
                      height: 32.0,
                      color: Color.fromRGBO(40, 59, 74, 0.5),
                      indent: 0.0,
                      endIndent: 0.0,
                    );
                  }).toList()
                  ..removeLast(),
          ),
        ),
      ),
    );
  }
}

/// Confirmation card showing payment summary
class _ConfirmationCard extends StatelessWidget {
  final LnurlPayRequestDetails payRequestDetails;
  final LnurlPayState state;

  const _ConfirmationCard({required this.payRequestDetails, required this.state});

  String _extractDescription(String metadataStr) {
    try {
      if (metadataStr.contains('"text/plain"')) {
        final RegExp descRegex = RegExp(r'"text/plain"\s*,\s*"([^"]+)"');
        final Match? match = descRegex.firstMatch(metadataStr);
        if (match != null && match.groupCount >= 1) {
          return match.group(1)!;
        }
      }
    } catch (_) {}
    return '';
  }

  @override
  Widget build(BuildContext context) {
    if (state is! LnurlPayReady) {
      return const SizedBox.shrink();
    }

    final LnurlPayReady readyState = state as LnurlPayReady;
    final String description =
        readyState.comment ?? _extractDescription(payRequestDetails.metadataStr);

    return PaymentConfirmationView(
      amountSats: readyState.amountSats,
      feeSats: readyState.feeSats,
      recipientLabel: payRequestDetails.address ?? '',
      recipientSubtitle: payRequestDetails.address == null
          ? 'You are requested to pay:'
          : 'is requesting you to pay:',
      description: description,
    );
  }
}
