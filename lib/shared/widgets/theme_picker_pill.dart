import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/theme/tokens.dart';

class ThemePickerPill extends ConsumerWidget {
  const ThemePickerPill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final activePresetId = ref.watch(themePresetProvider);
    final activeTheme = AppColorsTokens.allPresets.firstWhere(
      (p) => p.id.toLowerCase() == activePresetId.toLowerCase(),
      orElse: () => AppColorsTokens.ocean,
    );

    return PopupMenuButton<String>(
      tooltip: 'Change Theme',
      elevation: 6,
      offset: const Offset(0, 46),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadiusTokens.tile),
        side: BorderSide(color: tokens.colors.line, width: 1),
      ),
      color: tokens.colors.card,
      onSelected: (presetId) {
        ref.read(themePresetProvider.notifier).setThemePreset(presetId);
      },
      itemBuilder: (context) {
        return AppColorsTokens.allPresets.map((preset) {
          final isSelected = preset.id.toLowerCase() == activePresetId.toLowerCase();
          return PopupMenuItem<String>(
            value: preset.id,
            child: Row(
              children: [
                // Swatch dot
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: preset.brand1,
                    shape: BoxShape.circle,
                    border: Border.all(color: preset.brand2, width: 1),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    preset.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: tokens.colors.ink,
                    ),
                  ),
                ),
                if (preset.isDark) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: tokens.colors.track,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Dark',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: tokens.colors.muted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                if (isSelected)
                  const Icon(LucideIcons.check, size: 14, color: AppColorsTokens.success),
              ],
            ),
          );
        }).toList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: tokens.colors.card,
          borderRadius: BorderRadius.circular(AppRadiusTokens.pill),
          border: Border.all(color: tokens.colors.line, width: 1),
          boxShadow: [tokens.colors.shadow],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: activeTheme.brand1,
                shape: BoxShape.circle,
                border: Border.all(color: activeTheme.brand2, width: 1),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              activeTheme.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: tokens.colors.ink,
              ),
            ),
            const SizedBox(width: 4),
            Icon(LucideIcons.chevronDown, size: 13, color: tokens.colors.muted),
          ],
        ),
      ),
    );
  }
}

