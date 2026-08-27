import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../../../config/language/locale_keys.g.dart';
import '../../../config/res/config_imports.dart';
import '../../navigation/navigator.dart';

enum _MediaChoice { file, image }

/// Safe facade around image_picker, image_cropper, and file_picker.
///
/// Android gallery selection intentionally uses image_picker's system Photo
/// Picker path and therefore needs no broad storage permission. Camera access
/// is requested only by the native plugin when [ImageSource.camera] is used.
class ImageHelper {
  ImageHelper._();

  static final ImagePicker _picker = ImagePicker();
  static final ImageCropper _cropper = ImageCropper();
  static bool _operationInFlight = false;

  static const Set<String> _imageExtensions = {
    'jpg',
    'jpeg',
    'png',
    'gif',
    'bmp',
    'webp',
    'heic',
  };

  static Future<File?> getImage({int? maxBytes}) =>
      _pickImage(source: ImageSource.gallery, maxBytes: maxBytes);

  static Future<List<File>> getImages({int? maxBytes}) =>
      _pickMultiple(maxBytes: maxBytes);

  static Future<File?> getImageFromCameraOrDevice({
    BuildContext? context,
    int? maxBytes,
  }) async {
    final modalContext = context ?? Go.navigatorKey.currentContext;
    if (modalContext == null || _operationInFlight) return null;

    final source = await showModalBottomSheet<ImageSource>(
      context: modalContext,
      useSafeArea: true,
      builder: (sheetContext) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(LocaleKeys.photoLibrary),
            onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
          ),
          if (_picker.supportsImageSource(ImageSource.camera))
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(LocaleKeys.camera),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
        ],
      ),
    );
    if (source == null) return null;
    return _pickImage(source: source, maxBytes: maxBytes);
  }

  static Future<File?> getMedia({int? maxBytes}) {
    return _exclusive<File>(() async {
      final result = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const [
          'pdf',
          'jpg',
          'jpeg',
          'png',
          'gif',
          'bmp',
          'webp',
          'heic',
        ],
      );
      final path = result?.path;
      if (path == null) return null;
      return _validatedFile(path, maxBytes: maxBytes, allowPdf: true);
    });
  }

  static Future<List<File?>> getMultiMedia({int? maxBytes}) async {
    final files = await _exclusive<List<File>>(() async {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const [
          'pdf',
          'jpg',
          'jpeg',
          'png',
          'gif',
          'bmp',
          'webp',
          'heic',
        ],
      );
      final files = <File>[];
      for (final item in result) {
        final path = item.path;
        if (path == null) continue;
        final file = await _validatedFile(
          path,
          maxBytes: maxBytes,
          allowPdf: true,
        );
        if (file != null) files.add(file);
      }
      return files;
    });
    return files ?? const <File>[];
  }

  static Future<List<File?>> getImageOrFile(
    bool isSingle, {
    BuildContext? context,
    int? maxBytes,
  }) async {
    final modalContext = context ?? Go.navigatorKey.currentContext;
    if (modalContext == null) return const [];
    final choice = await showModalBottomSheet<_MediaChoice>(
      context: modalContext,
      useSafeArea: true,
      builder: (sheetContext) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.file_copy_outlined),
            title: Text(LocaleKeys.selectFile),
            onTap: () => Navigator.pop(sheetContext, _MediaChoice.file),
          ),
          ListTile(
            leading: const Icon(Icons.image_outlined),
            title: Text(LocaleKeys.selectImage),
            onTap: () => Navigator.pop(sheetContext, _MediaChoice.image),
          ),
        ],
      ),
    );
    if (choice == null) return const [];
    if (choice == _MediaChoice.file) {
      return isSingle
          ? <File?>[await getMedia(maxBytes: maxBytes)]
          : getMultiMedia(maxBytes: maxBytes);
    }
    return isSingle
        ? <File?>[await getImage(maxBytes: maxBytes)]
        : (await getImages(maxBytes: maxBytes)).cast<File?>();
  }

  static Future<File?> takePicture({
    int? maxBytes,
    String cropTitle = 'Crop image',
  }) => _pickImage(
    source: ImageSource.camera,
    crop: true,
    maxBytes: maxBytes,
    cropTitle: cropTitle,
  );

  static Future<File?> pickImage({
    int? maxBytes,
    String cropTitle = 'Crop image',
  }) => _pickImage(
    source: ImageSource.gallery,
    crop: true,
    maxBytes: maxBytes,
    cropTitle: cropTitle,
  );

  static Future<List<File>> pickMultiImages({int? maxBytes}) =>
      _pickMultiple(maxBytes: maxBytes);

  /// Recovers results after Android destroys the activity under memory
  /// pressure while a picker intent is open. Call from the owning screen's
  /// initialization and treat an empty list as cancellation/no lost result.
  static Future<List<File>> recoverLostImages({int? maxBytes}) async {
    final files = await _exclusive<List<File>>(() async {
      final response = await _picker.retrieveLostData();
      if (response.isEmpty || response.exception != null) return <File>[];
      final recovered = <File>[];
      for (final image in response.files ?? const <XFile>[]) {
        final file = await _validatedFile(image.path, maxBytes: maxBytes);
        if (file != null) recovered.add(file);
      }
      return recovered;
    });
    return files ?? const [];
  }

  static Future<File?> _pickImage({
    required ImageSource source,
    bool crop = false,
    int? maxBytes,
    String cropTitle = 'Crop image',
  }) {
    return _exclusive<File>(() async {
      if (source == ImageSource.camera &&
          !_picker.supportsImageSource(ImageSource.camera)) {
        return null;
      }
      final image = await _picker.pickImage(source: source);
      if (image == null) return null;
      var file = await _validatedFile(image.path, maxBytes: maxBytes);
      if (file == null || !crop) return file;
      file = await _cropImage(sourcePath: file.path, title: cropTitle);
      if (file == null) return null;
      return _validatedFile(file.path, maxBytes: maxBytes);
    });
  }

  static Future<List<File>> _pickMultiple({int? maxBytes}) async {
    final files = await _exclusive<List<File>>(() async {
      final images = await _picker.pickMultiImage();
      final selected = <File>[];
      for (final image in images) {
        final file = await _validatedFile(image.path, maxBytes: maxBytes);
        if (file != null) selected.add(file);
      }
      return selected;
    });
    return files ?? const [];
  }

  static Future<T?> _exclusive<T>(Future<T?> Function() operation) async {
    if (_operationInFlight) return null;
    _operationInFlight = true;
    try {
      return await operation();
    } on PlatformException {
      return null;
    } on FileSystemException {
      return null;
    } on StateError {
      return null;
    } finally {
      _operationInFlight = false;
    }
  }

  static Future<File?> _validatedFile(
    String path, {
    int? maxBytes,
    bool allowPdf = false,
  }) async {
    final extension = path.split('.').last.toLowerCase();
    if (!_imageExtensions.contains(extension) &&
        !(allowPdf && extension == 'pdf')) {
      return null;
    }
    final file = File(path);
    if (!await file.exists()) return null;
    if (maxBytes != null && await file.length() > maxBytes) return null;
    return file;
  }

  static Future<File?> _cropImage({
    required String sourcePath,
    required String title,
  }) async {
    try {
      final cropped = await _cropper.cropImage(
        sourcePath: sourcePath,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: title,
            toolbarColor: AppColors.primary,
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor: AppColors.primary,
            aspectRatioPresets: const [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPresetCustom(),
            ],
          ),
          IOSUiSettings(
            title: title,
            aspectRatioPresets: const [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPresetCustom(),
            ],
          ),
        ],
      );
      return cropped == null ? null : File(cropped.path);
    } on PlatformException {
      return null;
    } on StateError {
      return null;
    }
  }
}

class CropAspectRatioPresetCustom implements CropAspectRatioPresetData {
  const CropAspectRatioPresetCustom();

  @override
  (int, int)? get data => (324, 214);

  @override
  String get name => '324 x 214 (3:2)';
}
