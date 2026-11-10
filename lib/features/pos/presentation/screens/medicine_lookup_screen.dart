import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/models/medicine_model.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_data_table.dart';
import '../../../../shared/widgets/app_search_field.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_skeleton.dart';
import '../../../../shared/widgets/section_card.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../qr/presentation/widgets/universal_scanner_dialog.dart';
import '../controllers/pos_controller.dart';

class MedicineLookupScreen extends ConsumerStatefulWidget {
  const MedicineLookupScreen({super.key});

  @override
  ConsumerState<MedicineLookupScreen> createState() => _MedicineLookupScreenState();
}

class _MedicineLookupScreenState extends ConsumerState<MedicineLookupScreen> {
  final _searchController = TextEditingController();
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Pain & Fever',
    'Antibiotics',
    'Stomach & Acid',
    'Cold & Allergy',
    'Diabetes & Heart',
    'Vitamins & Minerals',
    'Respiratory',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _scanBarcodeLookup() async {
    final code = await UniversalScannerDialog.show(
      context,
      title: 'Scan Barcode to Check Price & Stock',
    );
    if (code != null && code.isNotEmpty) {
      _searchController.text = code;
      ref.read(posSearchQueryProvider.notifier).state = code;
    }
  }

  void _showMedicineDetailSheet(BuildContext context, MedicineModel med, String currency, AppTokens tokens) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadiusTokens.largeCard)),
      ),
      builder: (ctx) {
        final isOutOfStock = med.availableStock <= 0;

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (med.imageUrl != null && med.imageUrl!.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        med.imageUrl!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return LoadingSkeleton.imageBox(width: 48, height: 48, radius: 10);
                        },
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          med.name,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                        ),
                        if (med.genericName != null)
                          Text(
                            med.genericName!,
                            style: TextStyle(fontSize: 13, color: tokens.colors.muted),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Key specs
              Row(
                children: [
                  Expanded(
                    child: _InfoTile(
                      label: 'Retail Price',
                      value: '$currency ${med.salePrice.toStringAsFixed(2)}',
                      isHighlight: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _InfoTile(
                      label: 'Stock In Hand',
                      value: '${med.availableStock} ${med.unit}',
                      isDanger: isOutOfStock,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _InfoTile(
                      label: 'Category',
                      value: med.category ?? 'General',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _InfoTile(
                      label: 'Manufacturer',
                      value: med.manufacturer ?? 'Standard',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _InfoTile(
                      label: 'Barcode',
                      value: med.barcode ?? 'Not assigned',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _InfoTile(
                      label: 'Nearest Expiry',
                      value: med.nearestExpiry != null
                          ? med.nearestExpiry.toString().split(' ').first
                          : 'No batch recorded',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: AppButton.white(
                      text: 'Close',
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: AppButton(
                      text: isOutOfStock ? 'Out of Stock' : '+ Add to POS Cart',
                      icon: const Icon(LucideIcons.shoppingBag, size: 16, color: Colors.white),
                      onPressed: isOutOfStock
                          ? null
                          : () {
                              Navigator.pop(ctx);
                              try {
                                ref.read(cartControllerProvider.notifier).addItem(med);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Added "${med.name}" to POS cart!'),
                                    backgroundColor: AppColorsTokens.success,
                                    action: SnackBarAction(
                                      label: 'View Cart',
                                      textColor: Colors.white,
                                      onPressed: () => context.go('/pos'),
                                    ),
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.toString()), backgroundColor: AppColorsTokens.danger),
                                );
                              }
                            },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final medicinesAsync = ref.watch(posMedicinesStreamProvider);
    final pharmacy = ref.watch(currentPharmacyProvider).value;
    final currency = pharmacy?.currency ?? 'Rs';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner / Top Controls
          Row(
            children: [
              Expanded(
                child: AppSearchField(
                  controller: _searchController,
                  maxWidth: double.infinity,
                  placeholder: 'Lookup price & stock: name, formula, or barcode...',
                  onChanged: (val) {
                    ref.read(posSearchQueryProvider.notifier).state = val;
                  },
                ),
              ),
              const SizedBox(width: 10),
              AppButton.white(
                text: 'Scan Barcode',
                icon: const Icon(LucideIcons.camera, size: 16),
                onPressed: _scanBarcodeLookup,
              ),
              const SizedBox(width: 10),
              AppButton(
                text: 'Open POS',
                icon: const Icon(LucideIcons.calculator, size: 16, color: Colors.white),
                onPressed: () => context.go('/pos'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Category Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
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
                        cat,
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

          // Catalog List & Table
          medicinesAsync.when(
            loading: () => LoadingSkeleton.tableRows(context: context, rows: 6),
            error: (err, _) => Center(child: Text('Error: $err')),
            data: (medicines) {
              var list = medicines.where((m) => m.isActive).toList();
              if (_selectedCategory != 'All') {
                list = list
                    .where((m) =>
                        m.category?.toLowerCase() == _selectedCategory.toLowerCase())
                    .toList();
              }

              if (list.isEmpty) {
                return const EmptyState(
                  title: 'No Medicines Found',
                  subtitle: 'Try searching another brand name, generic formula, or scan a barcode.',
                  icon: LucideIcons.search,
                );
              }

              const columns = [
                AppTableColumn(label: 'Medicine & Formula', flex: 3),
                AppTableColumn(label: 'Category', flex: 2),
                AppTableColumn(label: 'Stock Availability', flex: 2),
                AppTableColumn(label: 'Retail Price', align: TextAlign.right, flex: 2),
                AppTableColumn(label: 'Quick Action', align: TextAlign.right, flex: 2),
              ];

              final rows = list.map((m) {
                final isOutOfStock = m.availableStock <= 0;
                StatusBadgeVariant badgeVariant = StatusBadgeVariant.success;
                String badgeLabel = '${m.availableStock} ${m.unit} In Stock';

                if (isOutOfStock) {
                  badgeVariant = StatusBadgeVariant.danger;
                  badgeLabel = 'Out of Stock';
                } else if (m.isLowStock) {
                  badgeVariant = StatusBadgeVariant.amber;
                  badgeLabel = 'Low Stock (${m.availableStock} ${m.unit})';
                }

                return [
                  InkWell(
                    onTap: () => _showMedicineDetailSheet(context, m, currency, tokens),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (m.imageUrl != null && m.imageUrl!.isNotEmpty) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              m.imageUrl!,
                              width: 32,
                              height: 32,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return LoadingSkeleton.imageBox(width: 32, height: 32, radius: 6);
                              },
                              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
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
                      ],
                    ),
                  ),
                  Text(m.category ?? 'General', style: const TextStyle(fontSize: 13)),
                  StatusBadge(label: badgeLabel, variant: badgeVariant),
                  Text(
                    '$currency ${m.salePrice.toStringAsFixed(2)}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColorsTokens.brand,
                      fontFeatures: AppTypographyTokens.tabularFigures,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: AppButton(
                      text: '+ Add',
                      icon: const Icon(LucideIcons.plus, size: 14, color: Colors.white),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      height: 32,
                      onPressed: isOutOfStock
                          ? null
                          : () {
                              try {
                                ref.read(cartControllerProvider.notifier).addItem(m);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('✓ Added "${m.name}" to POS cart!'),
                                    backgroundColor: AppColorsTokens.success,
                                    duration: const Duration(seconds: 2),
                                    action: SnackBarAction(
                                      label: 'Go to POS',
                                      textColor: Colors.white,
                                      onPressed: () => context.go('/pos'),
                                    ),
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.toString()), backgroundColor: AppColorsTokens.danger),
                                );
                              }
                            },
                    ),
                  ),
                ];
              }).toList();

              final mobileCards = list.map((m) {
                final isOutOfStock = m.availableStock <= 0;

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
                            Text(
                              m.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            if (m.genericName != null)
                              Text(
                                m.genericName!,
                                style: TextStyle(fontSize: 12, color: tokens.colors.muted),
                              ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  '$currency ${m.salePrice.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColorsTokens.brand,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isOutOfStock ? '• Out of stock' : '• ${m.availableStock} in stock',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isOutOfStock ? AppColorsTokens.danger : AppColorsTokens.success,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      AppButton(
                        text: '+ Add',
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        height: 32,
                        onPressed: isOutOfStock
                            ? null
                            : () {
                                try {
                                  ref.read(cartControllerProvider.notifier).addItem(m);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('✓ Added "${m.name}" to cart'),
                                      backgroundColor: AppColorsTokens.success,
                                      action: SnackBarAction(
                                        label: 'POS',
                                        textColor: Colors.white,
                                        onPressed: () => context.go('/pos'),
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(e.toString()), backgroundColor: AppColorsTokens.danger),
                                  );
                                }
                              },
                      ),
                    ],
                  ),
                );
              }).toList();

              return SectionCard(
                title: 'Medicine Price & Stock Directory',
                subtitle: 'Showing ${list.length} medicines available at counter',
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

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlight;
  final bool isDanger;

  const _InfoTile({
    required this.label,
    required this.value,
    this.isHighlight = false,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: isHighlight ? 16 : 13,
              fontWeight: FontWeight.bold,
              color: isDanger
                  ? AppColorsTokens.danger
                  : (isHighlight ? AppColorsTokens.brand : const Color(0xFF1E293B)),
            ),
          ),
        ],
      ),
    );
  }
}
