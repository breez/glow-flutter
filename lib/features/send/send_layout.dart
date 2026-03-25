import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:glow/features/send/widgets/paste_and_scan_actions.dart';
import 'package:glow/widgets/back_button.dart';
import 'package:glow/features/send/widgets/send_approve_button.dart';
import 'package:glow/features/send/widgets/send_form.dart';
import 'package:glow/widgets/card_wrapper.dart';

class SendLayout extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController controller;
  final AutoSizeGroup textGroup;
  final FocusNode focusNode;
  final bool isValidating;
  final String errorMessage;
  final VoidCallback onPaste;
  final VoidCallback onScan;
  final ValueChanged<String> onSubmit;
  final VoidCallback onApprove;

  const SendLayout({
    required this.formKey,
    required this.controller,
    required this.textGroup,
    required this.focusNode,
    required this.isValidating,
    required this.errorMessage,
    required this.onPaste,
    required this.onScan,
    required this.onSubmit,
    required this.onApprove,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const GlowBackButton(), title: const Text('Payee Information')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: CardWrapper(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              child: Column(
                children: <Widget>[
                  SendForm(
                    formKey: formKey,
                    controller: controller,
                    focusNode: focusNode,
                    errorMessage: errorMessage,
                    onSubmit: onSubmit,
                  ),
                  const SizedBox(height: 36),
                  PasteAndScanActions(onPaste: onPaste, onScan: onScan, textGroup: textGroup),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SendApproveButton(
        controller: controller,
        isValidating: isValidating,
        onApprove: onApprove,
      ),
    );
  }
}
