import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/env/env.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'core/theme/tokens.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // Falls back to defaults in Env class
  }

  // Connect with Firebase (project: pharmsaas)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Enable offline persistence: caches locally and syncs automatically when online
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  } catch (e) {
    debugPrint('Firebase initialization: $e');
  }

  runApp(
    const ProviderScope(
      child: PharmaCareApp(),
    ),
  );
}

class PharmaCareApp extends ConsumerWidget {
  const PharmaCareApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    final presetId = ref.watch(themePresetProvider);
    final customColor = ref.watch(customBrandColorProvider);

    final selectedPreset = AppColorsTokens.getPreset(presetId, customColor: customColor);

    final lightTokens = selectedPreset.isDark
        ? AppColorsTokens.getById(presetId, isDark: false, customColor: customColor)
        : selectedPreset;
    final darkTokens = selectedPreset.isDark
        ? selectedPreset
        : AppColorsTokens.getById(presetId, isDark: true, customColor: customColor);

    final effectiveThemeMode = (selectedPreset.isDark && themeMode != ThemeMode.dark)
        ? ThemeMode.dark
        : themeMode;

    return MaterialApp.router(
      title: Env.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.buildTheme(lightTokens, isDark: false),
      darkTheme: AppTheme.buildTheme(darkTokens, isDark: true),
      themeMode: effectiveThemeMode,
      routerConfig: router,
    );
  }
}
