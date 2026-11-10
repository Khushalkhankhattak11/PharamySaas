import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/models/sale_model.dart';
import '../../../../shared/models/user_role.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_data_table.dart';
import '../../../../shared/widgets/app_search_field.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/metric_tile.dart';
import '../../../../shared/widgets/section_card.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../pos/data/receipt_printer_service.dart';
import '../../../qr/presentation/widgets/universal_scanner_dialog.dart';
import '../controllers/sales_controller.dart';

class SalesHistoryScreen extends ConsumerStatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  ConsumerState<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends ConsumerState<SalesHistoryScreen> {
  final _searchController = TextEditingController();
  bool _filterOnlyMySales = false;
  bool _initializedFilter = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _scanInvoiceQr() async {
    final code = await UniversalScannerDialog.show(
      context,
      title: 'Scan Receipt QR to Lookup Invoice',
    );
    if (code != null && code.isNotEmpty) {
      final clean = code.replaceAll('INV-', '').trim();
      _searchController.text = clean;
      ref.read(salesSearchQueryProvider.notifier).state = clean;
    }
  }

  void _showSaleDetailsDialog(SaleModel sale) {
    final pharmacy = ref.read(currentPharmacyProvider).value;
    final currency = pharmacy?.currency ?? 'Rs';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadiusTokens.largeCard)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Invoice #${sale.invoiceNo}',
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            StatusBadge(
              label: sale.paymentMethod,
              variant: sale.paymentMethod.toLowerCase().contains('card')
                  ? StatusBadgeVariant.info
                  : StatusBadgeVariant.success,
            ),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customer: ${sale.customerName} • Cashier: ${sale.cashierName ?? "Counter"}',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
                Text(
                  'Date: ${sale.createdAt.toLocal().toString().split('.')[0]}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const Divider(height: 24),
                const Text('Items Purchased:',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                ...sale.items.map((i) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${i.medicineName} (x${i.quantity})',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          Text(
                            '$currency ${i.total.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                fontFeatures:
                                    AppTypographyTokens.tabularFigures),
                          ),
                        ],
                      ),
                    )),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal:', style: TextStyle(fontSize: 13)),
                    Text(
                        '$currency ${(sale.total + sale.discount).toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 13)),
                  ],
                ),
                if (sale.discount > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Discount:',
                          style: TextStyle(
                              fontSize: 13, color: AppColorsTokens.danger)),
                      Text('-$currency ${sale.discount.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 13, color: AppColorsTokens.danger)),
                    ],
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Amount:',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(
                      '$currency ${sale.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColorsTokens.brand,
                          fontFeatures: AppTypographyTokens.tabularFigures),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          AppButton(
            text: 'Reprint Receipt',
            icon:
                const Icon(LucideIcons.printer, size: 16, color: Colors.white),
            onPressed: () async {
              if (pharmacy != null) {
                await ReceiptPrinterService.printReceipt(
                  sale: sale,
                  pharmacy: pharmacy,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final salesAsync = ref.watch(salesHistoryListProvider);
    final pharmacy = ref.watch(currentPharmacyProvider).value;
    final currency = pharmacy?.currency ?? 'Rs';
    final profile = ref.watch(currentProfileProvider).value;
    final isCashier = profile?.role == UserRole.cashier;

    if (!_initializedFilter && profile != null) {
      _initializedFilter = true;
      if (isCashier) {
        _filterOnlyMySales = true;
      }
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cashier Shift Quick Banner (Today's performance)
          salesAsync.maybeWhen(
            data: (allSales) {
              final now = DateTime.now();
              final todaySales = allSales.where((s) {
                final isToday = s.createdAt.year == now.year &&
                    s.createdAt.month == now.month &&
                    s.createdAt.day == now.day;
                if (!isToday) return false;
                if (_filterOnlyMySales && profile != null) {
                  final matchId = s.cashierId == profile.id;
                  final matchName = s.cashierName?.toLowerCase() == profile.fullName.toLowerCase();
                  return matchId || matchName;
                }
                return true;
              }).toList();

              final todayCount = todaySales.length;
              final todayVol = todaySales.fold(0.0, (sum, s) => sum + s.total);
              final avgTicket = todayCount > 0 ? (todayVol / todayCount) : 0.0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 600;
                    if (isNarrow) {
                      return Column(
                        children: [
                          MetricTile(
                            label: isCashier ? 'My Invoices Today' : "Today's Invoices",
                            value: '$todayCount receipts',
                          ),
                          const SizedBox(height: 10),
                          MetricTile(
                            label: isCashier ? 'My Sales Volume Today' : "Today's Revenue",
                            value: '$currency ${todayVol.toStringAsFixed(0)}',
                          ),
                          const SizedBox(height: 10),
                          MetricTile(
                            label: 'Average Receipt Value',
                            value: '$currency ${avgTicket.toStringAsFixed(0)}',
                          ),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(
                          child: MetricTile(
                            label: isCashier ? 'My Invoices Today' : "Today's Invoices",
                            value: '$todayCount receipts',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: MetricTile(
                            label: isCashier ? 'My Sales Volume Today' : "Today's Revenue",
                            value: '$currency ${todayVol.toStringAsFixed(0)}',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: MetricTile(
                            label: 'Average Receipt Value',
                            value: '$currency ${avgTicket.toStringAsFixed(0)}',
                          ),
                        ),
                      ],
                    );
                  },
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),

          // Controls Row: Search + QR Scan
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 480;

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppSearchField(
                      controller: _searchController,
                      maxWidth: double.infinity,
                      placeholder: 'Search invoice #, customer name, cashier...',
                      onChanged: (val) {
                        ref.read(salesSearchQueryProvider.notifier).state = val;
                      },
                    ),
                    const SizedBox(height: 10),
                    AppButton.white(
                      text: 'Scan Receipt QR',
                      icon: const Icon(LucideIcons.qrCode, size: 16),
                      onPressed: _scanInvoiceQr,
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
                      placeholder: 'Search invoice #, customer name, cashier...',
                      onChanged: (val) {
                        ref.read(salesSearchQueryProvider.notifier).state = val;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  AppButton.white(
                    text: 'Scan Receipt QR',
                    icon: const Icon(LucideIcons.qrCode, size: 16),
                    onPressed: _scanInvoiceQr,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),

          // Sales Filter: My Sales vs All Store Sales
          Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _filterOnlyMySales = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: _filterOnlyMySales ? AppColorsTokens.brandGradient : null,
                    color: _filterOnlyMySales ? null : tokens.colors.card,
                    borderRadius: BorderRadius.circular(AppRadiusTokens.pill),
                    border: Border.all(
                      color: _filterOnlyMySales ? Colors.transparent : tokens.colors.line,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.user,
                        size: 14,
                        color: _filterOnlyMySales ? Colors.white : tokens.colors.ink,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'My Sales',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: _filterOnlyMySales ? FontWeight.w700 : FontWeight.w500,
                          color: _filterOnlyMySales ? Colors.white : tokens.colors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() => _filterOnlyMySales = false),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: !_filterOnlyMySales ? AppColorsTokens.brandGradient : null,
                    color: !_filterOnlyMySales ? null : tokens.colors.card,
                    borderRadius: BorderRadius.circular(AppRadiusTokens.pill),
                    border: Border.all(
                      color: !_filterOnlyMySales ? Colors.transparent : tokens.colors.line,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.store,
                        size: 14,
                        color: !_filterOnlyMySales ? Colors.white : tokens.colors.ink,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'All Store Sales',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: !_filterOnlyMySales ? FontWeight.w700 : FontWeight.w500,
                          color: !_filterOnlyMySales ? Colors.white : tokens.colors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Sales Table Card
          salesAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, _) => Center(child: Text('Error loading sales: $err')),
            data: (sales) {
              var displayed = sales;
              if (_filterOnlyMySales && profile != null) {
                displayed = sales.where((s) {
                  final matchId = s.cashierId == profile.id;
                  final matchName = s.cashierName?.toLowerCase() == profile.fullName.toLowerCase();
                  return matchId || matchName;
                }).toList();
              }

              if (displayed.isEmpty) {
                return const EmptyState(
                  title: 'No Sales History Found',
                  subtitle: 'No sales receipts match your query or filter criteria.',
                  icon: LucideIcons.receipt,
                );
              }

              const columns = [
                AppTableColumn(label: 'Invoice', flex: 2),
                AppTableColumn(label: 'Customer', flex: 2),
                AppTableColumn(label: 'Cashier', flex: 2),
                AppTableColumn(label: 'Payment', flex: 2),
                AppTableColumn(label: 'Total', align: TextAlign.right, flex: 2),
                AppTableColumn(label: 'Date & Time', flex: 2),
                AppTableColumn(label: 'Reprint', align: TextAlign.right, flex: 2),
              ];

              final rows = displayed.map((sale) {
                final isCard = sale.paymentMethod.toLowerCase().contains('card');

                return [
                  InkWell(
                    onTap: () => _showSaleDetailsDialog(sale),
                    child: Text(
                      '#${sale.invoiceNo}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColorsTokens.brand,
                      ),
                    ),
                  ),
                  Text(
                    sale.customerName,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  Text(
                    sale.cashierName ?? 'Cashier',
                    style: const TextStyle(fontSize: 13),
                  ),
                  StatusBadge(
                    label: sale.paymentMethod,
                    variant: isCard
                        ? StatusBadgeVariant.info
                        : StatusBadgeVariant.success,
                  ),
                  Text(
                    '$currency ${sale.total.toStringAsFixed(2)}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      fontFeatures: AppTypographyTokens.tabularFigures,
                    ),
                  ),
                  Text(
                    sale.createdAt.toLocal().toString().split('.')[0],
                    style: TextStyle(fontSize: 12, color: tokens.colors.muted),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: const Icon(LucideIcons.printer, size: 16),
                      color: AppColorsTokens.brand,
                      tooltip: 'Reprint Thermal Receipt',
                      onPressed: () => _showSaleDetailsDialog(sale),
                    ),
                  ),
                ];
              }).toList();

              final mobileCards = displayed.map((sale) {
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
                              'Invoice #${sale.invoiceNo} • ${sale.customerName}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$currency ${sale.total.toStringAsFixed(2)} • ${sale.paymentMethod} • ${sale.cashierName ?? "Counter"}',
                              style: TextStyle(
                                  fontSize: 12, color: tokens.colors.muted),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.printer, size: 18),
                        color: AppColorsTokens.brand,
                        tooltip: 'Reprint Receipt',
                        onPressed: () => _showSaleDetailsDialog(sale),
                      ),
                    ],
                  ),
                );
              }).toList();

              return SectionCard(
                title: isCashier ? 'My Completed Invoices' : 'Sales Invoices',
                subtitle: 'Showing ${displayed.length} completed transactions',
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
