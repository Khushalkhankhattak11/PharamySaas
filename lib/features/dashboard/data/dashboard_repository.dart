import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/firebase/firebase_providers.dart';
import '../../../core/firebase/firestore_collections.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/models/dashboard_summary_model.dart';
import '../../../shared/models/sale_model.dart';
import '../../../shared/widgets/donut_chart_card.dart';
import '../../../shared/widgets/pill_bar_chart.dart';
import '../../notifications/data/notifications_repository.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final notificationsRepo = ref.watch(notificationsRepositoryProvider);
  return DashboardRepository(firestore, notificationsRepo);
});

class DashboardRepository {
  final FirebaseFirestore _firestore;
  final NotificationsRepository? _notificationsRepo;

  DashboardRepository(this._firestore, [this._notificationsRepo]);

  Future<DashboardSummaryModel> getSummary(String pharmacyId) async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final tenDaysAhead = now.add(const Duration(days: 10));

    // Automatically check and generate real-time inventory & batch expiry alerts
    _notificationsRepo?.checkAndGenerateInventoryAlerts(pharmacyId: pharmacyId);

    // 1. Fetch sales for today and recent sales
    final salesSnapshot = await _firestore
        .collection(FirestoreCollections.sales)
        .where('pharmacy_id', isEqualTo: pharmacyId)
        .get();

    final allSales = salesSnapshot.docs.map((d) {
      final data = Map<String, dynamic>.from(d.data());
      data['id'] = d.id;
      return SaleModel.fromJson(data);
    }).toList();

    allSales.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final todaySalesList = allSales
        .where((s) =>
            s.createdAt.isAfter(todayStart) ||
            s.createdAt.isAtSameMomentAs(todayStart))
        .toList();
    final todayTotal = todaySalesList.fold(0.0, (total, s) => total + s.total);
    final todayInvoices = todaySalesList.length;
    final recentSales = allSales.take(10).toList();

    // 2. Fetch purchases to compute real procurement figures
    final purchasesSnapshot = await _firestore
        .collection(FirestoreCollections.purchases)
        .where('pharmacy_id', isEqualTo: pharmacyId)
        .get();

    double totalPurchases = 0.0;
    for (final doc in purchasesSnapshot.docs) {
      final amt = (doc.data()['total_amount'] as num?)?.toDouble() ?? 0.0;
      totalPurchases += amt;
    }

    final totalSalesRevenue =
        allSales.fold(0.0, (total, s) => total + s.total);
    final totalProfit =
        (totalSalesRevenue - totalPurchases).clamp(0.0, double.infinity);
    final totalInvoicesCount = allSales.length;

    // 3. Fetch medicines & inventory breakdown (merge pharmacy stocks subcollection + root medicines)
    final Map<String, Map<String, dynamic>> allMedsMap = {};
    final pharmacyDoc = _firestore.collection(FirestoreCollections.pharmacies).doc(pharmacyId);

    try {
      final prodSnapshot = await pharmacyDoc
          .collection(FirestoreCollections.products)
          .where('is_active', isEqualTo: true)
          .get();
      for (final doc in prodSnapshot.docs) {
        allMedsMap[doc.id] = doc.data();
      }
    } catch (_) {}

    try {
      final stockSnapshot = await pharmacyDoc
          .collection(FirestoreCollections.stocks)
          .where('is_active', isEqualTo: true)
          .get();
      for (final doc in stockSnapshot.docs) {
        if (!allMedsMap.containsKey(doc.id)) {
          allMedsMap[doc.id] = doc.data();
        }
      }
    } catch (_) {}

    try {
      final medSnapshot = await _firestore
          .collection(FirestoreCollections.medicines)
          .where('pharmacy_id', isEqualTo: pharmacyId)
          .where('is_active', isEqualTo: true)
          .get();
      for (final doc in medSnapshot.docs) {
        if (!allMedsMap.containsKey(doc.id)) {
          allMedsMap[doc.id] = doc.data();
        }
      }
    } catch (_) {}

    final totalMedicines = allMedsMap.length;
    int totalUnitsInStock = 0;
    int lowStockCount = 0;
    final Map<String, int> categoryCounts = {};

    for (final data in allMedsMap.values) {
      final stock = (data['available_stock'] as num?)?.toInt() ?? 0;
      final minLevel = (data['min_stock_level'] as num?)?.toInt() ?? 10;
      final cat = (data['category'] as String?)?.trim();
      final categoryName =
          (cat != null && cat.isNotEmpty) ? cat : 'General';

      totalUnitsInStock += stock;
      if (stock <= minLevel) {
        lowStockCount++;
      }
      categoryCounts[categoryName] =
          (categoryCounts[categoryName] ?? 0) + stock;
    }

