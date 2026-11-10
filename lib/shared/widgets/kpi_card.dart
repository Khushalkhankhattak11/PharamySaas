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
      // Invert Y with 2px padding
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
        accentColor = Colors.transparent,
        badgeTextColor = null;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    // (b) Pastel Variant: full pastel fill, no top border, text onPastel, label at 75% opacity,
    // icon square and trend badge filled with the card color, sparkline in onPastel.
    if (isPastel) {
      final fillColor = pastelColor ?? tokens.colors.pastel1;
      final onPastelColor = tokens.colors.onPastel;
      final labelColor = onPastelColor.withValues(alpha: 0.75);

      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadiusTokens.kpiCard),
          child: Container(
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: BorderRadius.circular(AppRadiusTokens.kpiCard),
              boxShadow: [tokens.colors.shadow],
            ),
            padding: const EdgeInsets.all(16),
            child: Stack(
              children: [
                // Trend badge pinned top right
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: tokens.colors.card,
                      borderRadius: BorderRadius.circular(AppRadiusTokens.pill),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: onPastelColor,
                        fontFeatures: AppTypographyTokens.tabularFigures,
                      ),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 38px Icon square
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: tokens.colors.card,
                        borderRadius: BorderRadius.circular(AppRadiusTokens.square),
                      ),
                      child: Icon(icon, size: 20, color: onPastelColor),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 2),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: labelColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.02 * 24,
                        color: onPastelColor,
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
                          color: onPastelColor,
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

    // (a) Tinted Variant: card with 4px top border in its color, 38px icon square (radius 12, color at 18%),
    // trend badge pinned top 16 right 14 (11/700, pill, color at 16%), label 12/600 muted (margin 12 0 2),
    // value 24/800, sparkline 34px high (7 points, stroke 2.2, round caps, no axes).
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
                // 4px top border
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 4,
                  child: Container(color: accentColor),
                ),
                // Trend badge pinned top 16, right 14
                Positioned(
                  top: 16,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.16),
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
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 38px icon square (radius 12, color at 18%)
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(AppRadiusTokens.square),
                        ),
                        child: Icon(icon, size: 20, color: accentColor),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 2),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: tokens.colors.muted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.02 * 24,
                          color: tokens.colors.ink,
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
