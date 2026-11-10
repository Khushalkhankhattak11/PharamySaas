import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/cart_item_model.dart';
import '../../../../shared/models/medicine_model.dart';
import '../../../../shared/models/sale_model.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../inventory/data/inventory_repository.dart';
import '../../../inventory/presentation/controllers/inventory_controller.dart';
import '../../data/pos_repository.dart';

final posSearchQueryProvider = StateProvider<String>((ref) => '');

final posMedicinesStreamProvider = StreamProvider<List<MedicineModel>>((ref) async* {
  final profile = await ref.watch(currentProfileProvider.future);
  if (profile == null || profile.pharmacyId == null) {
    yield [];
    return;
  }
  final repo = ref.watch(inventoryRepositoryProvider);
  final search = ref.watch(posSearchQueryProvider);
  yield* repo.watchMedicines(
    pharmacyId: profile.pharmacyId!,
    search: search,
    filter: 'all',
  );
});

class CartState {
  final List<CartItemModel> items;
  final double discount;
  final String customerName;
  final String paymentMethod;
  final bool isSubmitting;
  final String? errorMessage;
  final SaleModel? lastCompletedSale;

  const CartState({
    this.items = const [],
    this.discount = 0.0,
    this.customerName = 'Walk-in Customer',
    this.paymentMethod = 'Cash',
    this.isSubmitting = false,
    this.errorMessage,
    this.lastCompletedSale,
  });

  double get subtotal => items.fold(0.0, (sum, i) => sum + i.lineTotal);
  double get total => (subtotal - discount).clamp(0.0, double.infinity);
  int get totalItemCount => items.fold(0, (sum, i) => sum + i.quantity);

  CartState copyWith({
    List<CartItemModel>? items,
    double? discount,
    String? customerName,
    String? paymentMethod,
    bool? isSubmitting,
    String? errorMessage,
    SaleModel? lastCompletedSale,
    bool clearLastCompleted = false,
  }) {
    return CartState(
      items: items ?? this.items,
      discount: discount ?? this.discount,
      customerName: customerName ?? this.customerName,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
      lastCompletedSale: clearLastCompleted ? null : (lastCompletedSale ?? this.lastCompletedSale),
    );
  }
}

class CartController extends StateNotifier<CartState> {
  final PosRepository _repository;
  final Ref _ref;

  CartController(this._repository, this._ref) : super(const CartState());

  void addItem(MedicineModel medicine) {
    if (medicine.availableStock <= 0) {
      throw Exception('Medicine "${medicine.name}" has no available stock.');
    }

    final index = state.items.indexWhere((i) => i.medicineId == medicine.id);
    if (index >= 0) {
      final existing = state.items[index];
      if (existing.quantity >= medicine.availableStock) {
        throw Exception('Cannot exceed available stock of ${medicine.availableStock} ${medicine.unit}');
      }
      final updatedList = List<CartItemModel>.from(state.items);
      updatedList[index] = existing.copyWith(quantity: existing.quantity + 1);
      state = state.copyWith(items: updatedList);
    } else {
      final newItem = CartItemModel(
        medicineId: medicine.id,
        name: medicine.name,
        unit: medicine.unit,
        unitPrice: medicine.salePrice,
        availableStock: medicine.availableStock,
        quantity: 1,
      );
      state = state.copyWith(items: [...state.items, newItem]);
    }
  }

  Future<void> addByScannedCode(String code) async {
    final lookup = await _repository.lookupByCode(code);
    if (lookup['found'] != true) {
      throw Exception('No medicine found for code "$code"');
    }

    final medId = lookup['medicine_id'] as String;
    final name = lookup['medicine_name'] as String;
    final unit = lookup['unit'] as String? ?? 'Strip';
    final price = (lookup['sale_price'] as num).toDouble();
    final avail = (lookup['available_stock'] as num).toInt();

    if (avail <= 0) {
      throw Exception('Medicine "$name" is out of stock.');
    }

    final index = state.items.indexWhere((i) => i.medicineId == medId);
    if (index >= 0) {
      final existing = state.items[index];
      if (existing.quantity >= avail) {
        throw Exception('Cannot exceed available stock of $avail $unit');
      }
      final updatedList = List<CartItemModel>.from(state.items);
      updatedList[index] = existing.copyWith(quantity: existing.quantity + 1);
      state = state.copyWith(items: updatedList);
    } else {
      final newItem = CartItemModel(
        medicineId: medId,
        name: name,
        unit: unit,
        unitPrice: price,
        availableStock: avail,
        quantity: 1,
      );
      state = state.copyWith(items: [...state.items, newItem]);
    }
  }

  void updateQuantity(String medicineId, int quantity) {
    if (quantity <= 0) {
      removeItem(medicineId);
      return;
    }

    final index = state.items.indexWhere((i) => i.medicineId == medicineId);
    if (index >= 0) {
      final existing = state.items[index];
      if (quantity > existing.availableStock) {
        throw Exception('Cannot exceed available stock of ${existing.availableStock} ${existing.unit}');
      }
      final updatedList = List<CartItemModel>.from(state.items);
      updatedList[index] = existing.copyWith(quantity: quantity);
      state = state.copyWith(items: updatedList);
    }
  }

  void removeItem(String medicineId) {
    state = state.copyWith(
      items: state.items.where((i) => i.medicineId != medicineId).toList(),
    );
  }

  void setDiscount(double discount) {
    state = state.copyWith(discount: discount.clamp(0.0, state.subtotal));
  }

  void setCustomerName(String name) {
    state = state.copyWith(customerName: name);
  }

  void setPaymentMethod(String method) {
    state = state.copyWith(paymentMethod: method);
  }

  void clearCart() {
    state = state.copyWith(
      items: [],
      discount: 0.0,
      customerName: 'Walk-in Customer',
      clearLastCompleted: true,
    );
  }

  Future<SaleModel> checkout() async {
    if (state.items.isEmpty) {
      throw Exception('Cart is empty.');
    }

    state = state.copyWith(isSubmitting: true, errorMessage: null);

    try {
      final sale = await _repository.createSale(
        items: state.items,
        discount: state.discount,
        paymentMethod: state.paymentMethod,
        customerName: state.customerName,
      );

      _ref.invalidate(medicinesListProvider);
      _ref.invalidate(posMedicinesStreamProvider);

      state = state.copyWith(
        isSubmitting: false,
        lastCompletedSale: sale,
      );

      return sale;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }
}

final cartControllerProvider =
    StateNotifierProvider<CartController, CartState>((ref) {
  final repo = ref.watch(posRepositoryProvider);
  return CartController(repo, ref);
});

