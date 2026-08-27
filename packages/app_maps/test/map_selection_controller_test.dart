import 'dart:async';

import 'package:app_maps/app_maps.dart';
import 'package:flutter_test/flutter_test.dart';

final class _LocationService implements MapLocationService {
  bool enabled = true;
  MapPermissionState permission = MapPermissionState.granted;
  MapPoint point = const MapPoint(30, 31);
  Future<MapPoint>? pendingLocation;
  var requests = 0;

  @override
  Future<MapPermissionState> checkPermission() async => permission;
  @override
  Future<MapPoint> currentLocation() => pendingLocation ?? Future.value(point);
  @override
  Future<bool> isServiceEnabled() async => enabled;
  @override
  Future<bool> openAppSettings() async => true;
  @override
  Future<bool> openLocationSettings() async => true;
  @override
  Future<MapPermissionState> requestPermission() async {
    requests++;
    return permission;
  }
}

final class _AddressLookup implements MapAddressLookup {
  Object? error;
  @override
  Future<String?> lookup(MapPoint point, {required String languageCode}) async {
    if (error != null) throw error!;
    return '$languageCode:${point.latitude},${point.longitude}';
  }
}

AppMapConfig _config({bool configured = true}) => AppMapConfig(
  apiKeyConfigured: configured,
  fallbackPoint: const MapPoint(30, 30),
  locationTimeout: const Duration(milliseconds: 5),
  languageCode: 'ar',
);

void main() {
  test('missing API key is a controlled state', () async {
    final controller = MapSelectionController(
      config: _config(configured: false),
      locationService: _LocationService(),
    );
    await controller.initialize();
    expect(controller.state.status, MapSelectionStatus.missingApiKey);
    controller.dispose();
  });

  test('initializes to fallback without prompting for location', () async {
    final service = _LocationService()..permission = MapPermissionState.denied;
    final controller = MapSelectionController(
      config: _config(),
      locationService: service,
    );
    await controller.initialize();
    expect(controller.state.selectedPoint, const MapPoint(30, 30));
    expect(service.requests, 0);
    controller.dispose();
  });

  test('handles denied and permanently denied permission', () async {
    final service = _LocationService()..permission = MapPermissionState.denied;
    final controller = MapSelectionController(
      config: _config(),
      locationService: service,
    );
    await controller.goToCurrentLocation();
    expect(controller.state.status, MapSelectionStatus.permissionDenied);
    service.permission = MapPermissionState.permanentlyDenied;
    await controller.goToCurrentLocation();
    expect(
      controller.state.status,
      MapSelectionStatus.permissionPermanentlyDenied,
    );
    controller.dispose();
  });

  test('handles disabled services and location timeout', () async {
    final service = _LocationService()..enabled = false;
    final controller = MapSelectionController(
      config: _config(),
      locationService: service,
    );
    await controller.goToCurrentLocation();
    expect(controller.state.status, MapSelectionStatus.servicesDisabled);
    service
      ..enabled = true
      ..pendingLocation = Completer<MapPoint>().future;
    await controller.goToCurrentLocation();
    expect(controller.state.status, MapSelectionStatus.locationUnavailable);
    controller.dispose();
  });

  test('selection resolves an injected localized address', () async {
    final controller = MapSelectionController(
      config: _config(),
      locationService: _LocationService(),
      addressLookup: _AddressLookup(),
    );
    await controller.select(const MapPoint(1, 2));
    expect(controller.state.address, 'ar:1.0,2.0');
    controller.dispose();
  });

  test('address failure keeps the selected marker usable', () async {
    final lookup = _AddressLookup()..error = StateError('paid API unavailable');
    final controller = MapSelectionController(
      config: _config(),
      locationService: _LocationService(),
      addressLookup: lookup,
    );
    await controller.select(const MapPoint(1, 2));
    expect(controller.state.status, MapSelectionStatus.ready);
    expect(controller.state.selectedPoint, const MapPoint(1, 2));
    controller.dispose();
  });
}
