import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/tokens.dart';

class LoadingSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const LoadingSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.radius = 8.0,
  });

  const LoadingSkeleton.circle({
    super.key,
    required double size,
  })  : width = size,
        height = size,
        radius = size / 2;

  const LoadingSkeleton.pill({
    super.key,
    required this.width,
    required this.height,
  }) : radius = AppRadiusTokens.pill;

  const LoadingSkeleton.card({
    super.key,
    required this.width,
    required this.height,
  }) : radius = AppRadiusTokens.largeCard;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isDark = tokens.isDark;

    final baseColor = isDark ? tokens.colors.track : const Color(0xFFE2EDEB);
    final highlightColor = isDark ? tokens.colors.line : const Color(0xFFF4F9F8);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }

  /// Shimmer placeholder specifically for network medicine images
  static Widget imageBox({
    double width = 48,
    double height = 48,
    double radius = 10,
  }) {
    return LoadingSkeleton(width: width, height: height, radius: radius);
  }

  /// Shimmer for tables (Inventory, Lookup, Staff, Sales)
  static Widget tableRows({
    required BuildContext context,
    int rows = 6,
  }) {
    final tokens = context.tokens;
    return Container(
      decoration: BoxDecoration(
        color: tokens.colors.card,
        borderRadius: BorderRadius.circular(AppRadiusTokens.tile),
        border: Border.all(color: tokens.colors.line),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              LoadingSkeleton(width: 140, height: 16, radius: 4),
              Spacer(),
              LoadingSkeleton(width: 80, height: 16, radius: 4),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1),
          const SizedBox(height: 18),
          ...List.generate(rows, (i) {
            return const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  LoadingSkeleton(width: 36, height: 36, radius: 8),
                  SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LoadingSkeleton(width: 130, height: 14, radius: 4),
                        SizedBox(height: 6),
                        LoadingSkeleton(width: 80, height: 11, radius: 4),
                      ],
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: LoadingSkeleton(width: 70, height: 14, radius: 4),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: LoadingSkeleton(width: 50, height: 14, radius: 4),
                  ),
                  SizedBox(width: 12),
                  LoadingSkeleton(width: 60, height: 24, radius: 12),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Shimmer for POS screen medicine product grid
  static Widget posGrid({
    required BuildContext context,
    int count = 9,
  }) {
    final tokens = context.tokens;
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        const crossAxisCount = 3;
        const spacing = 12.0;
        const totalSpacing = spacing * (crossAxisCount - 1);
        final cardWidth = (availableWidth - totalSpacing) / crossAxisCount;
        final cardHeight = cardWidth / 1.45;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: List.generate(count, (idx) {
            return SizedBox(
              width: cardWidth,
              height: cardHeight,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: tokens.colors.card,
                  borderRadius: BorderRadius.circular(AppRadiusTokens.tile),
                  border: Border.all(color: tokens.colors.line),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        LoadingSkeleton(width: 28, height: 28, radius: 6),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              LoadingSkeleton(width: 90, height: 12, radius: 4),
                              SizedBox(height: 4),
                              LoadingSkeleton(width: 60, height: 10, radius: 4),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        LoadingSkeleton(width: 55, height: 14, radius: 4),
                        LoadingSkeleton(width: 30, height: 18, radius: 9),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        );
      },
    );
  }

  /// Shimmer for Dashboard (Hero, 6 KPIs, 2 Charts)
  static Widget dashboardSkeleton({
    required BuildContext context,
  }) {
    final tokens = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Hero banner shimmer
        Container(
          height: 140,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: tokens.colors.card,
            borderRadius: BorderRadius.circular(AppRadiusTokens.largeCard),
            border: Border.all(color: tokens.colors.line),
          ),
          child: const Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    LoadingSkeleton(width: 220, height: 22, radius: 6),
                    SizedBox(height: 12),
                    LoadingSkeleton(width: 380, height: 14, radius: 4),
                  ],
                ),
              ),
              LoadingSkeleton(width: 120, height: 40, radius: 10),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 4 KPI cards shimmer (using non-scrolling Wrap to prevent viewport dirty relayout)
        LayoutBuilder(builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 900;
          final crossAxisCount = isNarrow ? 2 : 4;
          const spacing = 14.0;
          final totalSpacing = spacing * (crossAxisCount - 1);
          final cardWidth = (constraints.maxWidth - totalSpacing) / crossAxisCount;
          final cardHeight = cardWidth / 1.8;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: List.generate(4, (_) {
              return SizedBox(
                width: cardWidth,
                height: cardHeight,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: tokens.colors.card,
                    borderRadius: BorderRadius.circular(AppRadiusTokens.tile),
                    border: Border.all(color: tokens.colors.line),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          LoadingSkeleton(width: 90, height: 12, radius: 4),
                          LoadingSkeleton(width: 32, height: 32, radius: 8),
                        ],
                      ),
                      LoadingSkeleton(width: 110, height: 24, radius: 6),
                      LoadingSkeleton(width: 130, height: 11, radius: 4),
                    ],
                  ),
                ),
              );
            }),
          );
        }),
        const SizedBox(height: 20),

        // Chart cards shimmer
        Row(
          children: [
            Expanded(
              flex: 5,
              child: Container(
                height: 260,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: tokens.colors.card,
                  borderRadius: BorderRadius.circular(AppRadiusTokens.largeCard),
                  border: Border.all(color: tokens.colors.line),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LoadingSkeleton(width: 140, height: 16, radius: 4),
                    SizedBox(height: 8),
                    LoadingSkeleton(width: 200, height: 12, radius: 4),
                    Spacer(),
                    LoadingSkeleton(width: double.infinity, height: 140, radius: 10),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 4,
              child: Container(
                height: 260,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: tokens.colors.card,
                  borderRadius: BorderRadius.circular(AppRadiusTokens.largeCard),
                  border: Border.all(color: tokens.colors.line),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LoadingSkeleton(width: 130, height: 16, radius: 4),
                    SizedBox(height: 8),
                    LoadingSkeleton(width: 160, height: 12, radius: 4),
                    Spacer(),
                    Center(child: LoadingSkeleton.circle(size: 130)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
