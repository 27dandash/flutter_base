// `Go.context` is the app's global Navigator context — always mounted
// while the app is alive, so the cross-await BuildContext warning never
// applies to this file.
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../navigation/navigator.dart';

/// Picks a date adaptively:
///   - Android → Material `showDatePicker` (calendar UI).
///   - iOS     → Cupertino `CupertinoDatePicker` inside a bottom sheet.
///
/// On success, writes the formatted string into [controller] and returns
/// the raw `DateTime` so callers can drive their own state too.
Future<DateTime?> showCustomDatePicker({
  required TextEditingController controller,
  String? dateFormat,
  DateTime? initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
}) async {
  final BuildContext context = Go.context;
  final DateTime now = DateTime.now();
  final DateTime first = firstDate ?? now;
  final DateTime last = lastDate ?? now.add(const Duration(days: 365 * 4));
  // showDatePicker asserts that the initial date lies inside the range; clamp
  // a caller-supplied value (for example a past date with the default
  // firstDate) instead of crashing in debug and misbehaving in release.
  final DateTime requested = initialDate ?? now;
  final DateTime initial = requested.isBefore(first)
      ? first
      : (requested.isAfter(last) ? last : requested);
  final locale = Localizations.localeOf(context);

  final DateTime? picked = defaultTargetPlatform == TargetPlatform.iOS
      ? await _showCupertino(
          context: context,
          initial: initial,
          first: first,
          last: last,
        )
      : await showDatePicker(
          context: context,
          locale: locale,
          initialDate: initial,
          firstDate: first,
          lastDate: last,
          initialEntryMode: DatePickerEntryMode.calendarOnly,
        );

  if (picked != null) {
    controller.text = DateFormat(
      dateFormat ?? 'EEE, M/d/y',
      locale.languageCode,
    ).format(picked);
  }
  return picked;
}

Future<DateTime?> _showCupertino({
  required BuildContext context,
  required DateTime initial,
  required DateTime first,
  required DateTime last,
}) async {
  DateTime temp = initial;
  return showModalBottomSheet<DateTime>(
    context: context,
    backgroundColor: Theme.of(context).bottomSheetTheme.modalBackgroundColor,
    showDragHandle: true,
    builder: (sheetCtx) => SafeArea(
      child: SizedBox(
        height: 280,
        child: Column(
          children: [
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: initial,
                minimumDate: first,
                maximumDate: last,
                onDateTimeChanged: (d) => temp = d,
              ),
            ),
            CupertinoButton(
              onPressed: () => Navigator.of(sheetCtx).pop(temp),
              child: Text(MaterialLocalizations.of(sheetCtx).okButtonLabel),
            ),
          ],
        ),
      ),
    ),
  );
}
