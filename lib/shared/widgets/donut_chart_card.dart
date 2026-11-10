import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';
import 'section_card.dart';

class CategoryShare {
  final String name;
  final double percentage;
  final Color color;

  const CategoryShare({
    required this.name,
    required this.percentage,
    required this.color,
  });
}

class DonutChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String totalUnits;
  final List<CategoryShare> categories;

  const DonutChartCard({
    super.key,
    this.title = 'Stock by category',
    this.subtitle = 'Share of units on hand',
    this.totalUnits = '0',
    this.categories = const [],
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final hasData = categories.isNotEmpty && categories.any((c) => c.percentage > 0);

    // 170px outer diameter (radius 85), 112px hole diameter (hole radius 56), so section radius = 85 - 56 = 29
    const outerRadius = 85.0;
    const holeRadius = 56.0;
    const sectionWidth = outerRadius - holeRadius; // 29px

    return SectionCard(
      title: title,
      subtitle: subtitle,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isStacked = constraints.maxWidth < 340;

          final donutWidget = SizedBox(
            width: 170,
            height: 170,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: hasData ? 2 : 0,
                    centerSpaceRadius: holeRadius,
                    startDegreeOffset: -90,
                    sections: hasData
                        ? categories.map((cat) {
                            return PieChartSectionData(
                              color: cat.color,
                              value: cat.percentage,
                              showTitle: false,
                              radius: sectionWidth,
                            );
                          }).toList()
                        : [
                            PieChartSectionData(
                              color: tokens.colors.line.withValues(alpha: 0.6),
                              value: 100,
                              showTitle: false,
                              radius: sectionWidth,
                            ),
                          ],
                  ),
                ),
                // Center text
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      totalUnits,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: tokens.colors.ink,
                        fontFeatures: AppTypographyTokens.tabularFigures,
                      ),
                    ),
                    Text(
                      'units',
                      style: TextStyle(
                        fontSize: 12,
                        color: tokens.colors.muted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );

          final legendWidget = hasData
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: categories.map((cat) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.5),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: cat.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              cat.name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: tokens.colors.ink,
                              ),
                            ),
                          ),
                          Text(
                            '${cat.percentage.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: tokens.colors.muted,
                              fontFeatures: AppTypographyTokens.tabularFigures,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                )
              : Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Text(
                      'No medicines in inventory yet',
                      style: TextStyle(
                        fontSize: 13,
                        color: tokens.colors.muted,
                      ),
                    ),
                  ),
                );

          if (isStacked) {
            return Column(
              children: [
                Center(child: donutWidget),
                const SizedBox(height: 20),
                legendWidget,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              donutWidget,
              const SizedBox(width: 20),
              Expanded(child: legendWidget),
            ],
          );
        },
      ),
    );
  }
}
