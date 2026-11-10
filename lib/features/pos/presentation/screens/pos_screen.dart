import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/models/medicine_model.dart';
import '../../../../shared/models/sale_model.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_search_field.dart';
import '../../../../shared/widgets/loading_skeleton.dart';
import '../../../../shared/widgets/receipt_preview.dart';
import '../../../../shared/widgets/section_card.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../qr/presentation/widgets/universal_scanner_dialog.dart';
import '../../data/receipt_printer_service.dart';
import '../controllers/pos_controller.dart';
import '../widgets/shift_register_bar.dart';

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  final _searchController = TextEditingController();
  final _customerController = TextEditingController(text: 'Walk-in Customer');
  final _discountController = TextEditingController(text: '0');
  String _selectedCategory = 'All';
  int _currentPage = 1;
  final int _itemsPerPage = 20;

  static const List<String> _defaultCategories = [
    'All',
    'Tablets',
    'Capsules',
    'Syrups',
    'Injections',
    'Supplies',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _customerController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _scanBarcodeForCart() async {
    final code = await UniversalScannerDialog.show(
      context,
      title: 'Scan Item to Add to Cart',
    );

    if (code == null || code.isEmpty) return;

    try {
      await ref.read(cartControllerProvider.notifier).addByScannedCode(code);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item added to cart!'),
            duration: Duration(seconds: 1),
            backgroundColor: AppColorsTokens.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColorsTokens.danger,
          ),
        );
      }
    }
  }

  void _showReceiptDialog(SaleModel sale) {
    final pharmacy = ref.read(currentPharmacyProvider).value;
    final receiptItems = sale.items
        .map((item) => ReceiptLineItem(
              name: item.medicineName,
              qty: item.quantity,
              price: item.unitPrice,
            ))
        .toList();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadiusTokens.card)),
        title: const Row(
          children: [
            Icon(LucideIcons.checkCircle2, color: AppColorsTokens.success, size: 24),
            SizedBox(width: 10),
            Text('Sale Saved!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ],
        ),
        content: SizedBox(
          width: 310,
          child: SingleChildScrollView(
            child: ReceiptPreview(
              pharmacyName: pharmacy?.name ?? 'PharmaCore',
              address: pharmacy?.address,
              phone: pharmacy?.phone,
              invoiceNumber: sale.invoiceNo.toString(),
              date: sale.createdAt,
              cashierName: sale.cashierName,
              items: receiptItems,
              subtotal: sale.subtotal,
              discount: sale.discount,
              total: sale.total,
              footer: pharmacy?.receiptFooter ?? 'Thank you for your visit!',
            ),
          ),
        ),
        actions: [
          GhostButton(
            text: 'New Sale',
            icon: const Icon(LucideIcons.shoppingBag, size: 16),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(cartControllerProvider.notifier).clearCart();
            },
          ),
          PrimaryButton(
            text: 'Print (80mm)',
            icon: const Icon(LucideIcons.printer, size: 16, color: Colors.white),
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
    final medicinesAsync = ref.watch(posMedicinesStreamProvider);
    final cart = ref.watch(cartControllerProvider);
    final pharmacy = ref.watch(currentPharmacyProvider).value;
    final currency = pharmacy?.currency ?? 'Rs';
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 960;

    return Material(
      type: MaterialType.transparency,
      child: !isDesktop
          ? _buildMobilePos(context, tokens, medicinesAsync, cart, currency)
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShiftRegisterBar(currency: currency),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Point of Sale (POS)', style: tokens.typography.pageTitle),
                      AppButton(
                        text: 'Scan',
                        icon: const Icon(LucideIcons.scanLine, size: 18, color: Colors.white),
                        onPressed: _scanBarcodeForCart,
                      ),
                    ],
                  ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left pane: Search/Scan, Category pills, Medicine grid & Pagination
            Expanded(
              flex: 7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search & Scan Bar
                  Row(
                    children: [
                      Expanded(
                        child: AppSearchField(
                          controller: _searchController,
                          maxWidth: double.infinity,
                          placeholder: 'Search medicine name, generic, barcode...',
                          onChanged: (val) {
                            ref.read(posSearchQueryProvider.notifier).state = val;
                            if (_currentPage != 1) {
                              setState(() => _currentPage = 1);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Category Pill Chips
                  medicinesAsync.maybeWhen(
                    data: (allMeds) {
                      final categories = _getCategories(allMeds);
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: categories.map((cat) {
                            final isSelected = _selectedCategory == cat;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: GestureDetector(
                                onTap: () => setState(() {
                                  _selectedCategory = cat;
                                  _currentPage = 1;
                                }),
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
                      );
                    },
                    orElse: () => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 14),

                  // Medicine Grid
                  medicinesAsync.when(
                    loading: () => LoadingSkeleton.posGrid(context: context, count: 10),
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
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: Text('No medicines found', style: tokens.typography.cardSubtitle),
                          ),
                        );
                      }

                      final totalItems = list.length;
                      final totalPages = (totalItems / _itemsPerPage).ceil().clamp(1, 99999);
                      if (_currentPage > totalPages) {
                        _currentPage = totalPages;
                      }

                      final startIndex = (_currentPage - 1) * _itemsPerPage;
                      final pagedList = list.skip(startIndex).take(_itemsPerPage).toList();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final width = constraints.maxWidth;
                              final crossAxisCount = width >= 720
                                  ? 5
                                  : (width >= 560
                                      ? 4
                                      : (width >= 400 ? 3 : 2));

                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  childAspectRatio: 0.82,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                ),
                                itemCount: pagedList.length,
                                itemBuilder: (context, idx) {
                                  final med = pagedList[idx];
                                  final isOutOfStock = med.availableStock <= 0;

                                  return _MedicineCard(
                                    med: med,
                                    currency: currency,
                                    isOutOfStock: isOutOfStock,
                                    onInfoTap: () => _showMedicineInfoDialog(med, currency),
                                    onTap: isOutOfStock
                                        ? () {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('${med.name} is currently out of stock.'),
                                                backgroundColor: AppColorsTokens.danger,
                                                duration: const Duration(seconds: 1),
                                              ),
                                            );
                                          }
                                        : () {
                                            try {
                                              ref.read(cartControllerProvider.notifier).addItem(med);
                                            } catch (e) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(e.toString()),
                                                  backgroundColor: AppColorsTokens.danger,
                                                ),
                                              );
                                            }
                                          },
                                  );
                                },
                              );
                            },
                          ),
                          _buildPagination(totalItems, totalPages, tokens),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
        const SizedBox(width: 20),

        // Right pane: Cart Card
        Expanded(
          flex: 4,
          child: _buildCartCard(context, tokens, cart, currency),
        ),
      ],
    ),
      ],
    ),
    ),
  );
  }

  Widget _buildCartCard(
    BuildContext context,
    AppTokens tokens,
    dynamic cart,
    String currency,
  ) {
    return SectionCard(
      title: 'Active Cart',
      subtitle: '${cart.totalItemCount} items selected',
      trailing: cart.items.isNotEmpty
          ? TextButton(
              onPressed: () => ref.read(cartControllerProvider.notifier).clearCart(),
              child: const Text('Clear', style: TextStyle(color: AppColorsTokens.danger)),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Customer Name input
          TextField(
            controller: _customerController,
            style: tokens.typography.body,
            decoration: InputDecoration(
              hintText: 'Customer name (optional)',
              prefixIcon: Icon(LucideIcons.user, size: 16, color: tokens.colors.muted),
              filled: true,
              fillColor: tokens.colors.track,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadiusTokens.pill),
                borderSide: BorderSide(color: tokens.colors.line),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Cart Items List
          if (cart.items.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(LucideIcons.shoppingCart, size: 36, color: tokens.colors.muted),
                  const SizedBox(height: 8),
                  Text('Cart is empty', style: tokens.typography.cardSubtitle),
                  const SizedBox(height: 4),
                  Text('Click items or scan barcodes to add', style: TextStyle(fontSize: 11, color: tokens.colors.muted)),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cart.items.length,
              separatorBuilder: (_, __) => Divider(color: tokens.colors.line, height: 16),
              itemBuilder: (context, idx) {
                final item = cart.items[idx];
                return Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          Text(
                            '$currency ${item.unitPrice.toStringAsFixed(2)} / unit',
                            style: TextStyle(fontSize: 11, color: tokens.colors.muted),
                          ),
                        ],
                      ),
                    ),
                    // Quantity stepper
                    Row(
                      children: [
                        _stepperButton(
                          icon: LucideIcons.minus,
                          tokens: tokens,
                          onTap: () => ref.read(cartControllerProvider.notifier).updateQuantity(item.medicineId, item.quantity - 1),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            item.quantity.toString(),
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                        ),
                        _stepperButton(
                          icon: LucideIcons.plus,
                          tokens: tokens,
                          onTap: () => ref.read(cartControllerProvider.notifier).updateQuantity(item.medicineId, item.quantity + 1),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$currency ${item.lineTotal.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ],
                );
              },
            ),

          const SizedBox(height: 16),
          Divider(color: tokens.colors.line),
          const SizedBox(height: 8),

          // Discount pill input
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Discount ($currency)', style: TextStyle(fontSize: 12, color: tokens.colors.muted)),
              SizedBox(
                width: 90,
                child: TextField(
                  controller: _discountController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onChanged: (val) {
                    final d = double.tryParse(val) ?? 0.0;
                    ref.read(cartControllerProvider.notifier).setDiscount(d);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Payment Method Selector
          const Text('Payment Method', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              {'name': 'Cash', 'icon': LucideIcons.banknote, 'color': const Color(0xFF0F766E)},
              {'name': 'EasyPaisa', 'icon': LucideIcons.smartphone, 'color': const Color(0xFF047857)},
              {'name': 'JazzCash', 'icon': LucideIcons.smartphone, 'color': const Color(0xFFBE123C)},
              {'name': 'Card', 'icon': LucideIcons.creditCard, 'color': const Color(0xFF1D4ED8)},
              {'name': 'Bank', 'icon': LucideIcons.building2, 'color': const Color(0xFF475569)},
            ].map((pm) {
              final method = pm['name'] as String;
              final icon = pm['icon'] as IconData;
              final color = pm['color'] as Color;
              final isSelected = cart.paymentMethod == method;

              return InkWell(
                onTap: () => ref.read(cartControllerProvider.notifier).setPaymentMethod(method),
                borderRadius: BorderRadius.circular(AppRadiusTokens.pill),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? color : color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadiusTokens.pill),
                    border: Border.all(
                      color: isSelected ? color : color.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 12, color: isSelected ? Colors.white : color),
                      const SizedBox(width: 4),
                      Text(
                        method,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : color,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Big Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Grand Total', style: tokens.typography.cardTitle.copyWith(fontSize: 15)),
              Text(
                '$currency ${cart.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.02 * 24,
                  color: AppColorsTokens.brand,
                  fontFeatures: AppTypographyTokens.tabularFigures,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Large Deep-Teal "Charge" Button
          AppButton(
            text: 'Charge $currency ${cart.total.toStringAsFixed(2)}',
            height: 52,
            isLoading: cart.isSubmitting,
            onPressed: cart.items.isEmpty || cart.isSubmitting
                ? null
                : () async {
                    try {
                      ref.read(cartControllerProvider.notifier).setCustomerName(
                            _customerController.text.trim().isEmpty
                                ? 'Walk-in Customer'
                                : _customerController.text.trim(),
                          );
                      final sale = await ref.read(cartControllerProvider.notifier).checkout();
                      _showReceiptDialog(sale);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString()), backgroundColor: AppColorsTokens.danger),
                        );
                      }
                    }
                  },
          ),
        ],
      ),
    );
  }

  Widget _stepperButton({
    required IconData icon,
    required AppTokens tokens,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: tokens.colors.track,
        shape: BoxShape.circle,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Center(
          child: Icon(icon, size: 14, color: tokens.colors.ink),
        ),
      ),
    );
  }

  Widget _buildMobilePos(
    BuildContext context,
    AppTokens tokens,
    AsyncValue<List<MedicineModel>> medicinesAsync,
    dynamic cart,
    String currency,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShiftRegisterBar(currency: currency),
          // Search & Scan on mobile
          Row(
            children: [
              Expanded(
                child: AppSearchField(
                  controller: _searchController,
                  placeholder: 'Search medicine name, generic...',
                  onChanged: (val) {
                    ref.read(posSearchQueryProvider.notifier).state = val;
                    if (_currentPage != 1) {
                      setState(() => _currentPage = 1);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(LucideIcons.scanLine),
                onPressed: _scanBarcodeForCart,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Category Chips on mobile
          medicinesAsync.maybeWhen(
            data: (allMeds) {
              final categories = _getCategories(allMeds);
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: categories.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _selectedCategory = cat;
                          _currentPage = 1;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? Colors.white : tokens.colors.ink,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
          const SizedBox(height: 12),

          // Results list / Grid
          medicinesAsync.when(
            loading: () => LoadingSkeleton.posGrid(context: context, count: 6),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (medicines) {
              var list = medicines.where((m) => m.isActive).toList();
              if (_selectedCategory != 'All') {
                list = list
                    .where((m) =>
                        m.category?.toLowerCase() == _selectedCategory.toLowerCase())
                    .toList();
              }

              if (list.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Text('No medicines found', style: tokens.typography.cardSubtitle),
                  ),
                );
              }

              final totalItems = list.length;
              final totalPages = (totalItems / _itemsPerPage).ceil().clamp(1, 99999);
              if (_currentPage > totalPages) {
                _currentPage = totalPages;
              }

              final startIndex = (_currentPage - 1) * _itemsPerPage;
              final pagedList = list.skip(startIndex).take(_itemsPerPage).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final crossAxisCount = width >= 720
                          ? 4
                          : (width >= 500
                              ? 3
                              : 2);

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: 0.82,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: pagedList.length,
                        itemBuilder: (context, idx) {
                          final med = pagedList[idx];
                          final isOutOfStock = med.availableStock <= 0;

                          return _MedicineCard(
                            med: med,
                            currency: currency,
                            isOutOfStock: isOutOfStock,
                            onInfoTap: () => _showMedicineInfoDialog(med, currency),
                            onTap: isOutOfStock
                                ? () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('${med.name} is currently out of stock.'),
                                        backgroundColor: AppColorsTokens.danger,
                                        duration: const Duration(seconds: 1),
                                      ),
                                    );
                                  }
                                : () {
                                    try {
                                      ref.read(cartControllerProvider.notifier).addItem(med);
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(e.toString()),
                                          backgroundColor: AppColorsTokens.danger,
                                        ),
                                      );
                                    }
                                  },
                          );
                        },
                      );
                    },
                  ),
                  _buildPagination(totalItems, totalPages, tokens),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          // Sticky Bottom Total Bar that expands to cart
          if (cart.items.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: AppColorsTokens.brandGradient,
                borderRadius: BorderRadius.circular(AppRadiusTokens.pill),
                boxShadow: const [AppColorsTokens.heroShadow],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${cart.totalItemCount} items', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                      Text('$currency ${cart.total.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  AppButton.white(
                    text: 'View Cart & Pay',
                    onPressed: () => _showMobileCartBottomSheet(context, tokens, cart, currency),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  void _showMobileCartBottomSheet(
    BuildContext context,
    AppTokens tokens,
    dynamic cart,
    String currency,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: tokens.colors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 20,
        ),
        child: SingleChildScrollView(
          child: _buildCartCard(context, tokens, cart, currency),
        ),
      ),
    );
  }

  List<String> _getCategories(List<MedicineModel> medicines) {
    final catSet = <String>{..._defaultCategories};
    for (final m in medicines) {
      if (m.category != null && m.category!.trim().isNotEmpty) {
        catSet.add(m.category!.trim());
      }
    }
    return catSet.toList();
  }

  void _showMedicineInfoDialog(MedicineModel med, String currency) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        contentPadding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColorsTokens.brand.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(LucideIcons.pill, color: AppColorsTokens.brand, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    med.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  if (med.genericName != null && med.genericName!.trim().isNotEmpty)
                    Text(
                      med.genericName!.trim(),
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                ],
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(height: 1),
              const SizedBox(height: 12),
              _buildDetailRow('Retail Price', '$currency ${med.salePrice.toStringAsFixed(2)}'),
              _buildDetailRow('Stock Available', '${med.availableStock} ${med.unit}'),
              _buildDetailRow('Min Stock Level', '${med.minStockLevel} ${med.unit}'),
              if (med.brandName != null && med.brandName!.trim().isNotEmpty)
                _buildDetailRow('Brand / Manufacturer', med.brandName!.trim()),
              if (med.category != null && med.category!.trim().isNotEmpty)
                _buildDetailRow('Category', med.category!.trim()),
              if (med.barcode != null && med.barcode!.trim().isNotEmpty)
                _buildDetailRow('Barcode', med.barcode!.trim()),
              if (med.nearestExpiry != null)
                _buildDetailRow(
                  'Expiry Date',
                  '${med.nearestExpiry!.day.toString().padLeft(2, '0')}/${med.nearestExpiry!.month.toString().padLeft(2, '0')}/${med.nearestExpiry!.year}',
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          if (med.availableStock > 0)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColorsTokens.brand,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                ref.read(cartControllerProvider.notifier).addItem(med);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${med.name} added to cart!'),
                    backgroundColor: AppColorsTokens.success,
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              icon: const Icon(LucideIcons.shoppingCart, size: 16),
              label: const Text('Add to Cart'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildPagination(int totalItems, int totalPages, AppTokens tokens) {
    if (totalItems <= 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: tokens.colors.card,
        borderRadius: BorderRadius.circular(AppRadiusTokens.input),
        border: Border.all(color: tokens.colors.line, width: 1),
        boxShadow: [tokens.colors.shadow],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              'Showing ${(_currentPage - 1) * _itemsPerPage + 1}–${((_currentPage - 1) * _itemsPerPage + _itemsPerPage).clamp(1, totalItems)} of $totalItems',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: tokens.colors.muted,
                fontFeatures: AppTypographyTokens.tabularFigures,
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPageNavButton(
                icon: LucideIcons.chevronLeft,
                isEnabled: _currentPage > 1,
                tokens: tokens,
                onTap: () {
                  if (_currentPage > 1) {
                    setState(() => _currentPage--);
                  }
                },
              ),
              const SizedBox(width: 4),
              ..._buildPageNumbers(totalPages, tokens),
              const SizedBox(width: 4),
              _buildPageNavButton(
                icon: LucideIcons.chevronRight,
                isEnabled: _currentPage < totalPages,
                tokens: tokens,
                onTap: () {
                  if (_currentPage < totalPages) {
                    setState(() => _currentPage++);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPageNavButton({
    required IconData icon,
    required bool isEnabled,
    required AppTokens tokens,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: isEnabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isEnabled ? tokens.colors.card : tokens.colors.track,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isEnabled ? tokens.colors.line : tokens.colors.line.withValues(alpha: 0.5),
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: isEnabled ? tokens.colors.ink : tokens.colors.muted,
        ),
      ),
    );
  }

  List<Widget> _buildPageNumbers(int totalPages, AppTokens tokens) {
    final List<Widget> list = [];

    if (totalPages <= 7) {
      for (int i = 1; i <= totalPages; i++) {
        list.add(_buildPageNumberButton(i, tokens));
      }
      return list;
    }

    list.add(_buildPageNumberButton(1, tokens));

    if (_currentPage > 3) {
      list.add(Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Text('…', style: TextStyle(color: tokens.colors.muted, fontWeight: FontWeight.bold)),
      ));
    }

    final start = (_currentPage - 1).clamp(2, totalPages - 1);
    final end = (_currentPage + 1).clamp(2, totalPages - 1);

    for (int i = start; i <= end; i++) {
      if (i > 1 && i < totalPages) {
        list.add(_buildPageNumberButton(i, tokens));
      }
    }

    if (_currentPage < totalPages - 2) {
      list.add(Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Text('…', style: TextStyle(color: tokens.colors.muted, fontWeight: FontWeight.bold)),
      ));
    }

    list.add(_buildPageNumberButton(totalPages, tokens));

    return list;
  }

  Widget _buildPageNumberButton(int page, AppTokens tokens) {
    final isCurrent = page == _currentPage;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        onTap: () => setState(() => _currentPage = page),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: isCurrent
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [tokens.colors.brand1, tokens.colors.brand2],
                  )
                : null,
            color: isCurrent ? null : tokens.colors.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isCurrent ? Colors.transparent : tokens.colors.line,
              width: 1,
            ),
            boxShadow: isCurrent
                ? [
                    BoxShadow(
                      color: tokens.colors.brand1.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Text(
            '$page',
            style: TextStyle(
              fontSize: 12,
              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
              color: isCurrent ? Colors.white : tokens.colors.ink,
              fontFeatures: AppTypographyTokens.tabularFigures,
            ),
          ),
        ),
      ),
    );
  }
}

class _MedicineCard extends StatefulWidget {
  final MedicineModel med;
  final String currency;
  final bool isOutOfStock;
  final VoidCallback onTap;
  final VoidCallback onInfoTap;

  const _MedicineCard({
    required this.med,
    required this.currency,
    required this.isOutOfStock,
    required this.onTap,
    required this.onInfoTap,
  });

  @override
  State<_MedicineCard> createState() => _MedicineCardState();
}

class _MedicineCardState extends State<_MedicineCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isOutOfStock = widget.isOutOfStock;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        transform: _isHovered && !isOutOfStock
            ? Matrix4.translationValues(0.0, -2.0, 0.0)
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: tokens.colors.card,
          borderRadius: BorderRadius.circular(AppRadiusTokens.productCard),
          border: Border.all(
            color: _isHovered && !isOutOfStock ? tokens.colors.accent : tokens.colors.line,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: (_isHovered && !isOutOfStock
                      ? tokens.colors.accent
                      : tokens.colors.brand2)
                  .withValues(alpha: _isHovered ? 0.12 : 0.04),
              blurRadius: _isHovered ? 12 : 6,
              offset: Offset(0, _isHovered ? 4 : 2),
            ),
          ],
        ),
        child: Opacity(
          opacity: isOutOfStock ? 0.45 : 1.0,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadiusTokens.productCard),
              onTap: widget.onTap,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Top: Product Image
                    Expanded(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: double.infinity,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: tokens.colors.track.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: widget.med.imageUrl != null &&
                                    widget.med.imageUrl!.trim().isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      widget.med.imageUrl!.trim(),
                                      fit: BoxFit.contain,
                                      width: double.infinity,
                                      height: double.infinity,
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Center(
                                          child: SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: tokens.colors.accent,
                                            ),
                                          ),
                                        );
                                      },
                                      errorBuilder: (_, __, ___) =>
                                          _buildPlaceholder(tokens),
                                    ),
                                  )
                                : _buildPlaceholder(tokens),
                          ),
                          if (isOutOfStock)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColorsTokens.danger,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  '0 stock',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Middle: Name (Centered & Bold as shown in reference)
                    Text(
                      widget.med.name,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: isOutOfStock
                            ? tokens.colors.muted
                            : tokens.colors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Bottom: Price (Centered) & Info (i) icon on right
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(width: 22), // Balances info icon for true centering
                        Expanded(
                          child: Text(
                            '${widget.currency} ${widget.med.salePrice.toStringAsFixed(2)}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isOutOfStock
                                  ? tokens.colors.muted
                                  : tokens.colors.ink,
                              fontFeatures: AppTypographyTokens.tabularFigures,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: widget.onInfoTap,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: Icon(
                              LucideIcons.info,
                              size: 16,
                              color: tokens.colors.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(AppTokens tokens) {
    return Container(
      padding: const EdgeInsets.all(8),
      alignment: Alignment.center,
      child: Icon(
        LucideIcons.pill,
        size: 32,
        color: tokens.colors.muted.withValues(alpha: 0.5),
      ),
    );
  }
}
