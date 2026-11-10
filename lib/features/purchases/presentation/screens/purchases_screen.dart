import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_data_table.dart';
import '../../../../shared/widgets/app_search_field.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/section_card.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/purchases_controller.dart';

class PurchasesScreen extends ConsumerStatefulWidget {
  const PurchasesScreen({super.key});

  @override
  ConsumerState<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends ConsumerState<PurchasesScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final purchasesAsync = ref.watch(purchasesListProvider);
    final currency = ref.watch(currentPharmacyProvider).value?.currency ?? 'Rs';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Controls Row
          Row(
            children: [
              Expanded(
                child: AppSearchField(
                  controller: _searchController,
                  maxWidth: double.infinity,
                  placeholder: 'Search invoice # or supplier...',
                  onChanged: (val) =>
                      setState(() => _searchQuery = val.toLowerCase()),
                ),
              ),
              const SizedBox(width: 12),
              AppButton(
                text: '+ New Stock-In',
                icon:
                    const Icon(LucideIcons.plus, size: 16, color: Colors.white),
                onPressed: () => context.push('/purchases/new'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          purchasesAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, _) => Center(child: Text('Error: $err')),
            data: (purchases) {
              final filtered = _searchQuery.isEmpty
                  ? purchases
                  : purchases.where((p) {
                      final inv = p.invoiceNo?.toLowerCase() ?? '';
                      final supp = p.supplierName?.toLowerCase() ?? '';
                      return inv.contains(_searchQuery) ||
                          supp.contains(_searchQuery);
                    }).toList();

              if (filtered.isEmpty) {
                return EmptyState(
                  title: 'No Purchases Recorded',
                  subtitle:
                      'Record supplier invoices and receive inventory batches.',
                  icon: LucideIcons.shoppingCart,
                  actionLabel: 'Record First Purchase',
                  onAction: () => context.push('/purchases/new'),
                );
              }

              const columns = [
                AppTableColumn(label: 'Invoice #', flex: 2),
                AppTableColumn(label: 'Supplier', flex: 3),
                AppTableColumn(label: 'Received By', flex: 2),
                AppTableColumn(
                    label: 'Total Cost', align: TextAlign.right, flex: 2),
                AppTableColumn(label: 'Date', flex: 2),
              ];

              final rows = filtered.map((p) {
                return [
                  Text(
                    p.invoiceNo ?? '#PO-AUTO',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColorsTokens.brand),
                  ),
                  Text(p.supplierName ?? 'Direct Supplier',
                      style: const TextStyle(fontSize: 13)),
                  Text(p.createdBy ?? 'Storekeeper',
                      style: const TextStyle(fontSize: 13)),
                  Text(
                    '$currency ${p.total.toStringAsFixed(2)}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      fontFeatures: AppTypographyTokens.tabularFigures,
                    ),
                  ),
                  Text(
                    p.createdAt.toString().split(' ').first,
                    style: TextStyle(fontSize: 12, color: tokens.colors.muted),
                  ),
                ];
              }).toList();

              final mobileCards = filtered.map((p) {
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
                              p.supplierName ?? 'Supplier',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${p.invoiceNo ?? '#PO'} • ${p.createdAt.toString().split(' ').first}',
                              style: TextStyle(
                                  fontSize: 11, color: tokens.colors.muted),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$currency ${p.total.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColorsTokens.brand),
                      ),
                    ],
                  ),
                );
              }).toList();

              return SectionCard(
                title: 'Purchase Invoices',
                subtitle: 'Showing ${filtered.length} batch receipt records',
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
