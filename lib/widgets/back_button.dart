import 'package:flutter/material.dart';

/// Custom back button widget matching Misty Breez design.
///
/// Uses the icomoon font icon for a consistent look across the app.
/// Named GlowBackButton to avoid conflict with Flutter's built-in BackButton.
class GlowBackButton extends StatelessWidget {
  const GlowBackButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(IconData(0xe906, fontFamily: 'icomoon')),
      onPressed: onPressed ?? () => Navigator.pop(context),
    );
  }
}
