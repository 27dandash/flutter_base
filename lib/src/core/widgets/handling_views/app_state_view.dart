import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

enum AppViewStatus {
  loading,
  content,
  empty,
  error,
  noInternet,
  permissionRequired,
}

/// One project-wide renderer for loading/content/empty/error boundary states.
/// All user-facing copy is injected so the widget never caches translations.
class AppStateView extends StatelessWidget {
  const AppStateView({
    super.key,
    required this.status,
    required this.content,
    required this.message,
    this.skeleton,
    this.actionLabel,
    this.onAction,
    this.compact = false,
    this.semanticLabel,
    this.title,
    this.visual,
  });

  const AppStateView.content({Key? key, required Widget content})
    : this(
        key: key,
        status: AppViewStatus.content,
        content: content,
        message: '',
      );

  const AppStateView.loading({
    Key? key,
    required String message,
    Widget? skeleton,
    bool compact = false,
    String? semanticLabel,
  }) : this(
         key: key,
         status: AppViewStatus.loading,
         content: const SizedBox.shrink(),
         message: message,
         skeleton: skeleton,
         compact: compact,
         semanticLabel: semanticLabel,
       );

  const AppStateView.empty({
    Key? key,
    required String message,
    String? title,
    Widget? visual,
    String? actionLabel,
    VoidCallback? onAction,
    bool compact = false,
    String? semanticLabel,
  }) : this(
         key: key,
         status: AppViewStatus.empty,
         content: const SizedBox.shrink(),
         message: message,
         title: title,
         visual: visual,
         actionLabel: actionLabel,
         onAction: onAction,
         compact: compact,
         semanticLabel: semanticLabel,
       );

  const AppStateView.error({
    Key? key,
    required String message,
    String? title,
    Widget? visual,
    String? actionLabel,
    VoidCallback? onAction,
    bool compact = false,
    String? semanticLabel,
  }) : this(
         key: key,
         status: AppViewStatus.error,
         content: const SizedBox.shrink(),
         message: message,
         title: title,
         visual: visual,
         actionLabel: actionLabel,
         onAction: onAction,
         compact: compact,
         semanticLabel: semanticLabel,
       );

  const AppStateView.offline({
    Key? key,
    required String message,
    String? title,
    String? actionLabel,
    VoidCallback? onAction,
    bool compact = false,
    String? semanticLabel,
  }) : this(
         key: key,
         status: AppViewStatus.noInternet,
         content: const SizedBox.shrink(),
         message: message,
         title: title,
         actionLabel: actionLabel,
         onAction: onAction,
         compact: compact,
         semanticLabel: semanticLabel,
       );

  const AppStateView.permissionRequired({
    Key? key,
    required String message,
    String? title,
    String? actionLabel,
    VoidCallback? onAction,
    bool compact = false,
    String? semanticLabel,
  }) : this(
         key: key,
         status: AppViewStatus.permissionRequired,
         content: const SizedBox.shrink(),
         message: message,
         title: title,
         actionLabel: actionLabel,
         onAction: onAction,
         compact: compact,
         semanticLabel: semanticLabel,
       );

  final AppViewStatus status;
  final Widget content;
  final Widget? skeleton;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;
  final String? semanticLabel;
  final String? title;
  final Widget? visual;

  @override
  Widget build(BuildContext context) {
    if (status == AppViewStatus.content) return content;
    if (status == AppViewStatus.loading) {
      final placeholder = skeleton;
      if (placeholder != null) {
        return Skeletonizer(enabled: true, child: placeholder);
      }
      return Semantics(
        liveRegion: true,
        label: semanticLabel ?? message,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final icon = switch (status) {
      AppViewStatus.empty => Icons.inbox_outlined,
      AppViewStatus.error => Icons.error_outline,
      AppViewStatus.noInternet => Icons.wifi_off_outlined,
      AppViewStatus.permissionRequired => Icons.lock_outline,
      _ => Icons.info_outline,
    };
    final body = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(child: visual ?? Icon(icon, size: compact ? 28 : 52)),
        const SizedBox(height: 8),
        if (title != null && title!.isNotEmpty) ...[
          ExcludeSemantics(
            child: Text(
              title!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 4),
        ],
        if (message.isNotEmpty)
          ExcludeSemantics(child: Text(message, textAlign: TextAlign.center)),
        if (onAction != null && actionLabel != null) ...[
          const SizedBox(height: 12),
          FilledButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ],
    );
    final accessible = Semantics(
      container: true,
      explicitChildNodes: true,
      liveRegion: status == AppViewStatus.error,
      label:
          semanticLabel ??
          [
            title,
            message,
          ].whereType<String>().where((v) => v.isNotEmpty).join('. '),
      child: body,
    );
    if (compact) return accessible;
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: accessible,
        ),
      ),
    );
  }
}
