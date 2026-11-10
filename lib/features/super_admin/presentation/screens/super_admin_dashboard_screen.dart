import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pharmcysas/shared/widgets/hero_banner.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/models/pharmacy_model.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_data_table.dart';
import '../../../../shared/widgets/donut_chart_card.dart';
import '../../../../shared/widgets/kpi_card.dart';
import '../../../../shared/widgets/section_card.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../controllers/super_admin_controller.dart';

class SuperAdminDashboardScreen extends ConsumerWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(platformStatsProvider);
    final pendingAsync = ref.watch(pendingApprovalsProvider);
    final screenWidth = MediaQuery.of(context).size.width;

    return statsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(48.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(48.0),
          child: Text('Error loading stats: $err'),
        ),
      ),
      data: (stats) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Hero
            HeroBanner(
              title: 'Platform Overview 🚀',
              subtitle:
                  'Managing ${stats.totalPharmacies} registered pharmacies across the SaaS network. ${stats.pendingPharmacies} require verification.',
              statusText: 'All clusters operational',
              primaryButtonText: 'Review Pending',
              onPrimaryAction: () => context.go('/super-admin/approvals'),
              secondaryButtonText: 'All Pharmacies',
              onSecondaryAction: () => context.go('/super-admin/pharmacies'),
              inlineMetricText: '${stats.activeUsers} active staff',
            ),
            const SizedBox(height: 20),

            // 2. Pastel KPI Cards
            _buildKpiGrid(context, stats, screenWidth),
            const SizedBox(height: 20),

            // 3. Row with Donut of pharmacies by status and Recent pending approvals
            _buildStatusAndApprovalsRow(
                context, ref, stats, pendingAsync, screenWidth),
          ],
        );
      },
    );
  }

  Widget _buildKpiGrid(
      BuildContext context, dynamic stats, double screenWidth) {
    final cards = [
      KpiCard.pastel(
        label: 'Total Pharmacies',
        value: stats.totalPharmacies.toString(),
        badgeText: 'All Tenants',
        icon: LucideIcons.building,
        pastelColor: AppColorsTokens.lime,
        sparklineData: const [4, 6, 8, 12, 14, 18, 22],
        onTap: () => context.go('/super-admin/pharmacies'),
      ),
      KpiCard(
        label: 'Pending Approvals',
        value: stats.pendingPharmacies.toString(),
        badgeText: 'Review',
        icon: LucideIcons.clock,
        accentColor: AppColorsTokens.amber,
        badgeTextColor: AppColorsTokens.amberText,
        sparklineData: const [2, 3, 2, 4, 3, 5, 4],
        onTap: () => context.go('/super-admin/approvals'),
      ),
      KpiCard.pastel(
        label: 'Approved Active',
        value: stats.approvedPharmacies.toString(),
        badgeText: 'Verified',
        icon: LucideIcons.checkCircle2,
        pastelColor: AppColorsTokens.mint,
        sparklineData: const [5, 8, 10, 14, 16, 20, 24],
        onTap: () => context.go('/super-admin/pharmacies'),
      ),
      KpiCard(
        label: 'Platform Sales',
        value: 'Rs ${(stats.totalSalesVolume / 1000).toStringAsFixed(0)}k',
        badgeText: 'Gross',
        icon: LucideIcons.trendingUp,
        accentColor: AppColorsTokens.info,
        sparklineData: const [20, 24, 28, 35, 42, 50, 64],
        onTap: () => context.go('/super-admin/pharmacies'),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        if (totalWidth <= 0) return const SizedBox.shrink();

        int effectiveCols = 4;
        if (totalWidth < 600) {
          effectiveCols = 1;
        } else if (totalWidth < 900) {
          effectiveCols = 2;
        } else if (totalWidth < 1200) {
          effectiveCols = 3;
        }

        const spacing = 16.0;
        final totalSpacing = (effectiveCols - 1) * spacing;
        final availableWidth =
            (totalWidth - totalSpacing).clamp(0.0, double.infinity);
        final cardWidth = effectiveCols > 0
            ? (availableWidth / effectiveCols).clamp(1.0, double.infinity)
            : totalWidth;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards.map((c) {
            return SizedBox(
              width: cardWidth,
              child: c,
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildStatusAndApprovalsRow(
    BuildContext context,
    WidgetRef ref,
    dynamic stats,
    AsyncValue<List<PharmacyModel>> pendingAsync,
    double screenWidth,
  ) {
    final donut = DonutChartCard(
      title: 'Pharmacies by status',
      subtitle: 'Tenant compliance & health',
      totalUnits: stats.totalPharmacies.toString(),
      categories: [
        CategoryShare(
          name: 'Approved',
          percentage: stats.totalPharmacies > 0
              ? (stats.approvedPharmacies / stats.totalPharmacies * 100)
              : 80,
          color: const Color(0xFF0F766E),
        ),
        CategoryShare(
          name: 'Pending',
          percentage: stats.totalPharmacies > 0
              ? (stats.pendingPharmacies / stats.totalPharmacies * 100)
              : 15,
          color: AppColorsTokens.amber,
        ),
        const CategoryShare(
          name: 'Suspended',
          percentage: 5,
          color: AppColorsTokens.orange,
        ),
      ],
    );

    final pendingList = pendingAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error: $e'),
      data: (pharmacies) {
        if (pharmacies.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text(
                'No pending approvals! All pharmacies are verified.',
                style: TextStyle(color: Color(0xFF4B6567)),
              ),
            ),
          );
        }

        const columns = [
          AppTableColumn(label: 'Pharmacy', flex: 3),
          AppTableColumn(label: 'City', flex: 2),
          AppTableColumn(label: 'License', flex: 2),
          AppTableColumn(label: 'Status', flex: 2),
          AppTableColumn(label: 'Action', align: TextAlign.right, flex: 2),
        ];

        final rows = pharmacies.take(4).map((p) {
          return [
            Text(p.name,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            Text(p.city ?? '—',
                style: const TextStyle(fontSize: 13),
                overflow: TextOverflow.ellipsis),
            Text(p.licenseNo ?? '—',
                style: const TextStyle(fontSize: 13),
                overflow: TextOverflow.ellipsis),
            const StatusBadge(
                label: 'Pending', variant: StatusBadgeVariant.amber),
            Align(
              alignment: Alignment.centerRight,
              child: AppButton.white(
                text: 'Review',
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                height: 32,
                onPressed: () => context.go('/super-admin/approvals'),
              ),
            ),
          ];
        }).toList();

        final mobileCards = pharmacies.take(4).map((p) {
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
                        p.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${p.city ?? 'Unknown'} • ${p.licenseNo ?? 'No license'}',
                        style: TextStyle(
                            fontSize: 11, color: context.tokens.colors.muted),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AppButton.white(
                  text: 'Review',
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  height: 30,
                  onPressed: () => context.go('/super-admin/approvals'),
                ),
              ],
            ),
          );
        }).toList();

        return AppDataTable(
            columns: columns, rows: rows, mobileCards: mobileCards);
      },
    );

    final approvalsCard = SectionCard(
      title: 'Pending Verification Queue',
      subtitle: 'Pharmacies awaiting official approval',
      trailing: AppButton.ghost(
        text: 'View Queue',
        onPressed: () => context.go('/super-admin/approvals'),
      ),
      child: pendingList,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 900) {
          return Column(
            children: [
              donut,
              const SizedBox(height: 20),
              approvalsCard,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 10, child: donut),
            const SizedBox(width: 16),
            Expanded(flex: 16, child: approvalsCard),
          ],
        );
      },
    );
  }
}
