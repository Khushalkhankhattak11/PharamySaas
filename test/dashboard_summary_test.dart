import 'package:flutter_test/flutter_test.dart';
import 'package:pharmcysas/shared/models/dashboard_summary_model.dart';

void main() {
  group('DashboardSummaryModel Tests', () {
    test('Defaults to zero state for newly created pharmacy', () {
      const summary = DashboardSummaryModel(
        todaySales: 0.0,
        todayInvoices: 0,
        lowStockCount: 0,
        expiringSoonCount: 0,
        recentSales: [],
      );

      expect(summary.todaySales, 0.0);
      expect(summary.todayInvoices, 0);
      expect(summary.totalMedicines, 0);
      expect(summary.totalUnitsInStock, 0);
      expect(summary.expiredCount, 0);
      expect(summary.totalRevenue, 0.0);
      expect(summary.totalProfit, 0.0);
      expect(summary.totalPurchases, 0.0);
      expect(summary.totalInvoices, 0);
      expect(summary.recentSales, isEmpty);
      expect(summary.categoryShares, isEmpty);
      expect(summary.weekSales, isEmpty);
      expect(summary.monthlySpots, isEmpty);
    });

    test('Correctly stores and reports real pharmacy figures', () {
      const summary = DashboardSummaryModel(
        todaySales: 1540.0,
        todayInvoices: 3,
        lowStockCount: 2,
        expiringSoonCount: 1,
        expiredCount: 0,
        totalMedicines: 15,
        totalUnitsInStock: 450,
        recentSales: [],
        totalRevenue: 54000.0,
        totalProfit: 14000.0,
        totalPurchases: 40000.0,
        totalInvoices: 82,
      );

      expect(summary.todaySales, 1540.0);
      expect(summary.todayInvoices, 3);
      expect(summary.totalMedicines, 15);
      expect(summary.totalUnitsInStock, 450);
      expect(summary.totalRevenue, 54000.0);
      expect(summary.totalProfit, 14000.0);
      expect(summary.totalPurchases, 40000.0);
      expect(summary.totalInvoices, 82);
    });
  });
}
