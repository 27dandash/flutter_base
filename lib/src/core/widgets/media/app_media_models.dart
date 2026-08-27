import 'package:flutter/widgets.dart';

enum AppMediaKind { image, svg, video }

enum AppMediaSource { asset, file, network }

enum AppMediaOpenBehavior { none, fullscreen }

@immutable
class AppMediaRequest {
  const AppMediaRequest({
    required this.path,
    required this.kind,
    required this.source,
  });

  final String path;
  final AppMediaKind kind;
  final AppMediaSource source;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppMediaRequest &&
          path == other.path &&
          kind == other.kind &&
          source == other.source;

  @override
  int get hashCode => Object.hash(path, kind, source);

  static AppMediaRequest detect(String path) {
    final uri = Uri.tryParse(path);
    final cleanPath = uri?.path.isNotEmpty == true ? uri!.path : path;
    final extension = cleanPath.split('.').last.toLowerCase();
    final kind = switch (extension) {
      'svg' => AppMediaKind.svg,
      'mp4' || 'mov' || 'm4v' || 'webm' => AppMediaKind.video,
      _ => AppMediaKind.image,
    };
    final source =
        uri != null && (uri.scheme == 'http' || uri.scheme == 'https')
        ? AppMediaSource.network
        : AppMediaSource.asset;
    return AppMediaRequest(path: path, kind: kind, source: source);
  }
}
