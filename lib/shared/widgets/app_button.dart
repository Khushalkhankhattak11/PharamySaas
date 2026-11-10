import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';

enum AppButtonVariant {
  primary,
  white,
  ghost,
  danger,
  secondary,
}

class AppButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final Widget? icon;
  final bool isLoading;
  final double? width;
  final double height;
  final double radius;
  final EdgeInsetsGeometry? padding;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.width,
    this.height = 44.0,
    this.radius = AppRadiusTokens.pill,
    this.padding,
  });

  const AppButton.primary({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.width,
    this.height = 44.0,
    this.radius = AppRadiusTokens.pill,
    this.padding,
  }) : variant = AppButtonVariant.primary;

  const AppButton.white({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.width,
    this.height = 44.0,
    this.radius = AppRadiusTokens.pill,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
  }) : variant = AppButtonVariant.white;

  const AppButton.ghost({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.width,
    this.height = 44.0,
    this.radius = AppRadiusTokens.pill,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
  }) : variant = AppButtonVariant.ghost;

  const AppButton.danger({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.width,
    this.height = 44.0,
    this.radius = AppRadiusTokens.pill,
    this.padding,
  }) : variant = AppButtonVariant.danger;

  const AppButton.secondary({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.width,
    this.height = 44.0,
    this.radius = AppRadiusTokens.pill,
    this.padding,
  }) : variant = AppButtonVariant.secondary;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    Color textColor;
    Gradient? gradient;
    Color? solidColor;
    Border? border;
    List<BoxShadow> shadows = [];

    switch (widget.variant) {
      case AppButtonVariant.primary:
        gradient = AppColorsTokens.brandGradient;
        textColor = Colors.white;
        if (_isHovered) {
          shadows = [
            BoxShadow(
              color: AppColorsTokens.brand.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 4),
            )
          ];
        }
        break;
      case AppButtonVariant.white:
        solidColor = Colors.white;
        textColor = AppColorsTokens.tooltipDark; // #05343A
        if (_isHovered) {
          shadows = [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ];
        }
        break;
      case AppButtonVariant.ghost:
        solidColor = Colors.white.withValues(alpha: _isHovered ? 0.22 : 0.14);
        border = Border.all(
          color: Colors.white.withValues(alpha: 0.35),
          width: 1,
        );
        textColor = Colors.white;
        break;
      case AppButtonVariant.danger:
        solidColor = AppColorsTokens.danger;
        textColor = Colors.white;
        if (_isHovered) {
          shadows = [
            BoxShadow(
              color: AppColorsTokens.danger.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ];
        }
        break;
      case AppButtonVariant.secondary:
        solidColor = tokens.colors.card;
        border = Border.all(color: tokens.colors.line, width: 1);
        textColor = tokens.colors.ink;
        break;
    }

    final effectivePadding = widget.padding ??
        const EdgeInsets.symmetric(horizontal: 18, vertical: 10);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeInOut,
      width: widget.width,
      height: widget.height,
      transform: _isPressed
          ? Matrix4.diagonal3Values(0.98, 0.98, 1.0)
          : Matrix4.identity(),
      decoration: BoxDecoration(
        color: solidColor,
        gradient: gradient,
        borderRadius: BorderRadius.circular(widget.radius),
        border: border,
        boxShadow: shadows,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(widget.radius),
          onTap: isEnabled ? widget.onPressed : null,
          onHover: (hovered) => setState(() => _isHovered = hovered),
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          child: Padding(
            padding: effectivePadding,
            child: Row(
              mainAxisSize: widget.width != null ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (widget.isLoading)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(textColor),
                    ),
                  )
                else ...[
                  if (widget.icon != null) ...[
                    widget.icon!,
                    const SizedBox(width: 8),
                  ],
                  Text(
                    widget.text,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}