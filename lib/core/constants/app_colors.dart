import 'package:flutter/material.dart';
import '../theme/tokens.dart';

class AppColors {
  // Primary brand palette - Medical Teal / Emerald
  static const Color primary = AppColorsTokens.brand; // #0B5D5A
  static const Color primaryDark = AppColorsTokens.brandGradientEnd; // #064E4B
  static const Color primaryLight = AppColorsTokens.brandGradientStart; // #0F766E
  static const Color primaryContainer = Color(0xFFE0F3F1);

  // Secondary palette
  static const Color secondary = AppColorsTokens.info; // #2563EB
  static const Color secondaryDark = Color(0xFF1D4ED8);
  static const Color secondaryLight = Color(0xFF60A5FA);

  // Status colors
  static const Color success = AppColorsTokens.success; // #16A34A
  static const Color warning = AppColorsTokens.amber; // #F59E0B
  static const Color error = AppColorsTokens.danger; // #DC2626
  static const Color info = AppColorsTokens.info; // #2563EB

  // Expiry specific colors
  static const Color expired = AppColorsTokens.danger; // #DC2626
  static const Color expiringSoon30 = AppColorsTokens.orange; // #EA580C
  static const Color expiringSoon90 = AppColorsTokens.amber; // #F59E0B
  static const Color fresh = AppColorsTokens.success; // #16A34A

  // Pastels
  static const Color lime = AppColorsTokens.lime;
  static const Color mint = AppColorsTokens.mint;
  static const Color peach = AppColorsTokens.peach;
  static const Color lavender = AppColorsTokens.lavender;
  static const Color rose = AppColorsTokens.rose;

  // Neutrals - Light
  static const Color backgroundLight = Color(0xFFF4F9F8);
  static const Color surfaceLight = Color(0xE0FFFFFF); // rgba(255,255,255,0.88)
  static const Color surfaceVariantLight = Color(0xFFE6EFEE); // track
  static const Color textPrimaryLight = Color(0xFF06292B); // ink
  static const Color textSecondaryLight = Color(0xFF4B6567); // muted
  static const Color borderLight = Color(0xFFDFECEB); // line

  // Neutrals - Dark
  static const Color backgroundDark = Color(0xFF0A1314);
  static const Color surfaceDark = Color(0xE6142628);
  static const Color surfaceVariantDark = Color(0xFF1B3234);
  static const Color textPrimaryDark = Color(0xFFE8F5F3);
  static const Color textSecondaryDark = Color(0xFF9BB8B6);
  static const Color borderDark = Color(0xFF1F3739);
}
