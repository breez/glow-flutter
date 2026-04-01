import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

class AnimatedLogo extends StatefulWidget {
  const AnimatedLogo({super.key});

  @override
  State<AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<AnimatedLogo> with SingleTickerProviderStateMixin {
  static const Duration duration = Duration(milliseconds: 5000);

  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: duration)..forward(from: 0.0);

    // Scale animation: starts small, grows to 1.0
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.2, curve: Curves.elasticOut),
      ),
    );

    // Opacity animation: fade in smoothly
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeInOut),
      ),
    );

    // Glow/pulse animation: single pulse during scale animation then fades out
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.2, curve: Curves.easeInOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    final Size screenSize = MediaQuery.of(context).size;
    final Color scaffoldBgColor = themeData.scaffoldBackgroundColor;

    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable?>[
        _scaleAnimation,
        _opacityAnimation,
        _glowAnimation,
      ]),
      builder: (BuildContext context, Widget? child) {
        // Single pulse effect - fade out glow smoothly after peak
        final double pulseValue = _glowAnimation.value;
        final double glowOpacity = (1.0 - pulseValue).clamp(0.0, 1.0);

        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // Animated logo with glowing effect on the image itself
                Container(
                  height: screenSize.height * 0.19,
                  alignment: Alignment.center,
                  child: Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      // Glow layer behind the image - fades out smoothly
                      Container(
                        height: 128.0,
                        width: 128.0,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: themeData.colorScheme.primary.withValues(
                                alpha: .4 * glowOpacity,
                              ),
                              blurRadius: 30 + (glowOpacity * 15),
                              spreadRadius: 5 + (glowOpacity * 5),
                            ),
                            BoxShadow(
                              color: pulseValue == 1.0
                                  ? scaffoldBgColor
                                  : themeData.colorScheme.secondary.withValues(
                                      alpha: .4 * glowOpacity,
                                    ),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      // The image itself
                      Image.asset(
                        'assets/icon/glow_transparent.png',
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        height: 128.0,
                        width: 128.0,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: screenSize.height * 0.03),
                // Tagline with staggered animation
                Opacity(
                  opacity: ((_opacityAnimation.value - 0.3) / 0.7).clamp(
                    0.0,
                    1.0,
                  ), // Delayed fade-in
                  child: AutoSizeText(
                    'Glow',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .85),
                      fontSize: 32.0,
                      height: 1.1,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
