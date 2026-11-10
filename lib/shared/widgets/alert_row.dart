import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';

class AlertRow extends StatelessWidget {
  final String title;
  final String caption;
  final int count;
  final Color alertColor;
  final VoidCallback? onTap;

  const AlertRow({
    super.key,
    required this.title,
    required this.caption,
    required this.count,
    required this.alertColor,
    this.onTap,
  });

  const AlertRow.lowStock({
    super.key,
    required this.count,
    this.caption = 'Items below minimum threshold',
    this.onTap,
  })  : title = 'Low stock items',
        alertColor = AppColorsTokens.amber; // #F59E0B

  const AlertRow.expiringSoon({
    super.key,
    required this.count,
    this.caption = 'Batches expiring within 30 days',
    this.onTap,
  })  : title = 'Expiring in 30 days',
        alertColor = AppColorsTokens.orange; // #F97316

  const AlertRow.expired({
    super.key,
    required this.count,
    this.caption = 'Batches passed expiry date',
    this.onTap,
  })  : title = 'Expired batches',
        alertColor = AppColorsTokens.danger; // #EF4444

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadiusTokens.alertRow),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: alertColor.withValues(alpha: 0.12), // 12% semantic tint
            borderRadius: BorderRadius.circular(AppRadiusTokens.alertRow),
            border: Border.all(
              color: alertColor.withValues(alpha: 0.30), // 30% border
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: tokens.colors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      caption,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: tokens.colors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: alertColor,
                  fontFeatures: AppTypographyTokens.tabularFigures,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
