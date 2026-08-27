import 'dart:io';

enum AppImagePickSource { camera, gallery }

sealed class AppImagePickResult {
  const AppImagePickResult();
}

final class AppImagePickSuccess extends AppImagePickResult {
  const AppImagePickSuccess(this.files);

  final List<File> files;
}

final class AppImagePickCancelled extends AppImagePickResult {
  const AppImagePickCancelled();
}

final class AppImagePickPermissionDenied extends AppImagePickResult {
  const AppImagePickPermissionDenied();
}

final class AppImagePickTooLarge extends AppImagePickResult {
  const AppImagePickTooLarge();
}

final class AppImagePickFailure extends AppImagePickResult {
  const AppImagePickFailure();
}
