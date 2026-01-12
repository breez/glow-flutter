import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

/// A reusable bottom navigation bar button widget.
///
/// Handles padding, sizing, and styling for consistent button appearance.
class BottomNavButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool enabled;
  final bool loading;
  final bool stickToBottom;
  final bool expand;
  final TextStyle? textStyle;
  final Color? backgroundColor;
  final Color? disabledColor;
  final double? elevation;
  final BorderRadius? borderRadius;
  final EdgeInsets? padding;
  final BoxConstraints? constraints;
  final Widget? loadingWidget;

  const BottomNavButton({
    required this.text,
    this.onPressed,
    this.enabled = true,
    this.loading = false,
    this.stickToBottom = false,
    this.expand = false,
    this.textStyle,
    this.backgroundColor,
    this.disabledColor,
    this.elevation,
    this.borderRadius,
    this.padding,
    this.constraints,
    this.loadingWidget,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding:
          padding ??
          EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 40.0,
          ),
      child: Column(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        children: <Widget>[
          ConstrainedBox(
            constraints: constraints ?? const BoxConstraints(minHeight: 48.0, minWidth: 168.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: backgroundColor ?? theme.primaryColorLight,
                elevation: elevation ?? 0.0,
                disabledBackgroundColor: disabledColor ?? theme.disabledColor,
                shape: RoundedRectangleBorder(
                  borderRadius: borderRadius ?? BorderRadius.circular(8.0),
                ),
                minimumSize: expand ? Size(screenWidth, 48) : const Size(0, 48),
              ),
              onPressed: (enabled && !loading) ? onPressed : null,
              child: loading
                  ? loadingWidget ??
                        const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                  : AutoSizeText(text, maxLines: 1, style: textStyle ?? theme.textTheme.labelLarge),
            ),
          ),
        ],
      ),
    );
  }
}
