import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'tokens.dart';

const String _kThemeModeKey = 'app_theme_mode';
const String _kThemePresetKey = 'app_theme_preset';
const String _kCustomBrandColorKey = 'app_custom_brand_color';

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.light) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedIndex = prefs.getInt(_kThemeModeKey);
      final savedPreset = prefs.getString(_kThemePresetKey);
      if (savedIndex != null && savedIndex >= 0 && savedIndex < ThemeMode.values.length) {
        state = ThemeMode.values[savedIndex];
      } else if (savedPreset != null && savedPreset.isNotEmpty) {
        final preset = AppColorsTokens.getPreset(savedPreset);
        state = preset.isDark ? ThemeMode.dark : ThemeMode.light;
      }
    } catch (_) {
      // Default to light if preference reading fails
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kThemeModeKey, mode.index);
    } catch (_) {}
  }

  Future<void> toggleTheme() async {
    final nextMode = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(nextMode);
  }
}

/// Theme preset identifier (defaults to 'ocean')
final themePresetProvider = StateNotifierProvider<ThemePresetNotifier, String>((ref) {
  return ThemePresetNotifier();
});

class ThemePresetNotifier extends StateNotifier<String> {
  ThemePresetNotifier() : super('ocean') {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPreset = prefs.getString(_kThemePresetKey);
      if (savedPreset != null && savedPreset.isNotEmpty) {
        state = savedPreset;
      }
    } catch (_) {}
  }

  Future<void> setThemePreset(String presetId) async {
    state = presetId;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kThemePresetKey, presetId);
      final preset = AppColorsTokens.getPreset(presetId);
      await prefs.setInt(_kThemeModeKey, (preset.isDark ? ThemeMode.dark : ThemeMode.light).index);
    } catch (_) {}
  }
}

/// Helper to apply a preset and immediately synchronize theme mode and persist preferences
void applyThemePreset(WidgetRef ref, String presetId) {
  final preset = AppColorsTokens.getPreset(presetId);
  ref.read(themePresetProvider.notifier).setThemePreset(presetId);
  ref.read(themeModeProvider.notifier).setThemeMode(preset.isDark ? ThemeMode.dark : ThemeMode.light);
}

/// Custom brand color for Enterprise brand derivation
final customBrandColorProvider = StateNotifierProvider<CustomBrandColorNotifier, Color>((ref) {
  return CustomBrandColorNotifier();
});

class CustomBrandColorNotifier extends StateNotifier<Color> {
  CustomBrandColorNotifier() : super(const Color(0xFF0F766E)) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedColorInt = prefs.getInt(_kCustomBrandColorKey);
      if (savedColorInt != null) {
        state = Color(savedColorInt);
      }
    } catch (_) {}
  }

  Future<void> setCustomBrandColor(Color color) async {
    state = color;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kCustomBrandColorKey, color.toARGB32());
    } catch (_) {}
  }
}

/// Active AppColorsTokens based on selected preset, custom color, and theme mode
final activeThemeTokensProvider = Provider<AppColorsTokens>((ref) {
  final preset = ref.watch(themePresetProvider);
  final customColor = ref.watch(customBrandColorProvider);
  final mode = ref.watch(themeModeProvider);
  final isDark = mode == ThemeMode.dark;
  return AppColorsTokens.getById(preset, isDark: isDark, customColor: customColor);
});
