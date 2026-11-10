import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tokens.dart';

class AppTheme {
  static ThemeData buildTheme(AppColorsTokens tokens, {required bool isDark}) {
    final baseTextTheme = isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme;
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(baseTextTheme).apply(
      bodyColor: tokens.ink,
      displayColor: tokens.ink,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: tokens.bgTop,
      colorScheme: isDark
          ? ColorScheme.dark(
              primary: tokens.brand1,
              onPrimary: tokens.bgTop,
              secondary: tokens.accent,
              onSecondary: Colors.white,
              surface: tokens.card,
              onSurface: tokens.ink,
              error: AppColorsTokens.danger,
              onError: Colors.white,
              outline: tokens.line,
            )
          : ColorScheme.light(
              primary: tokens.brand1,
              onPrimary: Colors.white,
              secondary: tokens.accent,
              onSecondary: Colors.white,
              surface: tokens.card,
              onSurface: tokens.ink,
              error: AppColorsTokens.danger,
              onError: Colors.white,
              outline: tokens.line,
            ),
      textTheme: textTheme,
      extensions: [
        tokens,
      ],
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
          borderSide: BorderSide(color: tokens.glow, width: 2),
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
          backgroundColor: tokens.brand1,
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
          foregroundColor: tokens.brand1,
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  static ThemeData get lightTheme => buildTheme(AppColorsTokens.light, isDark: false);
  static ThemeData get darkTheme => buildTheme(AppColorsTokens.dark, isDark: true);
}
