import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/services/medicine_image_service.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/constants/standard_medicine_catalog.dart';
import '../../../../shared/models/medicine_model.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_search_field.dart';
import '../../../../shared/widgets/loading_skeleton.dart';
import '../../../../shared/widgets/section_card.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../qr/presentation/widgets/universal_scanner_dialog.dart';
import '../controllers/inventory_controller.dart';

class MedicineFormScreen extends ConsumerStatefulWidget {
  final String? medicineId;

  const MedicineFormScreen({super.key, this.medicineId});

  @override
  ConsumerState<MedicineFormScreen> createState() => _MedicineFormScreenState();
}

class _MedicineFormScreenState extends ConsumerState<MedicineFormScreen> {
  // Tab index: 0 = Quick Catalog, 1 = Custom Form
  int _selectedTabIndex = 0;

  // Custom Form Controllers
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _brandNameController = TextEditingController();
  final _registrationNumberController = TextEditingController();
  final _genericController = TextEditingController();
  final _categoryController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _salePriceController = TextEditingController();
  final _discountController = TextEditingController(text: '0');
  final _initialStockController = TextEditingController(text: '0');
  final _minStockController = TextEditingController(text: '10');

  // Photo capture state
  Uint8List? _capturedImageBytes;
  String? _capturedImageName;
  bool _isUploadingImage = false;

  String _selectedUnit = 'Strip';
  final List<String> _units = [
    'Strip',
    'Tablet',
    'Capsule',
    'Bottle',
    'Box',
    'Ampoule',
    'Vial',
    'Tube',
    'Pack',
    'Sachet',
  ];

  // Catalog search & filter state
  String _catalogSearchQuery = '';
  String _catalogSelectedCategory = 'All';

