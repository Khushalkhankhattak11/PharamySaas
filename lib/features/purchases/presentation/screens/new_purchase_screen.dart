import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/models/medicine_model.dart';
import '../../../../shared/models/purchase_model.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../inventory/data/inventory_repository.dart';
import '../../../inventory/presentation/controllers/inventory_controller.dart';
import '../../../qr/presentation/widgets/universal_scanner_dialog.dart';
import '../../../suppliers/presentation/controllers/suppliers_controller.dart';
import '../controllers/purchases_controller.dart';

class NewPurchaseScreen extends ConsumerStatefulWidget {
  const NewPurchaseScreen({super.key});

  @override
  ConsumerState<NewPurchaseScreen> createState() => _NewPurchaseScreenState();
}

class _NewPurchaseScreenState extends ConsumerState<NewPurchaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _invoiceNoController = TextEditingController();

  String? _selectedSupplierId;
  final List<PurchaseLineItem> _items = [];

  // Temporary line inputs
  MedicineModel? _selectedMedicine;
  final _batchNoController = TextEditingController();
  final _qtyController = TextEditingController();
  final _costController = TextEditingController();
  DateTime? _selectedExpiry;

  @override
  void dispose() {
    _invoiceNoController.dispose();
    _batchNoController.dispose();
    _qtyController.dispose();
    _costController.dispose();
    super.dispose();
  }

  Future<void> _scanMedicineForLine() async {
    final code = await UniversalScannerDialog.show(
      context,
      title: 'Scan Medicine for Stock-In',
    );

    if (code == null || code.isEmpty) return;

    try {
      final repo = ref.read(inventoryRepositoryProvider);
      final lookup = await repo.lookupByCode(code);

      if (lookup['found'] == true) {
        final medId = lookup['medicine_id'] as String;
        final medicines = ref.read(medicinesListProvider).value ?? [];
        final match = medicines.firstWhere((m) => m.id == medId, orElse: () => medicines.first);

        setState(() {
          _selectedMedicine = match;
          if (_batchNoController.text.isEmpty) {
            _batchNoController.text = 'B-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
          }
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No medicine found for code "$code"'), backgroundColor: AppColors.error),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scan error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _pickExpiryDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 365)),
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 365 * 10)),
    );

    if (picked != null) {
      setState(() => _selectedExpiry = picked);
    }
  }

  void _addLineItem() {
    if (_selectedMedicine == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a medicine')),
      );
      return;
    }

    final batchNo = _batchNoController.text.trim();
    if (batchNo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Batch number is required')),
      );
      return;
    }

    if (_selectedExpiry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expiry date is required')),
      );
      return;
    }

    final qty = int.tryParse(_qtyController.text);
    if (qty == null || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid quantity (> 0)')),
      );
      return;
    }

    final cost = double.tryParse(_costController.text);
    if (cost == null || cost < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid purchase price')),
      );
      return;
    }

    setState(() {
      _items.add(
        PurchaseLineItem(
          medicineId: _selectedMedicine!.id,
          medicineName: _selectedMedicine!.name,
          batchNo: batchNo,
          expiryDate: _selectedExpiry!,
          quantity: qty,
          purchasePrice: cost,
        ),
      );

      // Reset line fields
      _selectedMedicine = null;
      _batchNoController.clear();
      _qtyController.clear();
      _costController.clear();
      _selectedExpiry = null;
    });
  }

  Future<void> _handleSavePurchase() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one line item to this purchase.')),
      );
      return;
    }

    try {
      final controller = ref.read(purchasesActionControllerProvider.notifier);
      final purchase = await controller.recordPurchase(
        supplierId: _selectedSupplierId,
        invoiceNo: _invoiceNoController.text.isEmpty ? null : _invoiceNoController.text,
        items: _items,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Stock received successfully (Invoice: ${purchase.invoiceNo ?? 'N/A'}). Batches created!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save purchase: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final suppliersAsync = ref.watch(suppliersListProvider);
    final medicinesAsync = ref.watch(medicinesListProvider);
    final currency = ref.watch(currentPharmacyProvider).value?.currency ?? 'USD';
    final actionState = ref.watch(purchasesActionControllerProvider);
    final isLoading = actionState.isLoading;

    final double grandTotal = _items.fold(0.0, (sum, i) => sum + i.lineTotal);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
              // 1. Supplier & Invoice Header
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Invoice & Supplier Details',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 600;
                          final supplierField = suppliersAsync.when(
                            loading: () => const LinearProgressIndicator(),
                            error: (_, __) => const Text('Error loading suppliers'),
                            data: (suppliers) {
                              return DropdownButtonFormField<String>(
                                initialValue: _selectedSupplierId,
                                decoration: const InputDecoration(
                                  labelText: 'Select Supplier (Optional)',
                                  prefixIcon: Icon(Icons.local_shipping_outlined),
                                ),
                                items: [
                                  const DropdownMenuItem(value: null, child: Text('No Supplier / Direct')),
                                  ...suppliers.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
                                ],
                                onChanged: (val) => setState(() => _selectedSupplierId = val),
                              );
                            },
                          );
                          final invoiceField = TextFormField(
                            controller: _invoiceNoController,
                            decoration: const InputDecoration(
                              labelText: 'Supplier Invoice Number',
                              hintText: 'e.g. INV-98421',
                              prefixIcon: Icon(Icons.receipt_outlined),
                            ),
                          );

                          if (isNarrow) {
                            return Column(
                              children: [
                                supplierField,
                                const SizedBox(height: 12),
                                invoiceField,
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Expanded(child: supplierField),
                              const SizedBox(width: 16),
                              Expanded(child: invoiceField),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // 2. Add Line Item Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Add Medicine Batch Item',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          OutlinedButton.icon(
                            onPressed: _scanMedicineForLine,
                            icon: const Icon(Icons.qr_code_scanner, size: 16),
                            label: const Text('Scan QR / Barcode'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      medicinesAsync.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (_, __) => const Text('Error loading medicines'),
                        data: (medicines) {
                          return DropdownButtonFormField<MedicineModel>(
                            initialValue: _selectedMedicine,
                            decoration: const InputDecoration(
                              labelText: 'Select Medicine *',
                              prefixIcon: Icon(Icons.medication_outlined),
                            ),
                            items: medicines.map((m) {
                              return DropdownMenuItem(
                                value: m,
                                child: Text('${m.name} (${m.unit}) • QR: ${m.qrCode}'),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedMedicine = val;
                                if (val != null && _batchNoController.text.isEmpty) {
                                  _batchNoController.text = 'B-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
                                }
                              });
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 550;
                          final batchField = TextFormField(
                            controller: _batchNoController,
                            decoration: const InputDecoration(
                              labelText: 'Batch Number *',
                              hintText: 'e.g. B-9021',
                              prefixIcon: Icon(Icons.numbers),
                            ),
                          );
                          final expiryField = InkWell(
                            onTap: _pickExpiryDate,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Expiry Date *',
                                prefixIcon: Icon(Icons.calendar_month_outlined),
                              ),
                              child: Text(
                                _selectedExpiry != null
                                    ? _selectedExpiry!.toLocal().toString().split(' ')[0]
                                    : 'Pick Expiry Date',
                                style: TextStyle(
                                  color: _selectedExpiry != null
                                      ? AppColors.textPrimaryLight
                                      : AppColors.textSecondaryLight,
                                ),
                              ),
                            ),
                          );

                          if (isNarrow) {
                            return Column(
                              children: [
                                batchField,
                                const SizedBox(height: 12),
                                expiryField,
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Expanded(child: batchField),
                              const SizedBox(width: 12),
                              Expanded(child: expiryField),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 650;
                          final qtyField = TextFormField(
                            controller: _qtyController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Received Quantity *',
                              prefixIcon: Icon(Icons.add_shopping_cart),
                            ),
                          );
                          final costField = TextFormField(
                            controller: _costController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Unit Cost Price *',
                              prefixText: '$currency ',
                              prefixIcon: const Icon(Icons.attach_money),
                            ),
                          );
                          final addButton = ElevatedButton.icon(
                            onPressed: _addLineItem,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              minimumSize: Size(isNarrow ? double.infinity : 140, 48),
                            ),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Line'),
                          );

                          if (isNarrow) {
                            return Column(
                              children: [
                                qtyField,
                                const SizedBox(height: 12),
                                costField,
                                const SizedBox(height: 12),
                                addButton,
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Expanded(child: qtyField),
                              const SizedBox(width: 12),
                              Expanded(child: costField),
                              const SizedBox(width: 12),
                              addButton,
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // 3. Line Items Table
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Purchase Lines (${_items.length} items)',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Grand Total: $currency ${grandTotal.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_items.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Center(
                            child: Text(
                              'No lines added yet. Select a medicine and add batch details above.',
                              style: TextStyle(color: AppColors.textSecondaryLight),
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _items.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, idx) {
                            final item = _items[idx];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.primaryContainer,
                                child: Text('${idx + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                              ),
                              title: Text(item.medicineName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                'Batch: ${item.batchNo} • Exp: ${item.expiryDate.toLocal().toString().split(' ')[0]} • Qty: ${item.quantity} × $currency ${item.purchasePrice.toStringAsFixed(2)}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '$currency ${item.lineTotal.toStringAsFixed(2)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: AppColors.error),
                                    onPressed: () {
                                      setState(() => _items.removeAt(idx));
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: isLoading ? null : _handleSavePurchase,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                ),
                icon: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(
                  'Confirm & Record Stock-In ($currency ${grandTotal.toStringAsFixed(2)})',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
  }
}
