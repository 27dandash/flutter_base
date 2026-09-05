import 'package:app_maps/app_maps.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

final class _LocationService implements MapLocationService {
  _LocationService({
    required this.permission,
    this.serviceEnabled = true,
    this.currentThrows = false,
  });

  final MapPermissionState permission;
  final bool serviceEnabled;
  final bool currentThrows;
  var settingsOpened = 0;
  var locationSettingsOpened = 0;

  @override
  Future<MapPermissionState> checkPermission() async => permission;

  @override
  Future<MapPoint> currentLocation() async {
    if (currentThrows) throw StateError('native');
    return const MapPoint(30, 31);
  }

  @override
  Future<bool> isServiceEnabled() async => serviceEnabled;

  @override
  Future<bool> openAppSettings() async {
    settingsOpened++;
    return true;
  }

  @override
  Future<bool> openLocationSettings() async {
    locationSettingsOpened++;
    return true;
  }

  @override
  Future<MapPermissionState> requestPermission() async => permission;
}

Future<void> _pumpMapPage(
  WidgetTester tester, {
  required AppMapMessages messages,
  required _LocationService service,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.dark(),
      home: MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.8)),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: AppMapPage(
            config: const AppMapConfig(
              apiKeyConfigured: true,
              fallbackPoint: MapPoint(30, 31),
            ),
            title: 'الموقع',
            confirmLabel: 'تأكيد',
            messages: messages,
            locationService: service,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('missing key is a localized accessible page state', (
    tester,
  ) async {
    const message = 'الخرائط غير مهيأة';
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: AppMapPage(
            config: const AppMapConfig(
              apiKeyConfigured: false,
              fallbackPoint: MapPoint(30, 31),
            ),
            title: 'الموقع',
            confirmLabel: 'تأكيد',
            messages: const AppMapMessages(missingConfiguration: message),
            locationService: _LocationService(
              permission: MapPermissionState.denied,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text(message), findsOneWidget);
    expect(find.byType(GoogleMap), findsNothing);
    expect(
      tester
          .widgetList<Semantics>(find.byType(Semantics))
          .any((widget) => widget.properties.label == message),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('permission denied shows accessible banner with retry action', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(480, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const messages = AppMapMessages(
      permissionDenied: 'يلزم إذن الموقع',
      retry: 'إعادة المحاولة',
      openSettings: 'فتح الإعدادات',
    );
    final service = _LocationService(permission: MapPermissionState.denied);

    await _pumpMapPage(tester, messages: messages, service: service);
    await tester.tap(find.byIcon(Icons.my_location));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text(messages.permissionDenied), findsOneWidget);
    expect(find.text(messages.retry), findsOneWidget);
    expect(find.byType(GoogleMap), findsOneWidget);
    expect(
      tester
          .widgetList<Semantics>(find.byType(Semantics))
          .any(
            (widget) => widget.properties.label == messages.permissionDenied,
          ),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'permanent permission denial opens app settings from injected copy',
    (tester) async {
      const messages = AppMapMessages(
        permissionPermanentlyDenied: 'تم حظر إذن الموقع',
        retry: 'إعادة المحاولة',
        openSettings: 'فتح الإعدادات',
      );
      final service = _LocationService(
        permission: MapPermissionState.permanentlyDenied,
      );

      await _pumpMapPage(tester, messages: messages, service: service);
      await tester.tap(find.byIcon(Icons.my_location));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text(messages.permissionPermanentlyDenied), findsOneWidget);
      await tester.tap(find.text(messages.openSettings));
      await tester.pump();

      expect(service.settingsOpened, 1);
      expect(find.textContaining('native'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('services disabled opens location settings from injected copy', (
    tester,
  ) async {
    const messages = AppMapMessages(
      servicesDisabled: 'خدمات الموقع متوقفة',
      retry: 'إعادة المحاولة',
      openSettings: 'فتح الإعدادات',
    );
    final service = _LocationService(
      permission: MapPermissionState.granted,
      serviceEnabled: false,
    );

    await _pumpMapPage(tester, messages: messages, service: service);
    await tester.tap(find.byIcon(Icons.my_location));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text(messages.servicesDisabled), findsOneWidget);
    await tester.tap(find.text(messages.openSettings));
    await tester.pump();

    expect(service.locationSettingsOpened, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('location unavailable shows retry without raw errors', (
    tester,
  ) async {
    const messages = AppMapMessages(
      locationUnavailable: 'تعذر تحديد موقعك الحالي',
      retry: 'إعادة المحاولة',
    );
    final service = _LocationService(
      permission: MapPermissionState.granted,
      currentThrows: true,
    );

    await _pumpMapPage(tester, messages: messages, service: service);
    await tester.tap(find.byIcon(Icons.my_location));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text(messages.locationUnavailable), findsOneWidget);
    expect(find.text(messages.retry), findsOneWidget);
    expect(find.text(messages.openSettings), findsNothing);
    expect(find.textContaining('native'), findsNothing);
    expect(find.textContaining('StateError'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
