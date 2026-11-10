import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';

enum StatusBadgeVariant {
  success,
  amber,
  orange,
  danger,
  info,
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
    Color textColor;
    Color bgColor;

    switch (variant) {
      case StatusBadgeVariant.success:
        textColor = AppColorsTokens.trendGreenText;
        bgColor = AppColorsTokens.success.withValues(alpha: 0.15);
        break;
      case StatusBadgeVariant.amber:
        textColor = AppColorsTokens.amberText;
        bgColor = AppColorsTokens.amber.withValues(alpha: 0.15);
        break;
      case StatusBadgeVariant.orange:
        textColor = AppColorsTokens.orangeText;
        bgColor = AppColorsTokens.orange.withValues(alpha: 0.15);
        break;
      case StatusBadgeVariant.danger:
        textColor = AppColorsTokens.danger;
        bgColor = AppColorsTokens.danger.withValues(alpha: 0.15);
        break;
      case StatusBadgeVariant.info:
        textColor = AppColorsTokens.info;
        bgColor = AppColorsTokens.info.withValues(alpha: 0.15);
        break;
      case StatusBadgeVariant.neutral:
        textColor = AppColorsTokens.light.muted;
        bgColor = AppColorsTokens.light.track;
        break;
      case StatusBadgeVariant.custom:
        textColor = customTextColor ?? AppColorsTokens.light.ink;
        bgColor = customBgColor ?? AppColorsTokens.light.track;
        break;
    }

    if (customTextColor != null) textColor = customTextColor!;
    if (customBgColor != null) bgColor = customBgColor!;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTrend ? 8 : 10,
        vertical: isTrend ? 4 : 5,
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

