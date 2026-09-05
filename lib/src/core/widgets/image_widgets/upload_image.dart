import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../config/language/locale_keys.g.dart';
import '../../../config/res/config_imports.dart';
import '../../shared/extensions/widgets/widget_extentions.dart';
import '../../shared/helpers/image_helper.dart';
import '../fields/text_fields/default_text_field.dart';
import 'cached_image.dart';

enum UploadImageType { single, multi }

class UploadImageWidget extends StatefulWidget {
  final List<int>? removedImages;
  final Widget? tappedItem;
  final Function(List<File>)? onUpload;
  final UploadImageType uploadImageType;

  const UploadImageWidget({
    super.key,
    this.removedImages,
    this.tappedItem,
    this.onUpload,
    this.uploadImageType = UploadImageType.single,
  });

  @override
  State<UploadImageWidget> createState() => _UploadImageWidgetState();
}

class _UploadImageWidgetState extends State<UploadImageWidget> {
  final imageValue = ValueNotifier<List<dynamic>>([]);
  bool _busy = false;

  Future<void> _pickMultiImages() async {
    if (_busy) return;
    _busy = true;
    try {
      final images = await ImageHelper.pickMultiImages();
      if (!mounted || images.isEmpty) return;
      _updateImageValue(images);
      _notifyUpload(images);
    } finally {
      if (mounted) _busy = false;
    }
  }

  Future<void> _pickSingleImage() async {
    if (_busy) return;
    _busy = true;
    try {
      final image = await ImageHelper.pickImage();
      if (!mounted || image == null) return;
      _updateImageValue([image]);
      _notifyUpload([image]);
    } finally {
      if (mounted) _busy = false;
    }
  }

  void _updateImageValue(List<File> images) {
    if (widget.uploadImageType == UploadImageType.single) {
      imageValue.value = List.from(images);
    } else {
      imageValue.value = List.from(imageValue.value..addAll(images));
    }
  }

  void _notifyUpload(List<File> images) {
    if (!mounted) return;
    widget.onUpload?.call(imageValue.value.whereType<File>().toList());
  }

  void _removeItem(dynamic item) {
    final updated = List<dynamic>.from(imageValue.value);
    updated.remove(item);
    imageValue.value = updated;
    _notifyUpload(updated.whereType<File>().toList());
  }

  Future<void> _handlePickTap() async {
    if (_busy) return;
    if (widget.uploadImageType == UploadImageType.single) {
      await _pickSingleImage();
    } else {
      await _pickMultiImages();
    }
  }

  @override
  void dispose() {
    imageValue.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.tappedItem != null) ...{
          Semantics(
            button: true,
            enabled: !_busy,
            label: LocaleKeys.selectImage,
            child: GestureDetector(
              onTap: _busy ? null : _handlePickTap,
              child: widget.tappedItem! is DefaultTextField
                  ? AbsorbPointer(child: widget.tappedItem)
                  : widget.tappedItem!,
            ),
          ),
        },
        ValueListenableBuilder(
          valueListenable: imageValue,
          builder: (context, value, child) {
            return Column(
              children: [
                if (value.isNotEmpty) 10.szH,
                Wrap(
                  spacing: 8.0.w,
                  runSpacing: 8.0.h,
                  children: value
                      .map(
                        (item) => Stack(
                          clipBehavior: Clip.none,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: item is String
                                  ? CachedImage(
                                      url: item,
                                      width: 70.0.w,
                                      height: 70.0.h,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.file(
                                      item,
                                      width: 70.0.w,
                                      height: 70.0.h,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                            PositionedDirectional(
                              top: 0,
                              end: 0,
                              child: Semantics(
                                button: true,
                                label: LocaleKeys.imageRemove,
                                child: IconButton(
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 48,
                                    minHeight: 48,
                                  ),
                                  onPressed: () => _removeItem(item),
                                  icon: Container(
                                    decoration: const BoxDecoration(
                                      color: AppColors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.close,
                                      color: Colors.red,
                                      size: 16.sp,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
