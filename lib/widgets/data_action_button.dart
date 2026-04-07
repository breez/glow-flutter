import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

class DataActionButtonTheme {
  static const BoxConstraints constraints = BoxConstraints(minHeight: 48.0, minWidth: 138.0);

  static const TextStyle textStyle = TextStyle(
    fontSize: 16,
    letterSpacing: 0.2,
    fontWeight: FontWeight.w500,
    height: 1.24,
  );

  static const double borderRadius = 8.0;
  static const double iconSize = 20.0;
  static const double spacing = 32.0;

  static ButtonStyle get buttonStyle => OutlinedButton.styleFrom(
    side: const BorderSide(color: Colors.white),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
  );
}

class DataActionButton extends StatelessWidget {
  final Widget? icon;
  final String label;
  final VoidCallback onPressed;
  final String? tooltip;
  final AutoSizeGroup? textGroup;

  const DataActionButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.tooltip,
    this.textGroup,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: DataActionButtonTheme.constraints,
      child: Tooltip(
        message: tooltip ?? label,
        child: icon != null
            ? OutlinedButton.icon(
                style: DataActionButtonTheme.buttonStyle,
                icon: icon,
                label: AutoSizeText(
                  label,
                  style: DataActionButtonTheme.textStyle,
                  maxLines: 1,
                  group: textGroup,
                  stepGranularity: 0.1,
                ),
                onPressed: onPressed,
              )
            : OutlinedButton(
                style: DataActionButtonTheme.buttonStyle,
                onPressed: onPressed,
                child: AutoSizeText(
                  label,
                  style: DataActionButtonTheme.textStyle,
                  maxLines: 1,
                  group: textGroup,
                  stepGranularity: 0.1,
                ),
              ),
      ),
    );
  }
}
