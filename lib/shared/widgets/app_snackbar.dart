import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/tokens.dart';

enum SnackBarType { success, error, info, warning }

class AppSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    Color bg;
    IconData icon;

    switch (type) {
      case SnackBarType.success:
        bg = AppColorsTokens.success;
        icon = LucideIcons.checkCircle;
        break;
      case SnackBarType.error:
        bg = AppColorsTokens.danger;
        icon = LucideIcons.alertCircle;
        break;
      case SnackBarType.warning:
        bg = AppColorsTokens.amber;
        icon = LucideIcons.alertTriangle;
        break;
      case SnackBarType.info:
        bg = AppColorsTokens.info;
        icon = LucideIcons.info;
        break;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: bg,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadiusTokens.tile),
        ),
        margin: const EdgeInsets.all(16),
        content: Row(
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void success(BuildContext context, String message) =>
      show(context, message: message, type: SnackBarType.success);

  static void error(BuildContext context, String message) =>
      show(context, message: message, type: SnackBarType.error);

  static void warning(BuildContext context, String message) =>
      show(context, message: message, type: SnackBarType.warning);

  static void info(BuildContext context, String message) =>
      show(context, message: message, type: SnackBarType.info);
}

