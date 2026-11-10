import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';

class ProgressListItem {
  final String name;
  final String valueText;
  final double percentage; // 0.0 to 1.0

  const ProgressListItem({
    required this.name,
    required this.valueText,
    required this.percentage,
  });
}

class ProgressListRow extends StatelessWidget {
  final String name;
  final String valueText;
  final double percentage; // 0.0 to 1.0

  const ProgressListRow({
    super.key,
    required this.name,
    required this.valueText,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final clampedPercent = percentage.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: tokens.colors.ink,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              valueText,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: tokens.colors.muted,
                fontFeatures: AppTypographyTokens.tabularFigures,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 10,
          decoration: BoxDecoration(
            color: tokens.colors.track,
            borderRadius: BorderRadius.circular(AppRadiusTokens.pill),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: clampedPercent,
            child: Container(
              decoration: BoxDecoration(
                color: tokens.colors.accent,
                borderRadius: BorderRadius.circular(AppRadiusTokens.pill),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ProgressList extends StatelessWidget {
  final List<ProgressListItem> items;

  const ProgressList({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final item = items[index];
        return ProgressListRow(
          name: item.name,
          valueText: item.valueText,
          percentage: item.percentage,
        );
      },
    );
  }
}

