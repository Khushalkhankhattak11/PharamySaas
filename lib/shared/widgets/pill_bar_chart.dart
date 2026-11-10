import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';
import 'section_card.dart';

class DaySales {
  final String day;
  final double amountK;
  final Color pastelColor;

  const DaySales({
    required this.day,
    required this.amountK,
    required this.pastelColor,
  });
}

class StripedOverlayPainter extends CustomPainter {
  final Color stripeColor;

  StripedOverlayPainter({
    this.stripeColor = const Color(0x59FFFFFF), // 35% white
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = stripeColor
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final diagonalLength = size.width + size.height;
    const step = 7.0;

    canvas.save();
    // Clip to the bar's bounding box
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

    for (double offset = -size.height; offset < diagonalLength; offset += step) {
      canvas.drawLine(
        Offset(offset, 0),
        Offset(offset + size.height, size.height),
        paint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant StripedOverlayPainter oldDelegate) => false;
}

class PillBarChart extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<DaySales> sales;
  final int initialSelectedIndex;

  const PillBarChart({
    super.key,
    this.title = 'Sales this week',
    this.subtitle = 'Daily total in Rs thousands',
    this.initialSelectedIndex = 6, // Today (last day of 7-day window)
    this.sales = const [],
  });

  @override
  State<PillBarChart> createState() => _PillBarChartState();
}

class _PillBarChartState extends State<PillBarChart> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.sales.isEmpty
        ? 0
        : widget.initialSelectedIndex.clamp(0, widget.sales.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    if (widget.sales.isEmpty) {
      return SectionCard(
        title: widget.title,
        subtitle: widget.subtitle,
        child: SizedBox(
          height: 220,
          child: Center(
            child: Text(
              'No sales recorded this week',
              style: TextStyle(
                fontSize: 13,
                color: tokens.colors.muted,
              ),
            ),
          ),
        ),
      );
    }
    final maxAmount = widget.sales.map((s) => s.amountK).fold<double>(0.0, math.max);

    return SectionCard(
      title: widget.title,
      subtitle: widget.subtitle,
      child: SizedBox(
        height: 220,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = math.max(0.0, constraints.maxWidth);
            final count = math.max(1, widget.sales.length);
            final itemWidth = math.max(8.0, math.min(54.0, (availableWidth - (count - 1) * 8) / count));

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(widget.sales.length, (index) {
                final item = widget.sales[index];
                final isSelected = index == _selectedIndex;
                final heightFactor = maxAmount <= 0
                    ? 0.15
                    : (item.amountK / (maxAmount * 1.15)).clamp(0.15, 1.0);

                final String tooltipText = item.amountK <= 0
                    ? '${item.day} · Rs 0'
                    : item.amountK < 1
                        ? '${item.day} · Rs ${(item.amountK * 1000).toInt()}'
                        : '${item.day} · Rs ${item.amountK.toStringAsFixed(1)}k';

                return Expanded(
                  child: Center(
                    child: SizedBox(
                      width: math.max(4.0, itemWidth),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Tooltip for selected bar
                          if (isSelected)
                            Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColorsTokens.tooltipDark, // #05343A
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x33000000),
                                    blurRadius: 8,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Text(
                                tooltipText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  fontFeatures: AppTypographyTokens.tabularFigures,
                                ),
                                maxLines: 1,
                              ),
                            )
                          else
                            const SizedBox(height: 31), // Height spacer equivalent to tooltip
                          // Full-height bar track
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedIndex = index),
                              child: Container(
                                width: itemWidth,
                                decoration: BoxDecoration(
                                  color: tokens.colors.track,
                                  borderRadius: BorderRadius.circular(AppRadiusTokens.pill),
                                ),
                                alignment: Alignment.bottomCenter,
                                child: FractionallySizedBox(
                                  heightFactor: heightFactor,
                                  child: Container(
                                    width: itemWidth,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColorsTokens.brandGradientStart // #0F766E
                                          : item.pastelColor,
                                      borderRadius: BorderRadius.circular(AppRadiusTokens.pill),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(AppRadiusTokens.pill),
                                      child: isSelected
                                          ? null
                                          : CustomPaint(
                                              painter: StripedOverlayPainter(),
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Day label
                          Text(
                            item.day,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? tokens.colors.ink : tokens.colors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}

