class CashShiftModel {
  final String id;
  final String pharmacyId;
  final String cashierId;
  final String cashierName;
  final String status; // 'open' | 'closed'
  final DateTime openedAt;
  final DateTime? closedAt;
  final double openingCash;
  final double expectedClosingCash;
  final double? actualClosingCash;
  final double? cashDiscrepancy;
  final double cashSales;
  final double easypaisaSales;
  final double jazzcashSales;
  final double cardSales;
  final double otherSales;
  final double totalSales;
  final int totalTransactions;
  final String? openingNote;
  final String? closingNote;
  final String? scheduledStart; // e.g. "09:00"
  final String? scheduledEnd;   // e.g. "17:00"
  final String? punctualityStatus; // 'on_time' | 'late' | 'early'
  final int? punctualityMinutes;   // e.g. +25 or -10
  final DateTime createdAt;
  final DateTime? updatedAt;

  const CashShiftModel({
    required this.id,
    required this.pharmacyId,
    required this.cashierId,
    required this.cashierName,
    required this.status,
    required this.openedAt,
    this.closedAt,
    required this.openingCash,
    required this.expectedClosingCash,
    this.actualClosingCash,
    this.cashDiscrepancy,
    this.cashSales = 0.0,
    this.easypaisaSales = 0.0,
    this.jazzcashSales = 0.0,
    this.cardSales = 0.0,
    this.otherSales = 0.0,
    this.totalSales = 0.0,
    this.totalTransactions = 0,
    this.openingNote,
    this.closingNote,
    this.scheduledStart,
    this.scheduledEnd,
    this.punctualityStatus,
    this.punctualityMinutes,
    required this.createdAt,
    this.updatedAt,
  });

  bool get isOpen => status == 'open';
  bool get isClosed => status == 'closed';
  bool get isOnTime => punctualityStatus == 'on_time';
  bool get isLate => punctualityStatus == 'late';
  bool get isEarly => punctualityStatus == 'early';

  double get totalOnlineSales =>
      easypaisaSales + jazzcashSales + cardSales + otherSales;

  double get cashDifference =>
      actualClosingCash != null ? (actualClosingCash! - expectedClosingCash) : 0.0;

  bool get isBalanced =>
      actualClosingCash != null && cashDifference.abs() < 0.01;
  bool get isOver =>
      actualClosingCash != null && cashDifference >= 0.01;
  bool get isShort =>
      actualClosingCash != null && cashDifference <= -0.01;

