import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';

class SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final double strokeWidth;

  SparklinePainter({
    required this.data,
    required this.color,
    this.strokeWidth = 2.2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final minVal = data.reduce((curr, next) => curr < next ? curr : next);
    final maxVal = data.reduce((curr, next) => curr > next ? curr : next);
    final range = (maxVal - minVal) == 0 ? 1.0 : (maxVal - minVal);

    final path = Path();
    final stepX = size.width / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      // Invert Y so highest value is at top with 2px padding
      final normalized = (data[i] - minVal) / range;
      final y = size.height - (normalized * (size.height - 4) + 2);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        final prevX = (i - 1) * stepX;
        final prevNormalized = (data[i - 1] - minVal) / range;
        final prevY = size.height - (prevNormalized * (size.height - 4) + 2);

        // Smooth cubic bezier
        final midX = (prevX + x) / 2;
        path.cubicTo(midX, prevY, midX, y, x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant SparklinePainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.color != color;
  }
}

class KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String badgeText;
  final IconData icon;
  final Color accentColor;
  final List<double> sparklineData;
  final bool isPastel;
  final Color? pastelColor;
  final Color? badgeTextColor;
  final VoidCallback? onTap;

  const KpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.badgeText,
    required this.icon,
    required this.accentColor,
    required this.sparklineData,
    this.isPastel = false,
    this.pastelColor,
    this.badgeTextColor,
    this.onTap,
  });

  const KpiCard.pastel({
    super.key,
    required this.label,
    required this.value,
    required this.badgeText,
    required this.icon,
    required Color this.pastelColor,
    required this.sparklineData,
    this.onTap,
  })  : isPastel = true,
        accentColor = const Color(0xFF05343A),
        badgeTextColor = const Color(0xFF06292B);

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    // Pastel variant styling
    if (isPastel) {
      final bgColor = pastelColor ?? AppColorsTokens.lime;
      const textColor = Color(0xFF06292B);
      const labelColor = Color(0xFF2F4B4D);
      const sparklineColor = Color(0xFF05343A);

      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadiusTokens.kpiCard),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(AppRadiusTokens.kpiCard),
              boxShadow: [tokens.colors.shadow],
            ),
            child: Stack(
              children: [
                // Top-right trend badge
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(AppRadiusTokens.pill),
                    ),
                    child: Text(
                      badgeText,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                        fontFeatures: AppTypographyTokens.tabularFigures,
                      ),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon square
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadiusTokens.iconSquare),
                      ),
                      child: Icon(icon, size: 20, color: sparklineColor),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: labelColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.02 * 24,
                        color: textColor,
                        fontFeatures: AppTypographyTokens.tabularFigures,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 34,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: SparklinePainter(
                          data: sparklineData,
                          color: sparklineColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Default tinted card with 4px top accent
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadiusTokens.kpiCard),
        child: Container(
          decoration: BoxDecoration(
            color: tokens.colors.card,
            borderRadius: BorderRadius.circular(AppRadiusTokens.kpiCard),
            border: Border.all(color: tokens.colors.line, width: 1),
            boxShadow: [tokens.colors.shadow],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadiusTokens.kpiCard),
            child: Stack(
              children: [
                // 4px top accent
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 4,
                  child: Container(color: accentColor),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 38x38 icon square
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(AppRadiusTokens.iconSquare),
                            ),
                            child: Icon(icon, size: 20, color: accentColor),
                          ),
                          // Top-right trend badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(AppRadiusTokens.pill),
                            ),
                            child: Text(
                              badgeText,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: badgeTextColor ?? accentColor,
                                fontFeatures: AppTypographyTokens.tabularFigures,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        label,
                        style: tokens.typography.kpiLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        style: tokens.typography.kpiValue,
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 34,
                        width: double.infinity,
                        child: CustomPaint(
                          painter: SparklinePainter(
                            data: sparklineData,
                            color: accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

