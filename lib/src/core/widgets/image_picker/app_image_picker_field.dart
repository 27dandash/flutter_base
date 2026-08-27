import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../../config/language/locale_keys.g.dart';
import '../media/media.dart';
import 'app_image_picker_models.dart';
import 'app_image_picker_service.dart';

class AppImagePickerField extends StatefulWidget {
  const AppImagePickerField({
    super.key,
    required this.service,
    required this.onChanged,
    this.initialFiles = const [],
    this.maxCount = 1,
    this.maxBytes,
    this.allowCamera = true,
    this.allowGallery = true,
    this.cropSingleImage = true,
    this.recoverLostOnStart = true,
    this.semanticLabel,
  }) : assert(maxCount > 0),
       assert(allowCamera || allowGallery);

  final AppImagePickerService service;
  final ValueChanged<List<File>> onChanged;
  final List<File> initialFiles;
  final int maxCount;
  final int? maxBytes;
  final bool allowCamera;
  final bool allowGallery;
  final bool cropSingleImage;
  final bool recoverLostOnStart;
  final String? semanticLabel;

  @override
  State<AppImagePickerField> createState() => _AppImagePickerFieldState();
}

class _AppImagePickerFieldState extends State<AppImagePickerField> {
  late List<File> _files;
  bool _busy = false;
  String? _error;
  int _operation = 0;

  @override
  void initState() {
    super.initState();
    _files = List<File>.from(widget.initialFiles.take(widget.maxCount));
    if (widget.recoverLostOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_recoverLost());
      });
    }
  }

  @override
  void didUpdateWidget(covariant AppImagePickerField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialFiles != widget.initialFiles) {
      _files = List<File>.from(widget.initialFiles.take(widget.maxCount));
    }
  }

  @override
  void dispose() {
    _operation++;
    super.dispose();
  }

  Future<void> _recoverLost() async {
    final operation = ++_operation;
    AppImagePickResult result;
    try {
      result = await widget.service.recoverLost(maxBytes: widget.maxBytes);
    } catch (_) {
      result = const AppImagePickFailure();
    }
    if (!mounted || operation != _operation) return;
    _applyResult(result, replaceIndex: null);
  }

  Future<void> _pick({int? replaceIndex}) async {
    if (_busy) return;
    if (replaceIndex == null && _files.length >= widget.maxCount) {
      setState(() => _error = LocaleKeys.imageLimitReached);
      return;
    }
    final source = await _chooseSource();
    if (!mounted || source == null) return;
    final operation = ++_operation;
    setState(() {
      _busy = true;
      _error = null;
    });
    final remaining = replaceIndex == null
        ? widget.maxCount - _files.length
        : 1;
    AppImagePickResult result;
    try {
      result = await widget.service.pick(
        source: source,
        multiple: source == AppImagePickSource.gallery && remaining > 1,
        crop: widget.cropSingleImage && remaining == 1,
        maxBytes: widget.maxBytes,
      );
    } catch (_) {
      result = const AppImagePickFailure();
    }
    if (!mounted || operation != _operation) return;
    setState(() => _busy = false);
    _applyResult(result, replaceIndex: replaceIndex);
  }

  Future<AppImagePickSource?> _chooseSource() async {
    if (widget.allowCamera && !widget.allowGallery) {
      return AppImagePickSource.camera;
    }
    if (!widget.allowCamera && widget.allowGallery) {
      return AppImagePickSource.gallery;
    }
    return showModalBottomSheet<AppImagePickSource>(
      context: context,
      useSafeArea: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(LocaleKeys.camera),
              onTap: () =>
                  Navigator.pop(sheetContext, AppImagePickSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(LocaleKeys.photoLibrary),
              onTap: () =>
                  Navigator.pop(sheetContext, AppImagePickSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  void _applyResult(AppImagePickResult result, {required int? replaceIndex}) {
    switch (result) {
      case AppImagePickCancelled():
        return;
      case AppImagePickPermissionDenied():
        setState(() => _error = LocaleKeys.permissionRequired);
      case AppImagePickTooLarge():
        setState(() => _error = LocaleKeys.imageTooLarge);
      case AppImagePickFailure():
        setState(() => _error = LocaleKeys.mediaLoadFailed);
      case AppImagePickSuccess(:final files):
        final next = List<File>.from(_files);
        if (replaceIndex != null && files.isNotEmpty) {
          next[replaceIndex] = files.first;
        } else {
          next.addAll(files.take(widget.maxCount - next.length));
        }
        setState(() {
          _files = next;
          _error = null;
        });
        widget.onChanged(List<File>.unmodifiable(next));
    }
  }

  void _remove(int index) {
    final next = List<File>.from(_files)..removeAt(index);
    setState(() {
      _files = next;
      _error = null;
    });
    widget.onChanged(List<File>.unmodifiable(next));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      label: widget.semanticLabel ?? LocaleKeys.selectImage,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var index = 0; index < _files.length; index++)
                _ImageTile(
                  file: _files[index],
                  onRemove: () => _remove(index),
                  onReplace: _busy ? null : () => _pick(replaceIndex: index),
                ),
              if (_files.length < widget.maxCount)
                OutlinedButton.icon(
                  onPressed: _busy ? null : _pick,
                  icon: _busy
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_photo_alternate_outlined),
                  label: Text(LocaleKeys.imageAdd),
                ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Semantics(
              liveRegion: true,
              child: Text(_error!, style: TextStyle(color: colors.error)),
            ),
          ],
        ],
      ),
    );
  }
}

class _ImageTile extends StatelessWidget {
  const _ImageTile({
    required this.file,
    required this.onRemove,
    required this.onReplace,
  });

  final File file;
  final VoidCallback onRemove;
  final VoidCallback? onReplace;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 112,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AppMedia.fileImage(
              file: file,
              semanticLabel: LocaleKeys.selectImage,
            ),
          ),
          PositionedDirectional(
            top: 0,
            end: 0,
            child: IconButton.filled(
              tooltip: LocaleKeys.imageRemove,
              onPressed: onRemove,
              icon: const Icon(Icons.close),
            ),
          ),
          PositionedDirectional(
            bottom: 0,
            end: 0,
            child: IconButton.filledTonal(
              tooltip: LocaleKeys.imageReplace,
              onPressed: onReplace,
              icon: const Icon(Icons.refresh),
            ),
          ),
        ],
      ),
    );
  }
}
