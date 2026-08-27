import 'dart:async';

import 'package:flutter/material.dart';

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
  bool _submitting = false;

  Future<void> _submit() async {
    if (_submitting || widget.onPressed == null) return;
    setState(() => _submitting = true);
    try {
      await widget.onPressed!();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = widget.isLoading || _submitting;
    final action = widget.onPressed == null || loading ? null : _submit;
    final foreground = widget.variant == AppButtonVariant.destructive
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;
    final child = loading
        ? Row(
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
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.leading != null) ...[
                widget.leading!,
                const SizedBox(width: 8),
              ],
              Flexible(child: Text(widget.label)),
            ],
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
