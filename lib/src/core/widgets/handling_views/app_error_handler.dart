import 'package:flutter/material.dart';

import '../../../config/language/locale_keys.g.dart';
import '../../network/error/failures.dart';

class AppErrorHandler extends StatelessWidget {
  const AppErrorHandler({
    super.key,
    required this.failure,
    this.onRetry,
    this.compact = false,
  });

  final Failure failure;
  final VoidCallback? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (failure is CancelledFailure) return const SizedBox.shrink();

    final icon = _iconFor(failure);
    final message = failure.userMessage;
    final showRetry = failure.retryable && onRetry != null;

    if (compact) {
      return Semantics(
        container: true,
        liveRegion: true,
        label: message,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: Colors.redAccent),
            const SizedBox(width: 8),
            Flexible(child: Text(message)),
            if (showRetry) ...[
              const SizedBox(width: 8),
              TextButton(onPressed: onRetry, child: Text(LocaleKeys.retry)),
            ],
          ],
        ),
      );
    }

    return Semantics(
      container: true,
      liveRegion: true,
      label: message,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (showRetry) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: Text(LocaleKeys.retry)),
            ],
          ],
        ),
      ),
    );
  }

  static IconData _iconFor(Failure f) => switch (f) {
    NetworkFailure() => Icons.wifi_off_rounded,
    TimeoutFailure() => Icons.timer_off_outlined,
    UnauthorizedFailure() => Icons.lock_outline,
    PermissionFailure() => Icons.block_outlined,
    NotFoundFailure() => Icons.search_off_rounded,
    MaintenanceFailure() => Icons.construction_rounded,
    RateLimitFailure() => Icons.speed_outlined,
    PayloadTooLargeFailure() => Icons.attach_file_outlined,
    ValidationFailure() => Icons.rule_outlined,
    BadCertificateFailure() => Icons.gpp_bad_outlined,
    ParseFailure() ||
    UnknownFailure() ||
    ServerFailure() => Icons.error_outline_rounded,
    ConflictFailure() => Icons.merge_type_outlined,
    NeedActiveFailure() => Icons.mark_email_unread_outlined,
    BlockedFailure() => Icons.no_accounts_outlined,
    CancelledFailure() => Icons.close_rounded,
  };
}