    // Dynamic category shares
    const categoryPalette = [
      Color(0xFF0F766E), // Teal
      Color(0xFF9AD9D0), // Mint
      Color(0xFFDDF2B0), // Lime
      Color(0xFFF5D5AE), // Peach
      Color(0xFFC3C6F3), // Lavender
      Color(0xFFFCA5A5), // Rose
    ];

    List<CategoryShare> categoryShares = [];
    if (totalUnitsInStock > 0) {
      int cIdx = 0;
      categoryShares = categoryCounts.entries.map((entry) {
        final pct = (entry.value / totalUnitsInStock) * 100.0;
        final color = categoryPalette[cIdx % categoryPalette.length];
        cIdx++;
        return CategoryShare(
          name: entry.key,
          percentage: double.parse(pct.toStringAsFixed(1)),
          color: color,
        );
      }).toList();
      categoryShares.sort((a, b) => b.percentage.compareTo(a.percentage));
    }

    // 4. Fetch expiring soon and expired batches
    final batchSnapshot = await _firestore
        .collection(FirestoreCollections.batches)
        .where('pharmacy_id', isEqualTo: pharmacyId)
        .get();

    int expiringSoonCount = 0;
    int expiredCount = 0;
    for (final doc in batchSnapshot.docs) {
      final expiryStr = doc.data()['expiry_date'] as String?;
      final qty = (doc.data()['quantity'] as num?)?.toInt() ?? 0;
      if (expiryStr != null && qty > 0) {
        final expDate = DateTime.tryParse(expiryStr);
        if (expDate != null) {
          if (expDate.isBefore(now)) {
            expiredCount++;
          } else if (expDate.isBefore(tenDaysAhead)) {
            expiringSoonCount++;
          }
        }
      }
    }

    // 5. Monthly spots for the last 6 months (5 months ago to current month)
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final List<String> monthLabels = [];
    final List<FlSpot> monthlySpots = [];

    for (int i = 5; i >= 0; i--) {
      final targetDate = DateTime(now.year, now.month - i, 1);
      final nextMonth = DateTime(targetDate.year, targetDate.month + 1, 1);
      final label = monthNames[targetDate.month - 1];
      monthLabels.add(label);

      final monthSales = allSales.where((s) =>
          (s.createdAt.isAfter(targetDate) ||
              s.createdAt.isAtSameMomentAs(targetDate)) &&
          s.createdAt.isBefore(nextMonth));
      final monthTotal = monthSales.fold(0.0, (acc, s) => acc + s.total);
      final amountInK = monthTotal / 1000.0;
      monthlySpots.add(FlSpot(
        (5 - i).toDouble(),
        double.parse(amountInK.toStringAsFixed(1)),
      ));
    }

    // 6. Weekly sales for the last 7 days (6 days ago to today)
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const pastels = [
      AppColorsTokens.peach,
      AppColorsTokens.rose,
      AppColorsTokens.lime,
      AppColorsTokens.mint,
      AppColorsTokens.lavender,
    ];

    final List<DaySales> weekSales = [];
    for (int i = 6; i >= 0; i--) {
      final dayDate = DateTime(now.year, now.month, now.day - i);
      final nextDayDate = dayDate.add(const Duration(days: 1));
      final dayName = dayNames[dayDate.weekday - 1];

      final daySales = allSales.where((s) =>
          (s.createdAt.isAfter(dayDate) ||
              s.createdAt.isAtSameMomentAs(dayDate)) &&
          s.createdAt.isBefore(nextDayDate));
      final dayTotal = daySales.fold(0.0, (acc, s) => acc + s.total);
      final dayAmountK = dayTotal / 1000.0;

      weekSales.add(
        DaySales(
          day: dayName,
          amountK: double.parse(dayAmountK.toStringAsFixed(1)),
          pastelColor: pastels[(6 - i) % pastels.length],
        ),
      );
    }

    return DashboardSummaryModel(
      todaySales: todayTotal,
      todayInvoices: todayInvoices,
      lowStockCount: lowStockCount,
      expiringSoonCount: expiringSoonCount,
      expiredCount: expiredCount,
      totalMedicines: totalMedicines,
      totalUnitsInStock: totalUnitsInStock,
      recentSales: recentSales,
      totalRevenue: totalSalesRevenue,
      totalProfit: totalProfit,
      totalPurchases: totalPurchases,
      totalInvoices: totalInvoicesCount,
      monthlySpots: monthlySpots,
      monthLabels: monthLabels,
      currentMonthIndex: 5,
      weekSales: weekSales,
      categoryShares: categoryShares,
    );
  }
}
