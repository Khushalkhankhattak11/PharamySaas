import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_data_table.dart';
import '../../../../shared/widgets/app_search_field.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_skeleton.dart';
import '../../../../shared/widgets/section_card.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../qr/presentation/widgets/universal_scanner_dialog.dart';
import '../../data/inventory_repository.dart';
import '../controllers/inventory_controller.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleScan() async {
    final scannedCode = await UniversalScannerDialog.show(
      context,
      title: 'Scan Medicine QR or Barcode',
    );

    if (scannedCode == null || scannedCode.isEmpty) return;

    try {
      final repo = ref.read(inventoryRepositoryProvider);
      final lookup = await repo.lookupByCode(scannedCode);

      if (!mounted) return;

      if (lookup['found'] == true) {
        final medId = lookup['medicine_id'] as String;
        context.push('/inventory/$medId');
      } else {
        final profile = ref.read(currentProfileProvider).value;
        final canAdd = profile?.role.canAddMedicine ?? false;

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadiusTokens.largeCard)),
            title: const Text('Unknown Barcode / Code'),
            content: Text(
              canAdd
                  ? 'Code "$scannedCode" does not match any medicine in your database.\n\nWould you like to register a new medicine with this barcode?'
                  : 'Code "$scannedCode" was not found in the pharmacy inventory. Please inform the storekeeper to register it.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(canAdd ? 'Cancel' : 'Close'),
              ),
              if (canAdd)
                AppButton(
                  text: 'Create New Medicine',
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.push('/inventory/add?barcode=$scannedCode');
                  },
                ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lookup error: $e'), backgroundColor: AppColorsTokens.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final currentFilter = ref.watch(inventoryFilterProvider);
    final medicinesAsync = ref.watch(medicinesListProvider);
    final pharmacy = ref.watch(currentPharmacyProvider).value;
    final currency = pharmacy?.currency ?? 'Rs';
    final profile = ref.watch(currentProfileProvider).value;
    final canAddMedicine = profile?.role.canAddMedicine ?? false;
    final canEditMedicine = profile?.role.canEditMedicine ?? false;

    final filterOptions = [
      {'label': 'All Medicines', 'id': 'all'},
      {'label': 'Low Stock', 'id': 'low_stock'},
      {'label': 'Expiring Soon (<=90d)', 'id': 'expiring'},
      {'label': 'Expired', 'id': 'expired'},
      {'label': 'Inactive', 'id': 'inactive'},
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        // Controls Row: Search + Scan + Add Button
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 540;

            if (isNarrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppSearchField(
                    controller: _searchController,
                    maxWidth: double.infinity,
                    placeholder: 'Search by name, generic, barcode or QR...',
                    onChanged: (val) {
                      ref.read(inventorySearchProvider.notifier).state = val;
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton.white(
                          text: 'Scan Barcode',
                          icon: const Icon(LucideIcons.scanLine, size: 16),
                          onPressed: _handleScan,
                        ),
                      ),
                      if (canAddMedicine) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: AppButton(
                            text: '+ Add Medicine',
                            onPressed: () => context.push('/inventory/add'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              );
            }

            return Row(
              children: [
                Expanded(
                  child: AppSearchField(
                    controller: _searchController,
                    maxWidth: double.infinity,
                    placeholder: 'Search by name, generic, barcode or QR...',
                    onChanged: (val) {
                      ref.read(inventorySearchProvider.notifier).state = val;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                AppButton.white(
                  text: 'Scan',
                  icon: const Icon(LucideIcons.scanLine, size: 16),
                  onPressed: _handleScan,
                ),
                if (canAddMedicine) ...[
                  const SizedBox(width: 10),
                  AppButton(
                    text: '+ Add Medicine',
                    onPressed: () => context.push('/inventory/add'),
                  ),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 16),

        // Filter chips (pills)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: filterOptions.map((opt) {
              final id = opt['id']!;
              final label = opt['label']!;
              final isSelected = currentFilter == id;

              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: GestureDetector(
                  onTap: () => ref.read(inventoryFilterProvider.notifier).state = id,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      gradient: isSelected ? AppColorsTokens.brandGradient : null,
                      color: isSelected ? null : tokens.colors.card,
                      borderRadius: BorderRadius.circular(AppRadiusTokens.pill),
                      border: Border.all(
                        color: isSelected ? Colors.transparent : tokens.colors.line,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : tokens.colors.ink,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),

        // Table Card
        medicinesAsync.when(
          loading: () => LoadingSkeleton.tableRows(context: context, rows: 7),
          error: (err, _) => Center(child: Text('Error: $err')),
          data: (medicines) {
            if (medicines.isEmpty) {
              return EmptyState(
                title: 'No Medicines Found',
                subtitle: 'Try changing your search term or filter criteria.',
                icon: LucideIcons.package,
                actionLabel: canAddMedicine ? 'Add New Medicine' : null,
                onAction: canAddMedicine ? () => context.push('/inventory/add') : null,
              );
            }

            final columns = [
              const AppTableColumn(label: 'Medicine', flex: 3),
              const AppTableColumn(label: 'Category', flex: 2),
              const AppTableColumn(label: 'Stock Level', flex: 2),
              const AppTableColumn(label: 'Sale Price', align: TextAlign.right, flex: 2),
              const AppTableColumn(label: 'Status', flex: 2),
              AppTableColumn(
                label: canEditMedicine ? 'Action' : 'View',
                align: TextAlign.right,
                flex: 2,
              ),
            ];

            final rows = medicines.map((m) {
              StatusBadgeVariant badgeVariant = StatusBadgeVariant.success;
              String badgeLabel = 'Safe';

              if (m.availableStock <= 0) {
                badgeVariant = StatusBadgeVariant.danger;
                badgeLabel = 'Out of Stock';
              } else if (m.isLowStock) {
                badgeVariant = StatusBadgeVariant.amber;
                badgeLabel = 'Low Stock';
              }

              return [
                InkWell(
                  onTap: () => context.push('/inventory/${m.id}'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        m.name,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      if (m.genericName != null)
                        Text(
                          m.genericName!,
                          style: TextStyle(fontSize: 11, color: tokens.colors.muted),
                        ),
                    ],
                  ),
                ),
                Text(m.category ?? 'General', style: const TextStyle(fontSize: 13)),
                Text(
                  '${m.availableStock} ${m.unit}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFeatures: AppTypographyTokens.tabularFigures,
                  ),
                ),
                Text(
                  '$currency ${m.salePrice.toStringAsFixed(2)}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    fontFeatures: AppTypographyTokens.tabularFigures,
                  ),
                ),
                StatusBadge(label: badgeLabel, variant: badgeVariant),
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(LucideIcons.eye, size: 16),
                        color: tokens.colors.muted,
                        tooltip: 'View Details',
                        onPressed: () => context.push('/inventory/${m.id}'),
                      ),
                      if (canEditMedicine)
                        IconButton(
                          icon: const Icon(LucideIcons.edit2, size: 16),
                          color: tokens.colors.muted,
                          tooltip: 'Edit Details',
                          onPressed: () => context.push('/inventory/${m.id}/edit'),
                        ),
                    ],
                  ),
                ),
              ];
            }).toList();

            final mobileCards = medicines.map((m) {
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: tokens.colors.card,
                  borderRadius: BorderRadius.circular(AppRadiusTokens.tile),
                  border: Border.all(color: tokens.colors.line),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('${m.availableStock} ${m.unit} in stock • $currency ${m.salePrice.toStringAsFixed(2)}', style: TextStyle(fontSize: 12, color: tokens.colors.muted)),
                        ],
                      ),
                    ),
                    AppButton.white(
                      text: 'View',
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      height: 32,
                      onPressed: () => context.push('/inventory/${m.id}'),
                    ),
                  ],
                ),
              );
            }).toList();

            return SectionCard(
              title: 'Medicine Catalog',
              subtitle: canAddMedicine
                  ? 'Showing ${medicines.length} registered items'
                  : 'Showing ${medicines.length} items (Read-Only Mode for Cashier)',
              child: AppDataTable(
                columns: columns,
                rows: rows,
                mobileCards: mobileCards,
              ),
            );
          },
        ),
      ],
    ),
    );
  }
}
