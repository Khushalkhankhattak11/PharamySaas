import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';

class AppChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final Widget? icon;
  final Widget? trailing;

  const AppChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.icon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadiusTokens.pill),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? null : tokens.colors.card,
            gradient: isSelected ? tokens.colors.gradient : null,
            borderRadius: BorderRadius.circular(AppRadiusTokens.pill),
            border: isSelected ? null : Border.all(color: tokens.colors.line, width: 1),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: tokens.colors.brand1.withValues(alpha: 0.28),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                icon!,
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : tokens.colors.muted,
                  height: 1.1,
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 6),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class FilterChipGroup<T> extends StatelessWidget {
  final List<T> values;
  final String Function(T value) labelBuilder;
  final T selectedValue;
  final ValueChanged<T> onSelected;
  final double spacing;

  const FilterChipGroup({
    super.key,
    required this.values,
    required this.labelBuilder,
    required this.selectedValue,
    required this.onSelected,
    this.spacing = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: values.map((val) {
          final isSelected = val == selectedValue;
          return Padding(
            padding: EdgeInsets.only(right: spacing),
            child: AppChip(
              label: labelBuilder(val),
              isSelected: isSelected,
              onTap: () => onSelected(val),
            ),
          );
        }).toList(),
      ),
    );
  }
}
