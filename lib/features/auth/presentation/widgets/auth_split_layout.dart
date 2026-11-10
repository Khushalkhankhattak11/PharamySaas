import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/hero_banner.dart';

class AuthSplitLayout extends StatelessWidget {
  final Widget cardContent;
  final double cardMaxWidth;

  const AuthSplitLayout({
    super.key,
    required this.cardContent,
    this.cardMaxWidth = 420.0,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;

    final rightCard = Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: cardMaxWidth),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: tokens.colors.card,
              borderRadius: BorderRadius.circular(AppRadiusTokens.largeCard),
              border: Border.all(color: tokens.colors.line, width: 1),
              boxShadow: [tokens.colors.shadow],
            ),
            child: cardContent,
          ),
        ),
      ),
    );

    if (!isDesktop) {
      return Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(gradient: tokens.colors.bgGradient),
          child: SafeArea(child: rightCard),
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          // Left hero-style teal gradient panel
          Expanded(
            flex: 5,
            child: Container(
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(-0.8, -0.6),
                  end: Alignment(0.8, 0.6),
                  colors: [
                    Color(0xFF0F766E),
                    Color(0xFF064E4B),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Radial glow
                  Positioned(
                    top: -100,
                    right: -100,
                    width: 600,
                    height: 500,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0.85, -0.2),
                          radius: 0.85,
                          colors: [
                            tokens.colors.glow.withValues(alpha: 0.4),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.6],
                        ),
                      ),
                    ),
                  ),
                  // Capsule watermark rotated -38deg
                  Positioned(
                    right: -30,
                    bottom: 80,
                    child: Transform.rotate(
                      angle: -38 * math.pi / 180,
                      child: CustomPaint(
                        size: const Size(300, 120),
                        painter: CapsuleWatermarkPainter(),
                      ),
                    ),
                  ),
                  // Left panel content
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 64),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Logo mark + Title
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: AppColorsTokens.brandGradient,
                                borderRadius: BorderRadius.circular(AppRadiusTokens.logoMark),
                                boxShadow: const [AppColorsTokens.logoMarkShadow],
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                '+',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'PharmaCore',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                Text(
                                  'Smart pharmacy management',
                                  style: TextStyle(
                                    color: Color(0xCCFFFFFF),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Center value propositions / 3 feature lines
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'The complete operating system for modern pharmacies.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                height: 1.25,
                                letterSpacing: -0.02 * 32,
                              ),
                            ),
                            const SizedBox(height: 32),
                            _buildFeatureLine(
                              LucideIcons.checkCircle2,
                              'Multi-tenant real-time inventory & FEFO batch control',
                            ),
                            const SizedBox(height: 18),
                            _buildFeatureLine(
                              LucideIcons.zap,
                              'Lightning-fast POS billing with QR & thermal receipts',
                            ),
                            const SizedBox(height: 18),
                            _buildFeatureLine(
                              LucideIcons.shieldCheck,
                              'Strict role permissions & automated daily stock alerts',
                            ),
                          ],
                        ),

                        // Footer
                        const Text(
                          '© 2026 PharmaCore SaaS Inc. Enterprise Grade Security.',
                          style: TextStyle(
                            color: Color(0x99FFFFFF),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Right white card panel
          Expanded(
            flex: 6,
            child: Container(
              height: double.infinity,
              decoration: BoxDecoration(gradient: tokens.colors.bgGradient),
              child: rightCard,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildFeatureLine(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColorsTokens.statusDot, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}