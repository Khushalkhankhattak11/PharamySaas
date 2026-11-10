import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';

enum StatusBadgeVariant {
  success,
  info,
  amber,
  orange,
  danger,
  purple,
  neutral,
  custom,
}

class StatusBadge extends StatelessWidget {
  final String label;
  final StatusBadgeVariant variant;
  final Color? customTextColor;
  final Color? customBgColor;
  final bool isTrend;
  final Widget? icon;

  const StatusBadge({
    super.key,
    required this.label,
    this.variant = StatusBadgeVariant.info,
    this.customTextColor,
    this.customBgColor,
    this.isTrend = false,
    this.icon,
  });

  const StatusBadge.trend({
    super.key,
    required this.label,
    this.variant = StatusBadgeVariant.success,
    this.customTextColor,
    this.customBgColor,
    this.icon,
  }) : isTrend = true;

  @override
  Widget build(BuildContext context) {
    Color baseColor;

    switch (variant) {
      case StatusBadgeVariant.success:
        baseColor = AppColorsTokens.success; // #22C55E
        break;
      case StatusBadgeVariant.info:
        baseColor = AppColorsTokens.info; // #3B82F6
        break;
      case StatusBadgeVariant.amber:
        baseColor = AppColorsTokens.amber; // #F59E0B
        break;
      case StatusBadgeVariant.orange:
        baseColor = AppColorsTokens.orange; // #F97316
        break;
      case StatusBadgeVariant.danger:
        baseColor = AppColorsTokens.danger; // #EF4444
        break;
      case StatusBadgeVariant.purple:
        baseColor = AppColorsTokens.purple; // #A855F7
        break;
      case StatusBadgeVariant.neutral:
        baseColor = AppColorsTokens.light.muted;
        break;
      case StatusBadgeVariant.custom:
        baseColor = customTextColor ?? AppColorsTokens.light.ink;
        break;
    }

    final textColor = customTextColor ?? baseColor;
    final bgColor = customBgColor ?? baseColor.withValues(alpha: 0.16);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTrend ? 8 : 10,
        vertical: isTrend ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadiusTokens.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            icon!,
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: isTrend ? 11 : 12,
              fontWeight: FontWeight.w700,
              color: textColor,
              height: 1.1,
              fontFeatures: AppTypographyTokens.tabularFigures,
            ),
          ),
        ],
      ),
    );
  }
}
