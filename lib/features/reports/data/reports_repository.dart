import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/firebase/firebase_providers.dart';
import '../../../core/firebase/firestore_collections.dart';
import '../../../shared/models/report_model.dart';
import '../../../shared/models/sale_model.dart';
import '../../auth/data/auth_repository.dart';

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final authRepo = ref.watch(authRepositoryProvider);
  return ReportsRepository(firestore, authRepo);
});

class ReportsRepository {
  final FirebaseFirestore _firestore;
  final AuthRepository _authRepo;

  ReportsRepository(this._firestore, this._authRepo);

  Future<MonthlyReportModel> getMonthlyReport(int month, int year) async {
    final user = _authRepo.currentUser;
    final profile = user != null ? await _authRepo.getProfile(user.id) : null;
    final pharmacyId = profile?.pharmacyId;

    if (pharmacyId == null) {
      return MonthlyReportModel(
        year: year,
        month: month,
        totalSales: 0.0,
        totalCost: 0.0,
        totalProfit: 0.0,
        totalDiscount: 0.0,
        invoiceCount: 0,
        avgSale: 0.0,
        prevMonthSales: 0.0,
        growthPct: 0.0,
        dailySales: [],
        topMedicines: [],
        cashierSales: [],
        paymentMethods: [],
      );
    }

    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 1).subtract(const Duration(milliseconds: 1));

    final snapshot = await _firestore
        .collection(FirestoreCollections.sales)
        .where('pharmacy_id', isEqualTo: pharmacyId)
        .get();

    final allSales = snapshot.docs.map((d) {
      final data = Map<String, dynamic>.from(d.data());
      data['id'] = d.id;
      return SaleModel.fromJson(data);
    }).toList();

    final currentMonthSales = allSales.where((s) {
      return s.createdAt.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
          s.createdAt.isBefore(endDate.add(const Duration(seconds: 1)));
    }).toList();

    double totalSales = 0.0;
    double totalCost = 0.0;
    double totalDiscount = 0.0;

    final Map<int, List<double>> dailyTotals = {};
    final Map<String, _MedAgg> medMap = {};
    final Map<String, _CashierAgg> cashierMap = {};
    final Map<String, _PaymentAgg> paymentMap = {};

    for (final s in currentMonthSales) {
      totalSales += s.total;
      totalDiscount += s.discount;

      // Payment Method
      final pMethod = s.paymentMethod;
      final pAgg = paymentMap.putIfAbsent(pMethod, () => _PaymentAgg(pMethod));
      pAgg.count++;
      pAgg.total += s.total;

      // Daily
      final day = s.createdAt.day;
      dailyTotals.putIfAbsent(day, () => []).add(s.total);

      // Cashier
      final cName = s.cashierName ?? 'Staff';
      final cAgg = cashierMap.putIfAbsent(cName, () => _CashierAgg(cName));
      cAgg.invoices++;
      cAgg.total += s.total;

      // Items & Cost
      for (final item in s.items) {
        final itemCost = (item.costPrice ?? 0.0) * item.quantity;
        totalCost += itemCost;

        final mAgg = medMap.putIfAbsent(item.medicineName, () => _MedAgg(item.medicineName));
        mAgg.qty += item.quantity;
        mAgg.revenue += item.total;
        mAgg.profit += (item.total - itemCost);
      }
    }

    final totalProfit = (totalSales - totalCost).clamp(0.0, double.infinity);
    final invoiceCount = currentMonthSales.length;
    final avgSale = invoiceCount > 0 ? (totalSales / invoiceCount) : 0.0;

    // Previous month sales for growth
    final prevMonthStart = DateTime(year, month - 1, 1);
    final prevMonthEnd = DateTime(year, month, 1).subtract(const Duration(milliseconds: 1));
    final prevMonthSalesList = allSales.where((s) {
      return s.createdAt.isAfter(prevMonthStart.subtract(const Duration(seconds: 1))) &&
          s.createdAt.isBefore(prevMonthEnd.add(const Duration(seconds: 1)));
    }).toList();
    final prevMonthSales = prevMonthSalesList.fold(0.0, (acc, s) => acc + s.total);
    final growthPct = prevMonthSales > 0 ? ((totalSales - prevMonthSales) / prevMonthSales) * 100 : 0.0;

    // Daily entries
    final List<DailySaleEntry> dailySales = [];
    final daysInMonth = DateTime(year, month + 1, 0).day;
    for (int d = 1; d <= daysInMonth; d++) {
      final list = dailyTotals[d] ?? [];
      dailySales.add(DailySaleEntry(
        day: d,
        total: list.fold(0.0, (acc, val) => acc + val),
        count: list.length,
      ));
    }

    // Top medicines
    final topMedsList = medMap.values.map((m) {
      return TopMedicineEntry(
        medicineName: m.name,
        totalQuantity: m.qty,
        revenue: m.revenue,
        profit: m.profit,
      );
    }).toList();
    topMedsList.sort((a, b) => b.totalQuantity.compareTo(a.totalQuantity));

    // Cashier sales
    final cashierSalesList = cashierMap.values.map((c) {
      return CashierSaleEntry(
        cashierName: c.name,
        invoiceCount: c.invoices,
        totalSales: c.total,
      );
    }).toList();
    cashierSalesList.sort((a, b) => b.totalSales.compareTo(a.totalSales));

    // Payment methods
    final paymentMethodsList = paymentMap.values.map((p) {
      return PaymentMethodEntry(
        paymentMethod: p.name,
        count: p.count,
        totalAmount: p.total,
      );
    }).toList();

