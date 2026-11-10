import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';

enum AppButtonVariant {
  primary,
  large,
  white,
  translucentOutline,
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
  final double? height;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final double? fontSize;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.width,
    this.height,
    this.radius = AppRadiusTokens.pill,
    this.padding,
    this.fontSize,
  });

  const AppButton.primary({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.width,
    this.height,
    this.radius = AppRadiusTokens.pill,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
    this.fontSize = 14,
  }) : variant = AppButtonVariant.primary;

  const AppButton.large({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.width = double.infinity,
    this.height,
    this.radius = AppRadiusTokens.pill,
    this.padding = const EdgeInsets.all(16),
    this.fontSize = 16,
  }) : variant = AppButtonVariant.large;

  const AppButton.white({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.width,
    this.height,
    this.radius = AppRadiusTokens.pill,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    this.fontSize = 14,
  }) : variant = AppButtonVariant.white;

  const AppButton.translucentOutline({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.width,
    this.height,
    this.radius = AppRadiusTokens.pill,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    this.fontSize = 14,
  }) : variant = AppButtonVariant.translucentOutline;

  const AppButton.ghost({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.width,
    this.height,
    this.radius = AppRadiusTokens.pill,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
    this.fontSize = 13,
  }) : variant = AppButtonVariant.ghost;

  const AppButton.danger({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.width,
    this.height,
    this.radius = AppRadiusTokens.pill,
    this.padding,
    this.fontSize = 14,
  }) : variant = AppButtonVariant.danger;

  const AppButton.secondary({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.width,
    this.height,
    this.radius = AppRadiusTokens.pill,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
    this.fontSize = 13,
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
    FontWeight fontWeight = FontWeight.w700;
    double effectiveFontSize = widget.fontSize ?? 14;

    switch (widget.variant) {
      case AppButtonVariant.primary:
        gradient = tokens.colors.gradient;
        textColor = Colors.white;
        if (_isHovered) {
          shadows = [
            BoxShadow(
              color: tokens.colors.brand1.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 4),
            )
          ];
        }
        break;

      case AppButtonVariant.large:
        gradient = tokens.colors.gradient;
        textColor = Colors.white;
        effectiveFontSize = 16;
        if (_isHovered) {
          shadows = [
            BoxShadow(
              color: tokens.colors.brand1.withValues(alpha: 0.40),
              blurRadius: 16,
              offset: const Offset(0, 5),
            )
          ];
        }
        break;

      case AppButtonVariant.white:
        solidColor = Colors.white;
        textColor = tokens.colors.brand2;
        if (_isHovered) {
          shadows = [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ];
        }
        break;

      case AppButtonVariant.translucentOutline:
        solidColor = Colors.white.withValues(alpha: _isHovered ? 0.22 : 0.14);
        border = Border.all(
          color: Colors.white.withValues(alpha: 0.35),
          width: 1,
        );
        textColor = Colors.white;
        break;

      case AppButtonVariant.ghost:
      case AppButtonVariant.secondary:
        solidColor = tokens.colors.card;
        border = Border.all(color: tokens.colors.line, width: 1);
        textColor = tokens.colors.ink;
        fontWeight = FontWeight.w600;
        effectiveFontSize = widget.fontSize ?? 13;
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
    }

    final effectivePadding = widget.padding ??
        const EdgeInsets.symmetric(horizontal: 18, vertical: 11);

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
                      fontSize: effectiveFontSize,
                      fontWeight: fontWeight,
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

/// Primary button shortcut: pill, padding 11 18, gradient brand1 -> brand2, white 14/700
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool isLoading;
  final double? width;
  final EdgeInsetsGeometry? padding;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.width,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
  });

  @override
  Widget build(BuildContext context) {
    return AppButton.primary(
      text: text,
      onPressed: onPressed,
      icon: icon,
      isLoading: isLoading,
      width: width,
      padding: padding,
    );
  }
}

/// Ghost button shortcut: pill, padding 9 14, card color, 1px line border, ink 13/600
class GhostButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool isLoading;
  final double? width;
  final EdgeInsetsGeometry? padding;

  const GhostButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.width,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
  });

  @override
  Widget build(BuildContext context) {
    return AppButton.ghost(
      text: text,
      onPressed: onPressed,
      icon: icon,
      isLoading: isLoading,
      width: width,
      padding: padding,
    );
  }
}
