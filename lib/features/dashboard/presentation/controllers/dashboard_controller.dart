import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/dashboard_summary_model.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../inventory/presentation/controllers/inventory_controller.dart';
import '../../../sales/presentation/controllers/sales_controller.dart';
import '../../data/dashboard_repository.dart';

final dashboardSummaryProvider = FutureProvider<DashboardSummaryModel>((ref) async {
  final profile = await ref.watch(currentProfileProvider.future);
  if (profile == null || profile.pharmacyId == null) {
    return const DashboardSummaryModel(
      todaySales: 0,
      todayInvoices: 0,
      lowStockCount: 0,
      expiringSoonCount: 0,
      recentSales: [],
    );
  }

  // Auto-react in real-time to sales and inventory changes across all roles
  ref.watch(salesHistoryListProvider);
  ref.watch(medicinesListProvider);

  final repo = ref.watch(dashboardRepositoryProvider);
  return await repo.getSummary(profile.pharmacyId!);
});

