import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/tokens.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import 'plan_upgrade_dialog.dart';

class PlanCard extends ConsumerWidget {
  final String? planName;
  final String? renewsDate;
  final VoidCallback? onManage;
  final bool? isPendingUpgrade;
  final String? requestedPlan;

  const PlanCard({
    super.key,
    this.planName,
    this.renewsDate,
    this.onManage,
    this.isPendingUpgrade,
    this.requestedPlan,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pharmacy = ref.watch(currentPharmacyProvider).value;

    final resolvedPlan = planName ?? pharmacy?.plan ?? 'Standard';
    final resolvedPending = isPendingUpgrade ?? pharmacy?.isPlanUpgradePending ?? false;
    final resolvedRequested = requestedPlan ?? pharmacy?.requestedPlan;

    String resolvedExpiry;
    if (renewsDate != null) {
      resolvedExpiry = renewsDate!;
    } else if (pharmacy?.planExpiresAt != null) {
      resolvedExpiry = DateFormat('MMM dd, yyyy').format(pharmacy!.planExpiresAt!.toLocal());
    } else {
      resolvedExpiry = 'No Expiry Set';
    }

    final VoidCallback effectiveOnManage = onManage ?? () => showPlanUpgradeDialog(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColorsTokens.brandGradient,
        borderRadius: BorderRadius.circular(AppRadiusTokens.planCard),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33064E4B),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '$resolvedPlan Plan',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              if (resolvedPending)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B),
                    borderRadius: BorderRadius.circular(AppRadiusTokens.pill),
                  ),
                  child: const Text(
                    'Upgrade Pending',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppRadiusTokens.pill),
                  ),
                  child: const Text(
                    'Active',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          if (resolvedPending && resolvedRequested != null)
            Text(
              'Requested $resolvedRequested • Under Review',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFFFDE68A), // Light amber
              ),
              overflow: TextOverflow.ellipsis,
            )
          else
            Text(
              'Renews on $resolvedExpiry',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: effectiveOnManage,
                borderRadius: BorderRadius.circular(AppRadiusTokens.pill),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadiusTokens.pill),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1F000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        resolvedPending ? 'View Upgrade Status' : 'Manage & Upgrade Plan',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColorsTokens.tooltipDark, // #05343A
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
