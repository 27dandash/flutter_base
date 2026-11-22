import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// Digit-by-digit one-time-code input.
///
/// - One real [TextField] (so paste, autofill and the keyboard work) drawn as
///   [length] boxes; always LTR so the digits never flip in Arabic.
/// - Arabic-Indic / Persian digits are converted to English digits.
/// - [onCompleted] fires once when all digits are entered.
class AppOtpField extends StatefulWidget {
  const AppOtpField({
    required this.onCompleted,
    this.length = 4,
    this.onChanged,
    this.enabled = true,
    this.hasError = false,
    this.autofocus = true,
    this.semanticLabel,
    super.key,
  }) : assert(length > 0);

  final int length;
  final ValueChanged<String> onCompleted;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final bool hasError;
  final bool autofocus;
  final String? semanticLabel;

  /// Converts Arabic-Indic and Persian digits to ASCII digits.
  static String toEnglishDigits(String input) {
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    final out = StringBuffer();
    for (final rune in input.runes) {
      final ch = String.fromCharCode(rune);
      final a = arabic.indexOf(ch);
      final p = persian.indexOf(ch);
      out.write(a >= 0 ? '$a' : (p >= 0 ? '$p' : ch));
    }
    return out.toString();
  }

  @override
  State<AppOtpField> createState() => _AppOtpFieldState();
}

class _AppOtpFieldState extends State<AppOtpField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();
  final ValueNotifier<String> _code = ValueNotifier<String>('');
  bool _completedFired = false;

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    _code.dispose();
    super.dispose();
  }

  void _onChanged(String raw) {
    final digits = AppOtpField.toEnglishDigits(raw)
        .replaceAll(RegExp(r'\D'), '');
    final value = digits.length > widget.length
        ? digits.substring(0, widget.length)
        : digits;
    if (value != raw) {
      _controller.value = TextEditingValue(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
    }
    _code.value = value;
    widget.onChanged?.call(value);
    if (value.length == widget.length) {
      if (!_completedFired) {
        _completedFired = true;
        widget.onCompleted(value);
      }
    } else {
      _completedFired = false;
    }
  }

  /// Clears the field (for example after a wrong code).
  void clear() {
    _controller.clear();
    _code.value = '';
    _completedFired = false;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      textField: true,
      label: widget.semanticLabel,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.enabled ? _focus.requestFocus : null,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // The real input: invisible, but focusable and paste-able.
              Positioned.fill(
                child: Opacity(
                  opacity: 0,
                  child: TextField(
                    controller: _controller,
                    focusNode: _focus,
                    autofocus: widget.autofocus,
                    enabled: widget.enabled,
                    keyboardType: TextInputType.number,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩۰-۹]')),
                    ],
                    onChanged: _onChanged,
                    showCursor: false,
                    enableInteractiveSelection: false,
                  ),
                ),
              ),
              ValueListenableBuilder<String>(
                valueListenable: _code,
                builder: (context, code, _) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < widget.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      _OtpBox(
                        char: i < code.length ? code[i] : '',
                        active: widget.enabled && i == code.length,
                        hasError: widget.hasError,
                        colors: colors,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.char,
    required this.active,
    required this.hasError,
    required this.colors,
  });

  final String char;
  final bool active;
  final bool hasError;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final border = hasError
        ? colors.error
        : (active ? colors.primary : colors.outlineVariant);
    return Container(
      width: 52,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: active || hasError ? 2 : 1),
      ),
      child: Text(char, style: Theme.of(context).textTheme.titleLarge),
    );
  }
}
