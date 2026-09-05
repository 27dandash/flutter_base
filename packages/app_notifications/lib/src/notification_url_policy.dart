import 'package:flutter/foundation.dart';

/// Injectable policy for validating notification `open_url` actions.
///
/// By default only well-formed HTTPS URLs are accepted. Products may tighten
/// host restrictions or explicitly approve additional schemes.
@immutable
final class NotificationUrlPolicy {
  const NotificationUrlPolicy({
    this.allowedHttpsHosts = const {},
    this.approvedExtraSchemes = const {},
  });

  /// Accepts HTTPS URLs. When [allowedHttpsHosts] is non-empty, only matching
  /// hosts (or their subdomains) are accepted.
  static const secureDefault = NotificationUrlPolicy();

  final Set<String> allowedHttpsHosts;
  final Set<String> approvedExtraSchemes;

  /// Returns a validated [Uri] or `null` when the URL must be rejected.
  Uri? parseAllowedUrl(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;

    final uri = Uri.tryParse(raw.trim());
    if (uri == null || !uri.hasScheme || uri.userInfo.isNotEmpty) return null;

    final scheme = uri.scheme.toLowerCase();
    if (scheme == 'https') {
      if (!uri.hasAuthority || uri.host.trim().isEmpty) return null;
      if (allowedHttpsHosts.isEmpty) return uri;
      return _isHostAllowed(uri.host) ? uri : null;
    }
    final schemeApproved = approvedExtraSchemes.any(
      (candidate) => candidate.trim().toLowerCase() == scheme,
    );
    if (schemeApproved &&
        (uri.host.trim().isNotEmpty || uri.path.trim().isNotEmpty)) {
      return uri;
    }
    return null;
  }

  bool _isHostAllowed(String host) {
    final normalized = host.toLowerCase();
    return allowedHttpsHosts.any((allowed) {
      final candidate = allowed.toLowerCase().trim();
      if (candidate.isEmpty) return false;
      return normalized == candidate || normalized.endsWith('.$candidate');
    });
  }

  @override
  bool operator ==(Object other) =>
      other is NotificationUrlPolicy &&
      setEquals(allowedHttpsHosts, other.allowedHttpsHosts) &&
      setEquals(approvedExtraSchemes, other.approvedExtraSchemes);

  @override
  int get hashCode => Object.hash(
    Object.hashAllUnordered(allowedHttpsHosts),
    Object.hashAllUnordered(approvedExtraSchemes),
  );
}
