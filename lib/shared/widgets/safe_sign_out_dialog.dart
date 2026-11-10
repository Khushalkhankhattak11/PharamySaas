import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/firebase/firestore_cache_helper.dart';
import '../../core/theme/tokens.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';

/// Shows a safe sign-out dialog.
/// Automatically verifies internet connectivity and pending Firestore writes.
/// If user is offline or has unsaved pending writes, warns them:
/// "Connect internet to save data first then logout".
Future<void> showSafeSignOutDialog(BuildContext context, WidgetRef ref) async {
  // Show quick verification modal
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogCtx) => const _SafeSignOutVerificationDialog(),
  );
}

class _SafeSignOutVerificationDialog extends ConsumerStatefulWidget {
  const _SafeSignOutVerificationDialog();

  @override
  ConsumerState<_SafeSignOutVerificationDialog> createState() =>
      _SafeSignOutVerificationDialogState();
}

class _SafeSignOutVerificationDialogState
    extends ConsumerState<_SafeSignOutVerificationDialog> {
  bool _isChecking = true;
  bool _isConnected = true;
  bool _hasPendingWrites = false;
  bool _isSyncing = false;
  String? _syncMessage;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    setState(() {
      _isChecking = true;
    });

    final isConnected = await NetworkSyncService.isInternetConnected();
    final hasPending = await NetworkSyncService.hasPendingWrites();

    if (mounted) {
      setState(() {
        _isChecking = false;
        _isConnected = isConnected;
        _hasPendingWrites = hasPending;
      });
    }
  }

  Future<void> _attemptSync() async {
    setState(() {
      _isSyncing = true;
      _syncMessage = 'Connecting and syncing pending changes...';
    });

    final isConnected = await NetworkSyncService.isInternetConnected();
    if (!isConnected) {
      if (mounted) {
        setState(() {
          _isSyncing = false;
          _isConnected = false;
          _syncMessage = 'Still offline. Please enable Wi-Fi or mobile data to save changes.';
        });
      }
      return;
    }

    final synced = await NetworkSyncService.syncPendingWrites(
      timeout: const Duration(seconds: 8),
    );

    if (mounted) {
      setState(() {
        _isSyncing = false;
        _isConnected = true;
        _hasPendingWrites = !synced;
        _syncMessage = synced
            ? 'All data saved successfully to cloud!'
            : 'Some changes could not be saved yet. Please try again.';
      });
    }
  }

  Future<void> _performSignOut() async {
    Navigator.of(context, rootNavigator: true).pop();
    await ref.read(authControllerProvider.notifier).signOut();
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    if (_isChecking) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: tokens.colors.card,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(tokens.colors.brand1),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Checking cloud sync status...',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: tokens.colors.ink,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final hasSyncIssue = !_isConnected || _hasPendingWrites;

    if (hasSyncIssue) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: AppColorsTokens.amber.withValues(alpha: 0.4), width: 1.5),
        ),
        backgroundColor: tokens.colors.card,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Warning Header Icon
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColorsTokens.amber.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.wifiOff,
                        color: AppColorsTokens.amber,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Connect Internet to Save Data First',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            !_isConnected
                                ? 'No internet connection detected'
                                : 'Offline changes pending cloud upload',
                            style: TextStyle(
                              fontSize: 12,
                              color: tokens.colors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Explanation Note
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: tokens.colors.track,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: tokens.colors.line),
                  ),
                  child: Text(
                    'You have offline data and changes saved locally that have not finished syncing to the cloud.\n\nPlease connect to the internet to save your data first before logging out, otherwise your offline changes might not be saved to your pharmacy account.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: tokens.colors.ink,
                    ),
                  ),
                ),

                if (_syncMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _syncMessage!,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: _syncMessage!.contains('successfully')
                          ? AppColorsTokens.success
                          : AppColorsTokens.danger,
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Actions
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: tokens.colors.brand1,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _isSyncing ? null : _attemptSync,
                      icon: _isSyncing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(LucideIcons.refreshCw, size: 16),
                      label: Text(
                        _isSyncing ? 'Syncing...' : 'Connect & Save Data Now',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                      child: const Text('Stay Logged In'),
                    ),
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: _performSignOut,
                      child: const Text(
                        'Sign Out Anyway (May Lose Offline Changes)',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColorsTokens.danger,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Clean confirmation when all data is safely saved
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: tokens.colors.card,
      title: const Text('Sign Out'),
      content: const Text(
        'All your pharmacy data is synced and safely saved to the cloud. Are you sure you want to sign out?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColorsTokens.danger),
          onPressed: _performSignOut,
          child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
