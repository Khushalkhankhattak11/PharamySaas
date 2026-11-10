import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';

class SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final String badgeText;
  final bool isPositive;
  final VoidCallback? onTap;

  const SummaryCard({
    super.key,
    required this.label,
    required this.value,
    required this.badgeText,
    this.isPositive = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final badgeColor = isPositive ? AppColorsTokens.success : AppColorsTokens.danger;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadiusTokens.card),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: tokens.colors.card,
            borderRadius: BorderRadius.circular(AppRadiusTokens.card),
            border: Border.all(color: tokens.colors.line, width: 1),
            boxShadow: [tokens.colors.shadow],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: tokens.colors.muted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.02 * 26,
                    color: tokens.colors.ink,
                    fontFeatures: AppTypographyTokens.tabularFigures,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppRadiusTokens.pill),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: badgeColor,
                    fontFeatures: AppTypographyTokens.tabularFigures,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

