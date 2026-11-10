import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/models/cash_shift_model.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/shift_controller.dart';

class ShiftRegisterBar extends ConsumerWidget {
  final String currency;

  const ShiftRegisterBar({super.key, required this.currency});

  void _showOpenShiftDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _OpenShiftDialog(currency: currency),
    );
  }

  void _showCloseShiftDialog(BuildContext context, WidgetRef ref, CashShiftModel shift) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _CloseShiftDialog(currency: currency, shift: shift),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeShiftAsync = ref.watch(currentCashierShiftProvider);
    final profile = ref.watch(currentProfileProvider).value;
    final tokens = context.tokens;

    return activeShiftAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (shift) {
        if (shift == null) {
          // No active shift -> Warning Banner prompting Cashier to open shift
          final hasSchedule = profile?.shiftStart != null;
          final scheduleText = profile?.shiftLabel ??
              (hasSchedule ? '${profile!.shiftStart} - ${profile.shiftEnd}' : null);

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.wallet, color: Color(0xFFD97706), size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Cashier Counter Register is Closed',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF92400E)),
                          ),
                          if (scheduleText != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFFCD34D)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(LucideIcons.clock, size: 11, color: Color(0xFF92400E)),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Scheduled: $scheduleText',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF92400E)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        'Start shift and record opening cash (e.g. 4,000 PKR float) to track cash drawer balance and online sales.',
                        style: TextStyle(fontSize: 12, color: const Color(0xFFB45309).withValues(alpha: 0.9)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                AppButton(
                  text: 'Start Shift (Float)',
                  icon: const Icon(LucideIcons.plusCircle, size: 15, color: Colors.white),
                  onPressed: () => _showOpenShiftDialog(context, ref),
                ),
              ],
            ),
          );
        }

        // Active shift card
        final openTime = '${shift.openedAt.hour.toString().padLeft(2, '0')}:${shift.openedAt.minute.toString().padLeft(2, '0')}';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: tokens.colors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColorsTokens.brand.withValues(alpha: 0.3)),
            boxShadow: [tokens.colors.shadow],
          ),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 10,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Text('SHIFT ACTIVE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColorsTokens.success, letterSpacing: 0.5)),
                          const SizedBox(width: 6),
                          Text('• Started at $openTime', style: TextStyle(fontSize: 11, color: tokens.colors.muted)),
                          if (shift.punctualityStatus != null) ...[
                            const SizedBox(width: 6),
                            _punctualityBadge(shift),
                          ],
                        ],
                      ),
                      Text('Cashier: ${shift.cashierName}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ],
              ),

              // Float & Counter Cash
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _metricPill(
                    label: 'Opening Float',
                    value: '$currency ${shift.openingCash.toStringAsFixed(0)}',
                    color: const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 10),
                  _metricPill(
                    label: 'Cash in Drawer',
                    value: '$currency ${shift.expectedClosingCash.toStringAsFixed(0)}',
                    color: const Color(0xFF0F766E),
                  ),
                  const SizedBox(width: 10),
                  _metricPill(
                    label: 'Online Payments',
                    value: '$currency ${shift.totalOnlineSales.toStringAsFixed(0)}',
                    color: const Color(0xFF2563EB),
                    tooltip: 'EasyPaisa: ${shift.easypaisaSales.toStringAsFixed(0)} | JazzCash: ${shift.jazzcashSales.toStringAsFixed(0)} | Card: ${shift.cardSales.toStringAsFixed(0)}',
                  ),
                  const SizedBox(width: 10),
                  _metricPill(
                    label: 'Total Sales',
                    value: '$currency ${shift.totalSales.toStringAsFixed(0)}',
                    color: AppColorsTokens.brand,
                    tooltip: '${shift.totalTransactions} bills processed',
                  ),
                ],
              ),

              AppButton(
                text: 'Close Shift',
                icon: const Icon(LucideIcons.doorClosed, size: 15, color: Colors.white),
                onPressed: () => _showCloseShiftDialog(context, ref, shift),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _punctualityBadge(CashShiftModel shift) {
    if (shift.isOnTime) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
        decoration: BoxDecoration(
          color: const Color(0xFFDCFCE7),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          '✓ On Time',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF15803D)),
        ),
      );
    } else if (shift.isLate) {
      final mins = shift.punctualityMinutes ?? 0;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '⚠ Late by ${mins}m',
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFB91C1C)),
        ),
      );
    } else if (shift.isEarly) {
      final mins = (shift.punctualityMinutes ?? 0).abs();
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
        decoration: BoxDecoration(
          color: const Color(0xFFDBEAFE),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '⚡ ${mins}m Early',
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF1D4ED8)),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _metricPill({
    required String label,
    required String value,
    required Color color,
    String? tooltip,
  }) {
    final w = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip, child: w);
    }
    return w;
  }
}

