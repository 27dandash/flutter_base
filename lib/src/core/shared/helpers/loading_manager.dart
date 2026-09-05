import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../config/language/locale_keys.g.dart';

/// Instance-owned controller for a blocking overlay.
///
/// Create it in the owning State/DI scope and dispose it with that scope. This
/// intentionally replaces the old process-global notifier, which leaked state
/// across account switches and tests.
class BlockingOverlayController extends ValueNotifier<bool> {
  BlockingOverlayController() : super(false);

  void show() => value = true;
  void hide() => value = false;
}

class FullScreenLoadingManager extends StatelessWidget {
  final Widget child;
  final BlockingOverlayController controller;
  final String? loadingLabel;

  /// When `false` (default), system Back cannot dismiss routes while loading.
  final bool allowBackWhileLoading;

  const FullScreenLoadingManager({
    super.key,
    required this.child,
    required this.controller,
    this.loadingLabel,
    this.allowBackWhileLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: controller,
      builder: (context, isLoading, _) {
        return PopScope(
          canPop: !isLoading || allowBackWhileLoading,
          child: Stack(
            alignment: AlignmentDirectional.center,
            children: [
              child,
              if (isLoading)
                Semantics(
                  container: true,
                  liveRegion: true,
                  label: loadingLabel ?? LocaleKeys.loading,
                  child: ModalBarrier(
                    dismissible: false,
                    color: Colors.grey.withValues(alpha: 0.3),
                  ),
                ),
              if (isLoading)
                const Center(child: CupertinoActivityIndicator(radius: 15)),
            ],
          ),
        );
      },
    );
  }
}
