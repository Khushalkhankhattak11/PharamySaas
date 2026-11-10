import 'package:fl_chart/fl_chart.dart';
import '../widgets/donut_chart_card.dart';
import '../widgets/pill_bar_chart.dart';
import 'sale_model.dart';

class DashboardSummaryModel {
  final double todaySales;
  final int todayInvoices;
  final int lowStockCount;
  final int expiringSoonCount;
  final int expiredCount;
  final int totalMedicines;
  final int totalUnitsInStock;
  final List<SaleModel> recentSales;

  // Dynamic financial figures
  final double totalRevenue;
  final double totalProfit;
  final double totalPurchases;
  final int totalInvoices;

  // Chart series
  final List<FlSpot> monthlySpots;
  final List<String> monthLabels;
  final int currentMonthIndex;
  final List<DaySales> weekSales;
  final List<CategoryShare> categoryShares;

  const DashboardSummaryModel({
    required this.todaySales,
    required this.todayInvoices,
    required this.lowStockCount,
    required this.expiringSoonCount,
    this.expiredCount = 0,
    this.totalMedicines = 0,
    this.totalUnitsInStock = 0,
    required this.recentSales,
    this.totalRevenue = 0.0,
    this.totalProfit = 0.0,
    this.totalPurchases = 0.0,
    this.totalInvoices = 0,
    this.monthlySpots = const [],
    this.monthLabels = const [],
    this.currentMonthIndex = 5,
    this.weekSales = const [],
    this.categoryShares = const [],
  });
}
