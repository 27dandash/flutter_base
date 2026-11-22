import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../../config/language/locale_keys.g.dart';
import '../custom_messages.dart';
import '../../shared/extensions/base_state.dart';

/// "Didn't receive the code?  Resend" with a countdown.
///
/// - The countdown starts at [seconds] (59 by default) as soon as the row is
///   shown, and again after every successful resend.
/// - "Resend" is tappable only when the countdown reached zero; while the
///   resend request runs it is locked, so it can never fire twice.
/// - A successful resend shows a success snackbar; a failure keeps the link
///   enabled so the user can retry (the caller reports the error).
class OtpResendRow extends StatefulWidget {
  const OtpResendRow({
    required this.onResend,
    this.seconds = 59,
    this.successMessage,
    super.key,
  }) : assert(seconds > 0);

  /// Sends a new code. Throw (or return false) to signal failure.
  final Future<bool> Function() onResend;
  final int seconds;
  final String? successMessage;

  @override
  State<OtpResendRow> createState() => _OtpResendRowState();
}

class _OtpResendRowState extends State<OtpResendRow> {
  late final ValueNotifier<int> _remaining;
  bool _sending = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remaining = ValueNotifier<int>(widget.seconds);
    _start();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _remaining.dispose();
    super.dispose();
  }

  void _start() {
    _timer?.cancel();
    _remaining.value = widget.seconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remaining.value <= 1) {
        _remaining.value = 0;
        timer.cancel();
      } else {
        _remaining.value--;
      }
    });
  }

  Future<void> _resend() async {
    if (_sending || _remaining.value > 0) return;
    _sending = true;
    var ok = false;
    try {
      ok = await widget.onResend();
    } catch (_) {
      ok = false;
    } finally {
      _sending = false;
    }
    if (!mounted || !ok) return;
    _start();
    MessageUtils.showSnackBar(
      context: context,
      baseStatus: BaseStatus.success,
      message: widget.successMessage ?? LocaleKeys.otpResent,
    );
  }

  static String _format(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ValueListenableBuilder<int>(
      valueListenable: _remaining,
      builder: (context, remaining, _) {
        final waiting = remaining > 0;
        return Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          children: [
            Text(LocaleKeys.otpDidntReceive, style: theme.textTheme.bodyMedium),
            if (waiting)
              Text(
                LocaleKeys.otpResendIn.replaceFirst('{}', _format(remaining)),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              TextButton(onPressed: _resend, child: Text(LocaleKeys.otpResend)),
          ],
        );
      },
    );
  }
}
