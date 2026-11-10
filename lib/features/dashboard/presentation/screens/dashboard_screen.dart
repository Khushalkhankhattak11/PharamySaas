import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/models/dashboard_summary_model.dart';
import '../../../../shared/models/sale_model.dart';
import '../../../../shared/widgets/alert_row.dart';
import '../../../../shared/widgets/app_data_table.dart';
import '../../../../shared/widgets/area_chart_card.dart';
import '../../../../shared/widgets/donut_chart_card.dart';
import '../../../../shared/widgets/hero_banner.dart';
import '../../../../shared/widgets/kpi_card.dart';
import '../../../../shared/widgets/loading_skeleton.dart';
import '../../../../shared/widgets/pill_bar_chart.dart';
import '../../../../shared/widgets/section_card.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../inventory/presentation/controllers/inventory_controller.dart';
import '../../../pos/presentation/controllers/shift_controller.dart';
import '../controllers/dashboard_controller.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final profile = profileAsync.value;

    // Prevent flashing Admin Dashboard for SuperAdmin or while profile is loading
    if (profileAsync.isLoading || profile?.role.isSuperAdmin == true) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final pharmacy = ref.watch(currentPharmacyProvider).value;
    final currency = pharmacy?.currency ?? 'Rs';
    final screenWidth = MediaQuery.of(context).size.width;

    return summaryAsync.when(
      loading: () => LoadingSkeleton.dashboardSkeleton(context: context),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(48.0),
          child: Text('Failed to load dashboard: $err'),
        ),
      ),
      data: (summary) {
        final lowStock = summary.lowStockCount;
        final expiringSoon = summary.expiringSoonCount;
        final totalInvoicesToday = summary.todayInvoices;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. HERO BANNER
            HeroBanner(
              title: 'Good morning, ${profile?.fullName ?? 'Owner'} 👋',
              subtitle: summary.totalMedicines == 0 && summary.totalRevenue == 0
                  ? 'Welcome to your pharmacy workspace. Get started by adding medicines to your inventory or recording purchases.'
                  : 'You have $lowStock medicines running low and $expiringSoon batches expiring within 90 days. Review them before peak hours.',
              statusText: 'All systems running',
              primaryButtonText: 'Generate report',
              onPrimaryAction: () => context.go('/reports'),
              secondaryButtonText: '+ Add medicine',
              onSecondaryAction: () => context.push('/inventory/add'),
              inlineMetricText: '$totalInvoicesToday sales today',
            ),
            const SizedBox(height: 16),

            // Active Counter Register Banner
            _buildActiveRegisterBanner(context, ref, currency),
            const SizedBox(height: 4),

            // 2. KPI ROW (6 cards in grid)
            _buildKpiGrid(
              context: context,
              ref: ref,
              screenWidth: screenWidth,
              currency: currency,
              summary: summary,
            ),
            const SizedBox(height: 20),

            // 3. ROW A (Monthly revenue 1.7fr / Stock by category 1fr)
            _buildRowA(context, screenWidth, currency, summary),
            const SizedBox(height: 20),

            // 4. ROW B (Needs attention 1fr / Sales this week 1.4fr)
            _buildRowB(context, ref, screenWidth, summary),
            const SizedBox(height: 20),

            // 5. RECENT SALES CARD
            _buildRecentSalesCard(context, summary.recentSales, currency),
          ],
        );
      },
    );
  }

  Widget _buildKpiGrid({
    required BuildContext context,
    required WidgetRef ref,
    required double screenWidth,
    required String currency,
    required DashboardSummaryModel summary,
  }) {
    final revenueSparkline = summary.monthlySpots.isNotEmpty
        ? summary.monthlySpots.map((s) => s.y).toList()
        : const [0.0, 0.0, 0.0, 0.0, 0.0, 0.0];

    final weekSparkline = summary.weekSales.isNotEmpty
        ? summary.weekSales.map((w) => w.amountK).toList()
        : const [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];

    final cards = [
      KpiCard(
        label: 'Total revenue',
        value: '$currency ${summary.todaySales.toStringAsFixed(0)}',
        badgeText: summary.todaySales > 0 ? '+100%' : 'Today',
        icon: LucideIcons.trendingUp,
        accentColor: AppColorsTokens.info, // #2563EB
        sparklineData: revenueSparkline,
        onTap: () => context.go('/sales-history'),
      ),
      KpiCard.pastel(
        label: 'Medicines',
        value: summary.totalMedicines.toString(),
        badgeText: '${summary.totalUnitsInStock} units',
        icon: LucideIcons.pill,
        pastelColor: AppColorsTokens.lime,
        sparklineData: [
          (summary.totalMedicines * 0.8),
          (summary.totalMedicines * 0.9),
          summary.totalMedicines.toDouble(),
        ],
        onTap: () => context.go('/inventory'),
      ),
      KpiCard.pastel(
        label: 'Sales today',
        value: summary.todayInvoices.toString(),
        badgeText: summary.todayInvoices > 0
            ? '${summary.todayInvoices} bills'
            : 'No sales',
        icon: LucideIcons.shoppingBag,
        pastelColor: AppColorsTokens.mint,
        sparklineData: weekSparkline,
        onTap: () => context.go('/sales-history'),
      ),
      KpiCard(
        label: 'Low stock',
        value: summary.lowStockCount.toString(),
        badgeText: summary.lowStockCount > 0 ? 'Check' : 'Optimal',
        icon: LucideIcons.alertTriangle,
        accentColor: summary.lowStockCount > 0
            ? AppColorsTokens.amber
            : AppColorsTokens.trendGreenText,
        badgeTextColor: summary.lowStockCount > 0
            ? AppColorsTokens.amberText
            : AppColorsTokens.trendGreenText,
        sparklineData: [
          summary.lowStockCount.toDouble(),
          summary.lowStockCount.toDouble()
        ],
        onTap: () {
          ref.read(inventoryFilterProvider.notifier).state = 'low_stock';
          context.go('/inventory');
        },
      ),
      KpiCard(
        label: 'Expiring soon',
        value: summary.expiringSoonCount.toString(),
        badgeText: summary.expiringSoonCount > 0 ? '90 days' : 'None',
        icon: LucideIcons.clock,
        accentColor: summary.expiringSoonCount > 0
            ? AppColorsTokens.orange
            : AppColorsTokens.trendGreenText,
        badgeTextColor: summary.expiringSoonCount > 0
            ? AppColorsTokens.orangeText
            : AppColorsTokens.trendGreenText,
        sparklineData: [
          summary.expiringSoonCount.toDouble(),
          summary.expiringSoonCount.toDouble()
        ],
        onTap: () {
          ref.read(inventoryFilterProvider.notifier).state = 'expiring';
          context.go('/inventory');
        },
      ),
      KpiCard(
        label: 'Expired',
        value: summary.expiredCount.toString(),
        badgeText: summary.expiredCount > 0 ? 'Disposal' : 'Zero',
        icon: LucideIcons.trash2,
        accentColor: summary.expiredCount > 0
            ? AppColorsTokens.danger
            : AppColorsTokens.trendGreenText,
        badgeTextColor: summary.expiredCount > 0
            ? AppColorsTokens.danger
            : AppColorsTokens.trendGreenText,
        sparklineData: [
          summary.expiredCount.toDouble(),
          summary.expiredCount.toDouble()
        ],
        onTap: () {
          ref.read(inventoryFilterProvider.notifier).state = 'expired';
          context.go('/inventory');
        },
      ),
    ];

    // Responsive adaptive card grid based on parent container constraints
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        int crossAxisCount;
        if (availableWidth >= 1150) {
          crossAxisCount = 6;
        } else if (availableWidth >= 780) {
          crossAxisCount = 3;
        } else if (availableWidth >= 480) {
          crossAxisCount = 2;
        } else {
          crossAxisCount = 1;
        }

        const spacing = 12.0;
        final totalSpacing = spacing * (crossAxisCount - 1);
        final cardWidth = (availableWidth - totalSpacing) / crossAxisCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards.map((card) {
            return SizedBox(
              width: cardWidth,
              child: card,
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildRowA(
    BuildContext context,
    double screenWidth,
    String currency,
    DashboardSummaryModel summary,
  ) {
    final spots = summary.monthlySpots.isNotEmpty
        ? summary.monthlySpots
        : List.generate(6, (i) => FlSpot(i.toDouble(), 0));

    final monthLabels = summary.monthLabels.isNotEmpty
        ? summary.monthLabels
        : const ['M-5', 'M-4', 'M-3', 'M-2', 'M-1', 'Now'];

    final areaChart = AreaChartCard(
      title: 'Monthly revenue',
      subtitle: 'Revenue, profit and purchases overview',
      revenue: '$currency ${summary.totalRevenue.toStringAsFixed(0)}',
      revenueDelta: summary.totalRevenue > 0 ? '+100%' : '0%',
      profit: '$currency ${summary.totalProfit.toStringAsFixed(0)}',
      profitDelta: summary.totalProfit > 0 ? '+100%' : '0%',
      purchases: '$currency ${summary.totalPurchases.toStringAsFixed(0)}',
      purchasesDelta: summary.totalPurchases > 0 ? '+100%' : '0%',
      invoices: summary.totalInvoices.toString(),
      invoicesDelta: summary.totalInvoices > 0 ? '+100%' : '0%',
      spots: spots,
      monthLabels: monthLabels,
      highlightedIndex: summary.currentMonthIndex,
    );

    final donutChart = DonutChartCard(
      title: 'Stock by category',
      subtitle: 'Share of units on hand',
      totalUnits: summary.totalUnitsInStock.toString(),
      categories: summary.categoryShares,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 900) {
          return Column(
            children: [
              areaChart,
              const SizedBox(height: 20),
              donutChart,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 17, child: areaChart),
            const SizedBox(width: 16),
            Expanded(flex: 10, child: donutChart),
          ],
        );
      },
    );
  }

  Widget _buildRowB(
    BuildContext context,
    WidgetRef ref,
    double screenWidth,
    DashboardSummaryModel summary,
  ) {
    final needsAttention = SectionCard(
      title: 'Needs attention',
      subtitle: 'Real-time inventory alerts',
      child: Column(
        children: [
          AlertRow.lowStock(
            count: summary.lowStockCount,
            onTap: () {
              ref.read(inventoryFilterProvider.notifier).state = 'low_stock';
              context.go('/inventory');
            },
          ),
          const SizedBox(height: 10),
          AlertRow.expiringSoon(
            count: summary.expiringSoonCount,
            onTap: () {
              ref.read(inventoryFilterProvider.notifier).state = 'expiring';
              context.go('/inventory');
            },
          ),
          const SizedBox(height: 10),
          AlertRow.expired(
            count: summary.expiredCount,
            onTap: () {
              ref.read(inventoryFilterProvider.notifier).state = 'expired';
              context.go('/inventory');
            },
          ),
        ],
      ),
    );

    final pillBarChart = PillBarChart(
      title: 'Sales this week',
      subtitle: 'Daily total in Rs thousands',
      sales: summary.weekSales,
      initialSelectedIndex:
          summary.weekSales.isNotEmpty ? summary.weekSales.length - 1 : 0,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 900) {
          return Column(
            children: [
              needsAttention,
              const SizedBox(height: 20),
              pillBarChart,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 10, child: needsAttention),
            const SizedBox(width: 16),
            Expanded(flex: 14, child: pillBarChart),
          ],
        );
      },
    );
  }

  Widget _buildRecentSalesCard(
    BuildContext context,
    List<SaleModel> sales,
    String currency,
  ) {
    final tokens = context.tokens;

    if (sales.isEmpty) {
      return SectionCard(
        title: 'Recent sales',
        subtitle: 'Latest invoices from your cashiers',
        trailing: TextButton.icon(
          onPressed: () => context.go('/sales-history'),
          icon: const Icon(LucideIcons.arrowUpRight, size: 16),
          label: const Text('All sales'),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: tokens.colors.track,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.shoppingBag,
                    size: 32,
                    color: tokens.colors.muted,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'No sales recorded yet',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: tokens.colors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Once cashiers record transactions at the POS counter, they will show up here live.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: tokens.colors.muted,
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => context.go('/pos'),
                  icon: const Icon(LucideIcons.plusCircle, size: 16),
                  label: const Text('Open POS Terminal'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Columns: Invoice, Medicine, Cashier, Payment, Qty, Total
    const columns = [
      AppTableColumn(label: 'Invoice', flex: 2),
      AppTableColumn(label: 'Medicine', flex: 3),
      AppTableColumn(label: 'Cashier', flex: 2),
      AppTableColumn(label: 'Payment', flex: 2),
      AppTableColumn(label: 'Qty', align: TextAlign.right, flex: 1),
      AppTableColumn(label: 'Total', align: TextAlign.right, flex: 2),
    ];

    final tableRows = sales.map((s) {
      final invoice = '#INV-${s.invoiceNo}';
      final medicine = s.items.isNotEmpty
          ? s.items.first.medicineName
          : 'Prescription Item';
      final cashier = s.cashierName ?? 'Cashier';
      final payment = s.paymentMethod;
      final qty = s.items.isNotEmpty ? s.items.first.quantity.toString() : '1';
      final total = '$currency ${s.total.toStringAsFixed(2)}';

      final isCard = payment.toLowerCase().contains('card');

      return [
        Text(
          invoice,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        Text(
          medicine,
          style: const TextStyle(fontSize: 13),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          cashier,
          style: const TextStyle(fontSize: 13),
        ),
        StatusBadge(
          label: payment,
          variant:
              isCard ? StatusBadgeVariant.info : StatusBadgeVariant.success,
        ),
        Text(
          qty,
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            fontFeatures: AppTypographyTokens.tabularFigures,
          ),
        ),
        Text(
          total,
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            fontFeatures: AppTypographyTokens.tabularFigures,
          ),
        ),
      ];
    }).toList();

    final mobileCards = sales.map((s) {
      final invoice = '#INV-${s.invoiceNo}';
      final medicine = s.items.isNotEmpty
          ? s.items.first.medicineName
          : 'Prescription Item';
      final total = '$currency ${s.total.toStringAsFixed(2)}';
      final payment = s.paymentMethod;

      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.tokens.colors.card,
          borderRadius: BorderRadius.circular(AppRadiusTokens.tile),
          border: Border.all(color: context.tokens.colors.line),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    medicine,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text('$invoice • $payment',
                      style: TextStyle(
                          fontSize: 11, color: context.tokens.colors.muted)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              total,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: AppColorsTokens.brand,
              ),
            ),
          ],
        ),
      );
    }).toList();

    return SectionCard(
      title: 'Recent sales',
      subtitle: 'Latest invoices from your cashiers',
      trailing: TextButton.icon(
        onPressed: () => context.go('/sales-history'),
        icon: const Icon(LucideIcons.arrowUpRight, size: 16),
        label: const Text('All sales'),
      ),
      child: AppDataTable(
        columns: columns,
        rows: tableRows,
        mobileCards: mobileCards,
      ),
    );
  }

  Widget _buildActiveRegisterBanner(BuildContext context, WidgetRef ref, String currency) {
    final shiftsAsync = ref.watch(pharmacyShiftsStreamProvider);
    return shiftsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (shifts) {
        final openShifts = shifts.where((s) => s.isOpen).toList();
        if (openShifts.isEmpty) return const SizedBox.shrink();

        final shift = openShifts.first;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColorsTokens.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Counter Register Live: ${shift.cashierName} • Starting Float: $currency ${shift.openingCash.toStringAsFixed(0)} • In Drawer: $currency ${shift.expectedClosingCash.toStringAsFixed(0)} • Online Payments (EasyPaisa/Jazz/Card): $currency ${shift.totalOnlineSales.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF166534),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              TextButton.icon(
                onPressed: () => context.go('/staff'),
                icon: const Icon(LucideIcons.arrowRight, size: 14),
                label: const Text('Staff Progress'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF166534),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
