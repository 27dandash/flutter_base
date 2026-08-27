import 'dart:io';

import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import 'app_image_picker_models.dart';
import 'app_image_picker_service.dart';

final class PluginAppImagePickerService implements AppImagePickerService {
  PluginAppImagePickerService({ImagePicker? picker, ImageCropper? cropper})
    : _picker = picker ?? ImagePicker(),
      _cropper = cropper ?? ImageCropper();

  final ImagePicker _picker;
  final ImageCropper _cropper;
  bool _inFlight = false;

  static const _allowedExtensions = <String>{
    'jpg',
    'jpeg',
    'png',
    'gif',
    'bmp',
    'webp',
    'heic',
  };

  @override
  Future<AppImagePickResult> pick({
    required AppImagePickSource source,
    required bool multiple,
    required bool crop,
    int? maxBytes,
  }) async {
    if (_inFlight) return const AppImagePickCancelled();
    _inFlight = true;
    try {
      final imageSource = source == AppImagePickSource.camera
          ? ImageSource.camera
          : ImageSource.gallery;
      final files = <XFile>[];
      if (multiple && source == AppImagePickSource.gallery) {
        files.addAll(await _picker.pickMultiImage());
      } else {
        final file = await _picker.pickImage(source: imageSource);
        if (file != null) files.add(file);
      }
      if (files.isEmpty) return const AppImagePickCancelled();

      final validated = <File>[];
      for (final picked in files) {
        var file = File(picked.path);
        final validation = await _validate(file, maxBytes: maxBytes);
        if (validation != null) return validation;
        if (crop && files.length == 1) {
          final cropped = await _cropper.cropImage(sourcePath: file.path);
          if (cropped == null) return const AppImagePickCancelled();
          file = File(cropped.path);
          final croppedValidation = await _validate(file, maxBytes: maxBytes);
          if (croppedValidation != null) return croppedValidation;
        }
        validated.add(file);
      }
      return AppImagePickSuccess(List.unmodifiable(validated));
    } on PlatformException catch (error) {
      return _isPermissionError(error)
          ? const AppImagePickPermissionDenied()
          : const AppImagePickFailure();
    } on FileSystemException {
      return const AppImagePickFailure();
    } on StateError {
      return const AppImagePickFailure();
    } finally {
      _inFlight = false;
    }
  }

  @override
  Future<AppImagePickResult> recoverLost({int? maxBytes}) async {
    if (_inFlight) return const AppImagePickCancelled();
    _inFlight = true;
    try {
      final response = await _picker.retrieveLostData();
      if (response.isEmpty) return const AppImagePickCancelled();
      if (response.exception != null) {
        return _isPermissionError(response.exception!)
            ? const AppImagePickPermissionDenied()
            : const AppImagePickFailure();
      }
      final recovered = <File>[];
      for (final picked in response.files ?? const <XFile>[]) {
        final file = File(picked.path);
        final validation = await _validate(file, maxBytes: maxBytes);
        if (validation != null) return validation;
        recovered.add(file);
      }
      return recovered.isEmpty
          ? const AppImagePickCancelled()
          : AppImagePickSuccess(List.unmodifiable(recovered));
    } on PlatformException catch (error) {
      return _isPermissionError(error)
          ? const AppImagePickPermissionDenied()
          : const AppImagePickFailure();
    } on FileSystemException {
      return const AppImagePickFailure();
    } finally {
      _inFlight = false;
    }
  }

  Future<AppImagePickResult?> _validate(File file, {int? maxBytes}) async {
    final extension = file.path.split('.').last.toLowerCase();
    if (!_allowedExtensions.contains(extension) || !await file.exists()) {
      return const AppImagePickFailure();
    }
    if (maxBytes != null && await file.length() > maxBytes) {
      return const AppImagePickTooLarge();
    }
    return null;
  }

  bool _isPermissionError(PlatformException error) {
    final code = error.code.toLowerCase();
    return code.contains('permission') ||
        code.contains('denied') ||
        code.contains('restricted') ||
        code.contains('access');
  }
}
