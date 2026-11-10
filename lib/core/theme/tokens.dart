import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColorsTokens extends ThemeExtension<AppColorsTokens> {
  final String id;
  final String name;
  final bool isDark;

  final Color bgTop;
  final Color bgBottom;
  final Color card;
  final Color line;
  final Color ink;
  final Color muted;
  final Color track;
  final Color brand1;
  final Color brand2;
  final Color glow;
  final Color accent;
  final Color pastel1;
  final Color pastel2;
  final Color pastel3;
  final Color pastel4;
  final Color pastel5;
  final Color onPastel;
  final Color tooltipBg;
  final Color tooltipText;
  final BoxShadow shadow;

  const AppColorsTokens({
    required this.id,
    required this.name,
    required this.isDark,
    required this.bgTop,
    required this.bgBottom,
    required this.card,
    required this.line,
    required this.ink,
    required this.muted,
    required this.track,
    required this.brand1,
    required this.brand2,
    required this.glow,
    required this.accent,
    required this.pastel1,
    required this.pastel2,
    required this.pastel3,
    required this.pastel4,
    required this.pastel5,
    required this.onPastel,
    required this.tooltipBg,
    required this.tooltipText,
    required this.shadow,
  });

  // Instance pastels list & gradients
  List<Color> get pastels => [pastel1, pastel2, pastel3, pastel4, pastel5];

  LinearGradient get bgGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [bgTop, bgBottom],
      );

  LinearGradient get gradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [brand1, brand2],
      );

  LinearGradient get activeGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [brand1, brand2],
      );

  static const LinearGradient brandGradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1D4ED8), Color(0xFF0B2A6F)],
      );

  static const LinearGradient activePillGradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1D4ED8), Color(0xFF0B2A6F)],
      );

  // Dynamic semantic tint helpers (16% for badges, 12% for alert rows with 30% border)
  Color badgeTint(Color color) => color.withValues(alpha: 0.16);
  Color alertTint(Color color) => color.withValues(alpha: 0.12);
  Color alertBorder(Color color) => color.withValues(alpha: 0.30);

  // Fixed semantic colors (never change with theme)
  static const Color success = Color(0xFF22C55E);
  static const Color info = Color(0xFF3B82F6);
  static const Color amber = Color(0xFFF59E0B); // low stock
  static const Color orange = Color(0xFFF97316); // expiring
  static const Color danger = Color(0xFFEF4444); // expired/out of stock
  static const Color purple = Color(0xFFA855F7); // storekeeper role badge
  static const Color statusDot = Color(0xFF4ADE80);
  static const Color notificationDot = Color(0xFFEF4444);

  // Constant backwards-compatible aliases
  static const Color amberText = Color(0xFFB45309);
  static const Color orangeText = Color(0xFFC2410C);
  static const Color red = danger;
  static const Color trendGreenText = Color(0xFF15803D);
  static const Color focusRing = Color(0xFF38BDF8);

  // Static constants for backward-compatible static accesses
  static const Color brand = Color(0xFF1D4ED8);
  static const Color brandGradientStart = Color(0xFF1D4ED8);
  static const Color brandGradientEnd = Color(0xFF0B2A6F);
  static const Color activePillGradientEnd = Color(0xFF0B2A6F);
  static const Color tooltipDark = Color(0xFF0A1F3D);
  static const Color lime = Color(0xFFCFE3FF);
  static const Color mint = Color(0xFFBFE9F7);
  static const Color peach = Color(0xFFFDE3C3);
  static const Color lavender = Color(0xFFD9D4FB);
  static const Color rose = Color(0xFFFBC9D3);

  static const LinearGradient brandGradientStatic = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brandGradientStart, brandGradientEnd],
  );

  static const LinearGradient activePillGradientStatic = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brandGradientStart, activePillGradientEnd],
  );

  static const BoxShadow heroShadow = BoxShadow(
    color: Color(0x400B2A6F), // brand2 at 35-40%
    blurRadius: 40,
    offset: Offset(0, 20),
  );

  static const BoxShadow activeItemShadow = BoxShadow(
    color: Color(0x351D4ED8), // brand1 at 35%
    blurRadius: 18,
    offset: Offset(0, 8),
  );

  static const BoxShadow logoMarkShadow = BoxShadow(
    color: Color(0x401D4ED8), // brand1 at 40%
    blurRadius: 18,
    offset: Offset(0, 8),
  );

  // --- 10 PRESET THEMES ---

  /// 1. OCEAN (light - default)
  static const ocean = AppColorsTokens(
    id: 'ocean',
    name: 'Ocean',
    isDark: false,
    bgTop: Color(0xFFF3F8FF),
    bgBottom: Color(0xFFE1EEFC),
    card: Color(0xE6FFFFFF), // rgba(255,255,255,0.90)
    line: Color(0xFFDBE6F5),
    ink: Color(0xFF0A1F3D),
    muted: Color(0xFF52627A),
    track: Color(0xFFE5EDF8),
    brand1: Color(0xFF1D4ED8),
    brand2: Color(0xFF0B2A6F),
    glow: Color(0xFF38BDF8),
    accent: Color(0xFF2563EB),
    pastel1: Color(0xFFCFE3FF),
    pastel2: Color(0xFFBFE9F7),
    pastel3: Color(0xFFD9D4FB),
    pastel4: Color(0xFFFDE3C3),
    pastel5: Color(0xFFFBC9D3),
    onPastel: Color(0xFF0A1F3D),
    tooltipBg: Color(0xFF0A1F3D),
    tooltipText: Color(0xFFFFFFFF),
    shadow: BoxShadow(
      color: Color(0x140A1F3D), // 0 10 30 rgba(10,31,61,0.08)
      blurRadius: 30,
      offset: Offset(0, 10),
    ),
  );

  /// 2. VIOLET (light)
  static const violet = AppColorsTokens(
    id: 'violet',
    name: 'Violet',
    isDark: false,
    bgTop: Color(0xFFF7F4FF),
    bgBottom: Color(0xFFEBE4FB),
    card: Color(0xE6FFFFFF),
    line: Color(0xFFE2D9F5),
    ink: Color(0xFF1D1240),
    muted: Color(0xFF62567F),
    track: Color(0xFFECE6F8),
    brand1: Color(0xFF7C3AED),
    brand2: Color(0xFF3B1B8F),
    glow: Color(0xFFC084FC),
    accent: Color(0xFF7C3AED),
    pastel1: Color(0xFFE6DCFF),
    pastel2: Color(0xFFD3E7FF),
    pastel3: Color(0xFFFFD9EC),
    pastel4: Color(0xFFFDE8B8),
    pastel5: Color(0xFFC9F0DD),
    onPastel: Color(0xFF1D1240),
    tooltipBg: Color(0xFF1D1240),
    tooltipText: Color(0xFFFFFFFF),
    shadow: BoxShadow(
      color: Color(0x173B1B8F), // 0 10 30 rgba(59,27,143,0.09)
      blurRadius: 30,
      offset: Offset(0, 10),
    ),
  );

  /// 3. MIDNIGHT (dark)
  static const midnight = AppColorsTokens(
    id: 'midnight',
    name: 'Midnight',
    isDark: true,
    bgTop: Color(0xFF070B16),
    bgBottom: Color(0xFF0C1426),
    card: Color(0xEB121A2E), // rgba(18,26,46,0.92)
    line: Color(0xFF1F2B4A),
    ink: Color(0xFFE8EEFF),
    muted: Color(0xFF93A3C7),
    track: Color(0xFF17223D),
    brand1: Color(0xFF0891B2),
    brand2: Color(0xFF0E2F63),
    glow: Color(0xFF22D3EE),
    accent: Color(0xFF22D3EE),
    pastel1: Color(0xFF12324A),
    pastel2: Color(0xFF1B2F5C),
    pastel3: Color(0xFF2C2658),
    pastel4: Color(0xFF3A2F22),
    pastel5: Color(0xFF123A33),
    onPastel: Color(0xFFE8EEFF),
    tooltipBg: Color(0xFF22D3EE),
    tooltipText: Color(0xFF04121F),
    shadow: BoxShadow(
      color: Color(0x73000000), // 0 10 30 rgba(0,0,0,0.45)
      blurRadius: 30,
      offset: Offset(0, 10),
    ),
  );

  /// 4. EMERALD (light)
  static const emerald = AppColorsTokens(
    id: 'emerald',
    name: 'Emerald',
    isDark: false,
    bgTop: Color(0xFFF2FAF5),
    bgBottom: Color(0xFFDFF3E7),
    card: Color(0xE6FFFFFF),
    line: Color(0xFFD6EADC),
    ink: Color(0xFF052E1A),
    muted: Color(0xFF4A6A58),
    track: Color(0xFFE3F1E8),
    brand1: Color(0xFF059669),
    brand2: Color(0xFF065F46),
    glow: Color(0xFF34D399),
    accent: Color(0xFF059669),
    pastel1: Color(0xFFCDF3DC),
    pastel2: Color(0xFFD6F0A8),
    pastel3: Color(0xFFBFE3F5),
    pastel4: Color(0xFFFDE7B6),
    pastel5: Color(0xFFF9CDD0),
    onPastel: Color(0xFF052E1A),
    tooltipBg: Color(0xFF052E1A),
    tooltipText: Color(0xFFFFFFFF),
    shadow: BoxShadow(
      color: Color(0x17055F46), // 0 10 30 rgba(5,95,70,0.09)
      blurRadius: 30,
      offset: Offset(0, 10),
    ),
  );

  /// 5. ROSE (light)
  static const roseTheme = AppColorsTokens(
    id: 'rose',
    name: 'Rose',
    isDark: false,
    bgTop: Color(0xFFFFF5F7),
    bgBottom: Color(0xFFFDE4EA),
    card: Color(0xE6FFFFFF),
    line: Color(0xFFF6D6DE),
    ink: Color(0xFF3A0A1A),
    muted: Color(0xFF7A5160),
    track: Color(0xFFFBE6EC),
    brand1: Color(0xFFE11D48),
    brand2: Color(0xFF9F1239),
    glow: Color(0xFFFB7185),
    accent: Color(0xFFE11D48),
    pastel1: Color(0xFFFFD6DF),
    pastel2: Color(0xFFFDE0C8),
    pastel3: Color(0xFFE3D6FB),
    pastel4: Color(0xFFFFF0B8),
    pastel5: Color(0xFFCDEEDE),
    onPastel: Color(0xFF3A0A1A),
    tooltipBg: Color(0xFF3A0A1A),
    tooltipText: Color(0xFFFFFFFF),
    shadow: BoxShadow(
      color: Color(0x179F1239), // 0 10 30 rgba(159,18,57,0.09)
      blurRadius: 30,
      offset: Offset(0, 10),
    ),
  );

  /// 6. SUNSET (light)
  static const sunset = AppColorsTokens(
    id: 'sunset',
    name: 'Sunset',
    isDark: false,
    bgTop: Color(0xFFFFF6EF),
    bgBottom: Color(0xFFFFE6D3),
    card: Color(0xE6FFFFFF),
    line: Color(0xFFF7DCC7),
    ink: Color(0xFF3B1503),
    muted: Color(0xFF7C5A45),
    track: Color(0xFFFBE8D9),
    brand1: Color(0xFFF97316),
    brand2: Color(0xFFB91C1C),
    glow: Color(0xFFFBBF24),
    accent: Color(0xFFEA580C),
    pastel1: Color(0xFFFFE0C2),
    pastel2: Color(0xFFFFD0CC),
    pastel3: Color(0xFFFFF0B3),
    pastel4: Color(0xFFF2D6F5),
    pastel5: Color(0xFFCBEEDD),
    onPastel: Color(0xFF3B1503),
    tooltipBg: Color(0xFF3B1503),
    tooltipText: Color(0xFFFFFFFF),
    shadow: BoxShadow(
      color: Color(0x17B91C1C), // 0 10 30 rgba(185,28,28,0.09)
      blurRadius: 30,
      offset: Offset(0, 10),
    ),
  );

  /// 7. GRAPHITE (light)
  static const graphite = AppColorsTokens(
    id: 'graphite',
    name: 'Graphite',
    isDark: false,
    bgTop: Color(0xFFF6F7F9),
    bgBottom: Color(0xFFE6E8EC),
    card: Color(0xE6FFFFFF),
    line: Color(0xFFDCDFE5),
    ink: Color(0xFF0F172A),
    muted: Color(0xFF5B6472),
    track: Color(0xFFE8EAEE),
    brand1: Color(0xFF1F2937),
    brand2: Color(0xFF0B1220),
    glow: Color(0xFF94A3B8),
    accent: Color(0xFF111827),
    pastel1: Color(0xFFE3E6EC),
    pastel2: Color(0xFFD5DAE3),
    pastel3: Color(0xFFECEFF4),
    pastel4: Color(0xFFDFE3EA),
    pastel5: Color(0xFFCFD5DF),
    onPastel: Color(0xFF0F172A),
    tooltipBg: Color(0xFF0F172A),
    tooltipText: Color(0xFFFFFFFF),
    shadow: BoxShadow(
      color: Color(0x170F172A), // 0 10 30 rgba(15,23,42,0.09)
      blurRadius: 30,
      offset: Offset(0, 10),
    ),
  );

  /// 8. LAGOON (light)
  static const lagoon = AppColorsTokens(
    id: 'lagoon',
    name: 'Lagoon',
    isDark: false,
    bgTop: Color(0xFFEFFCFB),
    bgBottom: Color(0xFFD5F5F3),
    card: Color(0xE6FFFFFF),
    line: Color(0xFFC8ECE9),
    ink: Color(0xFF04302F),
    muted: Color(0xFF44706E),
    track: Color(0xFFDCF3F1),
    brand1: Color(0xFF0D9488),
    brand2: Color(0xFF155E75),
    glow: Color(0xFF5EEAD4),
    accent: Color(0xFF0891B2),
    pastel1: Color(0xFFC5F1EC),
    pastel2: Color(0xFFC4E8F7),
    pastel3: Color(0xFFD8E7FF),
    pastel4: Color(0xFFFDEBC3),
    pastel5: Color(0xFFF9D3D6),
    onPastel: Color(0xFF04302F),
    tooltipBg: Color(0xFF04302F),
    tooltipText: Color(0xFFFFFFFF),
    shadow: BoxShadow(
      color: Color(0x17155E75), // 0 10 30 rgba(21,94,117,0.09)
      blurRadius: 30,
      offset: Offset(0, 10),
    ),
  );

  /// 9. FOREST (dark)
  static const forest = AppColorsTokens(
    id: 'forest',
    name: 'Forest',
    isDark: true,
    bgTop: Color(0xFF07110C),
    bgBottom: Color(0xFF0C1D14),
    card: Color(0xEB102118), // rgba(16,33,24,0.92)
    line: Color(0xFF1D3A2A),
    ink: Color(0xFFE6F6EC),
    muted: Color(0xFF8FB09B),
    track: Color(0xFF15291D),
    brand1: Color(0xFF16A34A),
    brand2: Color(0xFF14532D),
    glow: Color(0xFF4ADE80),
    accent: Color(0xFF4ADE80),
    pastel1: Color(0xFF123524),
    pastel2: Color(0xFF1A3D2C),
    pastel3: Color(0xFF20304A),
    pastel4: Color(0xFF3A3320),
    pastel5: Color(0xFF123A38),
    onPastel: Color(0xFFE6F6EC),
    tooltipBg: Color(0xFF4ADE80),
    tooltipText: Color(0xFF052E16),
    shadow: BoxShadow(
      color: Color(0x73000000), // 0 10 30 rgba(0,0,0,0.45)
      blurRadius: 30,
      offset: Offset(0, 10),
    ),
  );

  /// 10. AURORA (dark)
  static const aurora = AppColorsTokens(
    id: 'aurora',
    name: 'Aurora',
    isDark: true,
    bgTop: Color(0xFF0D0817),
    bgBottom: Color(0xFF1A0F2E),
    card: Color(0xEB201438), // rgba(32,20,56,0.92)
    line: Color(0xFF342252),
    ink: Color(0xFFF1E9FF),
    muted: Color(0xFFB2A0D6),
    track: Color(0xFF281A45),
    brand1: Color(0xFFA855F7),
    brand2: Color(0xFF4C1D95),
    glow: Color(0xFFF0ABFC),
    accent: Color(0xFFE879F9),
    pastel1: Color(0xFF3A1F63),
    pastel2: Color(0xFF2B2A66),
    pastel3: Color(0xFF4A1F57),
    pastel4: Color(0xFF4A2F2A),
    pastel5: Color(0xFF1F3A52),
    onPastel: Color(0xFFF1E9FF),
    tooltipBg: Color(0xFFE879F9),
    tooltipText: Color(0xFF2A0A33),
    shadow: BoxShadow(
      color: Color(0x80000000), // 0 10 30 rgba(0,0,0,0.5)
      blurRadius: 30,
      offset: Offset(0, 10),
    ),
  );

  static const light = ocean;
  static const dark = midnight;

  /// Full list of 10 presets
  static const List<AppColorsTokens> allPresets = [
    ocean,
    violet,
    midnight,
    emerald,
    roseTheme,
    sunset,
    graphite,
    lagoon,
    forest,
    aurora,
  ];

  /// Derives a full design token system from a single brand color (Enterprise option)
  static AppColorsTokens deriveCustom(Color brandColor, {bool isDark = false}) {
    final hsl = HSLColor.fromColor(brandColor);
    final hue = hsl.hue;

    if (isDark) {
      final brand1 = HSLColor.fromAHSL(1.0, hue, (hsl.saturation * 1.1).clamp(0.4, 0.9), 0.55).toColor();
      final brand2 = HSLColor.fromAHSL(1.0, hue, (hsl.saturation * 1.0).clamp(0.4, 0.8), 0.28).toColor();
      final glow = HSLColor.fromAHSL(1.0, hue, 0.85, 0.70).toColor();
      final accent = brand1;
      final bgTop = HSLColor.fromAHSL(1.0, hue, 0.35, 0.05).toColor();
      final bgBottom = HSLColor.fromAHSL(1.0, hue, 0.35, 0.10).toColor();
      final card = HSLColor.fromAHSL(0.92, hue, 0.30, 0.12).toColor();
      final line = HSLColor.fromAHSL(1.0, hue, 0.25, 0.20).toColor();
      final ink = HSLColor.fromAHSL(1.0, hue, 0.20, 0.95).toColor();
      final muted = HSLColor.fromAHSL(1.0, hue, 0.15, 0.65).toColor();
      final track = HSLColor.fromAHSL(1.0, hue, 0.25, 0.14).toColor();

      return AppColorsTokens(
        id: 'custom',
        name: 'Custom',
        isDark: true,
        bgTop: bgTop,
        bgBottom: bgBottom,
        card: card,
        line: line,
        ink: ink,
        muted: muted,
        track: track,
        brand1: brand1,
        brand2: brand2,
        glow: glow,
        accent: accent,
        pastel1: HSLColor.fromAHSL(1.0, (hue + 20) % 360, 0.40, 0.16).toColor(),
        pastel2: HSLColor.fromAHSL(1.0, (hue + 60) % 360, 0.40, 0.16).toColor(),
        pastel3: HSLColor.fromAHSL(1.0, (hue + 140) % 360, 0.35, 0.16).toColor(),
        pastel4: HSLColor.fromAHSL(1.0, (hue + 200) % 360, 0.35, 0.16).toColor(),
        pastel5: HSLColor.fromAHSL(1.0, (hue + 280) % 360, 0.35, 0.16).toColor(),
        onPastel: ink,
        tooltipBg: accent,
        tooltipText: bgTop,
        shadow: const BoxShadow(
          color: Color(0x73000000), // 0 10 30 rgba(0,0,0,0.45)
          blurRadius: 30,
          offset: Offset(0, 10),
        ),
      );
    } else {
      final brand1 = HSLColor.fromAHSL(1.0, hue, (hsl.saturation * 1.0).clamp(0.5, 0.9), 0.38).toColor();
      final brand2 = HSLColor.fromAHSL(1.0, hue, (hsl.saturation * 1.0).clamp(0.5, 0.9), 0.22).toColor();
      final glow = HSLColor.fromAHSL(1.0, hue, 0.85, 0.58).toColor();
      final accent = brand1;
      final bgTop = HSLColor.fromAHSL(1.0, hue, 0.25, 0.97).toColor();
      final bgBottom = HSLColor.fromAHSL(1.0, hue, 0.30, 0.92).toColor();
      const card = Color(0xE6FFFFFF);
      final line = HSLColor.fromAHSL(1.0, hue, 0.20, 0.88).toColor();
      final ink = HSLColor.fromAHSL(1.0, hue, 0.45, 0.10).toColor();
      final muted = HSLColor.fromAHSL(1.0, hue, 0.20, 0.38).toColor();
      final track = HSLColor.fromAHSL(1.0, hue, 0.18, 0.93).toColor();

      return AppColorsTokens(
        id: 'custom',
        name: 'Custom',
        isDark: false,
        bgTop: bgTop,
        bgBottom: bgBottom,
        card: card,
        line: line,
        ink: ink,
        muted: muted,
        track: track,
        brand1: brand1,
        brand2: brand2,
        glow: glow,
        accent: accent,
        pastel1: HSLColor.fromAHSL(1.0, (hue + 20) % 360, 0.50, 0.88).toColor(),
        pastel2: HSLColor.fromAHSL(1.0, (hue + 60) % 360, 0.50, 0.88).toColor(),
        pastel3: HSLColor.fromAHSL(1.0, (hue + 140) % 360, 0.45, 0.88).toColor(),
        pastel4: HSLColor.fromAHSL(1.0, (hue + 200) % 360, 0.45, 0.88).toColor(),
        pastel5: HSLColor.fromAHSL(1.0, (hue + 280) % 360, 0.45, 0.88).toColor(),
        onPastel: ink,
        tooltipBg: ink,
        tooltipText: const Color(0xFFFFFFFF),
        shadow: BoxShadow(
          color: brand2.withValues(alpha: 0.08),
          blurRadius: 30,
          offset: const Offset(0, 10),
        ),
      );
    }
  }

  /// Returns the exact preset by ID without forcing brightness conversion
  static AppColorsTokens getPreset(String id, {Color? customColor}) {
    if (id.toLowerCase() == 'custom') {
      return deriveCustom(customColor ?? const Color(0xFF1D4ED8), isDark: false);
    }
    return allPresets.firstWhere(
      (p) => p.id.toLowerCase() == id.toLowerCase(),
      orElse: () => ocean,
    );
  }

  /// Resolves an AppColorsTokens preset by ID, dynamically honoring requested brightness
  static AppColorsTokens getById(String id, {bool isDark = false, Color? customColor}) {
    if (id.toLowerCase() == 'custom') {
      return deriveCustom(customColor ?? const Color(0xFF1D4ED8), isDark: isDark);
    }

    final matched = allPresets.firstWhere(
      (p) => p.id.toLowerCase() == id.toLowerCase(),
      orElse: () => ocean,
    );

    // If target brightness is dark but preset is light, map to dark counterpart or derive
    if (isDark && !matched.isDark) {
      if (matched.id == 'ocean') return midnight;
      if (matched.id == 'emerald') return forest;
      if (matched.id == 'violet') return aurora;
      return deriveCustom(matched.brand1, isDark: true);
    } else if (!isDark && matched.isDark) {
      if (matched.id == 'midnight') return ocean;
      if (matched.id == 'forest') return emerald;
      if (matched.id == 'aurora') return violet;
      return deriveCustom(matched.brand1, isDark: false);
    }

    return matched;
  }

  @override
  ThemeExtension<AppColorsTokens> copyWith({
    String? id,
    String? name,
    bool? isDark,
    Color? bgTop,
    Color? bgBottom,
    Color? card,
    Color? line,
    Color? ink,
    Color? muted,
    Color? track,
    Color? brand1,
    Color? brand2,
    Color? glow,
    Color? accent,
    Color? pastel1,
    Color? pastel2,
    Color? pastel3,
    Color? pastel4,
    Color? pastel5,
    Color? onPastel,
    Color? tooltipBg,
    Color? tooltipText,
    BoxShadow? shadow,
  }) {
    return AppColorsTokens(
      id: id ?? this.id,
      name: name ?? this.name,
      isDark: isDark ?? this.isDark,
      bgTop: bgTop ?? this.bgTop,
      bgBottom: bgBottom ?? this.bgBottom,
      card: card ?? this.card,
      line: line ?? this.line,
      ink: ink ?? this.ink,
      muted: muted ?? this.muted,
      track: track ?? this.track,
      brand1: brand1 ?? this.brand1,
      brand2: brand2 ?? this.brand2,
      glow: glow ?? this.glow,
      accent: accent ?? this.accent,
      pastel1: pastel1 ?? this.pastel1,
      pastel2: pastel2 ?? this.pastel2,
      pastel3: pastel3 ?? this.pastel3,
      pastel4: pastel4 ?? this.pastel4,
      pastel5: pastel5 ?? this.pastel5,
      onPastel: onPastel ?? this.onPastel,
      tooltipBg: tooltipBg ?? this.tooltipBg,
      tooltipText: tooltipText ?? this.tooltipText,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  ThemeExtension<AppColorsTokens> lerp(covariant ThemeExtension<AppColorsTokens>? other, double t) {
    if (other is! AppColorsTokens) return this;
    return AppColorsTokens(
      id: t < 0.5 ? id : other.id,
      name: t < 0.5 ? name : other.name,
      isDark: t < 0.5 ? isDark : other.isDark,
      bgTop: Color.lerp(bgTop, other.bgTop, t) ?? bgTop,
      bgBottom: Color.lerp(bgBottom, other.bgBottom, t) ?? bgBottom,
      card: Color.lerp(card, other.card, t) ?? card,
      line: Color.lerp(line, other.line, t) ?? line,
      ink: Color.lerp(ink, other.ink, t) ?? ink,
      muted: Color.lerp(muted, other.muted, t) ?? muted,
      track: Color.lerp(track, other.track, t) ?? track,
      brand1: Color.lerp(brand1, other.brand1, t) ?? brand1,
      brand2: Color.lerp(brand2, other.brand2, t) ?? brand2,
      glow: Color.lerp(glow, other.glow, t) ?? glow,
      accent: Color.lerp(accent, other.accent, t) ?? accent,
      pastel1: Color.lerp(pastel1, other.pastel1, t) ?? pastel1,
      pastel2: Color.lerp(pastel2, other.pastel2, t) ?? pastel2,
      pastel3: Color.lerp(pastel3, other.pastel3, t) ?? pastel3,
      pastel4: Color.lerp(pastel4, other.pastel4, t) ?? pastel4,
      pastel5: Color.lerp(pastel5, other.pastel5, t) ?? pastel5,
      onPastel: Color.lerp(onPastel, other.onPastel, t) ?? onPastel,
      tooltipBg: Color.lerp(tooltipBg, other.tooltipBg, t) ?? tooltipBg,
      tooltipText: Color.lerp(tooltipText, other.tooltipText, t) ?? tooltipText,
      shadow: BoxShadow.lerp(shadow, other.shadow, t) ?? shadow,
    );
  }
}

class AppRadiusTokens {
  static const double pill = 999.0;
  static const double input = 12.0;
  static const double square = 12.0;
  static const double logoMark = 14.0;
  static const double tile = 16.0;
  static const double alertRow = 16.0;
  static const double miniCard = 16.0;
  static const double productCard = 18.0;
  static const double planCard = 20.0;
  static const double kpiCard = 22.0;
  static const double card = 24.0;
  static const double largeCard = 24.0;
  static const double hero = 28.0;

  static final BorderRadius pillRadius = BorderRadius.circular(pill);
  static final BorderRadius inputRadius = BorderRadius.circular(input);
  static final BorderRadius squareRadius = BorderRadius.circular(square);
  static final BorderRadius logoMarkRadius = BorderRadius.circular(logoMark);
  static final BorderRadius tileRadius = BorderRadius.circular(tile);
  static final BorderRadius alertRowRadius = BorderRadius.circular(alertRow);
  static final BorderRadius productCardRadius = BorderRadius.circular(productCard);
  static final BorderRadius planCardRadius = BorderRadius.circular(planCard);
  static final BorderRadius kpiCardRadius = BorderRadius.circular(kpiCard);
  static final BorderRadius cardRadius = BorderRadius.circular(card);
  static final BorderRadius heroRadius = BorderRadius.circular(hero);
}

class AppSpacingTokens {
  static const double s4 = 4.0;
  static const double s6 = 6.0;
  static const double s8 = 8.0;
  static const double s10 = 10.0;
  static const double s12 = 12.0;
  static const double s14 = 14.0;
  static const double s16 = 16.0;
  static const double s20 = 20.0;
  static const double s22 = 22.0;
  static const double s24 = 24.0;
  static const double s28 = 28.0;
  static const double s32 = 32.0;
  static const double s40 = 40.0;
}

class AppTypographyTokens {
  final Color ink;
  final Color muted;

  const AppTypographyTokens({required this.ink, required this.muted});

  static const List<FontFeature> tabularFigures = [FontFeature.tabularFigures()];

  TextStyle get pageTitle => GoogleFonts.plusJakartaSans(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        color: ink,
        height: 1.2,
      );

  TextStyle get heroTitle => GoogleFonts.plusJakartaSans(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.02 * 34,
        color: Colors.white,
        height: 1.2,
      );

  TextStyle get heroSubtitle => GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.55,
        color: Colors.white.withValues(alpha: 0.90),
      );

  TextStyle get cardTitle => GoogleFonts.plusJakartaSans(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: ink,
        height: 1.3,
      );

  TextStyle get cardSubtitle => GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: muted,
        height: 1.4,
      );

  TextStyle get kpiValue => GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.02 * 24,
        color: ink,
        fontFeatures: tabularFigures,
      );

  TextStyle get summaryValue => GoogleFonts.plusJakartaSans(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.02 * 26,
        color: ink,
        fontFeatures: tabularFigures,
      );

  TextStyle get label => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: muted,
        letterSpacing: 0.2,
      );

  TextStyle get kpiLabel => label;

  TextStyle get navItem => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: ink,
      );

  TextStyle get navItemActive => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      );

  TextStyle get navGroupLabel => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: muted,
      );

  TextStyle get body => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: ink,
        fontFeatures: tabularFigures,
      );

  TextStyle get tableHeader => GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: muted,
      );

  TextStyle get tableCell => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: ink,
        fontFeatures: tabularFigures,
      );

  TextStyle get badge => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        fontFeatures: tabularFigures,
      );

  TextStyle get trendBadge => GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        fontFeatures: tabularFigures,
      );

  TextStyle get button => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w700,
      );

  TextStyle get smallButton => GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
      );

  TextStyle get receiptText => GoogleFonts.spaceMono(
        fontSize: 12,
        height: 1.7,
        fontWeight: FontWeight.w400,
      );
}

class AppTokens {
  final bool isDark;
  final AppColorsTokens colors;
  final AppTypographyTokens typography;

  const AppTokens({
    required this.isDark,
    required this.colors,
    required this.typography,
  });

  static AppTokens light = AppTokens(
    isDark: false,
    colors: AppColorsTokens.light,
    typography: AppTypographyTokens(
      ink: AppColorsTokens.light.ink,
      muted: AppColorsTokens.light.muted,
    ),
  );

  static AppTokens dark = AppTokens(
    isDark: true,
    colors: AppColorsTokens.dark,
    typography: AppTypographyTokens(
      ink: AppColorsTokens.dark.ink,
      muted: AppColorsTokens.dark.muted,
    ),
  );

  static AppTokens of(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorTokens = theme.extension<AppColorsTokens>() ?? (isDark ? AppColorsTokens.dark : AppColorsTokens.light);
    return AppTokens(
      isDark: isDark,
      colors: colorTokens,
      typography: AppTypographyTokens(
        ink: colorTokens.ink,
        muted: colorTokens.muted,
      ),
    );
  }
}

extension AppTokensExtension on BuildContext {
  AppTokens get tokens => AppTokens.of(this);
}
