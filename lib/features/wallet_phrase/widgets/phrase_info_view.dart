import 'package:flutter/material.dart';
import 'package:glow/widgets/back_button.dart';
import 'package:glow/widgets/bottom_nav_button.dart';

/// View for displaying information about the backup phrase importance
class PhraseInfoView extends StatefulWidget {
  final VoidCallback onNext;

  const PhraseInfoView({required this.onNext, super.key});

  @override
  State<PhraseInfoView> createState() => _PhraseInfoViewState();
}

class _PhraseInfoViewState extends State<PhraseInfoView> {
  bool _checked = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const GlowBackButton(), title: const Text('Backup Phrase')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: <Widget>[
              const Expanded(
                flex: 2,
                child: Image(
                  image: AssetImage('assets/image/phrase_info.png'),
                  height: 100,
                  width: 100,
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 96),
                child: const Text(
                  "You will be shown a list of words. Write down the words and store them in a safe place. Without these words, you won't be able to restore from backup and your funds will be lost.",
                  style: TextStyle(fontSize: 14.3, letterSpacing: 0.4, height: 1.16),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Theme(
                        data: Theme.of(context).copyWith(unselectedWidgetColor: Colors.white),
                        child: Checkbox(
                          value: _checked,
                          onChanged: (bool? v) => setState(() => _checked = v ?? false),
                          activeColor: Colors.white,
                          checkColor: Theme.of(context).canvasColor,
                        ),
                      ),
                      const Text(
                        'I UNDERSTAND',
                        style: TextStyle(
                          fontSize: 14.3,
                          letterSpacing: 1.25,
                          height: 1.16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SizedBox(
        height: 88,
        child: _checked ? BottomNavButton(text: 'NEXT', onPressed: widget.onNext) : null,
      ),
    );
  }
}
