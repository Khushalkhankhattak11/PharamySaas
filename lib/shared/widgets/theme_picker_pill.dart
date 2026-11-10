import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/theme/tokens.dart';

/// 2-row rounded theme picker bar matching the visual design truth in the dashboard screenshots
class ThemePickerBar extends ConsumerWidget {
  const ThemePickerBar({super.key});

  static const List<String> row1Ids = [
    'ocean',
    'violet',
    'midnight',
    'emerald',
    'rose',
    'sunset',
  ];

  static const List<String> row2Ids = [
    'graphite',
    'lagoon',
    'forest',
    'aurora',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final activePresetId = ref.watch(themePresetProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: tokens.colors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: tokens.colors.line, width: 1),
        boxShadow: [tokens.colors.shadow],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Row 1: Ocean, Violet, Midnight, Emerald, Rose, Sunset
          Row(
            mainAxisSize: MainAxisSize.min,
            children: row1Ids.map((id) {
              final preset = AppColorsTokens.getPreset(id);
              final isSelected = activePresetId.toLowerCase() == id.toLowerCase();
              return _ThemeItemChip(
                preset: preset,
                isSelected: isSelected,
                onTap: () => applyThemePreset(ref, id),
              );
            }).toList(),
          ),
          const SizedBox(height: 5),
          // Row 2: Graphite, Lagoon, Forest, Aurora
          Row(
            mainAxisSize: MainAxisSize.min,
            children: row2Ids.map((id) {
              final preset = AppColorsTokens.getPreset(id);
              final isSelected = activePresetId.toLowerCase() == id.toLowerCase();
              return _ThemeItemChip(
                preset: preset,
                isSelected: isSelected,
                onTap: () => applyThemePreset(ref, id),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ThemeItemChip extends StatelessWidget {
  final AppColorsTokens preset;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeItemChip({
    required this.preset,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    // Dot color: use glow or accent for dark themes like midnight to pop
    final dotColor = preset.id == 'midnight' ? const Color(0xFF22D3EE) : preset.brand1;

    if (isSelected) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 4),
            decoration: BoxDecoration(
              color: dotColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: dotColor.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              preset.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.1,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                preset.name,
                style: TextStyle(
                  color: tokens.colors.ink,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dropdown variant for compact spaces or mobile toolbars
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
        applyThemePreset(ref, presetId);
      },
      itemBuilder: (context) {
        return AppColorsTokens.allPresets.map((preset) {
          final isSelected = preset.id.toLowerCase() == activePresetId.toLowerCase();
          final dotColor = preset.id == 'midnight' ? const Color(0xFF22D3EE) : preset.brand1;
          return PopupMenuItem<String>(
            value: preset.id,
            child: Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: dotColor,
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
                color: activeTheme.id == 'midnight' ? const Color(0xFF22D3EE) : activeTheme.brand1,
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
