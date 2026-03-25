import 'package:flutter/material.dart';
import 'package:glow/widgets/back_button.dart';

/// View for verifying that the user has correctly written down the phrase
class PhraseVerificationView extends StatelessWidget {
  final List<int> wordIndices;
  final List<TextEditingController> controllers;
  final bool isVerifying;
  final VoidCallback onVerify;

  const PhraseVerificationView({
    required this.wordIndices,
    required this.controllers,
    required this.isVerifying,
    required this.onVerify,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const GlowBackButton(), title: const Text("Let's verify")),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Form(
                child: Column(
                  children: <Widget>[
                    for (int i = 0; i < 3; i++) ...<Widget>[
                      TextFormField(
                        controller: controllers[i],
                        decoration: InputDecoration(label: Text('${wordIndices[i] + 1}')),
                        enabled: !isVerifying,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 40.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  padding: EdgeInsets.zero,
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    width: MediaQuery.of(context).size.width,
                    child: Text(
                      'Please type words number ${wordIndices[0] + 1}, ${wordIndices[1] + 1} and ${wordIndices[2] + 1} of the generated backup phrase.',
                      style: const TextStyle(
                        color: Color(0xccffffff),
                        fontSize: 14.3,
                        letterSpacing: 0.4,
                        height: 1.16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _VerifyButton(isVerifying: isVerifying, onPressed: onVerify),
    );
  }
}

class _VerifyButton extends StatelessWidget {
  final bool isVerifying;
  final VoidCallback onPressed;

  const _VerifyButton({required this.isVerifying, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: FilledButton(
        onPressed: isVerifying ? null : onPressed,
        child: isVerifying
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator())
            : const Text('VERIFY'),
      ),
    );
  }
}
