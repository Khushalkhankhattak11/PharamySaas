import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/tokens.dart';
import '../constants/subscription_plans.dart';
import '../models/pharmacy_model.dart';
import '../widgets/app_button.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/settings/presentation/controllers/settings_controller.dart';

void showPlanUpgradeDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => const PlanUpgradeDialog(),
  );
}

class PlanUpgradeDialog extends ConsumerStatefulWidget {
  const PlanUpgradeDialog({super.key});

  @override
  ConsumerState<PlanUpgradeDialog> createState() => _PlanUpgradeDialogState();
}

class _PlanUpgradeDialogState extends ConsumerState<PlanUpgradeDialog> {
  int _selectedDurationDays = 365;
  String? _submittingPlanId;
  bool _isCancelling = false;

  @override
  Widget build(BuildContext context) {
    final pharmacyAsync = ref.watch(currentPharmacyProvider);
    final pharmacy = pharmacyAsync.value;

    final activePlanId = pharmacy?.plan ?? 'Standard';
    final requestedPlan = pharmacy?.requestedPlan;
    final isPending = pharmacy?.isPlanUpgradePending ?? false;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadiusTokens.largeCard),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1050, maxHeight: 850),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 20, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColorsTokens.brand.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      LucideIcons.sparkles,
                      color: AppColorsTokens.brand,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Subscription Plans & Benefits',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Compare plan advantages and request an upgrade for your pharmacy',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Pending Upgrade Banner
                    if (isPending && requestedPlan != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7), // Amber 100
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              LucideIcons.clock,
                              color: Color(0xFFD97706),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Plan Upgrade Request Under Review: $requestedPlan',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: Color(0xFF92400E),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'You submitted a request to switch to the $requestedPlan tier '
                                    '(${pharmacy?.requestedPlanDays ?? 365} Days validity). '
                                    'Super Admin review is required before activation. You will be able to access the new plan features as soon as Super Admin accepts.',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFFB45309),
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            TextButton.icon(
                              onPressed: _isCancelling
                                  ? null
                                  : () => _cancelRequest(context),
                              icon: _isCancelling
                                  ? const SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(LucideIcons.undo2, size: 14),
                              label: const Text('Cancel Request'),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFFB45309),
                                textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Duration selector for upgrade requests
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.calendar, size: 16, color: Color(0xFF64748B)),
                          const SizedBox(width: 10),
                          const Text(
                            'Desired Upgrade Period:',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          const Spacer(),
                          DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: _selectedDurationDays,
                              isDense: true,
                              items: const [
                                DropdownMenuItem(value: 30, child: Text('1 Month (30 Days)')),
                                DropdownMenuItem(value: 90, child: Text('3 Months (90 Days)')),
                                DropdownMenuItem(value: 180, child: Text('6 Months (180 Days)')),
                                DropdownMenuItem(value: 365, child: Text('1 Year (365 Days) — Recommended')),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedDurationDays = val);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Tier Cards Matrix
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isNarrow = constraints.maxWidth < 750;
                        if (isNarrow) {
                          return Column(
                            children: SubscriptionPlans.all.map((plan) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _buildPlanCard(
                                  plan: plan,
                                  isActive: plan.id.toLowerCase() == activePlanId.toLowerCase(),
                                  isRequested: isPending && plan.id.toLowerCase() == requestedPlan?.toLowerCase(),
                                  pharmacy: pharmacy,
                                ),
                              );
                            }).toList(),
                          );
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: SubscriptionPlans.all.map((plan) {
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: _buildPlanCard(
                                  plan: plan,
                                  isActive: plan.id.toLowerCase() == activePlanId.toLowerCase(),
                                  isRequested: isPending && plan.id.toLowerCase() == requestedPlan?.toLowerCase(),
                                  pharmacy: pharmacy,
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required SubscriptionPlanInfo plan,
    required bool isActive,
    required bool isRequested,
    required PharmacyModel? pharmacy,
  }) {
    final isSubmittingThis = _submittingPlanId == plan.id;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRequested
              ? const Color(0xFFF59E0B)
              : (isActive ? AppColorsTokens.brand : const Color(0xFFE2E8F0)),
          width: isActive || isRequested ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Plan Header
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColorsTokens.brand.withValues(alpha: 0.05)
                  : (isRequested
                      ? const Color(0xFFFFFBEB)
                      : const Color(0xFFFAFAFA)),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          plan.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: plan.accentColor,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: plan.accentColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            plan.badge,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: plan.accentColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColorsTokens.brand,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Active',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      )
                    else if (isRequested)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Requested',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  plan.staffSubtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  plan.tagline,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      plan.monthlyPrice,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '(${plan.yearlyPrice})',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Features List
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PLAN ADVANTAGES & FEATURES:',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 12),
                ...plan.benefits.map((b) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            LucideIcons.check,
                            size: 15,
                            color: AppColorsTokens.trendGreenText,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              b,
                              style: const TextStyle(
                                fontSize: 12,
                                height: 1.35,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                if (plan.limitations.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  ...plan.limitations.map((l) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              LucideIcons.minus,
                              size: 14,
                              color: Color(0xFFCBD5E1),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l,
                                style: const TextStyle(
                                  fontSize: 12,
                                  height: 1.35,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ],
            ),
          ),

          if (plan.staffNote.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  plan.staffNote,
                  style: const TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
            ),
          ],

          // Action Button
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: isActive
                ? OutlinedButton(
                    onPressed: null,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Current Active Plan'),
                  )
                : (isRequested
                    ? OutlinedButton.icon(
                        onPressed: null,
                        icon: const Icon(LucideIcons.clock, size: 14, color: Color(0xFFD97706)),
                        label: const Text('Approval Pending'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFD97706),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      )
                    : AppButton(
                        text: isSubmittingThis ? 'Submitting...' : 'Request Upgrade',
                        icon: isSubmittingThis
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(LucideIcons.arrowUpRight, size: 15, color: Colors.white),
                        onPressed: isSubmittingThis
                            ? null
                            : () => _requestUpgrade(context, plan.id),
                      )),
          ),
        ],
      ),
    );
  }

  Future<void> _requestUpgrade(BuildContext context, String planId) async {
    setState(() => _submittingPlanId = planId);
    try {
      await ref
          .read(settingsActionControllerProvider.notifier)
          .requestPlanUpgrade(
            plan: planId,
            planDays: _selectedDurationDays,
          );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Upgrade request to $planId submitted! Super Admin will review and activate it.',
            ),
            backgroundColor: AppColorsTokens.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit upgrade request: $e'),
            backgroundColor: AppColorsTokens.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submittingPlanId = null);
    }
  }

  Future<void> _cancelRequest(BuildContext context) async {
    setState(() => _isCancelling = true);
    try {
      await ref
          .read(settingsActionControllerProvider.notifier)
          .cancelPlanUpgradeRequest();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Plan upgrade request cancelled.'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel request: $e'),
            backgroundColor: AppColorsTokens.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }
}
