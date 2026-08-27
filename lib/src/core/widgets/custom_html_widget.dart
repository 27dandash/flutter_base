import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

import '../../config/res/config_imports.dart';

class CustomHtmlWidget extends StatelessWidget {
  final String data;

  const CustomHtmlWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Html(
      data: data
          .replaceAll(r'\r\n', '\n')
          .replaceAll(r'\t', '')
          .replaceAll(r'\"', '"')
          .trim(),
      style: {
        "body": Style(
          fontSize: FontSize(FontSizeManager.s11),
          color: AppColors.main,
          fontFamily: ConstantManager.fontFamily,
          lineHeight: LineHeight.number(1.5),
        ),
        "h1": Style(
          fontSize: FontSize(FontSizeManager.s11),
          fontWeight: FontWeightManager.regular,
          color: AppColors.primary,
          margin: Margins.only(top: AppMargin.mH16, bottom: AppMargin.mH12),
        ),
        "h2": Style(
          fontSize: FontSize(FontSizeManager.s11),
          fontWeight: FontWeightManager.regular,
          color: AppColors.primary,
          margin: Margins.only(top: AppMargin.mH14, bottom: AppMargin.mH10),
        ),
        "h3": Style(
          fontSize: FontSize(FontSizeManager.s11),
          fontWeight: FontWeightManager.regular,
          color: AppColors.secondary,
          margin: Margins.only(top: AppMargin.mH12, bottom: AppMargin.mH8),
        ),
        "p": Style(
          fontSize: FontSize(FontSizeManager.s11),
          margin: Margins.only(bottom: AppMargin.mH12),
        ),
        "ul": Style(
          margin: Margins.only(left: AppMargin.mW16, bottom: AppMargin.mH12),
        ),
        "ol": Style(
          margin: Margins.only(left: AppMargin.mW16, bottom: AppMargin.mH12),
        ),
        "li": Style(margin: Margins.only(bottom: AppMargin.mH6)),
        "a": Style(
          color: AppColors.primary,
          textDecoration: TextDecoration.underline,
        ),
        "strong": Style(fontWeight: FontWeightManager.bold),
        "em": Style(fontStyle: FontStyle.italic),
        '*': Style(
          fontSize: FontSize(FontSizeManager.s11),
          color: AppColors.main,
          fontFamily: ConstantManager.fontFamily,
          lineHeight: LineHeight.number(1.5),
        ),
      },
    );
  }
}