class _OpenShiftDialog extends ConsumerStatefulWidget {
  final String currency;

  const _OpenShiftDialog({required this.currency});

  @override
  ConsumerState<_OpenShiftDialog> createState() => _OpenShiftDialogState();
}

class _OpenShiftDialogState extends ConsumerState<_OpenShiftDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _cashController;
  late final TextEditingController _noteController;
  bool _isSubmitting = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _cashController = TextEditingController(text: '4000');
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _cashController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quickAmounts = [1000, 2000, 4000, 5000, 10000];
    final profile = ref.watch(currentProfileProvider).value;
    final scheduleText = profile?.shiftLabel ??
        (profile?.shiftStart != null ? '${profile!.shiftStart} - ${profile.shiftEnd}' : null);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadiusTokens.largeCard),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColorsTokens.brand.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(LucideIcons.wallet, color: AppColorsTokens.brand, size: 22),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Start Counter Shift', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              Text('Add starting cash in counter drawer', style: TextStyle(fontSize: 12, color: Color(0xFF4B6567))),
            ],
          ),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (scheduleText != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.calendarCheck, size: 16, color: Color(0xFF16A34A)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your Assigned Shift: $scheduleText',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF166534)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (_errorMsg != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColorsTokens.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColorsTokens.danger.withValues(alpha: 0.3)),
                  ),
                  child: Text(_errorMsg!, style: const TextStyle(fontSize: 12, color: AppColorsTokens.danger)),
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _cashController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: 'Starting Cash Float (${widget.currency}) *',
                  prefixText: '${widget.currency} ',
                  prefixIcon: const Icon(LucideIcons.coins),
                  helperText: 'e.g. 4000 PKR float for change',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Starting cash is required';
                  final num = double.tryParse(val.trim());
                  if (num == null || num < 0) return 'Enter a valid non-negative amount';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: quickAmounts.map((amt) {
                  return ActionChip(
                    label: Text('${widget.currency} $amt', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    onPressed: () {
                      _cashController.text = amt.toString();
                      setState(() {});
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Shift / Handover Note (Optional)',
                  hintText: 'e.g. Morning Shift, Drawer float verified',
                  prefixIcon: Icon(LucideIcons.fileText),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        AppButton(
          text: _isSubmitting ? 'Starting...' : 'Open Shift & Counter',
          icon: const Icon(LucideIcons.playCircle, size: 16, color: Colors.white),
          onPressed: _isSubmitting
              ? null
              : () async {
                  if (!_formKey.currentState!.validate()) return;
                  final cash = double.parse(_cashController.text.trim());
                  final note = _noteController.text.trim();

                  setState(() {
                    _isSubmitting = true;
                    _errorMsg = null;
                  });

                  final nav = Navigator.of(context);

                  try {
                    await ref.read(shiftActionControllerProvider.notifier).openShift(
                          openingCash: cash,
                          note: note.isEmpty ? null : note,
                        );
                    if (!mounted) return;
                    nav.pop();
                  } catch (e) {
                    if (!mounted) return;
                    setState(() {
                      _isSubmitting = false;
                      _errorMsg = e.toString().replaceFirst('Exception: ', '');
                    });
                  }
                },
        ),
      ],
    );
  }
}

class _CloseShiftDialog extends ConsumerStatefulWidget {
  final String currency;
  final CashShiftModel shift;

  const _CloseShiftDialog({required this.currency, required this.shift});

  @override
  ConsumerState<_CloseShiftDialog> createState() => _CloseShiftDialogState();
}

class _CloseShiftDialogState extends ConsumerState<_CloseShiftDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _countedCashController;
  late final TextEditingController _noteController;
  bool _isSubmitting = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _countedCashController = TextEditingController(
      text: widget.shift.expectedClosingCash.toStringAsFixed(0),
    );
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _countedCashController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shift = widget.shift;
    final currency = widget.currency;
    final counted = double.tryParse(_countedCashController.text.trim()) ?? 0.0;
    final diff = counted - shift.expectedClosingCash;
    final isBalanced = diff.abs() < 0.01;
    final isOver = diff >= 0.01;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadiusTokens.largeCard),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColorsTokens.danger.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(LucideIcons.doorClosed, color: AppColorsTokens.danger, size: 22),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Close Counter Shift & Reconcile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              Text('Count cash in drawer & review online payments', style: TextStyle(fontSize: 12, color: Color(0xFF4B6567))),
            ],
          ),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_errorMsg != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColorsTokens.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColorsTokens.danger.withValues(alpha: 0.3)),
                    ),
                    child: Text(_errorMsg!, style: const TextStyle(fontSize: 12, color: AppColorsTokens.danger)),
                  ),
                  const SizedBox(height: 12),
                ],

                // Shift Metrics Grid
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      _summaryLine('Opening Cash Float:', '$currency ${shift.openingCash.toStringAsFixed(2)}'),
                      const Divider(height: 12),
                      _summaryLine('Cash Sales Received:', '+ $currency ${shift.cashSales.toStringAsFixed(2)}', color: const Color(0xFF0F766E)),
                      const Divider(height: 12),
                      _summaryLine('Expected Cash in Drawer:', '$currency ${shift.expectedClosingCash.toStringAsFixed(2)}', isBold: true),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Online breakdown summary
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColorsTokens.brand.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColorsTokens.brand.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Online Payments Verified:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                          Text('EP: ${shift.easypaisaSales.toStringAsFixed(0)} | JC: ${shift.jazzcashSales.toStringAsFixed(0)} | Card: ${shift.cardSales.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        ],
                      ),
                      Text(
                        '$currency ${shift.totalOnlineSales.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColorsTokens.brand),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _countedCashController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                  decoration: InputDecoration(
                    labelText: 'Actual Counted Cash in Drawer ($currency) *',
                    prefixText: '$currency ',
                    prefixIcon: const Icon(LucideIcons.banknote),
                    helperText: 'Count physical notes and coins in counter drawer',
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Counted cash is required';
                    final num = double.tryParse(val.trim());
                    if (num == null || num < 0) return 'Invalid amount';
                    return null;
                  },
                ),
                const SizedBox(height: 10),

                // Live Discrepancy Indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isBalanced
                        ? const Color(0xFFF0FDF4)
                        : isOver
                            ? const Color(0xFFEFF6FF)
                            : const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isBalanced
                          ? const Color(0xFFBBF7D0)
                          : isOver
                              ? const Color(0xFFBFDBFE)
                              : const Color(0xFFFECACA),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isBalanced
                                ? LucideIcons.checkCircle2
                                : isOver
                                    ? LucideIcons.trendingUp
                                    : LucideIcons.alertTriangle,
                            size: 16,
                            color: isBalanced
                                ? const Color(0xFF16A34A)
                                : isOver
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFFDC2626),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isBalanced
                                ? 'Cash Drawer Balanced'
                                : isOver
                                    ? 'Cash Over (Surplus)'
                                    : 'Cash Shortage (Deficit)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isBalanced
                                  ? const Color(0xFF166534)
                                  : isOver
                                      ? const Color(0xFF1E40AF)
                                      : const Color(0xFF991B1B),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        isBalanced
                            ? '0.00 $currency'
                            : '${diff > 0 ? "+" : ""}${diff.toStringAsFixed(2)} $currency',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: isBalanced
                              ? const Color(0xFF166534)
                              : isOver
                                  ? const Color(0xFF1E40AF)
                                  : const Color(0xFF991B1B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'Closing / Handover Notes',
                    hintText: 'e.g. End of shift, drawer reconciled with manager',
                    prefixIcon: Icon(LucideIcons.messageSquare),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        AppButton(
          text: _isSubmitting ? 'Closing...' : 'Confirm & Close Shift',
          icon: const Icon(LucideIcons.checkCircle, size: 16, color: Colors.white),
          onPressed: _isSubmitting
              ? null
              : () async {
                  if (!_formKey.currentState!.validate()) return;
                  final countedVal = double.parse(_countedCashController.text.trim());
                  final noteVal = _noteController.text.trim();

                  setState(() {
                    _isSubmitting = true;
                    _errorMsg = null;
                  });

                  final messenger = ScaffoldMessenger.of(context);
                  final nav = Navigator.of(context);

                  try {
                    await ref.read(shiftActionControllerProvider.notifier).closeShift(
                          shiftId: shift.id,
                          actualClosingCash: countedVal,
                          note: noteVal.isEmpty ? null : noteVal,
                        );
                    if (!mounted) return;
                    nav.pop();
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('✓ Shift closed successfully! Total sales: $currency ${shift.totalSales.toStringAsFixed(2)}'),
                        backgroundColor: AppColorsTokens.success,
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    setState(() {
                      _isSubmitting = false;
                      _errorMsg = e.toString().replaceFirst('Exception: ', '');
                    });
                  }
                },
        ),
      ],
    );
  }

  Widget _summaryLine(String label, String value, {Color? color, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: const Color(0xFF64748B), fontWeight: isBold ? FontWeight.w700 : FontWeight.normal)),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 14 : 12,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: color ?? const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}
