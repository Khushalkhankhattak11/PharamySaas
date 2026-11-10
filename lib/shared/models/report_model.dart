class DailySaleEntry {
  final int day;
  final double total;
  final int count;

  const DailySaleEntry({
    required this.day,
    required this.total,
    required this.count,
  });

  factory DailySaleEntry.fromJson(Map<String, dynamic> json) {
    return DailySaleEntry(
      day: json['day'] as int? ?? 1,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      count: json['count'] as int? ?? 0,
    );
  }
}

class TopMedicineEntry {
  final String medicineName;
  final int totalQuantity;
  final double revenue;
  final double profit;

  const TopMedicineEntry({
    required this.medicineName,
    required this.totalQuantity,
    required this.revenue,
    required this.profit,
  });

  factory TopMedicineEntry.fromJson(Map<String, dynamic> json) {
    return TopMedicineEntry(
      medicineName: json['medicine_name'] as String? ?? '',
      totalQuantity: json['total_quantity'] as int? ?? 0,
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0.0,
      profit: (json['profit'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class CashierSaleEntry {
  final String cashierName;
  final int invoiceCount;
  final double totalSales;

  const CashierSaleEntry({
    required this.cashierName,
    required this.invoiceCount,
    required this.totalSales,
  });

  factory CashierSaleEntry.fromJson(Map<String, dynamic> json) {
    return CashierSaleEntry(
      cashierName: json['cashier_name'] as String? ?? 'Staff',
      invoiceCount: json['invoice_count'] as int? ?? 0,
      totalSales: (json['total_sales'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class PaymentMethodEntry {
  final String paymentMethod;
  final int count;
  final double totalAmount;

  const PaymentMethodEntry({
    required this.paymentMethod,
    required this.count,
    required this.totalAmount,
  });

  factory PaymentMethodEntry.fromJson(Map<String, dynamic> json) {
    return PaymentMethodEntry(
      paymentMethod: json['payment_method'] as String? ?? 'Cash',
      count: json['count'] as int? ?? 0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class MonthlyReportModel {
  final int month;
  final int year;
  final double totalSales;
  final double totalCost;
  final double totalProfit;
  final double totalDiscount;
  final int invoiceCount;
  final double avgSale;
  final double prevMonthSales;
  final double growthPct;
  final List<DailySaleEntry> dailySales;
  final List<TopMedicineEntry> topMedicines;
  final List<CashierSaleEntry> cashierSales;
  final List<PaymentMethodEntry> paymentMethods;

  const MonthlyReportModel({
    required this.month,
    required this.year,
    required this.totalSales,
    required this.totalCost,
    required this.totalProfit,
    required this.totalDiscount,
    required this.invoiceCount,
    required this.avgSale,
    required this.prevMonthSales,
    required this.growthPct,
    required this.dailySales,
    required this.topMedicines,
    required this.cashierSales,
    required this.paymentMethods,
  });

  factory MonthlyReportModel.fromJson(Map<String, dynamic> json) {
    final dailyList = (json['daily_sales'] as List? ?? [])
        .map((i) => DailySaleEntry.fromJson(Map<String, dynamic>.from(i as Map)))
        .toList();

    final topList = (json['top_medicines'] as List? ?? [])
        .map((i) => TopMedicineEntry.fromJson(Map<String, dynamic>.from(i as Map)))
        .toList();

    final cashierList = (json['cashier_sales'] as List? ?? [])
        .map((i) => CashierSaleEntry.fromJson(Map<String, dynamic>.from(i as Map)))
        .toList();

    final paymentList = (json['payment_methods'] as List? ?? [])
        .map((i) => PaymentMethodEntry.fromJson(Map<String, dynamic>.from(i as Map)))
        .toList();

    return MonthlyReportModel(
      month: json['month'] as int? ?? DateTime.now().month,
      year: json['year'] as int? ?? DateTime.now().year,
      totalSales: (json['total_sales'] as num?)?.toDouble() ?? 0.0,
      totalCost: (json['total_cost'] as num?)?.toDouble() ?? 0.0,
      totalProfit: (json['total_profit'] as num?)?.toDouble() ?? 0.0,
      totalDiscount: (json['total_discount'] as num?)?.toDouble() ?? 0.0,
      invoiceCount: json['invoice_count'] as int? ?? 0,
      avgSale: (json['avg_sale'] as num?)?.toDouble() ?? 0.0,
      prevMonthSales: (json['prev_month_sales'] as num?)?.toDouble() ?? 0.0,
      growthPct: (json['growth_pct'] as num?)?.toDouble() ?? 0.0,
      dailySales: dailyList,
      topMedicines: topList,
      cashierSales: cashierList,
      paymentMethods: paymentList,
    );
  }
}

