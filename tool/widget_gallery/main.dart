import 'dart:async';

import 'package:flutter_base/src/core/network/error/failures.dart';
import 'package:flutter_base/src/core/shared/extensions/base_state.dart';
import 'package:flutter_base/src/core/shared/helpers/loading_manager.dart';
import 'package:flutter_base/src/core/state/async/async.dart';
import 'package:flutter_base/src/core/state/paginated/paginated.dart';
import 'package:flutter_base/src/core/widgets/buttons/app_button.dart';
import 'package:flutter_base/src/core/widgets/buttons/default_button.dart';
import 'package:flutter_base/src/core/widgets/custom_messages.dart';
import 'package:flutter_base/src/core/widgets/dialogs/adaptive_alert.dart';
import 'package:flutter_base/src/core/widgets/fields/drop_downs/app_drop_down/app_dropdown.dart';
import 'package:flutter_base/src/core/widgets/fields/text_fields/default_text_field.dart';
import 'package:flutter_base/src/core/widgets/handling_views/app_error_handler.dart';
import 'package:flutter_base/src/core/widgets/handling_views/app_state_view.dart';
import 'package:flutter_base/src/core/widgets/image_picker/image_picker.dart';
import 'package:flutter_base/src/core/widgets/media/media.dart';
import 'package:flutter_base/src/core/widgets/pickers/custom_dialog.dart';
import 'package:flutter_base/src/core/widgets/pickers/default_bottom_sheet.dart';
import 'package:flutter_base/src/core/widgets/scaffolds/app_page_shell.dart';
import 'package:dartz/dartz.dart' show Either, Left, Right;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('ar'), Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: const WidgetGalleryApp(),
    ),
  );
}

/// External debug/test harness. No production entry point imports this file.
class WidgetGalleryApp extends StatefulWidget {
  const WidgetGalleryApp({super.key});

  @override
  State<WidgetGalleryApp> createState() => _WidgetGalleryAppState();
}

class _WidgetGalleryAppState extends State<WidgetGalleryApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Reusable widget gallery',
        theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
        darkTheme: ThemeData(
          colorSchemeSeed: Colors.indigo,
          brightness: Brightness.dark,
          useMaterial3: true,
        ),
        themeMode: _themeMode,
        locale: context.locale,
        supportedLocales: context.supportedLocales,
        localizationsDelegates: context.localizationDelegates,
        home: GalleryHome(
          darkMode: _themeMode == ThemeMode.dark,
          onThemeChanged: (dark) {
            setState(
              () => _themeMode = dark ? ThemeMode.dark : ThemeMode.light,
            );
          },
        ),
      ),
    );
  }
}

class GalleryHome extends StatefulWidget {
  const GalleryHome({
    super.key,
    required this.darkMode,
    required this.onThemeChanged,
  });

  final bool darkMode;
  final ValueChanged<bool> onThemeChanged;

  @override
  State<GalleryHome> createState() => _GalleryHomeState();
}

class _GalleryHomeState extends State<GalleryHome> {
  final _overlay = BlockingOverlayController();
  final _asyncCubit = _GalleryAsyncCubit();
  final _pageCubit = _GalleryPageCubit();
  final _picker = _GalleryPickerService();
  String? _single;
  List<String> _multi = const [];
  int _retries = 0;

  static const _options = ['Alpha', 'Beta', 'Gamma', 'Delta'];

