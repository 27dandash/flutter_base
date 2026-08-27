import 'package:dio/dio.dart';

import '../../../config/language/languages.dart';

/// Attaches `Accept-Language` to every outbound request so the backend
/// returns localized strings (error messages, validation text, etc.).
///
/// Reads the current locale from Intl, which EasyLocalization updates when
/// the root locale changes. No BuildContext is retained by the network layer.
class LocaleInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Don't overwrite a header the caller explicitly set per-request.
    if (options.headers['Accept-Language'] == null) {
      try {
        options.headers['Accept-Language'] =
            Languages.currentLanguage.languageCode;
      } catch (_) {
        // Navigator/context not ready yet — leave the header off.
      }
    }
    handler.next(options);
  }
}
