import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/report_model.dart';
import '../../data/reports_repository.dart';

final selectedReportMonthProvider = StateProvider<int>((ref) => DateTime.now().month);
final selectedReportYearProvider = StateProvider<int>((ref) => DateTime.now().year);

final monthlyReportProvider = FutureProvider<MonthlyReportModel>((ref) async {
  final month = ref.watch(selectedReportMonthProvider);
  final year = ref.watch(selectedReportYearProvider);
  final repo = ref.watch(reportsRepositoryProvider);
  return await repo.getMonthlyReport(month, year);
});

