import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../config/language/locale_keys.g.dart';
import '../../../../config/res/config_imports.dart';
import '../../../shared/extensions/text_style_extensions.dart';

/// Project-wide text input widget.
///
/// Wraps a `TextFormField` with the visual defaults the design system
/// expects (rounded border, hint/error typography, password toggle, …).
/// Every styling primitive (color, radius, spacing) comes from the
/// design tokens in `config/res/` — no inline hex colors or magic
/// numbers — so a token change ripples to every field in the app.
///
/// Example
///   ```dart
///   DefaultTextField(
///     title: LocaleKeys.email,
///     controller: _email,
///     inputType: TextInputType.emailAddress,
///     validator: Validators.validateEmail,
///   )
///   ```
class DefaultTextField extends StatefulWidget {
  // ── Content ────────────────────────────────────────────────────
  final String? title;
  final String? label;
  final String? suffixText;
  final TextEditingController? controller;
  final String? initialValue;
  final FormFieldValidator<String?>? validator;
  final FormFieldSetter<String>? onSaved;
  final List<TextInputFormatter>? inputFormatters;
  final String? errorText;

  // ── Decoration ─────────────────────────────────────────────────
  final Color? fillColor;
  final Color? borderColor;
  final bool? hasBorderColor;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? contentPadding;
  final TextStyle? style;
  final Widget? prefixIcon;
  final Widget? prefixWidget;
  final Widget? suffixIcon;
  final bool filled;

  // ── Behaviour ──────────────────────────────────────────────────
  final TextInputType inputType;
  final TextInputAction action;
  final TextAlign? textAlign;
  final int? maxLength;
  final int? maxLines;
  final int? minLines;
  final bool secure;
  final bool? isPassword;
  final bool enabled;
  final bool readOnly;
  final bool autoFocus;
  final bool closeWhenTapOutSide;
  final FocusNode? focusNode;
  final Iterable<String>? autofillHints;
  final TextCapitalization textCapitalization;
  final String? showPasswordSemanticsLabel;
  final String? hidePasswordSemanticsLabel;
  final String? semanticLabel;
  final AutovalidateMode? autovalidateMode;
  final bool autocorrect;
  final bool enableSuggestions;
  final EdgeInsets scrollPadding;

  // ── Callbacks ──────────────────────────────────────────────────
  final ValueChanged<String?>? onChanged;
  final ValueChanged<String?>? onSubmitted;
  final VoidCallback? onEditingComplete;
  final GestureTapCallback? onTap;

  const DefaultTextField({
    super.key,
    this.title,
    this.label,
    this.suffixText,
    this.controller,
    this.initialValue,
    this.validator,
    this.onSaved,
    this.inputFormatters,
    this.errorText,
    // Decoration
    this.fillColor,
    this.borderColor,
    this.hasBorderColor = true,
    this.borderRadius,
    this.contentPadding,
    this.style,
    this.prefixIcon,
    this.prefixWidget,
    this.suffixIcon,
    this.filled = true,
    // Behaviour
    this.inputType = TextInputType.text,
    this.action = TextInputAction.next,
    this.textAlign = TextAlign.start,
    this.maxLength,
    this.maxLines,
    this.minLines,
    this.secure = false,
    this.isPassword = false,
    this.enabled = true,
    this.readOnly = false,
    this.autoFocus = false,
    this.closeWhenTapOutSide = true,
    this.focusNode,
    this.autofillHints,
    this.textCapitalization = TextCapitalization.none,
    this.showPasswordSemanticsLabel,
    this.hidePasswordSemanticsLabel,
    this.semanticLabel,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.scrollPadding = const EdgeInsets.all(20),
    // Callbacks
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.onTap,
  }) : assert(
         controller == null || initialValue == null,
         'controller and initialValue cannot both be provided',
       );

  @override
  State<DefaultTextField> createState() => _DefaultTextFieldState();
}

class _DefaultTextFieldState extends State<DefaultTextField> {
  /// Visual config — kept private so callers don't accidentally tweak the
  /// design system from a single field.
  static const int _multilineDefaultMaxLines = 7;
  static const String _obscuringCharacter = '*';

  late bool _isObscured;

  @override
  void initState() {
    super.initState();
    _isObscured = widget.isPassword == true;
  }