  // 1-Click Batch Import State
  bool _isBatchImporting = false;
  int _batchImportProgress = 0;
  int _batchImportTotal = 0;

  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.medicineId != null) {
      _selectedTabIndex = 1; // Open edit mode directly
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandNameController.dispose();
    _registrationNumberController.dispose();
    _genericController.dispose();
    _categoryController.dispose();
    _manufacturerController.dispose();
    _barcodeController.dispose();
    _imageUrlController.dispose();
    _salePriceController.dispose();
    _discountController.dispose();
    _initialStockController.dispose();
    _minStockController.dispose();
    super.dispose();
  }

  void _populateExisting(MedicineModel med) {
    if (_initialized) return;
    _initialized = true;
    _nameController.text = med.name;
    _brandNameController.text = med.brandName ?? '';
    _registrationNumberController.text = med.registrationNumber ?? '';
    _genericController.text = med.genericName ?? '';
    _categoryController.text = med.category ?? '';
    _manufacturerController.text = med.manufacturer ?? '';
    _barcodeController.text = med.barcode ?? '';
    _imageUrlController.text = med.imageUrl ?? '';
    _salePriceController.text = med.salePrice.toStringAsFixed(2);
    _discountController.text = med.discountPercent.toStringAsFixed(0);
    _minStockController.text = med.minStockLevel.toString();
    _initialStockController.text = med.availableStock.toString();
    if (_units.contains(med.unit)) {
      _selectedUnit = med.unit;
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final service = ref.read(medicineImageServiceProvider);
    final file = await service.captureMedicinePhoto(source: source);
    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() {
        _capturedImageBytes = bytes;
        _capturedImageName = file.name;
      });
    }
  }

  MedicineModel? _findMatchingMedicine(List<MedicineModel> existingList) {
    final cleanName = _nameController.text.trim().toLowerCase();
    final cleanBrand = _brandNameController.text.trim().toLowerCase();
    final cleanBarcode = _barcodeController.text.trim().toLowerCase();
    final cleanReg = _registrationNumberController.text.trim().toLowerCase();

    if (cleanName.isEmpty && cleanBrand.isEmpty && cleanBarcode.isEmpty && cleanReg.isEmpty) {
      return null;
    }

    for (final med in existingList) {
      if (widget.medicineId != null && med.id == widget.medicineId) continue;
      if (cleanReg.isNotEmpty && med.registrationNumber != null && med.registrationNumber!.trim().toLowerCase() == cleanReg) {
        return med;
      }
      if (cleanBarcode.isNotEmpty && med.barcode != null && med.barcode!.trim().toLowerCase() == cleanBarcode) {
        return med;
      }
      if (cleanName.isNotEmpty && (med.name.trim().toLowerCase() == cleanName || (med.brandName != null && med.brandName!.trim().toLowerCase() == cleanName))) {
        return med;
      }
      if (cleanBrand.isNotEmpty && (med.brandName != null && med.brandName!.trim().toLowerCase() == cleanBrand || med.name.trim().toLowerCase() == cleanBrand)) {
        return med;
      }
    }
    return null;
  }

  Future<void> _scanBarcodeInto(TextEditingController controller) async {
    final code = await UniversalScannerDialog.show(
      context,
      title: 'Scan Manufacturer Barcode',
    );
    if (code != null && code.isNotEmpty) {
      setState(() {
        controller.text = code;
      });
    }
  }

  void _showQuickAddDialog(MedicineTemplate template, String currency, {MedicineModel? existingMed}) {
    final quickFormKey = GlobalKey<FormState>();
    final initialPrice = existingMed != null ? existingMed.salePrice : template.suggestedPrice;
    final priceController = TextEditingController(text: initialPrice.toStringAsFixed(2));
    final unitsController = TextEditingController(text: '50');
    final discountController = TextEditingController(text: (existingMed?.discountPercent ?? template.defaultDiscount).toStringAsFixed(0));
    final barcodeController = TextEditingController(text: existingMed?.barcode ?? template.defaultBarcode ?? '');
    String unit = existingMed?.unit ?? template.defaultUnit;
    DateTime expiryDate = DateTime.now().add(const Duration(days: 365));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final tokens = context.tokens;
          final p = double.tryParse(priceController.text) ?? initialPrice;
          final d = double.tryParse(discountController.text) ?? 0.0;
          final effectivePrice = d > 0 ? (p * (1 - (d / 100.0))) : p;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadiusTokens.largeCard)),
            titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            title: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: (existingMed?.imageUrl ?? template.imageUrl) != null
                      ? Image.network(
                          (existingMed?.imageUrl ?? template.imageUrl)!,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return LoadingSkeleton.imageBox(width: 48, height: 48, radius: 10);
                          },
                          errorBuilder: (_, __, ___) => Container(
                            width: 48,
                            height: 48,
                            color: AppColorsTokens.brand.withValues(alpha: 0.1),
                            child: const Icon(LucideIcons.pill, color: AppColorsTokens.brand, size: 24),
                          ),
                        )
                      : Container(
                          width: 48,
                          height: 48,
                          color: AppColorsTokens.brand.withValues(alpha: 0.1),
                          child: const Icon(LucideIcons.pill, color: AppColorsTokens.brand, size: 24),
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(template.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      Text(
                        '${template.genericName} • ${template.manufacturer}${template.registrationNumber != null ? ' • Reg: ${template.registrationNumber}' : ''}',
                        style: TextStyle(fontSize: 12, color: tokens.colors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Form(
                  key: quickFormKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: existingMed != null
                              ? AppColorsTokens.success.withValues(alpha: 0.1)
                              : AppColorsTokens.brand.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: existingMed != null
                                ? AppColorsTokens.success.withValues(alpha: 0.3)
                                : AppColorsTokens.brand.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              existingMed != null ? LucideIcons.checkCircle2 : LucideIcons.sparkles,
                              color: existingMed != null ? AppColorsTokens.success : AppColorsTokens.brand,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                existingMed != null
                                    ? '✓ Already in your inventory (Current: ${existingMed.availableStock} ${existingMed.unit}). Adding units here will add to existing stock without creating duplicates!'
                                    : 'Set your retail price, stock units, and discount. Medicine details will be saved directly to Firebase!',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: existingMed != null ? AppColorsTokens.success : tokens.colors.ink,
                                  fontWeight: existingMed != null ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Price & Discount Row
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: priceController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: 'Retail Price *',
                                prefixText: '$currency ',
                                prefixIcon: const Icon(LucideIcons.dollarSign, size: 16),
                              ),
                              onChanged: (_) => setModalState(() {}),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Required';
                                if (double.tryParse(v) == null) return 'Invalid';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: discountController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Discount %',
                                suffixText: '%',
                                prefixIcon: Icon(LucideIcons.percent, size: 16),
                              ),
                              onChanged: (_) => setModalState(() {}),
                              validator: (v) {
                                if (v != null && v.isNotEmpty && double.tryParse(v) == null) {
                                  return 'Invalid';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      if (d > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Effective Customer Price: $currency ${effectivePrice.toStringAsFixed(2)} ($d% off)',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColorsTokens.success),
                        ),
                      ],
                      const SizedBox(height: 14),

                      // Units & Packaging Unit Row
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: unitsController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: existingMed != null ? 'Additional Units to Add *' : 'Initial Stock Units *',
                                prefixIcon: const Icon(LucideIcons.boxes, size: 16),
                                helperText: existingMed != null
                                    ? 'New total will be: ${(existingMed.availableStock) + (int.tryParse(unitsController.text) ?? 0)} $unit'
                                    : 'Quantity added to inventory',
                              ),
                              onChanged: (_) => setModalState(() {}),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Required';
                                if (int.tryParse(v) == null) return 'Number required';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              initialValue: _units.contains(unit) ? unit : _units.first,
                              decoration: const InputDecoration(
                                labelText: 'Packaging',
                                prefixIcon: Icon(LucideIcons.package, size: 16),
                              ),
                              items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                              onChanged: (val) {
                                if (val != null) setModalState(() => unit = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Barcode & QR Code Row
                      TextFormField(
                        controller: barcodeController,
                        decoration: InputDecoration(
                          labelText: 'Manufacturer Barcode (Optional)',
                          prefixIcon: const Icon(LucideIcons.barcode, size: 16),
                          suffixIcon: IconButton(
                            icon: const Icon(LucideIcons.camera, size: 16),
                            tooltip: 'Scan Barcode',
                            onPressed: () async {
                              final scanned = await UniversalScannerDialog.show(context, title: 'Scan Barcode');
                              if (scanned != null && scanned.isNotEmpty) {
                                setModalState(() => barcodeController.text = scanned);
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Expiry Date Selector
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: expiryDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                          );
                          if (picked != null) {
                            setModalState(() => expiryDate = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Batch Expiry Date *',
                            prefixIcon: Icon(LucideIcons.calendar, size: 16),
                          ),
                          child: Text(
                            expiryDate.toString().split(' ').first,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              AppButton(
                text: existingMed != null ? 'Add to Stock & Save' : 'Save & Add to Firebase',
                icon: Icon(
                  existingMed != null ? LucideIcons.boxes : LucideIcons.plusCircle,
                  size: 16,
                  color: Colors.white,
                ),
                onPressed: () async {
                  if (!quickFormKey.currentState!.validate()) return;
                  final finalPrice = double.tryParse(priceController.text) ?? initialPrice;
                  final finalDiscount = double.tryParse(discountController.text) ?? 0.0;
                  final finalUnits = int.tryParse(unitsController.text) ?? 0;
                  final finalBarcode = barcodeController.text.trim();

                  Navigator.pop(ctx);
                  try {
                    final saved = await ref.read(inventoryActionControllerProvider.notifier).createMedicine(
                          name: template.name,
                          brandName: template.brandName,
                          registrationNumber: template.registrationNumber,
                          genericName: template.genericName,
                          category: template.category,
                          manufacturer: template.manufacturer,
                          barcode: finalBarcode.isEmpty ? template.defaultBarcode : finalBarcode,
                          unit: unit,
                          salePrice: finalPrice,
                          discountPercent: finalDiscount,
                          minStockLevel: 10,
                          initialStock: finalUnits,
                          expiryDate: expiryDate,
                          imageUrl: template.imageUrl,
                        );

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            existingMed != null
                                ? '✓ Added +$finalUnits $unit to "${saved.name}". Current Stock: ${saved.availableStock}!'
                                : '✓ "${template.name}" ($finalUnits $unit) added to Firebase inventory!',
                          ),
                          backgroundColor: AppColorsTokens.success,
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to add medicine: $e'),
                          backgroundColor: AppColorsTokens.danger,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleBatchImportAll(List<MedicineTemplate> templates) async {
    final existingMedicines = ref.read(medicinesListProvider).value ?? [];

    final toAdd = templates.where((t) {
      final nameClean = t.name.toLowerCase();
      final regClean = t.registrationNumber?.toLowerCase();
      final barcodeClean = t.defaultBarcode;
      return !existingMedicines.any((m) {
        if (regClean != null && m.registrationNumber != null && m.registrationNumber!.toLowerCase() == regClean) return true;
        if (barcodeClean != null && m.barcode != null && m.barcode == barcodeClean) return true;
        return m.name.toLowerCase() == nameClean;
      });
    }).toList();

    if (toAdd.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All medicines in this list are already saved in your Firebase inventory!'),
          backgroundColor: AppColorsTokens.brand,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadiusTokens.largeCard)),
        title: const Row(
          children: [
            Icon(LucideIcons.sparkles, color: AppColorsTokens.brand),
            SizedBox(width: 8),
            Text('1-Click Import to Firebase'),
          ],
        ),
        content: Text(
          'This will automatically add ${toAdd.length} common Pakistani medicines directly into your Firebase Inventory, Products & POS Billing with default initial stock (50 units each) and retail pricing.\n\nWould you like to proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          AppButton(
            text: 'Import All (${toAdd.length})',
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isBatchImporting = true;
      _batchImportProgress = 0;
      _batchImportTotal = toAdd.length;
    });

    int successCount = 0;
    final expiryDate = DateTime.now().add(const Duration(days: 365));

    try {
      final notifier = ref.read(inventoryActionControllerProvider.notifier);
      for (final item in toAdd) {
        try {
          await notifier.createMedicine(
            name: item.name,
            brandName: item.brandName,
            registrationNumber: item.registrationNumber,
            genericName: item.genericName,
            category: item.category,
            manufacturer: item.manufacturer,
            barcode: item.defaultBarcode,
            unit: item.defaultUnit,
            salePrice: item.suggestedPrice,
            discountPercent: item.defaultDiscount,
            minStockLevel: 10,
            initialStock: 50,
            expiryDate: expiryDate,
            imageUrl: item.imageUrl,
          );
          successCount++;
        } catch (e) {
          debugPrint('[BatchImport] Error adding ${item.name}: $e');
        }
        if (mounted) {
          setState(() {
            _batchImportProgress++;
          });
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Successfully saved $successCount medicines into your Firebase Products, Medicines, and POS Billing!'),
            backgroundColor: AppColorsTokens.success,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBatchImporting = false;
        });
      }
    }
  }

  Future<void> _handleCustomSave() async {
    if (!_formKey.currentState!.validate()) return;

    final price = double.tryParse(_salePriceController.text);
    final discount = double.tryParse(_discountController.text) ?? 0.0;
    final initialStock = int.tryParse(_initialStockController.text) ?? 0;
    final minStock = int.tryParse(_minStockController.text) ?? 10;

    if (price == null || price < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid sale price'), backgroundColor: AppColorsTokens.danger),
      );
      return;
    }

    setState(() => _isUploadingImage = true);

    String? finalImageUrl = _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim();

    // Upload captured image if present
    if (_capturedImageBytes != null) {
      try {
        final profile = await ref.read(currentProfileProvider.future);
        final pharmacyId = profile?.pharmacyId ?? 'global';
        final uploaded = await ref.read(medicineImageServiceProvider).uploadOrEncodeImage(
              pharmacyId: pharmacyId,
              fileName: _capturedImageName ?? 'med_${DateTime.now().millisecondsSinceEpoch}.jpg',
              bytes: _capturedImageBytes!,
            );
        if (uploaded != null) {
          finalImageUrl = uploaded;
        }
      } catch (_) {}
    }

    setState(() => _isUploadingImage = false);

    try {
      final controller = ref.read(inventoryActionControllerProvider.notifier);
      final brand = _brandNameController.text.trim().isEmpty ? null : _brandNameController.text.trim();
      final regNo = _registrationNumberController.text.trim().isEmpty ? null : _registrationNumberController.text.trim();

      if (widget.medicineId != null) {
        await controller.updateMedicine(
          medicineId: widget.medicineId!,
          name: _nameController.text.trim(),
          brandName: brand,
          registrationNumber: regNo,
          genericName: _genericController.text.trim().isEmpty ? null : _genericController.text.trim(),
          category: _categoryController.text.trim().isEmpty ? null : _categoryController.text.trim(),
          manufacturer: _manufacturerController.text.trim().isEmpty ? null : _manufacturerController.text.trim(),
          barcode: _barcodeController.text.trim().isEmpty ? null : _barcodeController.text.trim(),
          unit: _selectedUnit,
          salePrice: price,
          discountPercent: discount,
          minStockLevel: minStock,
          imageUrl: finalImageUrl,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Medicine updated successfully!'), backgroundColor: AppColorsTokens.success),
          );
          context.pop();
        }
      } else {
        final created = await controller.createMedicine(
          name: _nameController.text.trim(),
          brandName: brand,
          registrationNumber: regNo,
          genericName: _genericController.text.trim().isEmpty ? null : _genericController.text.trim(),
          category: _categoryController.text.trim().isEmpty ? null : _categoryController.text.trim(),
          manufacturer: _manufacturerController.text.trim().isEmpty ? null : _manufacturerController.text.trim(),
          barcode: _barcodeController.text.trim().isEmpty ? null : _barcodeController.text.trim(),
          unit: _selectedUnit,
          salePrice: price,
          discountPercent: discount,
          minStockLevel: minStock,
          initialStock: initialStock,
          imageUrl: finalImageUrl,
        );
        if (mounted) {
          final isRestocked = created.availableStock > initialStock && initialStock > 0;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isRestocked
                    ? '✓ Found existing stock for "${created.name}". Stock updated to ${created.availableStock} ${created.unit} (No duplicate created)!'
                    : '✓ Medicine "${created.name}" created with QR: ${created.qrCode}',
              ),
              backgroundColor: AppColorsTokens.success,
              duration: const Duration(seconds: 4),
            ),
          );
          context.go('/inventory/${created.id}');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving medicine: $e'), backgroundColor: AppColorsTokens.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isEdit = widget.medicineId != null;
    final currency = ref.watch(currentPharmacyProvider).value?.currency ?? 'Rs';

    final profile = ref.watch(currentProfileProvider).value;
    if (profile != null && !profile.role.canModifyInventory) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.shieldAlert, size: 48, color: AppColorsTokens.danger),
              const SizedBox(height: 16),
              const Text(
                'Access Denied',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Cashiers are not permitted to add or edit medicines. Inventory management is reserved for the Storekeeper and Admin.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF4B6567)),
              ),
              const SizedBox(height: 20),
              AppButton(
                text: 'Back to Inventory',
                onPressed: () => context.go('/inventory'),
              ),
            ],
          ),
        ),
      );
    }

    if (isEdit && !_initialized) {
      final detailAsync = ref.watch(medicineDetailProvider(widget.medicineId!));
      detailAsync.whenData((med) {
        if (med != null) _populateExisting(med);
      });
    }

    if (isEdit) {
      return _buildCustomFormView(tokens, currency, isEdit);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Mode Header Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: tokens.colors.card,
            borderRadius: BorderRadius.circular(AppRadiusTokens.tile),
            border: Border.all(color: tokens.colors.line),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 700;

              final titleSection = Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: AppColorsTokens.brandGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(LucideIcons.packagePlus, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Add Medicine to Pharmacy',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                        Text(
                          'Select from Pakistan pharmaceutical catalog or register a custom medicine',
                          style: TextStyle(fontSize: 12, color: tokens.colors.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              );

              final toggleSection = Container(
                decoration: BoxDecoration(
                  color: tokens.colors.track,
                  borderRadius: BorderRadius.circular(AppRadiusTokens.pill),
                  border: Border.all(color: tokens.colors.line),
                ),
                padding: const EdgeInsets.all(3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTabButton(
                      index: 0,
                      label: 'Pakistan Catalog (1-Click)',
                      icon: LucideIcons.sparkles,
                      tokens: tokens,
                    ),
                    _buildTabButton(
                      index: 1,
                      label: 'Custom Form',
                      icon: LucideIcons.edit3,
                      tokens: tokens,
                    ),
                  ],
                ),
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleSection,
                    const SizedBox(height: 12),
                    toggleSection,
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: titleSection),
                  const SizedBox(width: 16),
                  toggleSection,
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        // Main Content based on active tab
        if (_selectedTabIndex == 0)
          _buildCatalogQuickAddView(tokens, currency)
        else
          _buildCustomFormView(tokens, currency, false),
      ],
    );
  }

  Widget _buildTabButton({
    required int index,
    required String label,
    required IconData icon,
    required AppTokens tokens,
  }) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColorsTokens.brand : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadiusTokens.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : tokens.colors.muted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : tokens.colors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCatalogQuickAddView(AppTokens tokens, String currency) {
    final existingMedicines = ref.watch(medicinesListProvider).value ?? [];

    MedicineModel? findInPharmacy(MedicineTemplate item) {
      final cleanName = item.name.toLowerCase();
      final cleanBarcode = item.defaultBarcode;
      final cleanReg = item.registrationNumber?.toLowerCase();

      for (final med in existingMedicines) {
        if (cleanReg != null && cleanReg.isNotEmpty && med.registrationNumber != null) {
          if (med.registrationNumber!.toLowerCase() == cleanReg) return med;
        }
        if (cleanBarcode != null && cleanBarcode.isNotEmpty && med.barcode != null) {
          if (med.barcode == cleanBarcode) return med;
        }
        if (med.name.toLowerCase() == cleanName ||
            (med.brandName != null && med.brandName!.toLowerCase() == cleanName)) {
          return med;
        }
        if (item.brandName != null &&
            item.brandName!.isNotEmpty &&
            med.brandName != null &&
            med.brandName!.toLowerCase() == item.brandName!.toLowerCase()) {
          return med;
        }
      }
      return null;
    }

    // Build unified list of medicine templates for quick add
    final List<MedicineTemplate> allDisplayTemplates = List.from(StandardMedicineCatalog.items);

    // Also include custom medicines created by storekeeper that aren't already in standard catalog
    for (final med in existingMedicines) {
      final alreadyInCatalog = StandardMedicineCatalog.items.any(
        (t) => t.name.toLowerCase() == med.name.toLowerCase() ||
               (med.barcode != null && t.defaultBarcode == med.barcode) ||
               (med.registrationNumber != null && t.registrationNumber == med.registrationNumber),
      );
      if (!alreadyInCatalog) {
        allDisplayTemplates.add(
          MedicineTemplate(
            name: med.name,
            brandName: med.brandName,
            registrationNumber: med.registrationNumber,
            genericName: med.genericName ?? 'Custom Formula',
            category: med.category ?? 'General',
            manufacturer: med.manufacturer ?? 'Local Supplier',
            defaultUnit: med.unit,
            suggestedPrice: med.salePrice,
            defaultDiscount: med.discountPercent,
            defaultBarcode: med.barcode,
            description: 'Custom registered medicine in your pharmacy stock.',
            imageUrl: med.imageUrl,
          ),
        );
      }
    }

    final allCategories = ['All', 'My Pharmacy Stock', ...StandardMedicineCatalog.categories];

    final filtered = allDisplayTemplates.where((item) {
      final inStockMed = findInPharmacy(item);

      if (_catalogSelectedCategory == 'My Pharmacy Stock') {
        if (inStockMed == null) return false;
      } else if (_catalogSelectedCategory != 'All' && item.category != _catalogSelectedCategory) {
        return false;
      }

      if (_catalogSearchQuery.isNotEmpty) {
        final q = _catalogSearchQuery.toLowerCase();
        final match = item.name.toLowerCase().contains(q) ||
            item.genericName.toLowerCase().contains(q) ||
            item.manufacturer.toLowerCase().contains(q) ||
            (item.brandName?.toLowerCase().contains(q) ?? false) ||
            (item.registrationNumber?.toLowerCase().contains(q) ?? false) ||
            (item.defaultBarcode?.contains(q) ?? false);
        if (!match) return false;
      }
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1-Click Import All Banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColorsTokens.brand.withValues(alpha: 0.12),
                AppColorsTokens.brand.withValues(alpha: 0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(AppRadiusTokens.largeCard),
            border: Border.all(color: AppColorsTokens.brand.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppColorsTokens.brandGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(LucideIcons.sparkles, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pakistan Pharmaceutical Master Catalog',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Click "+ Add" on any medicine card below to add to your Firebase inventory, or use 1-Click Import to add all ${allDisplayTemplates.length} common medicines to Firebase Products & POS at once.',
                      style: TextStyle(fontSize: 12, color: tokens.colors.muted),
                    ),
                    if (_isBatchImporting) ...[
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: _batchImportTotal > 0 ? (_batchImportProgress / _batchImportTotal) : null,
                        color: AppColorsTokens.brand,
                        backgroundColor: tokens.colors.line,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Saving medicines to Firebase... ($_batchImportProgress / $_batchImportTotal)',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColorsTokens.brand),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              AppButton(
                text: _isBatchImporting
                    ? 'Saving...'
                    : '⚡ 1-Click Import All (${filtered.length})',
                isLoading: _isBatchImporting,
                icon: const Icon(LucideIcons.downloadCloud, size: 16, color: Colors.white),
                onPressed: _isBatchImporting ? null : () => _handleBatchImportAll(filtered),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Search Field
        AppSearchField(
          maxWidth: double.infinity,
          placeholder: 'Search Pakistan catalog by medicine name, brand, DRAP Reg No, formula, or barcode...',
          onChanged: (val) => setState(() => _catalogSearchQuery = val.trim()),
        ),
        const SizedBox(height: 12),

        // Category Filter Pills
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: allCategories.map((cat) {
              final isSel = _catalogSelectedCategory == cat;
              final isStockCategory = cat == 'My Pharmacy Stock';

              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: GestureDetector(
                  onTap: () => setState(() => _catalogSelectedCategory = cat),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      gradient: isSel ? AppColorsTokens.brandGradient : null,
                      color: isSel
                          ? null
                          : isStockCategory
                              ? AppColorsTokens.success.withValues(alpha: 0.12)
                              : tokens.colors.card,
                      borderRadius: BorderRadius.circular(AppRadiusTokens.pill),
                      border: Border.all(
                        color: isSel
                            ? Colors.transparent
                            : isStockCategory
                                ? AppColorsTokens.success.withValues(alpha: 0.4)
                                : tokens.colors.line,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isStockCategory) ...[
                          Icon(
                            LucideIcons.boxes,
                            size: 13,
                            color: isSel ? Colors.white : AppColorsTokens.success,
                          ),
                          const SizedBox(width: 5),
                        ],
                        Text(
                          cat,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                            color: isSel
                                ? Colors.white
                                : isStockCategory
                                    ? AppColorsTokens.success
                                    : tokens.colors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),

        // Catalog Grid
        if (filtered.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: tokens.colors.card,
              borderRadius: BorderRadius.circular(AppRadiusTokens.tile),
              border: Border.all(color: tokens.colors.line),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.packageSearch, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text('No medicines match your query.', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Switch to "Custom Form" to take a photo and register custom medicine.',
                      style: TextStyle(fontSize: 12, color: tokens.colors.muted)),
                ],
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 360,
              mainAxisExtent: 236,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
            ),
            itemCount: filtered.length,
            itemBuilder: (context, idx) {
              final item = filtered[idx];
              final inStock = findInPharmacy(item);

              return InkWell(
                onTap: () => _showQuickAddDialog(item, currency, existingMed: inStock),
                borderRadius: BorderRadius.circular(AppRadiusTokens.largeCard),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: tokens.colors.card,
                    borderRadius: BorderRadius.circular(AppRadiusTokens.largeCard),
                    border: Border.all(
                      color: inStock != null
                          ? AppColorsTokens.success.withValues(alpha: 0.35)
                          : tokens.colors.line,
                    ),
                    boxShadow: [tokens.colors.shadow],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: item.imageUrl != null
                                ? Image.network(
                                    item.imageUrl!,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return LoadingSkeleton.imageBox(width: 48, height: 48, radius: 10);
                                    },
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 48,
                                      height: 48,
                                      color: AppColorsTokens.brand.withValues(alpha: 0.1),
                                      child: const Icon(LucideIcons.pill, color: AppColorsTokens.brand, size: 24),
                                    ),
                                  )
                                : Container(
                                    width: 48,
                                    height: 48,
                                    color: AppColorsTokens.brand.withValues(alpha: 0.1),
                                    child: const Icon(LucideIcons.pill, color: AppColorsTokens.brand, size: 24),
                                  ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  item.genericName,
                                  style: TextStyle(fontSize: 12, color: tokens.colors.muted),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (item.registrationNumber != null)
                                  Text(
                                    'Reg: ${item.registrationNumber}',
                                    style: TextStyle(fontSize: 10, color: tokens.colors.muted),
                                  ),
                              ],
                            ),
                          ),
                          if (inStock != null)
                            StatusBadge(
                              label: 'In Stock (${inStock.availableStock})',
                              variant: StatusBadgeVariant.success,
                            )
                          else
                            StatusBadge(
                              label: item.category,
                              variant: StatusBadgeVariant.info,
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.description,
                        style: TextStyle(fontSize: 11, color: tokens.colors.muted),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${item.manufacturer} • ${item.defaultUnit}',
                                style: TextStyle(fontSize: 11, color: tokens.colors.muted),
                              ),
                              Text(
                                '$currency ${item.suggestedPrice.toStringAsFixed(0)}',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColorsTokens.brand),
                              ),
                            ],
                          ),
                          AppButton(
                            text: inStock != null ? 'Add Stock' : 'Add',
                            icon: Icon(
                              inStock != null ? LucideIcons.boxes : LucideIcons.plus,
                              size: 14,
                              color: Colors.white,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            height: 34,
                            onPressed: () => _showQuickAddDialog(item, currency, existingMed: inStock),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildCustomFormView(AppTokens tokens, String currency, bool isEdit) {
    final actionState = ref.watch(inventoryActionControllerProvider);
    final isLoading = actionState.isLoading || _isUploadingImage;
    final existingMedicines = ref.watch(medicinesListProvider).value ?? [];
    final matchedDuplicate = !isEdit ? _findMatchingMedicine(existingMedicines) : null;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: SectionCard(
          title: isEdit ? 'Update Medicine Details' : 'Register Custom Medicine',
          subtitle: isEdit
              ? 'Modify price, stock, photo, unit, and alert thresholds'
              : 'Take a photo, set stock and price to save directly to Firebase',
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Medicine Photo Capture Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: tokens.colors.track,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _capturedImageBytes != null
                          ? AppColorsTokens.brand
                          : tokens.colors.line,
                      width: _capturedImageBytes != null ? 1.5 : 1.0,
                    ),
                  ),
                  child: Column(
                    children: [
                      if (_capturedImageBytes != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            _capturedImageBytes!,
                            height: 160,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            OutlinedButton.icon(
                              icon: const Icon(LucideIcons.camera, size: 14),
                              label: const Text('Retake Photo'),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadiusTokens.pill)),
                              ),
                              onPressed: () => _pickImage(ImageSource.camera),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              icon: const Icon(LucideIcons.image, size: 14),
                              label: const Text('Change from Gallery'),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadiusTokens.pill)),
                              ),
                              onPressed: () => _pickImage(ImageSource.gallery),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(LucideIcons.trash2, color: AppColorsTokens.danger, size: 18),
                              tooltip: 'Remove Photo',
                              onPressed: () => setState(() {
                                _capturedImageBytes = null;
                                _capturedImageName = null;
                              }),
                            ),
                          ],
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColorsTokens.brand.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(LucideIcons.camera, color: AppColorsTokens.brand, size: 28),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Take Photo of Medicine Box / Strip',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Storekeeper can take a quick picture to save with stock and price in Firebase',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: tokens.colors.muted),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            AppButton(
                              text: 'Take Photo (Camera)',
                              icon: const Icon(LucideIcons.camera, size: 15, color: Colors.white),
                              height: 36,
                              onPressed: () => _pickImage(ImageSource.camera),
                            ),
                            OutlinedButton.icon(
                              icon: const Icon(LucideIcons.imagePlus, size: 15),
                              label: const Text('Upload from Gallery'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: tokens.colors.ink,
                                side: BorderSide(color: tokens.colors.line),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadiusTokens.pill)),
                              ),
                              onPressed: () => _pickImage(ImageSource.gallery),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Duplicate Detection Warning Banner
                if (matchedDuplicate != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColorsTokens.amber.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColorsTokens.amber),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(LucideIcons.alertCircle, color: AppColorsTokens.amber, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Medicine Already in Stock: "${matchedDuplicate.name}"',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColorsTokens.amberText),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Current available stock: ${matchedDuplicate.availableStock} ${matchedDuplicate.unit}. Saving will add the new stock units and update prices rather than creating a duplicate entry!',
                                style: TextStyle(fontSize: 12, color: tokens.colors.ink),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 3. Brand Name & Registration Number Row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _brandNameController,
                        decoration: const InputDecoration(
                          labelText: 'Brand Name',
                          hintText: 'e.g. Panadol, Augmentin, Brufen',
                          prefixIcon: Icon(LucideIcons.tag),
                          helperText: 'Commercial brand identity',
                        ),
                        onChanged: (val) {
                          setState(() {});
                          if (_nameController.text.trim().isEmpty && val.trim().isNotEmpty) {
                            _nameController.text = val.trim();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextFormField(
                        controller: _registrationNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Registration No. (DRAP Reg #)',
                          hintText: 'e.g. 001245, DRAP-8821',
                          prefixIcon: Icon(LucideIcons.shieldCheck),
                          helperText: 'Official regulatory approval number',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 4. Medicine Full Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Medicine / Trade Name *',
                    hintText: 'e.g. Panadol Extra 500mg, Augmentin 625mg',
                    prefixIcon: Icon(LucideIcons.pill),
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                // 5. Generic & Category Row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _genericController,
                        decoration: const InputDecoration(
                          labelText: 'Generic / Formula Name',
                          hintText: 'e.g. Paracetamol + Caffeine',
                          prefixIcon: Icon(LucideIcons.flaskConical),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextFormField(
                        controller: _categoryController,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          hintText: 'e.g. Analgesic, Antibiotic',
                          prefixIcon: Icon(LucideIcons.tag),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 6. Manufacturer & Packaging Unit Row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _manufacturerController,
                        decoration: const InputDecoration(
                          labelText: 'Manufacturer / Brand',
                          hintText: 'e.g. GSK, Pfizer, Searle',
                          prefixIcon: Icon(LucideIcons.building2),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _units.contains(_selectedUnit) ? _selectedUnit : _units.first,
                        decoration: const InputDecoration(
                          labelText: 'Packaging Unit *',
                          prefixIcon: Icon(LucideIcons.package),
                        ),
                        items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedUnit = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 7. Retail Price & Discount Row
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _salePriceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Retail Sale Price *',
                          prefixText: '$currency ',
                          prefixIcon: const Icon(LucideIcons.dollarSign),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Price is required' : null,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _discountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Discount %',
                          suffixText: '%',
                          prefixIcon: Icon(LucideIcons.percent),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 8. Stock Units & Low Stock Threshold Row
                Row(
                  children: [
                    if (!isEdit) ...[
                      Expanded(
                        child: TextFormField(
                          controller: _initialStockController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: matchedDuplicate != null ? 'Additional Units to Add *' : 'Initial Units in Stock *',
                            prefixIcon: const Icon(LucideIcons.boxes),
                            helperText: matchedDuplicate != null
                                ? 'New stock total: ${(matchedDuplicate.availableStock) + (int.tryParse(_initialStockController.text) ?? 0)}'
                                : 'Creates 1st batch with QR automatically',
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 14),
                    ],
                    Expanded(
                      child: TextFormField(
                        controller: _minStockController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Low Stock Threshold *',
                          prefixIcon: Icon(LucideIcons.alertTriangle),
                          helperText: 'Trigger low stock alerts below this count',
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 9. Manufacturer Barcode
                TextFormField(
                  controller: _barcodeController,
                  decoration: InputDecoration(
                    labelText: 'Manufacturer Barcode (Optional)',
                    hintText: 'Scan or enter packaging barcode',
                    prefixIcon: const Icon(LucideIcons.barcode),
                    suffixIcon: IconButton(
                      icon: const Icon(LucideIcons.camera),
                      tooltip: 'Scan with Camera / Scanner',
                      onPressed: () => _scanBarcodeInto(_barcodeController),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),

                // 10. Direct Image URL (Optional)
                TextFormField(
                  controller: _imageUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Medicine Image URL (Optional if photo captured above)',
                    hintText: 'https://...',
                    prefixIcon: Icon(LucideIcons.image),
                  ),
                ),
                const SizedBox(height: 24),

                AppButton(
                  text: isEdit
                      ? 'Update Medicine'
                      : matchedDuplicate != null
                          ? 'Add Stock to Existing Medicine (No Duplicate)'
                          : 'Register Medicine & Generate QR Code',
                  icon: Icon(
                    matchedDuplicate != null ? LucideIcons.boxes : LucideIcons.checkCircle2,
                    size: 16,
                    color: Colors.white,
                  ),
                  isLoading: isLoading,
                  onPressed: _handleCustomSave,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
