import 'dart:async';
import 'dart:io';

import 'package:flutter_base/src/core/widgets/image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

final class _PickerPlatform extends ImagePickerPlatform {
  XFile? single;
  List<XFile> multiple = const [];
  LostDataResponse lost = LostDataResponse.empty();
  Object? error;
  Completer<XFile?>? pending;

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    if (error case final error?) throw error;
    return pending?.future ?? single;
  }

  @override
  Future<List<XFile>> getMultiImageWithOptions({
    MultiImagePickerOptions options = const MultiImagePickerOptions(),
  }) async => multiple;

  @override
  Future<LostDataResponse> getLostData() async => lost;
}

void main() {
  late ImagePickerPlatform original;
  late _PickerPlatform platform;
  late Directory temporary;

  setUp(() async {
    original = ImagePickerPlatform.instance;
    platform = _PickerPlatform();
    ImagePickerPlatform.instance = platform;
    temporary = await Directory.systemTemp.createTemp('app-picker-test-');
  });

  tearDown(() async {
    ImagePickerPlatform.instance = original;
    await temporary.delete(recursive: true);
  });

  test(
    'maps cancellation, success and maximum size without raw errors',
    () async {
      final service = PluginAppImagePickerService();
      expect(
        await service.pick(
          source: AppImagePickSource.gallery,
          multiple: false,
          crop: false,
        ),
        isA<AppImagePickCancelled>(),
      );

      final image = File('${temporary.path}/picked.jpg');
      await image.writeAsBytes([1, 2, 3, 4]);
      platform.single = XFile(image.path);
      final success = await service.pick(
        source: AppImagePickSource.camera,
        multiple: false,
        crop: false,
        maxBytes: 4,
      );
      expect(success, isA<AppImagePickSuccess>());

      final tooLarge = await service.pick(
        source: AppImagePickSource.camera,
        multiple: false,
        crop: false,
        maxBytes: 3,
      );
      expect(tooLarge, isA<AppImagePickTooLarge>());
    },
  );

  test('maps permission failures and rejects unsupported files', () async {
    final service = PluginAppImagePickerService();
    platform.error = PlatformException(code: 'camera_access_denied');
    expect(
      await service.pick(
        source: AppImagePickSource.camera,
        multiple: false,
        crop: false,
      ),
      isA<AppImagePickPermissionDenied>(),
    );

    platform.error = null;
    final text = File('${temporary.path}/not-image.txt');
    await text.writeAsString('not an image');
    platform.single = XFile(text.path);
    expect(
      await service.pick(
        source: AppImagePickSource.gallery,
        multiple: false,
        crop: false,
      ),
      isA<AppImagePickFailure>(),
    );
  });

  test(
    'recovers lost activity results and guards concurrent launches',
    () async {
      final image = File('${temporary.path}/recovered.jpg');
      await image.writeAsBytes([1]);
      platform.lost = LostDataResponse(
        file: XFile(image.path),
        files: [XFile(image.path)],
        type: RetrieveType.image,
      );
      final service = PluginAppImagePickerService();
      expect(await service.recoverLost(), isA<AppImagePickSuccess>());

      platform.pending = Completer<XFile?>();
      final first = service.pick(
        source: AppImagePickSource.gallery,
        multiple: false,
        crop: false,
      );
      expect(
        await service.pick(
          source: AppImagePickSource.gallery,
          multiple: false,
          crop: false,
        ),
        isA<AppImagePickCancelled>(),
      );
      platform.pending!.complete(null);
      expect(await first, isA<AppImagePickCancelled>());
    },
  );
}