  @override
  void dispose() {
    _overlay.dispose();
    _asyncCubit.close();
    _pageCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<_GalleryAsyncCubit>.value(value: _asyncCubit),
        BlocProvider<_GalleryPageCubit>.value(value: _pageCubit),
      ],
      child: FullScreenLoadingManager(
        controller: _overlay,
        loadingLabel: 'Blocking operation',
        child: AppPageShell(
          title: const Text('Canonical widget gallery'),
          actions: [
            IconButton(
              key: const Key('gallery-locale'),
              tooltip: 'Switch Arabic and English',
              onPressed: () {
                final next = context.locale.languageCode == 'ar'
                    ? const Locale('en')
                    : const Locale('ar');
                context.setLocale(next);
              },
              icon: const Icon(Icons.translate),
            ),
            IconButton(
              key: const Key('gallery-theme'),
              tooltip: 'Switch light and dark theme',
              onPressed: () => widget.onThemeChanged(!widget.darkMode),
              icon: Icon(widget.darkMode ? Icons.light_mode : Icons.dark_mode),
            ),
          ],
          body: ListView(
            key: const Key('gallery-list'),
            padding: const EdgeInsets.all(16),
            children: [
              const _Heading('Buttons and repeated-submit protection'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final variant in AppButtonVariant.values)
                    SizedBox(
                      width: 170,
                      child: AppButton(
                        key: Key('button-${variant.name}'),
                        label: variant.name,
                        variant: variant,
                        onPressed: () async {
                          await Future<void>.delayed(
                            const Duration(milliseconds: 120),
                          );
                        },
                      ),
                    ),
                  const SizedBox(
                    width: 170,
                    child: AppButton(
                      key: Key('button-disabled'),
                      label: 'Disabled',
                      onPressed: null,
                    ),
                  ),
                  const SizedBox(
                    width: 170,
                    child: AppButton(
                      key: Key('button-loading'),
                      label: 'Submit',
                      loadingLabel: 'Submitting',
                      isLoading: true,
                      onPressed: null,
                    ),
                  ),
                  DefaultButton(
                    title: 'Legacy compatibility button',
                    onTap: () {},
                  ),
                ],
              ),
              const _Heading('Text fields'),
              const DefaultTextField(
                key: Key('field-standard'),
                label: 'Email',
                semanticLabel: 'Email address',
                inputType: TextInputType.emailAddress,
                autofillHints: [AutofillHints.email],
              ),
              const SizedBox(height: 8),
              const DefaultTextField(
                key: Key('field-invalid'),
                label: 'Invalid value',
                initialValue: 'bad',
                errorText: 'A safe localized validation message',
              ),
              const SizedBox(height: 8),
              const DefaultTextField(
                label: 'Disabled field',
                enabled: false,
                initialValue: 'Read only state',
              ),
              const _Heading('Dropdowns'),
              AppDropdown<String>(
                key: const Key('dropdown-single'),
                label: 'Single selection',
                items: _options,
                value: _single,
                itemAsString: (value) => value,
                onChanged: (value) => setState(() => _single = value),
              ),
              const SizedBox(height: 8),
              AppDropdown<String>(
                key: const Key('dropdown-multi'),
                label: 'Multiple selection',
                items: _options,
                itemAsString: (value) => value,
                onChanged: (_) {},
                isMultiSelect: true,
                selectedValues: _multi,
                onMultiChanged: (value) => setState(() => _multi = value),
              ),
              const SizedBox(height: 8),
              AppDropdown<String>(
                label: 'Loading lookup',
                items: const [],
                itemAsString: (value) => value,
                onChanged: (_) {},
                isLoading: true,
              ),
              const _Heading('State and error views'),
              const SizedBox(
                height: 120,
                child: AppStateView.loading(
                  message: 'Loading reusable content',
                  compact: true,
                ),
              ),
              AppStateView.empty(
                message: 'No reusable items yet',
                actionLabel: 'Create',
                onAction: () {},
                compact: true,
              ),
              AppStateView.offline(
                message: 'The network is unavailable',
                actionLabel: 'Retry',
                onAction: () => setState(() => _retries++),
                compact: true,
              ),
              AppErrorHandler(
                failure: const ServerFailure(technical: 'hidden detail'),
                onRetry: () => setState(() => _retries++),
                compact: true,
              ),
              Text('Retries: $_retries', key: const Key('retry-count')),
              const _Heading('Async and pagination'),
              SizedBox(
                height: 80,
                child: AsyncBlocBuilder<_GalleryAsyncCubit, String>(
                  builder: (_, value) => Center(child: Text(value)),
                  initialBuilder: (_) => const Center(child: Text('Initial')),
                  onRetry: _asyncCubit.succeed,
                ),
              ),
              Wrap(
                spacing: 8,
                children: [
                  TextButton(
                    key: const Key('async-success'),
                    onPressed: _asyncCubit.succeed,
                    child: const Text('Async success'),
                  ),
                  TextButton(
                    key: const Key('async-failure'),
                    onPressed: _asyncCubit.fail,
                    child: const Text('Async failure'),
                  ),
                ],
              ),
              SizedBox(
                height: 280,
                child: PaginatedListWidget<_GalleryPageCubit, int>(
                  itemBuilder: (_, item, _) =>
                      ListTile(title: Text('Item $item')),
                  emptyWidget: const Center(child: Text('No paginated rows')),
                ),
              ),
              const _Heading('Dialogs, sheets, messages and overlay'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton(
                    key: const Key('open-confirmation'),
                    onPressed: () => showAdaptiveAlert(
                      context: context,
                      title: 'Confirm safe action',
                      content: const Text('This is a test-only dialog.'),
                      actions: const [
                        AdaptiveAction(key: 'cancel', label: 'Cancel'),
                        AdaptiveAction(key: 'confirm', label: 'Confirm'),
                      ],
                    ),
                    child: const Text('Confirmation'),
                  ),
                  FilledButton(
                    key: const Key('open-custom-dialog'),
                    onPressed: () => showCustomDialog<void>(
                      context,
                      child: const Text('Custom dialog content'),
                    ),
                    child: const Text('Custom dialog'),
                  ),
                  FilledButton(
                    key: const Key('open-bottom-sheet'),
                    onPressed: () => showDefaultBottomSheet<void>(
                      context: context,
                      child: const Text('Keyboard-safe bottom sheet'),
                    ),
                    child: const Text('Bottom sheet'),
                  ),
                  FilledButton(
                    key: const Key('show-message'),
                    onPressed: () => MessageUtils.showSnackBar(
                      context: context,
                      baseStatus: BaseStatus.success,
                      message: 'Accessible feedback',
                    ),
                    child: const Text('Snackbar'),
                  ),
                  FilledButton(
                    key: const Key('show-overlay'),
                    onPressed: () async {
                      _overlay.show();
                      await Future<void>.delayed(
                        const Duration(milliseconds: 250),
                      );
                      _overlay.hide();
                    },
                    child: const Text('Loading overlay'),
                  ),
                ],
              ),
              const _Heading('Media and image picker'),
              Row(
                children: [
                  const Expanded(
                    child: AppMedia(
                      request: AppMediaRequest(
                        path: 'assets/svg/base_svg/search.svg',
                        kind: AppMediaKind.svg,
                        source: AppMediaSource.asset,
                      ),
                      semanticLabel: 'Search asset',
                      height: 72,
                    ),
                  ),
                  const Expanded(
                    child: AppMedia(
                      key: Key('missing-media'),
                      request: AppMediaRequest(
                        path: 'assets/missing.png',
                        kind: AppMediaKind.image,
                        source: AppMediaSource.asset,
                      ),
                      semanticLabel: 'Missing media fallback',
                      height: 72,
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      key: const Key('open-media-viewer'),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const AppMediaViewerPage(
                            request: AppMediaRequest(
                              path: 'assets/lottie/visit.json',
                              kind: AppMediaKind.image,
                              source: AppMediaSource.asset,
                            ),
                          ),
                        ),
                      ),
                      child: const Text('Viewer'),
                    ),
                  ),
                ],
              ),
              AppImagePickerField(
                key: const Key('image-picker'),
                service: _picker,
                onChanged: (_) {},
                recoverLostOnStart: false,
                allowCamera: false,
                semanticLabel: 'Test image picker',
              ),
              const _Heading('Page shells'),
              FilledButton(
                key: const Key('open-sliver-page'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const _SliverGalleryPage(),
                  ),
                ),
                child: const Text('Open sliver shell'),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 12),
    child: Text(text, style: Theme.of(context).textTheme.titleLarge),
  );
}

