import 'package:flutter/material.dart';

/// Displays the current exchange rate with a blink animation on rate changes.
class ExchangeRateLabel extends StatefulWidget {
  const ExchangeRateLabel({
    required this.rateText,
    super.key,
  });

  /// Formatted exchange rate text (e.g., "1 BTC = $65,000 USD").
  final String rateText;

  @override
  State<ExchangeRateLabel> createState() => _ExchangeRateLabelState();
}

class _ExchangeRateLabelState extends State<ExchangeRateLabel>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  String _previousRateText = '';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _animation = Tween<double>(begin: 1.0, end: 0.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _previousRateText = widget.rateText;
  }

  @override
  void didUpdateWidget(ExchangeRateLabel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.rateText != _previousRateText) {
      _previousRateText = widget.rateText;
      _controller.forward().then((_) => _controller.reverse());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _animation,
      builder: (BuildContext context, Widget? child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: Text(
            widget.rateText,
            style: TextStyle(
              fontSize: 13.0,
              color: theme.colorScheme.onSurface.withValues(
                alpha: _animation.value * 0.5,
              ),
            ),
          ),
        );
      },
    );
  }
}
