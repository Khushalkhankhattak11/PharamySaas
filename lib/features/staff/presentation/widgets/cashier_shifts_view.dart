import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/models/cash_shift_model.dart';
import '../../../../shared/models/user_role.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_data_table.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../pos/presentation/controllers/shift_controller.dart';
import '../controllers/staff_controller.dart';

class CashierShiftsView extends ConsumerWidget {
  const CashierShiftsView({super.key});

  void _showShiftDetailModal(BuildContext context, CashShiftModel shift, String currency) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadiusTokens.largeCard)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: shift.isOpen ? AppColorsTokens.success.withValues(alpha: 0.1) : AppColorsTokens.brand.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                shift.isOpen ? LucideIcons.playCircle : LucideIcons.checkCircle2,
                color: shift.isOpen ? AppColorsTokens.success : AppColorsTokens.brand,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Shift Audit: ${shift.cashierName}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                Text(
                  '${shift.openedAt.toLocal().toString().split('.')[0]} ${shift.isClosed ? "to ${shift.closedAt?.toLocal().toString().split('.')[0]}" : "(Currently Active)"}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Punctuality & Attendance Audit Box
                if (shift.punctualityStatus != null || shift.scheduledStart != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: shift.isOnTime
                          ? const Color(0xFFF0FDF4)
                          : shift.isLate
                              ? const Color(0xFFFEF2F2)
                              : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: shift.isOnTime
                            ? const Color(0xFFBBF7D0)
                            : shift.isLate
                                ? const Color(0xFFFECACA)
                                : const Color(0xFFBFDBFE),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          shift.isOnTime
                              ? LucideIcons.checkCircle
                              : shift.isLate
                                  ? LucideIcons.clockAlert
                                  : LucideIcons.zap,
                          size: 18,
                          color: shift.isOnTime
                              ? const Color(0xFF16A34A)
                              : shift.isLate
                                  ? const Color(0xFFDC2626)
                                  : const Color(0xFF2563EB),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                shift.isOnTime
                                    ? 'Staff Arrived On Time'
                                    : shift.isLate
                                        ? 'Staff Arrived Late by ${shift.punctualityMinutes} Minutes'
                                        : 'Staff Arrived Early by ${(shift.punctualityMinutes ?? 0).abs()} Minutes',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: shift.isOnTime
                                      ? const Color(0xFF166534)
                                      : shift.isLate
                                          ? const Color(0xFF991B1B)
                                          : const Color(0xFF1E40AF),
                                ),
                              ),
                              if (shift.scheduledStart != null)
                                Text(
                                  'Scheduled Shift Start: ${shift.scheduledStart} (Opened: ${shift.openedAt.hour.toString().padLeft(2, '0')}:${shift.openedAt.minute.toString().padLeft(2, '0')})',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Cash Drawer Reconciliation Box
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      _auditRow('Opening Cash Float:', '$currency ${shift.openingCash.toStringAsFixed(2)}'),
                      const Divider(height: 12),
                      _auditRow('Cash Sales Collected:', '+ $currency ${shift.cashSales.toStringAsFixed(2)}', color: const Color(0xFF0F766E)),
                      const Divider(height: 12),
                      _auditRow('Expected Cash in Drawer:', '$currency ${shift.expectedClosingCash.toStringAsFixed(2)}', isBold: true),
                      if (shift.isClosed && shift.actualClosingCash != null) ...[
                        const Divider(height: 12),
                        _auditRow('Actual Counted Cash:', '$currency ${shift.actualClosingCash!.toStringAsFixed(2)}', isBold: true),
                        const Divider(height: 12),
                        _auditRow(
                          'Discrepancy (Over/Short):',
                          shift.isBalanced
                              ? '0.00 $currency (Balanced)'
                              : '${shift.cashDifference > 0 ? "+" : ""}${shift.cashDifference.toStringAsFixed(2)} $currency (${shift.isOver ? "Over" : "Short"})',
                          color: shift.isBalanced
                              ? const Color(0xFF16A34A)
                              : shift.isOver
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFFDC2626),
                          isBold: true,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Online & Digital Payments
                const Text('Online Payment Inflows', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColorsTokens.brand.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColorsTokens.brand.withValues(alpha: 0.15)),
                  ),
                  child: Column(
                    children: [
                      _auditRow('EasyPaisa Account:', '$currency ${shift.easypaisaSales.toStringAsFixed(2)}', color: const Color(0xFF047857)),
                      const SizedBox(height: 6),
                      _auditRow('JazzCash Account:', '$currency ${shift.jazzcashSales.toStringAsFixed(2)}', color: const Color(0xFFBE123C)),
                      const SizedBox(height: 6),
                      _auditRow('Debit / Credit Cards:', '$currency ${shift.cardSales.toStringAsFixed(2)}', color: const Color(0xFF1D4ED8)),
                      if (shift.otherSales > 0) ...[
                        const SizedBox(height: 6),
                        _auditRow('Bank / Other Transfers:', '$currency ${shift.otherSales.toStringAsFixed(2)}'),
                      ],
                      const Divider(height: 14),
                      _auditRow('Total Online Payments:', '$currency ${shift.totalOnlineSales.toStringAsFixed(2)}', isBold: true, color: AppColorsTokens.brand),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Overall Totals
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Sales Volume: $currency ${shift.totalSales.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
                    Text('Transactions: ${shift.totalTransactions} bills', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                  ],
                ),
                if (shift.openingNote != null) ...[
                  const SizedBox(height: 12),
                  Text('Opening Note: ${shift.openingNote}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Color(0xFF475569))),
                ],
                if (shift.closingNote != null) ...[
                  const SizedBox(height: 6),
                  Text('Closing Note: ${shift.closingNote}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Color(0xFF475569))),
                ],
              ],
            ),
          ),
        ),
        actions: [
          AppButton(
            text: 'Close',
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  Widget _auditRow(String label, String value, {Color? color, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: const Color(0xFF64748B), fontWeight: isBold ? FontWeight.w700 : FontWeight.normal)),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 14 : 12,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
            color: color ?? const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final shiftsAsync = ref.watch(pharmacyShiftsStreamProvider);
    final staffAsync = ref.watch(staffListProvider);
    final pharmacy = ref.watch(currentPharmacyProvider).value;
    final currency = pharmacy?.currency ?? 'Rs';

    final selectedCashierId = ref.watch(shiftFilterCashierIdProvider);
    final selectedStatus = ref.watch(shiftFilterStatusProvider);

    final cashiers = (staffAsync.value ?? [])
        .where((s) => s.role == UserRole.cashier)
        .toList();

    return shiftsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, _) => Center(child: Text('Error loading shifts: $e')),
      data: (shifts) {
        final openShifts = shifts.where((s) => s.isOpen).toList();

        final totalSalesAll = shifts.fold<double>(0.0, (acc, s) => acc + s.totalSales);
        final totalCashAll = shifts.fold<double>(0.0, (acc, s) => acc + s.cashSales);
        final totalOnlineAll = shifts.fold<double>(0.0, (acc, s) => acc + s.totalOnlineSales);
        final totalEasyPaisa = shifts.fold<double>(0.0, (acc, s) => acc + s.easypaisaSales);
        final totalJazzCash = shifts.fold<double>(0.0, (acc, s) => acc + s.jazzcashSales);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Overview KPI Cards
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 900;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _kpiCard(
                      tokens: tokens,
                      width: isWide ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2,
                      title: 'Active Open Shifts',
                      value: '${openShifts.length} Cashiers',
                      subtext: openShifts.isEmpty ? 'All registers closed' : 'Currently on counter',
                      icon: LucideIcons.store,
                      color: const Color(0xFF0F766E),
                    ),
                    _kpiCard(
                      tokens: tokens,
                      width: isWide ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2,
                      title: 'Total Shift Sales',
                      value: '$currency ${totalSalesAll.toStringAsFixed(0)}',
                      subtext: 'Across all shifts recorded',
                      icon: LucideIcons.trendingUp,
                      color: AppColorsTokens.brand,
                    ),
                    _kpiCard(
                      tokens: tokens,
                      width: isWide ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2,
                      title: 'Cash Sales (Drawer)',
                      value: '$currency ${totalCashAll.toStringAsFixed(0)}',
                      subtext: 'Physical cash received',
                      icon: LucideIcons.banknote,
                      color: const Color(0xFF16A34A),
                    ),
                    _kpiCard(
                      tokens: tokens,
                      width: isWide ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2,
                      title: 'Online (EasyPaisa/Jazz)',
                      value: '$currency ${totalOnlineAll.toStringAsFixed(0)}',
                      subtext: 'EP: $currency ${totalEasyPaisa.toStringAsFixed(0)} | JC: $currency ${totalJazzCash.toStringAsFixed(0)}',
                      icon: LucideIcons.smartphone,
                      color: const Color(0xFF2563EB),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Live Active Shifts Section (if any)
            if (openShifts.isNotEmpty) ...[
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColorsTokens.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('Live Active Counter Registers', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 12),
              Column(
                children: openShifts.map((shift) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: tokens.colors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColorsTokens.success.withValues(alpha: 0.4), width: 1.5),
                      boxShadow: [tokens.colors.shadow],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColorsTokens.success.withValues(alpha: 0.15),
                          child: const Icon(LucideIcons.user, color: AppColorsTokens.success, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(shift.cashierName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 8),
                                  const StatusBadge(label: 'OPEN', variant: StatusBadgeVariant.success),
                                  if (shift.isOnTime) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDCFCE7),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '✓ On Time${shift.scheduledStart != null ? " (${shift.scheduledStart})" : ""}',
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF15803D)),
                                      ),
                                    ),
                                  ] else if (shift.isLate) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEE2E2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '⚠ Late by ${shift.punctualityMinutes}m${shift.scheduledStart != null ? " (${shift.scheduledStart})" : ""}',
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFB91C1C)),
                                      ),
                                    ),
                                  ] else if (shift.isEarly) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDBEAFE),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '⚡ ${(shift.punctualityMinutes ?? 0).abs()}m Early',
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF1D4ED8)),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Opened today at ${shift.openedAt.hour.toString().padLeft(2, '0')}:${shift.openedAt.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(fontSize: 12, color: tokens.colors.muted),
                              ),
                            ],
                          ),
                        ),
                        _statBox('Starting Float', '$currency ${shift.openingCash.toStringAsFixed(0)}', const Color(0xFF64748B)),
                        const SizedBox(width: 12),
                        _statBox('Cash in Drawer', '$currency ${shift.expectedClosingCash.toStringAsFixed(0)}', const Color(0xFF0F766E)),
                        const SizedBox(width: 12),
                        _statBox('Online Payments', '$currency ${shift.totalOnlineSales.toStringAsFixed(0)}', const Color(0xFF2563EB)),
                        const SizedBox(width: 12),
                        _statBox('Total Sales', '$currency ${shift.totalSales.toStringAsFixed(0)}', AppColorsTokens.brand),
                        const SizedBox(width: 16),
                        AppButton.white(
                          text: 'Audit Details',
                          icon: const Icon(LucideIcons.eye, size: 14),
                          onPressed: () => _showShiftDetailModal(context, shift, currency),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],

            // Shift Audit History & Filters
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Counter Shifts Audit Log', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                Row(
                  children: [
                    // Cashier Filter Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: tokens.colors.card,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: tokens.colors.line),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          value: selectedCashierId,
                          hint: const Text('All Cashiers', style: TextStyle(fontSize: 12)),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('All Cashiers', style: TextStyle(fontSize: 12)),
                            ),
                            ...cashiers.map((c) => DropdownMenuItem<String?>(
                                  value: c.id,
                                  child: Text(c.fullName, style: const TextStyle(fontSize: 12)),
                                )),
                          ],
                          onChanged: (val) => ref.read(shiftFilterCashierIdProvider.notifier).state = val,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Status Filter
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: tokens.colors.card,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: tokens.colors.line),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedStatus,
                          items: const [
                            DropdownMenuItem(value: 'all', child: Text('All Statuses', style: TextStyle(fontSize: 12))),
                            DropdownMenuItem(value: 'open', child: Text('Open Only', style: TextStyle(fontSize: 12))),
                            DropdownMenuItem(value: 'closed', child: Text('Closed Only', style: TextStyle(fontSize: 12))),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              ref.read(shiftFilterStatusProvider.notifier).state = val;
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (shifts.isEmpty)
              const EmptyState(
                title: 'No Shifts Recorded Yet',
                subtitle: 'When cashiers start their shifts in POS with initial counter cash, their shifts and reconciliations will appear here in real time.',
                icon: LucideIcons.wallet,
              )
            else
              AppDataTable(
                columns: const [
                  AppTableColumn(label: 'Cashier', flex: 3),
                  AppTableColumn(label: 'Shift Time', flex: 3),
                  AppTableColumn(label: 'Opening Cash', flex: 2),
                  AppTableColumn(label: 'Cash Sales', flex: 2),
                  AppTableColumn(label: 'Online (EP / JC / Card)', flex: 3),
                  AppTableColumn(label: 'Closing / Counted', flex: 2),
                  AppTableColumn(label: 'Status & Accuracy', flex: 2),
                  AppTableColumn(label: 'Action', align: TextAlign.right, flex: 2),
                ],
                rows: shifts.map((shift) {
                  final openStr = '${shift.openedAt.day}/${shift.openedAt.month} ${shift.openedAt.hour.toString().padLeft(2, '0')}:${shift.openedAt.minute.toString().padLeft(2, '0')}';
                  final closeStr = shift.closedAt != null
                      ? '${shift.closedAt!.hour.toString().padLeft(2, '0')}:${shift.closedAt!.minute.toString().padLeft(2, '0')}'
                      : 'Active';

                  return [
                    // Cashier
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(shift.cashierName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        Text('${shift.totalTransactions} bills', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      ],
                    ),

                    // Time & Punctuality
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$openStr - $closeStr',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 3),
                        if (shift.isOnTime)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '✓ On Time${shift.scheduledStart != null ? " (${shift.scheduledStart})" : ""}',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF15803D)),
                            ),
                          )
                        else if (shift.isLate)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '⚠ Late ${shift.punctualityMinutes}m${shift.scheduledStart != null ? " (${shift.scheduledStart})" : ""}',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFB91C1C)),
                            ),
                          )
                        else if (shift.isEarly)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDBEAFE),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '⚡ ${(shift.punctualityMinutes ?? 0).abs()}m Early',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF1D4ED8)),
                            ),
                          )
                        else if (shift.scheduledStart != null)
                          Text('Sched: ${shift.scheduledStart}', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                      ],
                    ),

                    // Opening Float
                    Text('$currency ${shift.openingCash.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),

                    // Cash Sales
                    Text('$currency ${shift.cashSales.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F766E))),

                    // Online Sales Breakdown
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$currency ${shift.totalOnlineSales.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF2563EB)),
                        ),
                        Text(
                          'EP: ${shift.easypaisaSales.toStringAsFixed(0)} | JC: ${shift.jazzcashSales.toStringAsFixed(0)} | C: ${shift.cardSales.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),

                    // Closing / Counted Cash
                    if (shift.isClosed && shift.actualClosingCash != null)
                      Text('$currency ${shift.actualClosingCash!.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))
                    else
                      Text('Exp: $currency ${shift.expectedClosingCash.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),

                    // Status & Accuracy Badge
                    if (shift.isOpen)
                      const StatusBadge(label: 'Active', variant: StatusBadgeVariant.success)
                    else if (shift.isBalanced)
                      const StatusBadge(label: 'Balanced', variant: StatusBadgeVariant.success)
                    else if (shift.isOver)
                      StatusBadge(label: '+${shift.cashDifference.toStringAsFixed(0)} Over', variant: StatusBadgeVariant.info)
                    else
                      StatusBadge(label: '${shift.cashDifference.toStringAsFixed(0)} Short', variant: StatusBadgeVariant.danger),

                    // Action
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        icon: const Icon(LucideIcons.fileSpreadsheet, size: 16),
                        tooltip: 'View Shift Audit Details',
                        onPressed: () => _showShiftDetailModal(context, shift, currency),
                      ),
                    ),
                  ];
                }).toList(),
              ),
          ],
        );
      },
    );
  }

  Widget _statBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }

  Widget _kpiCard({
    required AppTokens tokens,
    required double width,
    required String title,
    required String value,
    required String subtext,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.colors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.colors.line),
        boxShadow: [tokens.colors.shadow],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: tokens.colors.muted)),
                const SizedBox(height: 4),
                Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: tokens.colors.ink)),
                const SizedBox(height: 2),
                Text(subtext, style: TextStyle(fontSize: 11, color: tokens.colors.muted), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
