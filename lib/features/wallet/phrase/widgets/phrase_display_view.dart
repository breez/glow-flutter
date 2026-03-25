import 'package:flutter/material.dart';
import 'package:glow/features/wallet/widgets/backup_phrase_grid.dart';
import 'package:glow/widgets/back_button.dart';
import 'package:glow/widgets/bottom_nav_button.dart';

/// View for displaying the backup phrase
class PhraseDisplayView extends StatelessWidget {
  final String mnemonic;
  final String title;
  final String buttonText;
  final VoidCallback onButtonPressed;
  final bool showCloseButton;

  const PhraseDisplayView({
    required this.mnemonic,
    required this.title,
    required this.buttonText,
    required this.onButtonPressed,
    this.showCloseButton = false,
    super.key,
  });

  /// Factory for the verification flow (write down the words)
  factory PhraseDisplayView.writeDown({required String mnemonic, required VoidCallback onNext}) {
    return PhraseDisplayView(
      mnemonic: mnemonic,
      title: 'Write these words',
      buttonText: 'NEXT',
      onButtonPressed: onNext,
    );
  }

  /// Factory for viewing already-verified phrase
  factory PhraseDisplayView.viewOnly({required String mnemonic, required VoidCallback onClose}) {
    return PhraseDisplayView(
      mnemonic: mnemonic,
      title: 'Your backup phrase',
      buttonText: 'OK',
      onButtonPressed: onClose,
      showCloseButton: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: showCloseButton
            ? IconButton(icon: const Icon(Icons.close), onPressed: onButtonPressed)
            : const GlowBackButton(),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[BackupPhraseGrid(mnemonic: mnemonic)],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavButton(text: buttonText, onPressed: onButtonPressed),
    );
  }
}
