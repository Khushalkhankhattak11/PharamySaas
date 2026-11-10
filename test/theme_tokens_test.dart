import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmcysas/core/theme/tokens.dart';

void main() {
  group('AppColorsTokens - Theme Presets & Tokens', () {
    test('contains 10 swappable theme presets', () {
      expect(AppColorsTokens.allPresets.length, equals(10));
      final ids = AppColorsTokens.allPresets.map((p) => p.id).toSet();
      expect(ids, containsAll([
        'ocean',
        'emerald',
        'rose',
        'sunset',
        'graphite',
        'lagoon',
        'forest',
        'aurora',
        'midnight',
        'violet',
      ]));
    });

    test('default theme is Ocean with required design tokens', () {
      const ocean = AppColorsTokens.ocean;
      expect(ocean.id, equals('ocean'));
      expect(ocean.isDark, isFalse);
      expect(ocean.bgTop, equals(const Color(0xFFF3F8FF)));
      expect(ocean.bgBottom, equals(const Color(0xFFE1EEFC)));
      expect(ocean.card, equals(const Color(0xE6FFFFFF))); // rgba(255,255,255,0.90)
      expect(ocean.line, equals(const Color(0xFFDBE6F5)));
      expect(ocean.ink, equals(const Color(0xFF0A1F3D)));
      expect(ocean.muted, equals(const Color(0xFF52627A)));
      expect(ocean.track, equals(const Color(0xFFE5EDF8)));
      expect(ocean.brand1, equals(const Color(0xFF1D4ED8)));
      expect(ocean.brand2, equals(const Color(0xFF0B2A6F)));
      expect(ocean.glow, equals(const Color(0xFF38BDF8)));
      expect(ocean.accent, equals(const Color(0xFF2563EB)));
      expect(ocean.pastel1, equals(const Color(0xFFCFE3FF)));
      expect(ocean.pastel2, equals(const Color(0xFFBFE9F7)));
      expect(ocean.pastel3, equals(const Color(0xFFD9D4FB)));
      expect(ocean.pastel4, equals(const Color(0xFFFDE3C3)));
      expect(ocean.pastel5, equals(const Color(0xFFFBC9D3)));
      expect(ocean.onPastel, equals(const Color(0xFF0A1F3D)));
      expect(ocean.tooltipBg, equals(const Color(0xFF0A1F3D)));
      expect(ocean.tooltipText, equals(const Color(0xFFFFFFFF)));
    });

    test('Emerald theme matches exact color tokens', () {
      const emerald = AppColorsTokens.emerald;
      expect(emerald.bgTop, equals(const Color(0xFFF2FAF5)));
      expect(emerald.bgBottom, equals(const Color(0xFFDFF3E7)));
      expect(emerald.line, equals(const Color(0xFFD6EADC)));
      expect(emerald.ink, equals(const Color(0xFF052E1A)));
      expect(emerald.muted, equals(const Color(0xFF4A6A58)));
      expect(emerald.track, equals(const Color(0xFFE3F1E8)));
      expect(emerald.brand1, equals(const Color(0xFF059669)));
      expect(emerald.brand2, equals(const Color(0xFF065F46)));
      expect(emerald.glow, equals(const Color(0xFF34D399)));
      expect(emerald.accent, equals(const Color(0xFF059669)));
      expect(emerald.pastel1, equals(const Color(0xFFCDF3DC)));
      expect(emerald.pastel2, equals(const Color(0xFFD6F0A8)));
      expect(emerald.pastel3, equals(const Color(0xFFBFE3F5)));
      expect(emerald.pastel4, equals(const Color(0xFFFDE7B6)));
      expect(emerald.pastel5, equals(const Color(0xFFF9CDD0)));
      expect(emerald.onPastel, equals(const Color(0xFF052E1A)));
      expect(emerald.tooltipBg, equals(const Color(0xFF052E1A)));
    });

    test('Forest dark theme matches exact dark card and shadow', () {
      const forest = AppColorsTokens.forest;
      expect(forest.isDark, isTrue);
      expect(forest.bgTop, equals(const Color(0xFF07110C)));
      expect(forest.bgBottom, equals(const Color(0xFF0C1D14)));
      expect(forest.card, equals(const Color(0xEB102118))); // rgba(16,33,24,0.92)
      expect(forest.line, equals(const Color(0xFF1D3A2A)));
      expect(forest.ink, equals(const Color(0xFFE6F6EC)));
      expect(forest.muted, equals(const Color(0xFF8FB09B)));
      expect(forest.track, equals(const Color(0xFF15291D)));
      expect(forest.brand1, equals(const Color(0xFF16A34A)));
      expect(forest.brand2, equals(const Color(0xFF14532D)));
      expect(forest.glow, equals(const Color(0xFF4ADE80)));
      expect(forest.accent, equals(const Color(0xFF4ADE80)));
      expect(forest.shadow.color, equals(const Color(0x73000000))); // 0 10 30 rgba(0,0,0,0.45)
    });

    test('Aurora dark theme matches exact tokens', () {
      const aurora = AppColorsTokens.aurora;
      expect(aurora.isDark, isTrue);
      expect(aurora.bgTop, equals(const Color(0xFF0D0817)));
      expect(aurora.bgBottom, equals(const Color(0xFF1A0F2E)));
      expect(aurora.card, equals(const Color(0xEB201438)));
      expect(aurora.line, equals(const Color(0xFF342252)));
      expect(aurora.ink, equals(const Color(0xFFF1E9FF)));
      expect(aurora.muted, equals(const Color(0xFFB2A0D6)));
      expect(aurora.track, equals(const Color(0xFF281A45)));
      expect(aurora.brand1, equals(const Color(0xFFA855F7)));
      expect(aurora.brand2, equals(const Color(0xFF4C1D95)));
      expect(aurora.glow, equals(const Color(0xFFF0ABFC)));
      expect(aurora.accent, equals(const Color(0xFFE879F9)));
    });

    test('Alert colors never change across any theme', () {
      expect(AppColorsTokens.amber, equals(const Color(0xFFF59E0B)));
      expect(AppColorsTokens.orange, equals(const Color(0xFFF97316)));
      expect(AppColorsTokens.red, equals(const Color(0xFFEF4444)));
      expect(AppColorsTokens.success, equals(const Color(0xFF22C55E)));
      expect(AppColorsTokens.info, equals(const Color(0xFF3B82F6)));
    });

    test('deriveCustom derives coherent palette for light and dark modes', () {
      const brandColor = Color(0xFF2563EB); // Royal Blue
      final lightCustom = AppColorsTokens.deriveCustom(brandColor, isDark: false);
      expect(lightCustom.isDark, isFalse);
      expect(lightCustom.id, equals('custom'));
      expect(lightCustom.card, equals(const Color(0xE6FFFFFF)));

      final darkCustom = AppColorsTokens.deriveCustom(brandColor, isDark: true);
      expect(darkCustom.isDark, isTrue);
      expect(darkCustom.id, equals('custom'));
      expect(darkCustom.shadow.color, equals(const Color(0x73000000)));
    });

    test('getById resolves presets and adapts across brightness modes', () {
      final oceanLight = AppColorsTokens.getById('ocean', isDark: false);
      expect(oceanLight.id, equals('ocean'));

      final oceanDark = AppColorsTokens.getById('ocean', isDark: true);
      expect(oceanDark.id, equals('midnight'));

      final emeraldDark = AppColorsTokens.getById('emerald', isDark: true);
      expect(emeraldDark.id, equals('forest'));

      final custom = AppColorsTokens.getById('custom', customColor: const Color(0xFF7C3AED));
      expect(custom.id, equals('custom'));
    });
  });
}

