import 'dart:async';

import 'package:material_ui/material_ui.dart';

enum AppButtonVariant { primary, secondary, destructive, text }

/// Accessible production button with consistent variants and built-in
/// duplicate-submission protection for asynchronous actions.
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.leading,
    this.fullWidth = true,
    this.loadingLabel,
    this.isLoading = false,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
  });

  final String label;
  final FutureOr<void> Function()? onPressed;
  final AppButtonVariant variant;
  final Widget? leading;
  final bool fullWidth;
  final String? loadingLabel;
  final bool isLoading;
  final String? semanticLabel;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  /// True while [AppButton.onPressed] is running; guards against double taps
  /// without rebuilding anything but the button itself.
  final ValueNotifier<bool> _submitting = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _submitting.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting.value || widget.onPressed == null) return;
    _submitting.value = true;
    try {
      await widget.onPressed!();
    } finally {
      if (mounted) _submitting.value = false;
    }
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: _submitting,
    builder: (context, submitting, _) => _buildButton(context, submitting),
  );

  Widget _buildButton(BuildContext context, bool submitting) {
    final loading = widget.isLoading || submitting;
    final action = widget.onPressed == null || loading ? null : _submit;
    final foreground = widget.variant == AppButtonVariant.destructive
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;
    final content = loading
        ? Row(
            key: const ValueKey('app-button-loading'),
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              if (widget.loadingLabel != null) ...[
                const SizedBox(width: 8),
                Text(widget.loadingLabel!),
              ],
            ],
          )
        : Row(
            key: const ValueKey('app-button-label'),
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.leading != null) ...[
                widget.leading!,
                const SizedBox(width: 8),
              ],
              Flexible(child: Text(widget.label)),
            ],
          );

    // Label <-> spinner cross-fades and the button resizes smoothly.
    final child = AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: content,
      ),
    );

    final button = switch (widget.variant) {
      AppButtonVariant.primary => FilledButton(
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        onPressed: action,
        child: child,
      ),
      AppButtonVariant.secondary => OutlinedButton(
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        onPressed: action,
        child: child,
      ),
      AppButtonVariant.destructive => OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: foreground,
          side: BorderSide(color: foreground),
        ),
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        onPressed: action,
        child: child,
      ),
      AppButtonVariant.text => TextButton(
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        onPressed: action,
        child: child,
      ),
    };

    return Semantics(
      button: true,
      enabled: action != null,
      label: loading
          ? widget.loadingLabel ?? widget.semanticLabel ?? widget.label
          : widget.semanticLabel ?? widget.label,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
        child: widget.fullWidth
            ? SizedBox(width: double.infinity, child: button)
            : button,
      ),
    );
  }
}
