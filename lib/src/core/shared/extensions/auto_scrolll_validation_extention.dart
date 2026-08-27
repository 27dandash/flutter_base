import 'package:flutter/material.dart';

extension FormAutoScroll on GlobalKey<FormState> {
  bool validateAndScroll() {
    final bool isValid = currentState?.validate() ?? false;

    if (!isValid) {
      Element? firstErrorElement;

      void findFirstError(Element element) {
        if (firstErrorElement != null) return;

        if (element.widget is FormField) {
          final state = (element as StatefulElement).state;
          if (state is FormFieldState && state.hasError) {
            firstErrorElement = element;
            return;
          }
        }

        element.visitChildren(findFirstError);
      }

      currentContext?.visitChildElements(findFirstError);
      if (firstErrorElement != null) {
        Scrollable.ensureVisible(
          firstErrorElement!,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
          alignment: 0.1,
        );
      }
    }
    return isValid;
  }
}
