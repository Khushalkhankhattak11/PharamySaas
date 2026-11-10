import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';
import 'metric_tile.dart';
import 'section_card.dart';

class AreaChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String revenue;
  final String revenueDelta;
  final String profit;
  final String profitDelta;
  final String purchases;
  final String purchasesDelta;
  final String invoices;
  final String invoicesDelta;
  final List<FlSpot> spots;
  final List<String> monthLabels;
  final int highlightedIndex;
  final Widget? trailing;

  const AreaChartCard({
    super.key,
    this.title = 'Monthly revenue',
    this.subtitle = 'Revenue, profit and purchases overview',
    this.revenue = 'Rs 428,500',
    this.revenueDelta = '+18.4%',
    this.profit = 'Rs 124,200',
    this.profitDelta = '+12.1%',
    this.purchases = 'Rs 304,300',
    this.purchasesDelta = '+8.5%',
    this.invoices = '1,420',
    this.invoicesDelta = '+5.2%',
    required this.spots,
    required this.monthLabels,
    this.highlightedIndex = 4,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final chartAccent = tokens.colors.accent;

    return SectionCard(
      title: title,
      subtitle: subtitle,
      trailing: trailing ??
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: tokens.colors.card,
              borderRadius: BorderRadius.circular(AppRadiusTokens.pill),
              border: Border.all(color: tokens.colors.line, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Last 6 months',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: tokens.colors.ink,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down, size: 16, color: tokens.colors.muted),
              ],
            ),
          ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 4-column metric tile strip
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 520;
              if (isNarrow) {
                return GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2.1,
                  children: [
                    MetricTile(label: 'Revenue', value: revenue, delta: revenueDelta),
                    MetricTile(label: 'Profit', value: profit, delta: profitDelta),
                    MetricTile(label: 'Purchases', value: purchases, delta: purchasesDelta),
                    MetricTile(label: 'Invoices', value: invoices, delta: invoicesDelta),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: MetricTile(label: 'Revenue', value: revenue, delta: revenueDelta)),
                  const SizedBox(width: 10),
                  Expanded(child: MetricTile(label: 'Profit', value: profit, delta: profitDelta)),
                  const SizedBox(width: 10),
                  Expanded(child: MetricTile(label: 'Purchases', value: purchases, delta: purchasesDelta)),
                  const SizedBox(width: 10),
                  Expanded(child: MetricTile(label: 'Invoices', value: invoices, delta: invoicesDelta)),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Builder(
            builder: (context) {
              final double calculatedMaxY = spots.isEmpty
                  ? 50.0
                  : spots.map((s) => s.y).fold<double>(0.0, math.max);
              final double safeMaxY = calculatedMaxY <= 0 ? 50.0 : calculatedMaxY * 1.25;

              return SizedBox(
                height: 220,
                child: LineChart(
                  LineChartData(
                    minY: 0,
                    maxY: safeMaxY,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: safeMaxY / 4,
                      getDrawingHorizontalLine: (val) {
                        return FlLine(
                          color: tokens.colors.muted.withValues(alpha: 0.35),
                          strokeWidth: 1,
                          dashArray: [4, 6],
                        );
                      },
                    ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 1,
                      getTitlesWidget: (val, meta) {
                        final idx = val.toInt();
                        if (idx >= 0 && idx < monthLabels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              monthLabels[idx],
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: tokens.colors.muted,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => tokens.colors.tooltipBg,
                    tooltipRoundedRadius: 10,
                    tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          'Rs ${spot.y.toInt()}k',
                          TextStyle(
                            color: tokens.colors.tooltipText,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            fontFeatures: AppTypographyTokens.tabularFigures,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: chartAccent,
                    barWidth: 3.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      checkToShowDot: (spot, barData) {
                        return spot.x.toInt() == highlightedIndex;
                      },
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 7,
                          color: tokens.colors.card,
                          strokeWidth: 3.5,
                          strokeColor: chartAccent,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          chartAccent.withValues(alpha: 0.38),
                          chartAccent.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ],
  ),
);
  }
}