  @override
  void didUpdateWidget(covariant DefaultTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isPassword != widget.isPassword &&
        widget.isPassword == true) {
      _isObscured = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasLabel = widget.label != null;
    final obscured = widget.isPassword == true || widget.secure;
    final resolvedMaxLines = obscured
        ? 1
        : widget.maxLines ??
              (widget.inputType == TextInputType.multiline
                  ? _multilineDefaultMaxLines
                  : 1);
    final resolvedMinLines = obscured
        ? 1
        : widget.minLines ??
              (widget.inputType == TextInputType.multiline ? null : 1);

    final field = TextFormField(
      controller: widget.controller,
      initialValue: widget.initialValue,
      focusNode: widget.focusNode,
      keyboardType: widget.inputType,
      textCapitalization: widget.textCapitalization,
      textInputAction: widget.action,
      textAlign: widget.textAlign!,
      autofocus: widget.autoFocus,
      enabled: widget.enabled,
      readOnly: widget.onTap != null ? true : widget.readOnly,
      obscureText: widget.isPassword == true ? _isObscured : widget.secure,
      obscuringCharacter: _obscuringCharacter,
      style: widget.style,
      cursorColor: Theme.of(context).colorScheme.primary,
      maxLength: widget.maxLength,
      maxLines: resolvedMaxLines,
      minLines: resolvedMinLines,
      // Never learn or suggest from a secret.
      autocorrect: obscured ? false : widget.autocorrect,
      enableSuggestions: obscured ? false : widget.enableSuggestions,
      autovalidateMode: widget.autovalidateMode,
      scrollPadding: widget.scrollPadding,
      autofillHints:
          widget.autofillHints ?? _autofillHintsFor(widget, obscured),
      inputFormatters: widget.inputFormatters,
      validator: widget.validator,
      onSaved: widget.onSaved,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      onEditingComplete: widget.onEditingComplete,
      onTap: widget.onTap,
      onTapOutside: (_) {
        if (widget.closeWhenTapOutSide) {
          FocusScope.of(context).unfocus();
        }
      },
      decoration: _decoration(context, hasLabel: hasLabel),
    );
    final semanticsLabel = widget.semanticLabel;
    return semanticsLabel == null
        ? field
        : Semantics(label: semanticsLabel, textField: true, child: field);
  }

  InputDecoration _decoration(BuildContext context, {required bool hasLabel}) {
    final colors = Theme.of(context).colorScheme;
    final border =
        widget.borderRadius ?? BorderRadius.circular(AppCircular.r10);

    OutlineInputBorder outline(Color color) => OutlineInputBorder(
      borderRadius: border,
      borderSide: BorderSide(color: color),
    );

    return InputDecoration(
      isDense: true,
      errorMaxLines: 2,
      counterText: ConstantManager.emptyText,
      filled: widget.filled,
      fillColor: widget.fillColor ?? colors.surfaceContainerLowest,
      contentPadding: widget.contentPadding,
      // Content
      hintText: widget.title,
      label: hasLabel ? Text(widget.label!) : null,
      suffixText: widget.suffixText,
      errorText: widget.errorText,
      prefix: widget.prefixWidget,
      prefixIcon: widget.prefixIcon,
      suffixIcon: widget.suffixIcon ?? _passwordToggle(),
      // Typography
      hintStyle: const TextStyle().setHintColor.s13.regular,
      labelStyle: hasLabel
          ? const TextStyle().setSecondryColor.s12.medium
          : null,
      errorStyle: const TextStyle().setErrorColor.s12.regular,
      // Borders
      enabledBorder: widget.hasBorderColor == true
          ? outline(widget.borderColor ?? colors.outlineVariant)
          : OutlineInputBorder(
              borderRadius: border,
              borderSide: BorderSide.none,
            ),
      focusedBorder: outline(colors.primary),
      errorBorder: outline(colors.error),
      focusedErrorBorder: outline(colors.error),
    );
  }

  Widget? _passwordToggle() {
    if (widget.isPassword != true) return null;
    final label = _isObscured
        ? widget.showPasswordSemanticsLabel ?? LocaleKeys.showPassword
        : widget.hidePasswordSemanticsLabel ?? LocaleKeys.hidePassword;
    return IconButton(
      tooltip: label,
      onPressed: widget.enabled
          ? () => setState(() => _isObscured = !_isObscured)
          : null,
      icon: Icon(
        _isObscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        semanticLabel: label,
      ),
    );
  }
}

/// Autofill suggestions for a field that did not pass explicit
/// [DefaultTextField.autofillHints].
///
/// Only unambiguous types get a hint. The previous default offered
/// `name`/`username` for *every* other field, including passwords, amounts and
/// free text, which makes password managers fill the wrong value and surfaces
/// contact suggestions on unrelated inputs. Pass `autofillHints` for the login
/// username, the one-time code and similar fields.
Iterable<String>? _autofillHintsFor(DefaultTextField field, bool obscured) {
  if (obscured) return const [AutofillHints.password];
  final type = field.inputType;
  if (type == TextInputType.emailAddress) return const [AutofillHints.email];
  if (type == TextInputType.phone) {
    return const [AutofillHints.telephoneNumber];
  }
  if (type == TextInputType.url) return const [AutofillHints.url];
  return null;
}
