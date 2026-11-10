import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/models/report_model.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_data_table.dart';
import '../../../../shared/widgets/metric_tile.dart';
import '../../../../shared/widgets/plan_upgrade_dialog.dart';
import '../../../../shared/widgets/section_card.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/reports_repository.dart';
import '../controllers/reports_controller.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  Future<void> _exportExcel(
      BuildContext context, WidgetRef ref, MonthlyReportModel report) async {
    final pharmacy = ref.read(currentPharmacyProvider).value;
    if (pharmacy == null || !pharmacy.canExportExcelReports) {
      _showEnterpriseExcelDialog(context, ref, report);
      return;
    }

    final repo = ref.read(reportsRepositoryProvider);
    final bytes = repo.exportToExcel(
      report: report,
      pharmacyName: pharmacy.name,
      currency: pharmacy.currency,
    );

    await Share.shareXFiles(
      [
        XFile.fromData(
          bytes,
          name: 'Sales_Report_${report.year}_${report.month}.xlsx',
          mimeType:
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        ),
      ],
      text: 'Monthly Sales Report for ${pharmacy.name}',
    );
  }

  void _showEnterpriseExcelDialog(
      BuildContext context, WidgetRef ref, MonthlyReportModel report) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadiusTokens.largeCard)),
        title: const Row(
          children: [
            Icon(LucideIcons.sparkles, color: Color(0xFF7C3AED), size: 20),
            SizedBox(width: 8),
            Text('Enterprise Feature'),
          ],
        ),
        content: const Text(
          'Downloading raw Excel (.xlsx) spreadsheets is an Enterprise Plan feature.\n\n'
          'You can download and print this report in PDF format on all plans, or upgrade to Enterprise to export raw spreadsheets for custom accounting.',
          style: TextStyle(
              fontSize: 13, height: 1.5, color: Color(0xFF4B6567)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _exportPdf(context, ref, report);
            },
            child: const Text('Export as PDF instead'),
          ),
          AppButton(
            text: 'View Enterprise Plan',
            onPressed: () {
              Navigator.pop(ctx);
              showPlanUpgradeDialog(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _exportPdf(
      BuildContext context, WidgetRef ref, MonthlyReportModel report) async {
    final pharmacy = ref.read(currentPharmacyProvider).value;
    final repo = ref.read(reportsRepositoryProvider);
    await repo.exportToPdfAndPrint(
      report: report,
      pharmacyName: pharmacy?.name ?? 'Pharmacy',
      currency: pharmacy?.currency ?? 'Rs',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final month = ref.watch(selectedReportMonthProvider);
    final year = ref.watch(selectedReportYearProvider);
    final reportAsync = ref.watch(monthlyReportProvider);
    final pharmacy = ref.watch(currentPharmacyProvider).value;
    final currency = pharmacy?.currency ?? 'Rs';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        // Controls Row: Month / Year Picker + Export Buttons
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _pillDropdown<int>(
                  value: month,
                  items: List.generate(12, (i) => i + 1),
                  labelBuilder: (m) => _monthName(m),
                  onChanged: (v) {
                    if (v != null) {
                      ref.read(selectedReportMonthProvider.notifier).state = v;
                    }
                  },
                ),
                const SizedBox(width: 8),
                _pillDropdown<int>(
                  value: year,
                  items: [2024, 2025, 2026, 2027],
                  labelBuilder: (y) => y.toString(),
                  onChanged: (v) {
                    if (v != null) {
                      ref.read(selectedReportYearProvider.notifier).state = v;
                    }
                  },
                ),
              ],
            ),
            reportAsync.maybeWhen(
              data: (rep) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppButton.white(
                    text: 'Excel (.xlsx)',
                    icon: const Icon(LucideIcons.sheet, size: 16),
                    onPressed: () => _exportExcel(context, ref, rep),
                  ),
                  const SizedBox(width: 10),
                  AppButton(
                    text: 'Export PDF',
                    icon: const Icon(LucideIcons.fileText,
                        size: 16, color: Colors.white),
                    onPressed: () => _exportPdf(context, ref, rep),
                  ),
                ],
              ),
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
        const SizedBox(height: 20),

        reportAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(48),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (err, _) => Center(child: Text('Error: $err')),
          data: (report) {
            final marginPct = report.totalSales > 0
                ? (report.totalProfit / report.totalSales * 100)
                : 0.0;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Responsive KPI strip
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    if (width < 500) {
                      return Column(
                        children: [
                          MetricTile(
                            label: 'Gross Sales',
                            value: '$currency ${report.totalSales.toStringAsFixed(0)}',
                            delta: '+14.2%',
                          ),
                          const SizedBox(height: 10),
                          MetricTile(
                            label: 'Net Profit',
                            value: '$currency ${report.totalProfit.toStringAsFixed(0)}',
                            delta: '+18.1%',
                          ),
                          const SizedBox(height: 10),
                          MetricTile(
                            label: 'Invoices Issued',
                            value: report.invoiceCount.toString(),
                            delta: '+8.0%',
                          ),
                          const SizedBox(height: 10),
                          MetricTile(
                            label: 'Profit Margin',
                            value: '${marginPct.toStringAsFixed(1)}%',
                            delta: '+2.4%',
                          ),
                        ],
                      );
                    } else if (width < 900) {
                      return GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 2.3,
                        children: [
                          MetricTile(
                            label: 'Gross Sales',
                            value: '$currency ${report.totalSales.toStringAsFixed(0)}',
                            delta: '+14.2%',
                          ),
                          MetricTile(
                            label: 'Net Profit',
                            value: '$currency ${report.totalProfit.toStringAsFixed(0)}',
                            delta: '+18.1%',
                          ),
                          MetricTile(
                            label: 'Invoices Issued',
                            value: report.invoiceCount.toString(),
                            delta: '+8.0%',
                          ),
                          MetricTile(
                            label: 'Profit Margin',
                            value: '${marginPct.toStringAsFixed(1)}%',
                            delta: '+2.4%',
                          ),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(
                          child: MetricTile(
                            label: 'Gross Sales',
                            value: '$currency ${report.totalSales.toStringAsFixed(0)}',
                            delta: '+14.2%',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: MetricTile(
                            label: 'Net Profit',
                            value: '$currency ${report.totalProfit.toStringAsFixed(0)}',
                            delta: '+18.1%',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: MetricTile(
                            label: 'Invoices Issued',
                            value: report.invoiceCount.toString(),
                            delta: '+8.0%',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: MetricTile(
                            label: 'Profit Margin',
                            value: '${marginPct.toStringAsFixed(1)}%',
                            delta: '+2.4%',
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Daily Revenue Area Chart
                SectionCard(
                  title: 'Daily Sales Performance',
                  subtitle: '${_monthName(month)} $year daily revenue trend',
                  child: SizedBox(
                    height: 220,
                    child: LineChart(
                      LineChartData(
                        minY: 0,
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 5000,
                          getDrawingHorizontalLine: (val) {
                            return FlLine(
                              color:
                                  tokens.colors.muted.withValues(alpha: 0.35),
                              strokeWidth: 1,
                              dashArray: [4, 6],
                            );
                          },
                        ),
                        titlesData: const FlTitlesData(
                          leftTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: report.dailySales.map((d) {
                              return FlSpot(d.day.toDouble(), d.total);
                            }).toList(),
                            isCurved: true,
                            color: AppColorsTokens.brandGradientStart,
                            barWidth: 3.5,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  AppColorsTokens.brandGradientStart
                                      .withValues(alpha: 0.35),
                                  AppColorsTokens.brandGradientStart
                                      .withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Top 10 Medicines Table
                SectionCard(
                  title: 'Top Performing Medicines',
                  subtitle: 'Highest volume & revenue contributors',
                  child: AppDataTable(
                    columns: const [
                      AppTableColumn(label: 'Medicine Name', flex: 4),
                      AppTableColumn(
                          label: 'Units Sold', align: TextAlign.right, flex: 2),
                      AppTableColumn(
                          label: 'Total Revenue',
                          align: TextAlign.right,
                          flex: 3),
                    ],
                    rows: report.topMedicines.take(10).map((m) {
                      return [
                        Text(m.medicineName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 13)),
                        Text(
                          m.totalQuantity.toString(),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              fontFeatures: AppTypographyTokens.tabularFigures),
                        ),
                        Text(
                          '$currency ${m.revenue.toStringAsFixed(2)}',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              fontFeatures: AppTypographyTokens.tabularFigures),
                        ),
                      ];
                    }).toList(),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    ),
    );
  }

  Widget _pillDropdown<T>({
    required T value,
    required List<T> items,
    required String Function(T) labelBuilder,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadiusTokens.pill),
        border: Border.all(color: AppColorsTokens.light.line),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items
              .map((i) => DropdownMenuItem(
                  value: i,
                  child: Text(labelBuilder(i),
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.bold))))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  String _monthName(int m) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[m - 1];
  }
}
