import 'package:app_maps/app_maps.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

final class _UnusedLocationService implements MapLocationService {
  @override
  Future<MapPermissionState> checkPermission() async =>
      MapPermissionState.denied;
  @override
  Future<MapPoint> currentLocation() async => const MapPoint(0, 0);
  @override
  Future<bool> isServiceEnabled() async => false;
  @override
  Future<bool> openAppSettings() async => false;
  @override
  Future<bool> openLocationSettings() async => false;
  @override
  Future<MapPermissionState> requestPermission() async =>
      MapPermissionState.denied;
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
            locationService: _UnusedLocationService(),
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
}
