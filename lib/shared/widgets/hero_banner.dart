import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';
import 'app_button.dart';

class CapsuleWatermarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const borderColor = Color(0x1FFFFFFF); // rgba(255,255,255,0.12)
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14.0;

    final dividerPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14.0
      ..strokeCap = StrokeCap.square;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(7, 7, size.width - 14, size.height - 14),
      const Radius.circular(80),
    );

    canvas.drawRRect(rrect, borderPaint);

    // Center divider
    canvas.drawLine(
      Offset(size.width / 2, 7),
      Offset(size.width / 2, size.height - 7),
      dividerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PulsingStatusDot extends StatefulWidget {
  const PulsingStatusDot({super.key});

  @override
  State<PulsingStatusDot> createState() => _PulsingStatusDotState();
}

class _PulsingStatusDotState extends State<PulsingStatusDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Respect reduced motion
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    if (disableAnimations) {
      return Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: AppColorsTokens.statusDot,
          shape: BoxShape.circle,
        ),
      );
    }

    return SizedBox(
      width: 16,
      height: 16,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final scale = 1.0 + (_controller.value * 1.0); // 8px up to 16px
              final opacity = (1.0 - _controller.value).clamp(0.0, 1.0);

              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColorsTokens.statusDot.withValues(alpha: opacity * 0.6),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          ),
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColorsTokens.statusDot,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

class HeroBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  final String statusText;
  final String primaryButtonText;
  final VoidCallback? onPrimaryAction;
  final String? secondaryButtonText;
  final VoidCallback? onSecondaryAction;
  final String? inlineMetricText;

  const HeroBanner({
    super.key,
    required this.title,
    required this.subtitle,
    this.statusText = 'All systems running',
    this.primaryButtonText = 'Generate report',
    this.onPrimaryAction,
    this.secondaryButtonText = '+ Add medicine',
    this.onSecondaryAction,
    this.inlineMetricText,
  });

  @override
  Widget build(BuildContext context) {
    final isPhone = MediaQuery.of(context).size.width < 600;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadiusTokens.hero),
        boxShadow: const [AppColorsTokens.heroShadow],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadiusTokens.hero),
        child: Stack(
          children: [
            // Background gradients: Linear 120deg + Radial Glow
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(-0.8, -0.6),
                    end: Alignment(0.8, 0.6),
                    colors: [
                      Color(0xFF0F766E),
                      Color(0xFF064E4B),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: -60,
              right: -100,
              width: 700,
              height: 400,
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.85, -0.2),
                    radius: 0.85,
                    colors: [
                      AppColorsTokens.glow.withValues(alpha: 0.45),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.6],
                  ),
                ),
              ),
            ),
            // Watermark capsule: 300x120, 14px border rgba(255,255,255,0.12), radius 80, rotated -38deg
            if (!isPhone)
              Positioned(
                right: 40,
                top: 20,
                child: Transform.rotate(
                  angle: -38 * math.pi / 180,
                  child: CustomPaint(
                    size: const Size(300, 120),
                    painter: CapsuleWatermarkPainter(),
                  ),
                ),
              ),
            // Hero Content
            Padding(
              padding: EdgeInsets.all(isPhone ? 22.0 : 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Status chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadiusTokens.pill),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const PulsingStatusDot(),
                        const SizedBox(width: 8),
                        Text(
                          statusText,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Title: 34/800, letter-spacing -0.02em
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: isPhone ? 26 : 34,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.02 * (isPhone ? 26 : 34),
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Subtitle: 15, line-height 1.55, max width 520, 88% opacity
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.88),
                        height: 1.55,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  // Buttons Row
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      AppButton.white(
                        text: primaryButtonText,
                        onPressed: onPrimaryAction,
                      ),
                      if (secondaryButtonText != null)
                        AppButton.ghost(
                          text: secondaryButtonText!,
                          onPressed: onSecondaryAction,
                        ),
                      if (inlineMetricText != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Text(
                            inlineMetricText!,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.92),
                              fontFeatures: AppTypographyTokens.tabularFigures,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

