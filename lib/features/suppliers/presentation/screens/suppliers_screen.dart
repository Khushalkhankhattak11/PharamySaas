import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/models/supplier_model.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_data_table.dart';
import '../../../../shared/widgets/app_search_field.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/section_card.dart';
import '../controllers/suppliers_controller.dart';

class SuppliersScreen extends ConsumerStatefulWidget {
  const SuppliersScreen({super.key});

  @override
  ConsumerState<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends ConsumerState<SuppliersScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddEditDialog(BuildContext context, [SupplierModel? supplier]) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: supplier?.name ?? '');
    final phoneController = TextEditingController(text: supplier?.phone ?? '');
    final addressController = TextEditingController(text: supplier?.address ?? '');
    final isEdit = supplier != null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadiusTokens.largeCard)),
        title: Text(isEdit ? 'Edit Supplier' : 'Add New Supplier'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Company / Supplier Name *',
                    prefixIcon: Icon(LucideIcons.building),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Contact Phone',
                    prefixIcon: Icon(LucideIcons.phone),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: addressController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Office / Warehouse Address',
                    prefixIcon: Icon(LucideIcons.mapPin),
                  ),
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
          AppButton(
            text: isEdit ? 'Save Changes' : 'Create Supplier',
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx);

              try {
                final controller = ref.read(suppliersActionControllerProvider.notifier);
                if (isEdit) {
                  await controller.updateSupplier(
                    supplierId: supplier.id,
                    name: nameController.text.trim(),
                    phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
                    address: addressController.text.trim().isEmpty ? null : addressController.text.trim(),
                  );
                } else {
                  await controller.createSupplier(
                    name: nameController.text.trim(),
                    phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
                    address: addressController.text.trim().isEmpty ? null : addressController.text.trim(),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: AppColorsTokens.danger),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, SupplierModel supplier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadiusTokens.largeCard)),
        title: Text('Delete "${supplier.name}"?'),
        content: const Text(
          'Are you sure you want to remove this supplier? Past purchase records associated with this supplier will be preserved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          AppButton.danger(
            text: 'Delete',
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(suppliersActionControllerProvider.notifier).deleteSupplier(supplier.id);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting supplier: $e'), backgroundColor: AppColorsTokens.danger),
                  );
                }
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
    final suppliersAsync = ref.watch(suppliersListProvider);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        // Controls Row
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
                    placeholder: 'Search supplier name, phone, or address...',
                    onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                  ),
                  const SizedBox(height: 10),
                  AppButton(
                    text: '+ Add Supplier',
                    icon: const Icon(LucideIcons.plus, size: 16, color: Colors.white),
                    onPressed: () => _showAddEditDialog(context),
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
                    placeholder: 'Search supplier name, phone, or address...',
                    onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                  ),
                ),
                const SizedBox(width: 12),
                AppButton(
                  text: '+ Add Supplier',
                  icon: const Icon(LucideIcons.plus, size: 16, color: Colors.white),
                  onPressed: () => _showAddEditDialog(context),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),

        suppliersAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(48),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (err, _) => Center(child: Text('Error: $err')),
          data: (suppliers) {
            final filtered = _searchQuery.isEmpty
                ? suppliers
                : suppliers.where((s) {
                    final n = s.name.toLowerCase();
                    final p = s.phone?.toLowerCase() ?? '';
                    final a = s.address?.toLowerCase() ?? '';
                    return n.contains(_searchQuery) || p.contains(_searchQuery) || a.contains(_searchQuery);
                  }).toList();

            if (filtered.isEmpty) {
              return EmptyState(
                title: 'No Suppliers Found',
                subtitle: 'Add pharmaceutical distributors and manufacturers to track stock-ins.',
                icon: LucideIcons.truck,
                actionLabel: 'Add First Supplier',
                onAction: () => _showAddEditDialog(context),
              );
            }

            const columns = [
              AppTableColumn(label: 'Company Name', flex: 3),
              AppTableColumn(label: 'Phone Contact', flex: 2),
              AppTableColumn(label: 'Address / Warehouse', flex: 4),
              AppTableColumn(label: 'Actions', align: TextAlign.right, flex: 2),
            ];

            final rows = filtered.map((s) {
              return [
                Text(
                  s.name,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColorsTokens.brand),
                ),
                Text(s.phone ?? '—', style: const TextStyle(fontSize: 13)),
                Text(
                  s.address ?? '—',
                  style: TextStyle(fontSize: 12, color: tokens.colors.muted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(LucideIcons.edit2, size: 16),
                        color: tokens.colors.muted,
                        onPressed: () => _showAddEditDialog(context, s),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.trash2, size: 16),
                        color: AppColorsTokens.danger,
                        onPressed: () => _confirmDelete(context, s),
                      ),
                    ],
                  ),
                ),
              ];
            }).toList();

            final mobileCards = filtered.map((s) {
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: tokens.colors.card,
                  borderRadius: BorderRadius.circular(AppRadiusTokens.tile),
                  border: Border.all(color: tokens.colors.line),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          if (s.phone != null)
                            Text(s.phone!, style: TextStyle(fontSize: 12, color: tokens.colors.muted)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.edit2, size: 18),
                      onPressed: () => _showAddEditDialog(context, s),
                    ),
                  ],
                ),
              );
            }).toList();

            return SectionCard(
              title: 'Suppliers Directory',
              subtitle: 'Showing ${filtered.length} suppliers and distributors',
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
