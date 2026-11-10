import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/theme/tokens.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';

void showThemePickerDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => const ThemePickerDialog(),
  );
}

class ThemePickerDialog extends ConsumerWidget {
  const ThemePickerDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final activePresetId = ref.watch(themePresetProvider);
    final themeMode = ref.watch(themeModeProvider);
    final pharmacy = ref.watch(currentPharmacyProvider).value;
    final currentProfile = ref.watch(currentProfileProvider).valueOrNull;
    final isOwner = currentProfile?.role.isAdmin ?? false;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadiusTokens.largeCard),
        side: BorderSide(color: tokens.colors.line, width: 1),
      ),
      backgroundColor: tokens.colors.card,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 780),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: tokens.colors.brand1.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      LucideIcons.palette,
                      color: tokens.colors.brand1,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Theme & Appearance',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: tokens.colors.ink,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Select your preferred workspace theme preset',
                          style: TextStyle(
                            fontSize: 13,
                            color: tokens.colors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(LucideIcons.x, size: 20, color: tokens.colors.muted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: tokens.colors.line),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Mode Switcher Banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: tokens.colors.track,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: tokens.colors.line),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            themeMode == ThemeMode.dark ? LucideIcons.moon : LucideIcons.sun,
                            size: 18,
                            color: tokens.colors.ink,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  themeMode == ThemeMode.dark ? 'Dark Mode Active' : 'Light Mode Active',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: tokens.colors.ink,
                                  ),
                                ),
                                Text(
                                  'Toggle between light and dark backgrounds',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: tokens.colors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Switch.adaptive(
                            value: themeMode == ThemeMode.dark,
                            activeTrackColor: tokens.colors.brand1,
                            onChanged: (_) {
                              ref.read(themeModeProvider.notifier).toggleTheme();
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section Title
                    Text(
                      '10 HANDCRAFTED THEME PRESETS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: tokens.colors.muted,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 10 Presets Grid
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        // Prevent cards from shrinking below comfortable touch and visual width
                        int crossAxisCount;
                        if (width < 420) {
                          crossAxisCount = 2;
                        } else if (width < 680) {
                          crossAxisCount = 3;
                        } else if (width < 860) {
                          crossAxisCount = 4;
                        } else {
                          crossAxisCount = 5;
                        }
                        const spacing = 10.0;
                        final cardWidth = (width - (spacing * (crossAxisCount - 1))) / crossAxisCount;

                        return Wrap(
                          spacing: spacing,
                          runSpacing: spacing,
                          children: AppColorsTokens.allPresets.map((preset) {
                            final isSelected = activePresetId.toLowerCase() == preset.id.toLowerCase();

                            // Determine plan locking:
                            // Standard plan: 1 theme active (ocean).
                            // Professional plan: 3 themes active (ocean, violet, midnight).
                            // Enterprise plan: all 10 themes unlocked.
                            bool isLocked = false;
                            String lockLabel = 'Pro';
                            if (pharmacy != null) {
                              if (pharmacy.isStandardPlan) {
                                isLocked = preset.id != 'ocean';
                                lockLabel = (preset.id == 'violet' || preset.id == 'midnight') ? 'Pro' : 'Enterprise';
                              } else if (pharmacy.isProfessionalPlan) {
                                isLocked = preset.id != 'ocean' && preset.id != 'violet' && preset.id != 'midnight';
                                lockLabel = 'Enterprise';
                              }
                            }

                            return SizedBox(
                              width: cardWidth,
                              child: _buildThemeCard(
                                context: context,
                                ref: ref,
                                preset: preset,
                                isSelected: isSelected,
                                isLocked: isLocked,
                                lockLabel: lockLabel,
                                isOwner: isOwner,
                                tokens: tokens,
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

            Divider(height: 1, color: tokens.colors.line),

            // Footer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tokens.colors.brand1,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Done',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeCard({
    required BuildContext context,
    required WidgetRef ref,
    required AppColorsTokens preset,
    required bool isSelected,
    required bool isLocked,
    required String lockLabel,
    required bool isOwner,
    required AppTokens tokens,
  }) {
    return InkWell(
      onTap: () {
        if (isLocked) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'The ${preset.name} theme requires the $lockLabel plan. You can view and manage subscription plans inside Settings.',
              ),
              backgroundColor: AppColorsTokens.amber,
              action: isOwner
                  ? SnackBarAction(
                      label: 'Settings',
                      textColor: Colors.white,
                      onPressed: () {
                        Navigator.pop(context);
                        context.go('/settings');
                      },
                    )
                  : null,
            ),
          );
        } else {
          applyThemePreset(ref, preset.id);
        }
      },
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: tokens.colors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? preset.brand1
                : (isLocked ? tokens.colors.line.withValues(alpha: 0.5) : tokens.colors.line),
            width: isSelected ? 2.2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: preset.brand1.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Color Swatches Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _swatchCircle(preset.brand1),
                    const SizedBox(width: 3),
                    _swatchCircle(preset.brand2),
                    const SizedBox(width: 3),
                    _swatchCircle(preset.accent),
                  ],
                ),
                const SizedBox(width: 4),
                if (isSelected)
                  Icon(LucideIcons.checkCircle2, size: 15, color: preset.brand1)
                else if (isLocked)
                  Tooltip(
                    message: '$lockLabel Plan required',
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: tokens.colors.track,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.lock, size: 9, color: tokens.colors.muted),
                          const SizedBox(width: 2),
                          Text(
                            lockLabel == 'Enterprise' ? 'Ent' : 'Pro',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: tokens.colors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Theme Name
            Text(
              preset.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isLocked ? tokens.colors.muted : tokens.colors.ink,
              ),
            ),
            const SizedBox(height: 2),

            // Mode Label
            Text(
              preset.isDark ? 'Dark Preset' : 'Light Preset',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: tokens.colors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _swatchCircle(Color color) {
    return Container(
      width: 11,
      height: 11,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black12, width: 0.5),
      ),
    );
  }
}
