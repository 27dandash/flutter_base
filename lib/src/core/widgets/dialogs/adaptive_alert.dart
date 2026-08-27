import 'package:flutter/material.dart';

/// Platform-adaptive alert dialog.
///
/// Uses `AlertDialog.adaptive` so the same call renders as a Material
/// dialog on Android and a Cupertino dialog on iOS — no manual
/// `Platform.isIOS` checks scattered across feature code.
///
/// Returns the action key the user picked (or `null` if dismissed via
/// barrier tap on Material).
///
/// Example
///   ```dart
///   final picked = await showAdaptiveAlert(
///     context: context,
///     title: 'Delete order?',
///     content: const Text('This cannot be undone.'),
///     actions: [
///       AdaptiveAction(key: 'cancel', label: 'Cancel'),
///       AdaptiveAction(key: 'delete', label: 'Delete', destructive: true),
///     ],
///   );
///   if (picked == 'delete') { ... }
///   ```
Future<String?> showAdaptiveAlert({
  required BuildContext context,
  required String title,
  Widget? content,
  required List<AdaptiveAction> actions,
  bool barrierDismissible = true,
}) {
  return showAdaptiveDialog<String>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (ctx) => AlertDialog.adaptive(
      title: Text(title),
      content: content,
      actions: actions
          .map((a) => _AdaptiveActionButton(action: a))
          .toList(growable: false),
    ),
  );
}

/// One button in [showAdaptiveAlert].
///   - [key] is what `showAdaptiveAlert` returns from `Navigator.pop`.
///   - [destructive] / [isDefault] map to the matching `CupertinoDialogAction`
///     flags on iOS and to colour/weight hints on Material.
class AdaptiveAction {
  final String key;
  final String label;
  final bool destructive;
  final bool isDefault;

  const AdaptiveAction({
    required this.key,
    required this.label,
    this.destructive = false,
    this.isDefault = false,
  });
}

class _AdaptiveActionButton extends StatelessWidget {
  const _AdaptiveActionButton({required this.action});

  final AdaptiveAction action;

  @override
  Widget build(BuildContext context) {
    // `adaptive` constructors live on `TextButton` — they render as
    // CupertinoDialogAction on iOS automatically.
    final child = Text(
      action.label,
      style: TextStyle(
        color: action.destructive ? Theme.of(context).colorScheme.error : null,
        fontWeight: action.isDefault ? FontWeight.w600 : null,
      ),
    );

    return TextButton(
      onPressed: () => Navigator.of(context).pop(action.key),
      child: child,
    );
  }
}
