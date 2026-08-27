import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../config/res/assets.gen.dart';
import '../../../config/res/config_imports.dart';
import '../../shared/extensions/context_extension.dart';
import '../../shared/extensions/text_style_extensions.dart';
import '../pickers/custom_dialog.dart';

Future<dynamic> successDialog({
  required BuildContext context,
  required String title,
  String? desc,
  bool activeTimer = true,
}) {
  return showCustomDialog(
    context,
    barrierDismissible: false,
    child: SuccessDialogBody(
      title: title,
      desc: desc,
      activeTimer: activeTimer,
    ),
    margin: EdgeInsets.all(AppMargin.mH40),
  );
}

class SuccessDialogBody extends StatefulWidget {
  final String title;
  final bool activeTimer;
  final String? desc;

  const SuccessDialogBody({
    super.key,
    required this.title,
    required this.desc,
    required this.activeTimer,
  });

  @override
  State<SuccessDialogBody> createState() => SuccessDialogBodyState();
}

class SuccessDialogBodyState extends State<SuccessDialogBody> {
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    if (widget.activeTimer) {
      _dismissTimer = Timer(const Duration(seconds: 2), () {
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });
    }
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: AppMargin.mH10,
      children: [
        Center(
          child: AppAssets.lottie.successfullOrder.lottie(
            width: context.width * .3,
            fit: BoxFit.contain,
          ),
        ),
        Text(
          widget.title,
          textAlign: TextAlign.center,
          style: const TextStyle().setMainTextColor.s13.regular,
        ),

        if (widget.desc != null) ...[
          Text(
            widget.desc ?? '',
            textAlign: TextAlign.center,
            style: const TextStyle().setSecondryColor.s12.regular,
          ),
        ],
      ],
    );
  }
}
