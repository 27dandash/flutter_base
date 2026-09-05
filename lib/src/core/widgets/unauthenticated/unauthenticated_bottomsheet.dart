import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../config/language/locale_keys.g.dart';
import '../../../config/res/config_imports.dart';
import '../../shared/extensions/context_extension.dart';
import '../../shared/extensions/text_style_extensions.dart';
import '../../navigation/navigator.dart';
import '../../shared/cubits/user_cubit/user_cubit.dart';
import '../buttons/app_button.dart';
import 'show_modal_bottom_sheet.dart';

const String _routeName = 'UnAuthenticatedBottomSheet';

/// Duplicate-safe, context-owned presenter for the legacy session sheet.
class UnauthenticatedSheetPresenter {
  UnauthenticatedSheetPresenter();

  Future<void>? _pending;

  Future<void> show(BuildContext context, {required bool isBlocked}) async {
    if (!context.mounted) return;
    final pending = _pending;
    if (pending != null) return pending;

    final presentation = showAppModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      hasTopInductor: false,
      routeSettings: const RouteSettings(name: _routeName),
      child: UnAuthenticatedBottomSheet(isBlocked: isBlocked),
    ).whenComplete(() => _pending = null);
    _pending = presentation;
    return presentation;
  }
}

@Deprecated('Use UnauthenticatedSheetPresenter.show with a live BuildContext.')
class UnAuthenticatedBottomSheet extends StatelessWidget {
  const UnAuthenticatedBottomSheet({required this.isBlocked, super.key});

  final bool isBlocked;

  // Global state is retained only behind the deprecated compatibility API.
  // New code owns/injects an [UnauthenticatedSheetPresenter] at its UI
  // composition boundary, so unrelated navigators and tests never share it.
  static final UnauthenticatedSheetPresenter _legacyPresenter =
      UnauthenticatedSheetPresenter();

  @Deprecated(
    'Own an UnauthenticatedSheetPresenter and call show(context, ...) instead.',
  )
  static Future<void> show({required bool isBlocked}) {
    return _legacyPresenter.show(Go.context, isBlocked: isBlocked);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.login_rounded, size: 100.sp, color: AppColors.primary),
        const SizedBox(height: 16),
        Text(
          isBlocked ? LocaleKeys.blocked : LocaleKeys.appYourSessionIsExpired,
          textAlign: TextAlign.center,
          style: context.textStyle.s14.medium.setMainTextColor,
        ),
        const SizedBox(height: 32),
        AppButton(
          label: LocaleKeys.login,
          onPressed: () async {
            await injector<UserCubit>().logout();
            if (context.mounted) {
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          },
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
