import 'package:flutter/cupertino.dart';

import 'auto_scrolll_validation_extention.dart';

mixin FormMixin {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  /// Returns `true` when form is valid.
  bool validate() => formKey.currentState?.validate() ?? false;

  /// Validates and auto-scrolls to the first invalid field.
  bool validateAndScroll() => formKey.validateAndScroll();

  void clearValidate() => formKey.currentState?.reset();
}
