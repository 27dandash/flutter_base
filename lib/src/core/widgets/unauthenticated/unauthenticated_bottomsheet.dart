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

const String _routeName = "UnAuthenticatedBottomSheet";

class UnAuthenticatedBottomSheet extends StatelessWidget {
  const UnAuthenticatedBottomSheet._();

  static bool isOpend = false;
  static bool _isBlocked = false;

  static Future<void> show({required bool isBlocked}) async {
    final context = Go.context;
    if (isOpend) return;

    _isBlocked = isBlocked;
    isOpend = true;

    await showAppModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      hasTopInductor: false,
      routeSettings: const RouteSettings(name: _routeName),
      child: const UnAuthenticatedBottomSheet._(),
    ).whenComplete(() {
      isOpend = false;
      _isBlocked = false;
    });
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
          _isBlocked ? LocaleKeys.blocked : LocaleKeys.appYourSessionIsExpired,
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
            // Go.offAll(const LoginScreen());
          },
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