    return MonthlyReportModel(
      year: year,
      month: month,
      totalSales: totalSales,
      totalCost: totalCost,
      totalProfit: totalProfit,
      totalDiscount: totalDiscount,
      invoiceCount: invoiceCount,
      avgSale: avgSale,
      prevMonthSales: prevMonthSales,
      growthPct: growthPct,
      dailySales: dailySales,
      topMedicines: topMedsList.take(10).toList(),
      cashierSales: cashierSalesList,
      paymentMethods: paymentMethodsList,
    );
  }

  Uint8List exportToExcel({
    required MonthlyReportModel report,
    required String pharmacyName,
    required String currency,
  }) {
    final excel = Excel.createExcel();
    final sheet = excel['Sales_Report_${report.year}_${report.month}'];
    excel.delete('Sheet1');

    sheet.appendRow([TextCellValue('PHARMACY SALES & PROFIT REPORT')]);
    sheet.appendRow([TextCellValue('Pharmacy:'), TextCellValue(pharmacyName)]);
    sheet.appendRow([TextCellValue('Period:'), TextCellValue('${report.month}/${report.year}')]);
    sheet.appendRow([]);

    sheet.appendRow([TextCellValue('SUMMARY METRICS')]);
    sheet.appendRow([TextCellValue('Total Revenue / Sales:'), TextCellValue('$currency ${report.totalSales.toStringAsFixed(2)}')]);
    sheet.appendRow([TextCellValue('Total Medicine Cost:'), TextCellValue('$currency ${report.totalCost.toStringAsFixed(2)}')]);
    sheet.appendRow([TextCellValue('Gross Profit:'), TextCellValue('$currency ${report.totalProfit.toStringAsFixed(2)}')]);
    sheet.appendRow([TextCellValue('Total Discounts:'), TextCellValue('$currency ${report.totalDiscount.toStringAsFixed(2)}')]);
    sheet.appendRow([TextCellValue('Invoice Count:'), IntCellValue(report.invoiceCount)]);
    sheet.appendRow([TextCellValue('Average Sale:'), TextCellValue('$currency ${report.avgSale.toStringAsFixed(2)}')]);
    sheet.appendRow([]);

    sheet.appendRow([TextCellValue('TOP SELLING MEDICINES')]);
    sheet.appendRow([
      TextCellValue('Medicine Name'),
      TextCellValue('Quantity Sold'),
      TextCellValue('Revenue'),
      TextCellValue('Profit'),
    ]);
    for (final med in report.topMedicines) {
      sheet.appendRow([
        TextCellValue(med.medicineName),
        IntCellValue(med.totalQuantity),
        TextCellValue('$currency ${med.revenue.toStringAsFixed(2)}'),
        TextCellValue('$currency ${med.profit.toStringAsFixed(2)}'),
      ]);
    }
    sheet.appendRow([]);

    sheet.appendRow([TextCellValue('SALES BY CASHIER')]);
    sheet.appendRow([
      TextCellValue('Cashier Name'),
      TextCellValue('Invoices'),
      TextCellValue('Total Sales'),
    ]);
    for (final c in report.cashierSales) {
      sheet.appendRow([
        TextCellValue(c.cashierName),
        IntCellValue(c.invoiceCount),
        TextCellValue('$currency ${c.totalSales.toStringAsFixed(2)}'),
      ]);
    }

    final bytes = excel.save();
    return Uint8List.fromList(bytes ?? []);
  }

  Future<void> exportToPdfAndPrint({
    required MonthlyReportModel report,
    required String pharmacyName,
    required String currency,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(pharmacyName, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Monthly Performance & Financial Report', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                    ],
                  ),
                  pw.Text('Period: ${report.month}/${report.year}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 12),

              pw.Row(
                children: [
                  _pdfKpi('Total Sales', '$currency ${report.totalSales.toStringAsFixed(2)}'),
                  pw.SizedBox(width: 8),
                  _pdfKpi('Gross Profit', '$currency ${report.totalProfit.toStringAsFixed(2)}'),
                  pw.SizedBox(width: 8),
                  _pdfKpi('Invoices', '${report.invoiceCount} orders'),
                ],
              ),
              pw.SizedBox(height: 16),

              pw.Text('Top Performing Medicines', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              pw.TableHelper.fromTextArray(
                headers: ['Medicine', 'Qty Sold', 'Revenue', 'Profit'],
                data: report.topMedicines.map((m) {
                  return [
                    m.medicineName,
                    '${m.totalQuantity}',
                    '$currency ${m.revenue.toStringAsFixed(2)}',
                    '$currency ${m.profit.toStringAsFixed(2)}',
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
                cellHeight: 24,
              ),
              pw.SizedBox(height: 16),

              pw.Text('Cashier Sales Summary', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              pw.TableHelper.fromTextArray(
                headers: ['Cashier Staff', 'Invoices Processed', 'Total Sales'],
                data: report.cashierSales.map((c) {
                  return [
                    c.cashierName,
                    '${c.invoiceCount}',
                    '$currency ${c.totalSales.toStringAsFixed(2)}',
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
                cellHeight: 24,
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Report_${report.year}_${report.month}.pdf',
    );
  }

  pw.Widget _pdfKpi(String label, String value) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
            pw.SizedBox(height: 4),
            pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _MedAgg {
  final String name;
  int qty = 0;
  double revenue = 0.0;
  double profit = 0.0;
  _MedAgg(this.name);
}

class _CashierAgg {
  final String name;
  int invoices = 0;
  double total = 0.0;
  _CashierAgg(this.name);
}

class _PaymentAgg {
  final String name;
  int count = 0;
  double total = 0.0;
  _PaymentAgg(this.name);
}
