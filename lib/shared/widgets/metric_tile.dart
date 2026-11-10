import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';

class MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String? delta;
  final bool isPositiveDelta;

  const MetricTile({
    super.key,
    required this.label,
    required this.value,
    this.delta,
    this.isPositiveDelta = true,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tokens.colors.card,
        borderRadius: BorderRadius.circular(AppRadiusTokens.tile),
        border: Border.all(color: tokens.colors.line, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: tokens.typography.kpiLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: tokens.colors.ink,
                      fontFeatures: AppTypographyTokens.tabularFigures,
                    ),
                  ),
                ),
              ),
              if (delta != null) ...[
                const SizedBox(width: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    delta!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isPositiveDelta
                          ? AppColorsTokens.trendGreenText
                          : AppColorsTokens.danger,
                      fontFeatures: AppTypographyTokens.tabularFigures,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
