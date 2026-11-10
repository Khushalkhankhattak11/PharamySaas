import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/models/batch_model.dart';
import '../../../../shared/models/medicine_model.dart';
import '../../../../shared/widgets/loading_skeleton.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../qr/data/qr_label_service.dart';
import '../controllers/inventory_controller.dart';

class MedicineDetailScreen extends ConsumerWidget {
  final String medicineId;

  const MedicineDetailScreen({super.key, required this.medicineId});

  void _showAdjustStockDialog(BuildContext context, WidgetRef ref, BatchModel batch, MedicineModel medicine) {
    final formKey = GlobalKey<FormState>();
    final qtyController = TextEditingController();
    final reasonController = TextEditingController();
    bool isDeduction = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Adjust Stock: Batch ${batch.batchNo}'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Current Batch Quantity: ${batch.quantity} ${medicine.unit}'),
                  const SizedBox(height: 16),
                  const Text('Adjustment Type:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: true, label: Text('Deduct (Damage/Loss)')),
                      ButtonSegment(value: false, label: Text('Add (Correction)')),
                    ],
                    selected: {isDeduction},
                    onSelectionChanged: (set) {
                      setDialogState(() => isDeduction = set.first);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: qtyController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Adjustment Quantity *',
                      prefixIcon: Icon(Icons.numbers),
                    ),
                    validator: (v) {
                      final val = int.tryParse(v ?? '');
                      if (val == null || val <= 0) return 'Enter a positive quantity';
                      if (isDeduction && val > batch.quantity) {
                        return 'Cannot deduct more than current stock';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: reasonController,
                    decoration: const InputDecoration(
                      labelText: 'Reason for Adjustment *',
                      hintText: 'e.g. Expired write-off, Damaged packaging',
                      prefixIcon: Icon(Icons.notes_outlined),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Reason is required' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(ctx);

                final qty = int.parse(qtyController.text);
                final change = isDeduction ? -qty : qty;

                try {
                  await ref.read(inventoryActionControllerProvider.notifier).adjustStock(
                        batchId: batch.id,
                        medicineId: medicine.id,
                        quantityChange: change,
                        reason: reasonController.text,
                      );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Stock adjusted successfully.'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Adjustment failed: $e'), backgroundColor: AppColors.error),
                    );
                  }
                }
              },
              child: const Text('Save Adjustment'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPrintLabelModal(BuildContext context, MedicineModel medicine, BatchModel? batch, String currency) {
    LabelLayoutType selectedLayout = LabelLayoutType.thermal50x30;
    int copies = 1;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Print QR Label: ${medicine.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (batch != null)
                Text('Target: Batch ${batch.batchNo} (Exp: ${batch.expiryDate.toLocal().toString().split(' ')[0]})')
              else
                Text('Target: System Medicine QR (${medicine.qrCode})'),
              const SizedBox(height: 16),
              DropdownButtonFormField<LabelLayoutType>(
                initialValue: selectedLayout,
                decoration: const InputDecoration(labelText: 'Printer Format'),
                items: LabelLayoutType.values
                    .map((l) => DropdownMenuItem(value: l, child: Text(l.label)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedLayout = val);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: copies,
                decoration: const InputDecoration(labelText: 'Copies'),
                items: [1, 2, 5, 10, 20, 50]
                    .map((c) => DropdownMenuItem(value: c, child: Text('$c copies')))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => copies = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                final item = QrLabelItem(
                  medicineName: medicine.name,
                  qrCode: batch?.qrCode ?? medicine.qrCode,
                  price: medicine.salePrice,
                  currency: currency,
                  batchNo: batch?.batchNo,
                  expiryDate: batch?.expiryDate.toLocal().toString().split(' ')[0],
                  copies: copies,
                );
                await QrLabelService.printOrPreview(
                  items: [item],
                  layout: selectedLayout,
                );
              },
              icon: const Icon(Icons.print),
              label: const Text('Print / Preview PDF'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medicineAsync = ref.watch(medicineDetailProvider(medicineId));
    final batchesAsync = ref.watch(medicineBatchesProvider(medicineId));
    final pharmacy = ref.watch(currentPharmacyProvider).value;
    final currency = pharmacy?.currency ?? 'USD';
    final profile = ref.watch(currentProfileProvider).value;
    final canViewCost = profile?.role.canViewCostPrice ?? false;

    return medicineAsync.when(
      loading: () => LoadingSkeleton.tableRows(context: context, rows: 6),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (med) {
        if (med == null) return const Center(child: Text('Medicine not found'));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Action Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Medicine Details & Batches',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (profile?.role.canEditMedicine ?? false) ...[
                      OutlinedButton.icon(
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Edit Details'),
                        onPressed: () => context.push('/inventory/$medicineId/edit'),
                      ),
                      const SizedBox(width: 8),
                    ],
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Refresh',
                      onPressed: () {
                        ref.invalidate(medicineDetailProvider(medicineId));
                        ref.invalidate(medicineBatchesProvider(medicineId));
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Top Info & QR Card
            Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isNarrow = constraints.maxWidth < 650;

                        final qrWidget = Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              QrImageView(
                                data: med.qrCode,
                                version: QrVersions.auto,
                                size: 140.0,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                med.qrCode,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: () => _showPrintLabelModal(
                                    context, med, null, currency),
                                icon: const Icon(Icons.print, size: 14),
                                label: const Text('Print QR Label',
                                    style: TextStyle(fontSize: 12)),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  minimumSize: Size.zero,
                                ),
                              ),
                            ],
                          ),
                        );

                        final metaWidget = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (med.imageUrl != null && med.imageUrl!.isNotEmpty) ...[
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(
                                      med.imageUrl!,
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                ],
                                Flexible(
                                  child: Text(
                                    med.name,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: med.isActive
                                        ? AppColors.success
                                            .withValues(alpha: 0.1)
                                        : AppColors.error
                                            .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    med.isActive ? 'Active' : 'Inactive',
                                    style: TextStyle(
                                      color: med.isActive
                                          ? AppColors.success
                                          : AppColors.error,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (med.genericName != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Formula: ${med.genericName!}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 24,
                              runSpacing: 12,
                              children: [
                                _metaItem('Category', med.category ?? '—'),
                                _metaItem(
                                    'Manufacturer', med.manufacturer ?? '—'),
                                _metaItem('Retail Price',
                                    '$currency ${med.salePrice.toStringAsFixed(2)} / ${med.unit}'),
                                _metaItem(
                                    'Barcode', med.barcode ?? 'None registered'),
                                _metaItem('Min Alert Level',
                                    '${med.minStockLevel} ${med.unit}'),
                                _metaItem(
                                  'Total Available Stock',
                                  '${med.availableStock} ${med.unit}',
                                  isAlert: med.isLowStock,
                                ),
                              ],
                            ),
                          ],
                        );

                        if (isNarrow) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(child: qrWidget),
                              const SizedBox(height: 20),
                              metaWidget,
                            ],
                          );
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            qrWidget,
                            const SizedBox(width: 24),
                            Expanded(child: metaWidget),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Batches Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Stock Batches (FEFO Sorted by Earliest Expiry)',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    if (profile?.role.canManageBatches ?? false)
                      ElevatedButton.icon(
                        onPressed: () => context.push('/purchases/new'),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Batch (Stock-In)'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                batchesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Text('Error loading batches: $err'),
                  data: (batches) {
                    if (batches.isEmpty) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Center(
                            child: Column(
                              children: [
                                const Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.textSecondaryLight),
                                const SizedBox(height: 12),
                                const Text('No batches registered yet for this medicine.'),
                                if (profile?.role.canManageBatches ?? false) ...[
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () => context.push('/purchases/new'),
                                    child: const Text('Receive Stock In'),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: batches.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, idx) {
                        final b = batches[idx];
                        final status = b.expiryStatus;

                        Color statusColor = AppColors.fresh;
                        String statusLabel = 'Good';

                        switch (status) {
                          case BatchExpiryStatus.expired:
                            statusColor = AppColors.expired;
                            statusLabel = 'EXPIRED (${b.daysUntilExpiry.abs()} days ago)';
                            break;
                          case BatchExpiryStatus.critical30:
                            statusColor = AppColors.expiringSoon30;
                            statusLabel = 'EXPIRES SOON (${b.daysUntilExpiry} days)';
                            break;
                          case BatchExpiryStatus.warning90:
                            statusColor = AppColors.expiringSoon90;
                            statusLabel = 'Within 90 Days (${b.daysUntilExpiry} days)';
                            break;
                          case BatchExpiryStatus.fresh:
                            statusColor = AppColors.fresh;
                            statusLabel = 'Good (${b.daysUntilExpiry} days left)';
                            break;
                        }

                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: status == BatchExpiryStatus.expired
                                  ? AppColors.error
                                  : AppColors.borderLight,
                              width: status == BatchExpiryStatus.expired ? 1.5 : 1.0,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final isNarrow = constraints.maxWidth < 600;
                                final actionButtons = <Widget>[
                                  OutlinedButton.icon(
                                    onPressed: () => _showPrintLabelModal(context, med, b, currency),
                                    icon: const Icon(Icons.qr_code, size: 16),
                                    label: const Text('Batch Label'),
                                  ),
                                  if (profile?.role.canChangeStock ?? false) ...[
                                    const SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      onPressed: () => _showAdjustStockDialog(context, ref, b, med),
                                      icon: const Icon(Icons.tune, size: 16),
                                      label: const Text('Adjust'),
                                    ),
                                  ],
                                ];

                                if (isNarrow) {
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: statusColor.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Icon(Icons.layers, color: statusColor, size: 24),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      'Batch: ${b.batchNo}',
                                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: statusColor.withValues(alpha: 0.1),
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: Text(
                                                        statusLabel,
                                                        style: TextStyle(
                                                          color: statusColor,
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Expiry: ${b.expiryDate.toLocal().toString().split(' ')[0]} • Quantity: ${b.quantity} ${med.unit}',
                                                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
                                                ),
                                                if (canViewCost)
                                                  Text(
                                                    'Cost: $currency ${b.purchasePrice.toStringAsFixed(2)} • QR: ${b.qrCode}',
                                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(children: actionButtons),
                                    ],
                                  );
                                }

                                return Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(Icons.layers, color: statusColor, size: 24),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                'Batch: ${b.batchNo}',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: statusColor.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  statusLabel,
                                                  style: TextStyle(
                                                    color: statusColor,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Expiry: ${b.expiryDate.toLocal().toString().split(' ')[0]} • Quantity: ${b.quantity} ${med.unit}',
                                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
                                          ),
                                          if (canViewCost)
                                            Text(
                                              'Cost: $currency ${b.purchasePrice.toStringAsFixed(2)} • QR: ${b.qrCode}',
                                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                                            ),
                                        ],
                                      ),
                                    ),
                                    ...actionButtons,
                                  ],
                                );
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            );
        },
      );
  }

  Widget _metaItem(String label, String value, {bool isAlert = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isAlert ? AppColors.error : AppColors.textPrimaryLight,
          ),
        ),
      ],
    );
  }
}
