import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/sale_model.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/sales_repository.dart';

final salesSearchQueryProvider = StateProvider<String>((ref) => '');

final salesHistoryListProvider = StreamProvider<List<SaleModel>>((ref) async* {
  final profile = await ref.watch(currentProfileProvider.future);
  if (profile == null || profile.pharmacyId == null) {
    yield [];
    return;
  }

  final repo = ref.watch(salesRepositoryProvider);
  final search = ref.watch(salesSearchQueryProvider);

  yield* repo.watchSales(
    pharmacyId: profile.pharmacyId!,
    searchQuery: search,
  );
});

