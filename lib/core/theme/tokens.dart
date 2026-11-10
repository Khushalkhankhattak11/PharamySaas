import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColorsTokens {
  final Color bgTop;
  final Color bgBottom;
  final Color card;
  final Color line;
  final Color ink;
  final Color muted;
  final Color track;
  final BoxShadow shadow;

  // Shared colors across themes
  static const Color brand = Color(0xFF0B5D5A);
  static const Color brandGradientStart = Color(0xFF0F766E);
  static const Color brandGradientEnd = Color(0xFF064E4B);
  static const Color activePillGradientEnd = Color(0xFF05343A);

  // Pastels
  static const Color lime = Color(0xFFDDF2B0);
  static const Color mint = Color(0xFF9AD9D0);
  static const Color peach = Color(0xFFF5D5AE);
  static const Color lavender = Color(0xFFC3C6F3);
  static const Color rose = Color(0xFFF4B9BD);

  // Semantic
  static const Color success = Color(0xFF16A34A);
  static const Color trendGreenText = Color(0xFF15803D);
  static const Color amber = Color(0xFFF59E0B);
  static const Color amberText = Color(0xFFB45309);
  static const Color orange = Color(0xFFEA580C);
  static const Color orangeText = Color(0xFFC2410C);
  static const Color danger = Color(0xFFDC2626);
  static const Color info = Color(0xFF2563EB);

  // Hero extra
  static const Color glow = Color(0xFF2BB5A8);
  static const Color statusDot = Color(0xFF4ADE80);
  static const Color tooltipDark = Color(0xFF05343A);
  static const Color focusRing = Color(0xFF2DD4BF);

  const AppColorsTokens({
    required this.bgTop,
    required this.bgBottom,
    required this.card,
    required this.line,
    required this.ink,
    required this.muted,
    required this.track,
    required this.shadow,
  });

  static const light = AppColorsTokens(
    bgTop: Color(0xFFF4F9F8),
    bgBottom: Color(0xFFE0F3F1),
    card: Color(0xE0FFFFFF), // rgba(255,255,255,0.88)
    line: Color(0xFFDFECEB),
    ink: Color(0xFF06292B),
    muted: Color(0xFF4B6567),
    track: Color(0xFFE6EFEE),
    shadow: BoxShadow(
      color: Color(0x1205343A), // rgba(5,52,58,0.07)
      blurRadius: 30,
      offset: Offset(0, 10),
    ),
  );

  static const dark = AppColorsTokens(
    bgTop: Color(0xFF0A1314),
    bgBottom: Color(0xFF0E1E20),
    card: Color(0xE6142628), // rgba(20,38,40,0.90)
    line: Color(0xFF1F3739),
    ink: Color(0xFFE8F5F3),
    muted: Color(0xFF9BB8B6),
    track: Color(0xFF1B3234),
    shadow: BoxShadow(
      color: Color(0x59000000), // rgba(0,0,0,0.35)
      blurRadius: 30,
      offset: Offset(0, 10),
    ),
  );

  LinearGradient get bgGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [bgTop, bgBottom],
      );

  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brandGradientStart, brandGradientEnd],
  );

  static const LinearGradient activePillGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brandGradientStart, activePillGradientEnd],
  );

  static const BoxShadow heroShadow = BoxShadow(
    color: Color(0x47064E4B), // rgba(6,78,75,0.28)
    blurRadius: 40,
    offset: Offset(0, 20),
  );

  static const BoxShadow activeItemShadow = BoxShadow(
    color: Color(0x4D05343A), // rgba(5,52,58,0.30)
    blurRadius: 18,
    offset: Offset(0, 8),
  );

  static const BoxShadow logoMarkShadow = BoxShadow(
    color: Color(0x590B5D5A), // rgba(11,93,90,0.35)
    blurRadius: 18,
    offset: Offset(0, 8),
  );
}

class AppRadiusTokens {
  static const double pill = 999.0;
  static const double input = 999.0;
  static const double kpiCard = 22.0;
  static const double largeCard = 24.0;
  static const double hero = 28.0;
  static const double planCard = 20.0;
  static const double logoMark = 14.0;
  static const double tile = 16.0;
  static const double alertRow = 16.0;
  static const double iconSquare = 12.0;

  static final BorderRadius pillRadius = BorderRadius.circular(pill);
  static final BorderRadius kpiCardRadius = BorderRadius.circular(kpiCard);
  static final BorderRadius largeCardRadius = BorderRadius.circular(largeCard);
  static final BorderRadius heroRadius = BorderRadius.circular(hero);
  static final BorderRadius planCardRadius = BorderRadius.circular(planCard);
  static final BorderRadius logoMarkRadius = BorderRadius.circular(logoMark);
  static final BorderRadius tileRadius = BorderRadius.circular(tile);
  static final BorderRadius alertRowRadius = BorderRadius.circular(alertRow);
  static final BorderRadius iconSquareRadius = BorderRadius.circular(iconSquare);
}

class AppSpacingTokens {
  static const double s4 = 4.0;
  static const double s8 = 8.0;
  static const double s12 = 12.0;
  static const double s16 = 16.0;
  static const double s22 = 22.0;
  static const double s24 = 24.0;
  static const double s28 = 28.0;
  static const double s32 = 32.0;
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
        color: Colors.white.withValues(alpha: 0.88),
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

  TextStyle get kpiLabel => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: muted,
        letterSpacing: 0.2,
      );

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? dark : light;
  }
}

extension AppTokensExtension on BuildContext {
  AppTokens get tokens => AppTokens.of(this);
}

