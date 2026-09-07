library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:donjo/core/motion/app_motion.dart';
import 'package:donjo/core/theme/app_palette.dart';
import 'package:donjo/core/theme/spacing/app_spacing.dart';

/// IBM Carbon Design System Input Field.
///
/// Features:
/// - Distinct top label with optional required marker.
/// - Crisp, high-contrast borders with 2px Carbon interactive focus ring.
/// - Smooth productive motion transitions on focus and error states.
/// - Inline error message with Carbon error icon.
/// - Monospace support for OTP / reset tokens.
/// - Accessible password visibility toggle.
class AuthTextField extends StatefulWidget {
  const AuthTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.helper,
    this.errorText,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
    this.inputFormatters,
    this.enabled = true,
    this.mono = false,
    this.isRequired = false,
    this.maxLength,
    this.prefixIcon,
    this.suffixIcon,
    this.onSubmitted,
    this.onChanged,
    this.focusNode,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? helper;
  final String? errorText;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final bool enabled;
  final bool mono;
  final bool isRequired;
  final int? maxLength;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  FocusNode? _internalFocusNode;
  bool _isFocused = false;
  bool _isPasswordRevealed = false;

  FocusNode get _effectiveFocusNode =>
      widget.focusNode ?? (_internalFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _effectiveFocusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (_isFocused != _effectiveFocusNode.hasFocus) {
      setState(() => _isFocused = _effectiveFocusNode.hasFocus);
    }
  }

  @override
  void dispose() {
    _effectiveFocusNode.removeListener(_handleFocusChange);
    _internalFocusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    // Carbon border and fill resolution
    final Color borderColor;
    final double borderWidth;
    if (hasError) {
      borderColor = p.error;
      borderWidth = AppSizes.focusRing;
    } else if (_isFocused) {
      borderColor = p.link;
      borderWidth = AppSizes.focusRing;
    } else {
      borderColor = p.border;
      borderWidth = AppSizes.hairline;
    }

    final Color backgroundColor = widget.enabled ? p.field : p.surfaceMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Carbon Input Label
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            RichText(
              text: TextSpan(
                text: widget.label,
                style: context.appText.label.copyWith(
                  color: hasError
                      ? p.error
                      : (_isFocused ? p.link : p.textSecondary),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                children: [
                  if (widget.isRequired)
                    TextSpan(
                      text: ' *',
                      style: TextStyle(
                        color: p.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ),
            if (widget.helper != null && !hasError)
              Text(
                widget.helper!,
                style: context.appText.labelSmall.copyWith(
                  color: p.textPlaceholder,
                  fontSize: 11,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.spacing02),

        // 2. Interactive Input Box
        AnimatedContainer(
          duration: AppMotion.durationModerate01,
          curve: AppMotion.easeProductiveEntrance,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(AppRadius.field),
            border: Border.all(color: borderColor, width: borderWidth),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: p.link.withValues(alpha: 0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              if (widget.prefixIcon != null) ...[
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.spacing04),
                  child: widget.prefixIcon,
                ),
              ],
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _effectiveFocusNode,
                  enabled: widget.enabled,
                  obscureText: widget.obscure && !_isPasswordRevealed,
                  keyboardType: widget.keyboardType,
                  textInputAction: widget.textInputAction,
                  textCapitalization: widget.textCapitalization,
                  autofillHints: widget.autofillHints,
                  inputFormatters: widget.inputFormatters,
                  maxLength: widget.maxLength,
                  onSubmitted: widget.onSubmitted,
                  onChanged: widget.onChanged,
                  cursorColor: p.link,
                  cursorWidth: 2,
                  style: widget.mono
                      ? context.appText.mono.copyWith(
                          color: p.textPrimary,
                          fontSize: 15,
                          letterSpacing: 1.5,
                        )
                      : context.appText.body.copyWith(
                          color: p.textPrimary,
                          fontSize: 15,
                        ),
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    hintStyle: context.appText.bodySm.copyWith(
                      color: p.textPlaceholder.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    counterText: '',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: widget.prefixIcon != null
                          ? AppSpacing.spacing03
                          : AppSpacing.spacing05,
                      vertical: AppSpacing.spacing04 + 2,
                    ),
                  ),
                ),
              ),
              if (widget.obscure) ...[
                IconButton(
                  tooltip: _isPasswordRevealed
                      ? 'Hide password'
                      : 'Show password',
                  icon: AnimatedSwitcher(
                    duration: AppMotion.durationFast02,
                    child: Icon(
                      _isPasswordRevealed
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      key: ValueKey(_isPasswordRevealed),
                      size: 20,
                      color: _isFocused ? p.link : p.textSecondary,
                    ),
                  ),
                  onPressed: () => setState(
                    () => _isPasswordRevealed = !_isPasswordRevealed,
                  ),
                ),
              ] else if (widget.suffixIcon != null) ...[
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.spacing04),
                  child: widget.suffixIcon,
                ),
              ],
            ],
          ),
        ),

        // 3. Carbon Animated Inline Error
        AnimatedSize(
          duration: AppMotion.durationModerate01,
          curve: AppMotion.easeProductiveEntrance,
          child: hasError
              ? Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.spacing02),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.error_outline_rounded,
                          size: 14,
                          color: p.error,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.spacing02),
                      Expanded(
                        child: Text(
                          widget.errorText!,
                          style: context.appText.labelSmall.copyWith(
                            color: p.error,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
