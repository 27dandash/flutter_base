import 'app_image_picker_models.dart';

abstract interface class AppImagePickerService {
  Future<AppImagePickResult> pick({
    required AppImagePickSource source,
    required bool multiple,
    required bool crop,
    int? maxBytes,
  });

  Future<AppImagePickResult> recoverLost({int? maxBytes});
}
