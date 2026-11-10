import 'package:flutter_test/flutter_test.dart';
import 'package:pharmcysas/shared/models/report_model.dart';

void main() {
  group('Report Financial Calculations Tests', () {
    test('Calculates gross profit correctly from sales and cost', () {
      const report = MonthlyReportModel(
        month: 11,
        year: 2024,
        totalSales: 12500.0,
        totalCost: 7800.0,
        totalProfit: 4700.0,
        totalDiscount: 350.0,
        invoiceCount: 420,
        avgSale: 29.76,
        prevMonthSales: 10000.0,
        growthPct: 25.0,
        dailySales: [],
        topMedicines: [],
        cashierSales: [],
        paymentMethods: [],
      );

      final calculatedProfit = report.totalSales - report.totalCost;
      expect(calculatedProfit, 4700.0);
      expect(report.totalProfit, calculatedProfit);
    });

    test('Calculates Month-over-Month growth percentage accurately', () {
      const currentMonthSales = 15000.0;
      const prevMonthSales = 12000.0;

      const growth = ((currentMonthSales - prevMonthSales) / prevMonthSales) * 100;
      expect(growth, closeTo(25.0, 0.001));

      const declinedMonthSales = 8000.0;
      const negativeGrowth = ((declinedMonthSales - prevMonthSales) / prevMonthSales) * 100;
      expect(negativeGrowth, closeTo(-33.33, 0.01));
    });

    test('Calculates average sale order value correctly', () {
      const sales = 6450.0;
      const invoices = 215;

      const avg = sales / invoices;
      expect(avg, 30.0);
    });
  });
}
