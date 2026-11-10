import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tokens.dart';

class AppTheme {
  static ThemeData get lightTheme {
    const tokens = AppColorsTokens.light;
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(ThemeData.light().textTheme).apply(
      bodyColor: tokens.ink,
      displayColor: tokens.ink,
    );

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: tokens.bgTop,
      colorScheme: ColorScheme.light(
        primary: AppColorsTokens.brand,
        onPrimary: Colors.white,
        secondary: AppColorsTokens.info,
        onSecondary: Colors.white,
        surface: tokens.card,
        onSurface: tokens.ink,
        error: AppColorsTokens.danger,
        onError: Colors.white,
        outline: tokens.line,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: tokens.ink,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 1,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: tokens.ink,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: tokens.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadiusTokens.largeCard),
          side: BorderSide(color: tokens.line, width: 1),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: tokens.line,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadiusTokens.input),
          borderSide: BorderSide(color: tokens.line, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadiusTokens.input),
          borderSide: BorderSide(color: tokens.line, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadiusTokens.input),
          borderSide: const BorderSide(color: AppColorsTokens.focusRing, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadiusTokens.input),
          borderSide: const BorderSide(color: AppColorsTokens.danger, width: 1),
        ),
        hintStyle: GoogleFonts.plusJakartaSans(
          color: tokens.muted,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColorsTokens.brand,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 44),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadiusTokens.pill),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: tokens.ink,
          side: BorderSide(color: tokens.line, width: 1),
          minimumSize: const Size(64, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadiusTokens.pill),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColorsTokens.brand,
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    const tokens = AppColorsTokens.dark;
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme).apply(
      bodyColor: tokens.ink,
      displayColor: tokens.ink,
    );

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: tokens.bgTop,
      colorScheme: ColorScheme.dark(
        primary: AppColorsTokens.brand,
        onPrimary: Colors.white,
        secondary: AppColorsTokens.info,
        onSecondary: Colors.white,
        surface: tokens.card,
        onSurface: tokens.ink,
        error: AppColorsTokens.danger,
        onError: Colors.white,
        outline: tokens.line,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: tokens.ink,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 1,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: tokens.ink,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: tokens.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadiusTokens.largeCard),
          side: BorderSide(color: tokens.line, width: 1),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: tokens.line,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadiusTokens.input),
          borderSide: BorderSide(color: tokens.line, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadiusTokens.input),
          borderSide: BorderSide(color: tokens.line, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadiusTokens.input),
          borderSide: const BorderSide(color: AppColorsTokens.focusRing, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadiusTokens.input),
          borderSide: const BorderSide(color: AppColorsTokens.danger, width: 1),
        ),
        hintStyle: GoogleFonts.plusJakartaSans(
          color: tokens.muted,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColorsTokens.brand,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 44),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadiusTokens.pill),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: tokens.ink,
          side: BorderSide(color: tokens.line, width: 1),
          minimumSize: const Size(64, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadiusTokens.pill),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColorsTokens.brand,
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