class _SliverGalleryPage extends StatelessWidget {
  const _SliverGalleryPage();

  @override
  Widget build(BuildContext context) => AppPageShell.sliver(
    title: const Text('Sliver page shell'),
    slivers: [
      SliverList.builder(
        itemCount: 30,
        itemBuilder: (_, index) => ListTile(title: Text('Sliver row $index')),
      ),
    ],
  );
}

class _GalleryAsyncCubit extends AsyncCubit<String> {
  Future<void> succeed() => execute(() async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    return const Right('Async success state');
  });

  Future<void> fail() => execute(() async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    return const Left(ServerFailure());
  });
}

class _GalleryPageCubit extends PaginatedAsyncCubit<int> {
  _GalleryPageCubit() {
    unawaited(fetchInitialData());
  }

  @override
  Future<Either<Failure, PaginatedData<int>>> fetchPage(
    int page, {
    String? filterKey,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final start = (page - 1) * 20;
    return Right(
      PaginatedData(
        items: List<int>.generate(20, (index) => start + index),
        meta: PaginationMeta(
          totalItems: 60,
          countItems: 20,
          perPage: 20,
          totalPages: 3,
          currentPage: page,
          nextPageUrl: page < 3 ? '/items?page=${page + 1}' : null,
        ),
      ),
    );
  }
}

class _GalleryPickerService implements AppImagePickerService {
  @override
  Future<AppImagePickResult> pick({
    required AppImagePickSource source,
    required bool multiple,
    required bool crop,
    int? maxBytes,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return const AppImagePickCancelled();
  }

  @override
  Future<AppImagePickResult> recoverLost({int? maxBytes}) async {
    return const AppImagePickCancelled();
  }
}
