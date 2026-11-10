import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/env/env.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class ApprovalStatusScreen extends ConsumerWidget {
  const ApprovalStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final pharmacyAsync = ref.watch(currentPharmacyProvider);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: tokens.colors.bgGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: pharmacyAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: tokens.colors.card,
                      borderRadius: BorderRadius.circular(AppRadiusTokens.largeCard),
                      border: Border.all(color: tokens.colors.line),
                      boxShadow: [tokens.colors.shadow],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.alertTriangle, color: AppColorsTokens.danger, size: 48),
                        const SizedBox(height: 16),
                        Text('Error loading status: $err', style: tokens.typography.body),
                        const SizedBox(height: 20),
                        AppButton.primary(
                          text: 'Retry',
                          onPressed: () => ref.invalidate(currentPharmacyProvider),
                        ),
                      ],
                    ),
                  ),
                  data: (pharmacy) {
                    if (pharmacy == null) {
                      return Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: tokens.colors.card,
                          borderRadius: BorderRadius.circular(AppRadiusTokens.largeCard),
                          border: Border.all(color: tokens.colors.line),
                          boxShadow: [tokens.colors.shadow],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.store, size: 52, color: AppColorsTokens.brand),
                            const SizedBox(height: 18),
                            Text('Pharmacy Not Registered', style: tokens.typography.pageTitle.copyWith(fontSize: 22)),
                            const SizedBox(height: 8),
                            Text(
                              'Please complete your pharmacy registration to continue.',
                              textAlign: TextAlign.center,
                              style: tokens.typography.cardSubtitle,
                            ),
                            const SizedBox(height: 24),
                            AppButton.primary(
                              text: 'Register Pharmacy Now',
                              onPressed: () => context.go('/register-pharmacy'),
                            ),
                          ],
                        ),
                      );
                    }

                    final status = pharmacy.approvalStatus;
                    final isExpired = pharmacy.isSubscriptionExpired;

                    Color statusColor;
                    IconData iconData;
                    String title;
                    String description;

                    if (isExpired) {
                      statusColor = AppColorsTokens.orange;
                      iconData = LucideIcons.calendarX;
                      title = 'Subscription Expired';
                      description =
                          'Your pharmacy subscription has expired. Please contact platform support to renew your plan.';
                    } else if (status.isPending) {
                      statusColor = AppColorsTokens.amber;
                      iconData = LucideIcons.clock;
                      title = 'Waiting for Approval';
                      description =
                          'Your registration has been submitted and is currently undergoing verification by the Super Administrator.';
                    } else if (status.isRejected) {
                      statusColor = AppColorsTokens.danger;
                      iconData = LucideIcons.xCircle;
                      title = 'Application Rejected';
                      description =
                          'Your pharmacy registration was reviewed and could not be approved at this time.';
                    } else if (status.isSuspended) {
                      statusColor = AppColorsTokens.danger;
                      iconData = LucideIcons.ban;
                      title = 'Account Suspended';
                      description =
                          'Your pharmacy access has been temporarily suspended by the Super Administrator.';
                    } else {
                      statusColor = AppColorsTokens.success;
                      iconData = LucideIcons.checkCircle2;
                      title = 'Pharmacy Approved!';
                      description = 'Your pharmacy is active and ready for business.';
                    }

                    return Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: tokens.colors.card,
                        borderRadius: BorderRadius.circular(AppRadiusTokens.largeCard),
                        border: Border.all(color: tokens.colors.line, width: 1),
                        boxShadow: [tokens.colors.shadow],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Large Status Icon
                          Center(
                            child: Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(iconData, size: 36, color: statusColor),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: tokens.typography.pageTitle.copyWith(fontSize: 24),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            pharmacy.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColorsTokens.brand,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            description,
                            textAlign: TextAlign.center,
                            style: tokens.typography.cardSubtitle,
                          ),
                          const SizedBox(height: 24),

                          // Reason Card (if rejected or suspended)
                          if ((status.isRejected || status.isSuspended) &&
                              pharmacy.rejectionReason != null &&
                              pharmacy.rejectionReason!.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(AppRadiusTokens.tile),
                                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(LucideIcons.alertCircle, size: 16, color: statusColor),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Official Note from Super Admin:',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: statusColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    pharmacy.rejectionReason!,
                                    style: TextStyle(fontSize: 13, color: tokens.colors.ink),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Timeline
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: tokens.colors.track,
                              borderRadius: BorderRadius.circular(AppRadiusTokens.tile),
                              border: Border.all(color: tokens.colors.line),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Application Timeline',
                                  style: tokens.typography.cardTitle.copyWith(fontSize: 14),
                                ),
                                const SizedBox(height: 14),
                                _timelineStep(
                                  isDone: true,
                                  isCurrent: false,
                                  title: 'Registration Submitted',
                                  subtitle: 'Pharmacy and license details received',
                                ),
                                _timelineStep(
                                  isDone: status.isApproved,
                                  isCurrent: status.isPending,
                                  title: 'Super Admin Review',
                                  subtitle: status.isPending ? 'Verification in progress' : 'Review completed',
                                ),
                                _timelineStep(
                                  isDone: status.isApproved,
                                  isCurrent: false,
                                  isLast: true,
                                  title: 'Store Operations Activated',
                                  subtitle: status.isApproved ? 'Full access granted' : 'Pending approval',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Contact support & Logout buttons
                          Row(
                            children: [
                              Expanded(
                                child: AppButton.white(
                                  text: 'Contact Support',
                                  icon: const Icon(LucideIcons.helpCircle, size: 16),
                                  onPressed: () => _showSupportDialog(context),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: AppButton.ghost(
                                  text: 'Sign Out',
                                  icon: const Icon(LucideIcons.logOut, size: 16),
                                  onPressed: () async {
                                    await ref.read(authControllerProvider.notifier).signOut();
                                    if (context.mounted) context.go('/login');
                                  },
                                ),
                              ),
                            ],
                          ),
                          if (status.isApproved) ...[
                            const SizedBox(height: 14),
                            AppButton.primary(
                              text: 'Enter Dashboard',
                              onPressed: () => context.go('/dashboard'),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _timelineStep({
    required bool isDone,
    required bool isCurrent,
    required String title,
    required String subtitle,
    bool isLast = false,
  }) {
    Color stepColor = isDone
        ? AppColorsTokens.success
        : (isCurrent ? AppColorsTokens.amber : const Color(0xFF9BB8B6));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: stepColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isDone ? LucideIcons.check : (isCurrent ? LucideIcons.clock : LucideIcons.circle),
                size: 12,
                color: Colors.white,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 32,
                color: isDone ? AppColorsTokens.success : const Color(0xFFDFECEB),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: Color(0xFF4B6567)),
              ),
              const SizedBox(height: 14),
            ],
          ),
        ),
      ],
    );
  }

  void _showSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadiusTokens.largeCard)),
        title: const Text('Contact Platform Support'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Need assistance with your pharmacy verification?'),
            const SizedBox(height: 12),
            Text('Support Email: ${Env.supportEmail}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('Response time: typically within 24 hours.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
