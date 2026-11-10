import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/tokens.dart';

class AppSearchField extends StatefulWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final String placeholder;
  final double? maxWidth;
  final bool showShortcut;
  final FocusNode? focusNode;
  final bool isSquare;
  final String? label;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const AppSearchField({
    super.key,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.placeholder = 'Search medicines, invoices, batches...',
    this.maxWidth = 460.0,
    this.showShortcut = true,
    this.focusNode,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
  })  : isSquare = false,
        label = null;

  const AppSearchField.square({
    super.key,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    required this.placeholder,
    this.label,
    this.maxWidth,
    this.showShortcut = false,
    this.focusNode,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
  }) : isSquare = true;

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() => _isFocused = _focusNode.hasFocus);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (widget.focusNode == null) _focusNode.dispose();
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isWebOrDesktop = kIsWeb ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;

    final radius = widget.isSquare ? AppRadiusTokens.square : AppRadiusTokens.pill;
    final padding = widget.isSquare
        ? const EdgeInsets.symmetric(horizontal: 14, vertical: 11)
        : const EdgeInsets.symmetric(horizontal: 18, vertical: 11);

    final fieldWidget = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: tokens.colors.card,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: _isFocused ? tokens.colors.glow : tokens.colors.line,
          width: _isFocused ? 2 : 1,
        ),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: tokens.colors.glow.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [tokens.colors.shadow],
      ),
      padding: padding,
      child: Row(
        children: [
          widget.prefixIcon ??
              Icon(
                LucideIcons.search,
                size: 18,
                color: _isFocused ? tokens.colors.brand1 : tokens.colors.muted,
              ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              obscureText: widget.obscureText,
              keyboardType: widget.keyboardType,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: tokens.colors.ink,
                fontFeatures: AppTypographyTokens.tabularFigures,
              ),
              decoration: InputDecoration(
                hintText: widget.placeholder,
                hintStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: tokens.colors.muted,
                ),
                filled: false,
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (widget.suffixIcon != null) ...[
            const SizedBox(width: 8),
            widget.suffixIcon!,
          ] else
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _controller,
              builder: (context, value, _) {
                if (value.text.isNotEmpty) {
                  return IconButton(
                    icon: const Icon(LucideIcons.x, size: 16),
                    color: tokens.colors.muted,
                    splashRadius: 16,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    onPressed: () {
                      _controller.clear();
                      widget.onChanged?.call('');
                      widget.onClear?.call();
                    },
                  );
                }
                if (widget.showShortcut && isWebOrDesktop) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: tokens.colors.track,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: tokens.colors.line, width: 0.8),
                    ),
                    child: Text(
                      'Ctrl+K',
                      maxLines: 1,
                      softWrap: false,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: tokens.colors.muted,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
        ],
      ),
    );

    Widget result = fieldWidget;
    if (widget.maxWidth != null) {
      result = ConstrainedBox(
        constraints: BoxConstraints(maxWidth: widget.maxWidth!),
        child: result,
      );
    }

    if (widget.label != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.label!,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: tokens.colors.muted,
            ),
          ),
          const SizedBox(height: 6),
          result,
        ],
      );
    }

    return result;
  }
}