  factory CashShiftModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val, [DateTime? fallback]) {
      if (val is String && val.isNotEmpty) {
        return DateTime.tryParse(val) ?? (fallback ?? DateTime.now());
      }
      return fallback ?? DateTime.now();
    }

    double parseDouble(dynamic val) {
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    int parseInt(dynamic val) {
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    final opening = parseDouble(json['opening_cash']);
    final cashS = parseDouble(json['cash_sales']);
    final expected = json['expected_closing_cash'] != null
        ? parseDouble(json['expected_closing_cash'])
        : (opening + cashS);

    return CashShiftModel(
      id: json['id'] as String? ?? '',
      pharmacyId: json['pharmacy_id'] as String? ?? '',
      cashierId: json['cashier_id'] as String? ?? '',
      cashierName: json['cashier_name'] as String? ?? 'Cashier',
      status: json['status'] as String? ?? 'open',
      openedAt: parseDate(json['opened_at']),
      closedAt: json['closed_at'] != null ? parseDate(json['closed_at']) : null,
      openingCash: opening,
      expectedClosingCash: expected,
      actualClosingCash: json['actual_closing_cash'] != null
          ? parseDouble(json['actual_closing_cash'])
          : null,
      cashDiscrepancy: json['cash_discrepancy'] != null
          ? parseDouble(json['cash_discrepancy'])
          : null,
      cashSales: cashS,
      easypaisaSales: parseDouble(json['easypaisa_sales']),
      jazzcashSales: parseDouble(json['jazzcash_sales']),
      cardSales: parseDouble(json['card_sales']),
      otherSales: parseDouble(json['other_sales']),
      totalSales: parseDouble(json['total_sales']),
      totalTransactions: parseInt(json['total_transactions']),
      openingNote: json['opening_note'] as String?,
      closingNote: json['closing_note'] as String?,
      scheduledStart: json['scheduled_start'] as String?,
      scheduledEnd: json['scheduled_end'] as String?,
      punctualityStatus: json['punctuality_status'] as String?,
      punctualityMinutes: json['punctuality_minutes'] != null
          ? parseInt(json['punctuality_minutes'])
          : null,
      createdAt: parseDate(json['created_at']),
      updatedAt: json['updated_at'] != null ? parseDate(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pharmacy_id': pharmacyId,
      'cashier_id': cashierId,
      'cashier_name': cashierName,
      'status': status,
      'opened_at': openedAt.toIso8601String(),
      if (closedAt != null) 'closed_at': closedAt!.toIso8601String(),
      'opening_cash': openingCash,
      'expected_closing_cash': expectedClosingCash,
      if (actualClosingCash != null) 'actual_closing_cash': actualClosingCash,
      if (cashDiscrepancy != null) 'cash_discrepancy': cashDiscrepancy,
      'cash_sales': cashSales,
      'easypaisa_sales': easypaisaSales,
      'jazzcash_sales': jazzcashSales,
      'card_sales': cardSales,
      'other_sales': otherSales,
      'total_sales': totalSales,
      'total_transactions': totalTransactions,
      if (openingNote != null) 'opening_note': openingNote,
      if (closingNote != null) 'closing_note': closingNote,
      if (scheduledStart != null) 'scheduled_start': scheduledStart,
      if (scheduledEnd != null) 'scheduled_end': scheduledEnd,
      if (punctualityStatus != null) 'punctuality_status': punctualityStatus,
      if (punctualityMinutes != null) 'punctuality_minutes': punctualityMinutes,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  CashShiftModel copyWith({
    String? id,
    String? pharmacyId,
    String? cashierId,
    String? cashierName,
    String? status,
    DateTime? openedAt,
    DateTime? closedAt,
    double? openingCash,
    double? expectedClosingCash,
    double? actualClosingCash,
    double? cashDiscrepancy,
    double? cashSales,
    double? easypaisaSales,
    double? jazzcashSales,
    double? cardSales,
    double? otherSales,
    double? totalSales,
    int? totalTransactions,
    String? openingNote,
    String? closingNote,
    String? scheduledStart,
    String? scheduledEnd,
    String? punctualityStatus,
    int? punctualityMinutes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CashShiftModel(
      id: id ?? this.id,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      cashierId: cashierId ?? this.cashierId,
      cashierName: cashierName ?? this.cashierName,
      status: status ?? this.status,
      openedAt: openedAt ?? this.openedAt,
      closedAt: closedAt ?? this.closedAt,
      openingCash: openingCash ?? this.openingCash,
      expectedClosingCash: expectedClosingCash ?? this.expectedClosingCash,
      actualClosingCash: actualClosingCash ?? this.actualClosingCash,
      cashDiscrepancy: cashDiscrepancy ?? this.cashDiscrepancy,
      cashSales: cashSales ?? this.cashSales,
      easypaisaSales: easypaisaSales ?? this.easypaisaSales,
      jazzcashSales: jazzcashSales ?? this.jazzcashSales,
      cardSales: cardSales ?? this.cardSales,
      otherSales: otherSales ?? this.otherSales,
      totalSales: totalSales ?? this.totalSales,
      totalTransactions: totalTransactions ?? this.totalTransactions,
      openingNote: openingNote ?? this.openingNote,
      closingNote: closingNote ?? this.closingNote,
      scheduledStart: scheduledStart ?? this.scheduledStart,
      scheduledEnd: scheduledEnd ?? this.scheduledEnd,
      punctualityStatus: punctualityStatus ?? this.punctualityStatus,
      punctualityMinutes: punctualityMinutes ?? this.punctualityMinutes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

