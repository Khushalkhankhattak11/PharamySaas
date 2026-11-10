import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/models/medicine_model.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_data_table.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/section_card.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../inventory/data/inventory_repository.dart';
import '../../../inventory/presentation/controllers/inventory_controller.dart';
import '../../data/qr_label_service.dart';
import '../widgets/universal_scanner_dialog.dart';

class QrSetupScreen extends ConsumerStatefulWidget {
  const QrSetupScreen({super.key});

  @override
  ConsumerState<QrSetupScreen> createState() => _QrSetupScreenState();
}

class _QrSetupScreenState extends ConsumerState<QrSetupScreen> {
  final Set<String> _selectedMedicineIds = {};
  LabelLayoutType _selectedLayout = LabelLayoutType.a4Sheet;
  int _copiesPerMedicine = 1;

  Map<String, dynamic>? _lastScanResult;

  Future<void> _testScan() async {
    final code = await UniversalScannerDialog.show(
      context,
      title: 'QR / Barcode Hardware & Camera Test',
    );

    if (code != null && code.isNotEmpty) {
      try {
        final repo = ref.read(inventoryRepositoryProvider);
        final result = await repo.lookupByCode(code);
        setState(() {
          _lastScanResult = result;
        });
      } catch (e) {
        setState(() {
          _lastScanResult = {'found': false, 'error': e.toString(), 'code': code};
        });
      }
    }
  }

  Future<void> _handleBulkPrint(List<MedicineModel> medicines, String currency) async {
    final selected = medicines.where((m) => _selectedMedicineIds.contains(m.id)).toList();

    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one medicine to print labels.')),
      );
      return;
    }

    final items = selected.map((m) {
      return QrLabelItem(
        medicineName: m.name,
        qrCode: m.qrCode,
        price: m.salePrice,
        currency: currency,
        copies: _copiesPerMedicine,
      );
    }).toList();

    await QrLabelService.printOrPreview(
      items: items,
      layout: _selectedLayout,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final medicinesAsync = ref.watch(medicinesListProvider);
    final currency = ref.watch(currentPharmacyProvider).value?.currency ?? 'Rs';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Configuration Card: Layout & Copies & Scanner Test
          SectionCard(
            title: 'QR Label Printing & Scanner Testing',
            subtitle: 'Generate barcode / QR shelf tags for thermal printers or A4 paper',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 750;

                  final layoutSection = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Print Layout Format',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _layoutOption(
                              'A4 Sheet (3x8 grid)', LabelLayoutType.a4Sheet),
                          _layoutOption(
                              '50x30mm Thermal', LabelLayoutType.thermal50x30),
                          _layoutOption(
                              '80mm Roll Continuous', LabelLayoutType.roll80mm),
                        ],
                      ),
                    ],
                  );

                  final copiesSection = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Copies per Item',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(LucideIcons.minusCircle, size: 20),
                            onPressed: _copiesPerMedicine > 1
                                ? () => setState(() => _copiesPerMedicine--)
                                : null,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: tokens.colors.track,
                              borderRadius:
                                  BorderRadius.circular(AppRadiusTokens.pill),
                            ),
                            child: Text(
                              '$_copiesPerMedicine',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(LucideIcons.plusCircle, size: 20),
                            onPressed: () => setState(() => _copiesPerMedicine++),
                          ),
                        ],
                      ),
                    ],
                  );

                  final testSection = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Hardware Verification',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 8),
                      AppButton.white(
                        text: 'Test Scanner Input',
                        icon: const Icon(LucideIcons.scanLine, size: 16),
                        onPressed: _testScan,
                      ),
                    ],
                  );

                  if (isNarrow) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        layoutSection,
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            copiesSection,
                            const SizedBox(width: 20),
                            Expanded(child: testSection),
                          ],
                        ),
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: layoutSection),
                      const SizedBox(width: 20),
                      copiesSection,
                      const SizedBox(width: 20),
                      testSection,
                    ],
                  );
                },
              ),
              if (_lastScanResult != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: tokens.colors.track,
                    borderRadius: BorderRadius.circular(AppRadiusTokens.tile),
                    border: Border.all(color: tokens.colors.line),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _lastScanResult!['found'] == true ? LucideIcons.checkCircle : LucideIcons.alertCircle,
                        color: _lastScanResult!['found'] == true ? AppColorsTokens.success : AppColorsTokens.amber,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _lastScanResult!['found'] == true
                            ? 'Matched: ${_lastScanResult!['medicine']?['name']} (Stock: ${_lastScanResult!['available_stock']})'
                            : 'Unknown code scanned: ${_lastScanResult!['code'] ?? 'No match'}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Medicines Selection Card
        medicinesAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(48),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (err, _) => Center(child: Text('Error: $err')),
          data: (medicines) {
            if (medicines.isEmpty) {
              return const EmptyState(
                title: 'No Medicines Registered',
                subtitle: 'Add medicines in inventory first to print shelf tags.',
                icon: LucideIcons.qrCode,
              );
            }

            final isAllSelected = _selectedMedicineIds.length == medicines.length;

            const columns = [
              AppTableColumn(label: 'Select', flex: 1),
              AppTableColumn(label: 'Medicine Name', flex: 4),
              AppTableColumn(label: 'Category', flex: 2),
              AppTableColumn(label: 'System QR Code', flex: 3),
              AppTableColumn(label: 'Sale Price', align: TextAlign.right, flex: 2),
            ];

            final rows = medicines.map((m) {
              final isChecked = _selectedMedicineIds.contains(m.id);

              return [
                Checkbox(
                  value: isChecked,
                  activeColor: AppColorsTokens.brand,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _selectedMedicineIds.add(m.id);
                      } else {
                        _selectedMedicineIds.remove(m.id);
                      }
                    });
                  },
                ),
                Text(m.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                Text(m.category ?? 'General', style: const TextStyle(fontSize: 13)),
                StatusBadge(
                  label: m.qrCode,
                  variant: StatusBadgeVariant.info,
                ),
                Text(
                  '$currency ${m.salePrice.toStringAsFixed(2)}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, fontFeatures: AppTypographyTokens.tabularFigures),
                ),
              ];
            }).toList();

            return SectionCard(
              title: 'Select Medicines for Labels',
              subtitle: '${_selectedMedicineIds.length} of ${medicines.length} medicines selected',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        if (isAllSelected) {
                          _selectedMedicineIds.clear();
                        } else {
                          _selectedMedicineIds.addAll(medicines.map((m) => m.id));
                        }
                      });
                    },
                    child: Text(isAllSelected ? 'Deselect All' : 'Select All'),
                  ),
                  const SizedBox(width: 8),
                  AppButton(
                    text: 'Print Labels (${_selectedMedicineIds.length})',
                    icon: const Icon(LucideIcons.printer, size: 16, color: Colors.white),
                    onPressed: _selectedMedicineIds.isEmpty
                        ? null
                        : () => _handleBulkPrint(medicines, currency),
                  ),
                ],
              ),
              child: AppDataTable(
                columns: columns,
                rows: rows,
              ),
            );
          },
        ),
      ],
    ),
    );
  }

  Widget _layoutOption(String label, LabelLayoutType layout) {
    final tokens = context.tokens;
    final isSelected = _selectedLayout == layout;

    return GestureDetector(
      onTap: () => setState(() => _selectedLayout = layout),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColorsTokens.brandGradient : null,
          color: isSelected ? null : tokens.colors.track,
          borderRadius: BorderRadius.circular(AppRadiusTokens.pill),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : tokens.colors.ink,
          ),
        ),
      ),
    );
  }
}
