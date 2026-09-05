import 'dart:async';

import 'package:app_maps/app_maps.dart';
import 'package:flutter_test/flutter_test.dart';

final class _LocationService implements MapLocationService {
  _LocationService({
    this.serviceEnabled = true,
    this.permission = MapPermissionState.granted,
    this.currentThrows = false,
  });

  bool serviceEnabled;
  MapPermissionState permission;
  MapPoint current = const MapPoint(30.1, 31.2);
  bool currentThrows;
  Future<MapPoint>? pendingLocation;
  var permissionRequests = 0;
  var settingsOpened = 0;
  var locationSettingsOpened = 0;

  @override
  Future<MapPermissionState> checkPermission() async => permission;

  @override
  Future<MapPoint> currentLocation() async {
    if (currentThrows) throw StateError('native');
    final pending = pendingLocation;
    if (pending != null) return pending;
    return current;
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
  Future<MapPermissionState> requestPermission() async {
    permissionRequests++;
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

MapSelectionController _controller(_LocationService service) =>
    MapSelectionController(
      config: const AppMapConfig(
        apiKeyConfigured: true,
        fallbackPoint: MapPoint(30, 31),
        locationTimeout: Duration(milliseconds: 50),
      ),
      locationService: service,
    );

void main() {
  test('missing API key is a controlled state', () async {
    final controller = MapSelectionController(
      config: const AppMapConfig(
        apiKeyConfigured: false,
        fallbackPoint: MapPoint(30, 31),
      ),
      locationService: _LocationService(),
    );

    await controller.initialize();

    expect(controller.state.status, MapSelectionStatus.missingApiKey);
    controller.dispose();
  });

  test('initializes to fallback without prompting for location', () async {
    final service = _LocationService(permission: MapPermissionState.denied);
    final controller = _controller(service);

    await controller.initialize();

    expect(controller.state.selectedPoint, const MapPoint(30, 31));
    expect(service.permissionRequests, 0);
    controller.dispose();
  });

  test('permissionDenied surfaces without throwing', () async {
    final service = _LocationService(permission: MapPermissionState.denied);
    final controller = _controller(service);

    await controller.goToCurrentLocation();

    expect(controller.state.status, MapSelectionStatus.permissionDenied);
    controller.dispose();
  });

  test('permanently denied can open app settings', () async {
    final service = _LocationService(
      permission: MapPermissionState.permanentlyDenied,
    );
    final controller = _controller(service);

    await controller.goToCurrentLocation();
    await controller.openRequiredSettings();

    expect(
      controller.state.status,
      MapSelectionStatus.permissionPermanentlyDenied,
    );
    expect(service.settingsOpened, 1);
    controller.dispose();
  });

  test('servicesDisabled can open location settings', () async {
    final service = _LocationService(serviceEnabled: false);
    final controller = _controller(service);

    await controller.goToCurrentLocation();
    await controller.openRequiredSettings();

    expect(controller.state.status, MapSelectionStatus.servicesDisabled);
    expect(service.locationSettingsOpened, 1);
    controller.dispose();
  });

  test('location timeout maps to locationUnavailable', () async {
    final service = _LocationService()
      ..pendingLocation = Completer<MapPoint>().future;
    final controller = _controller(service);

    await controller.goToCurrentLocation();

    expect(controller.state.status, MapSelectionStatus.locationUnavailable);
    controller.dispose();
  });

  test('selection resolves an injected localized address', () async {
    final controller = MapSelectionController(
      config: const AppMapConfig(
        apiKeyConfigured: true,
        fallbackPoint: MapPoint(30, 31),
        languageCode: 'ar',
      ),
      locationService: _LocationService(),
      addressLookup: _AddressLookup(),
    );

    await controller.select(const MapPoint(1, 2));

    expect(controller.state.address, 'ar:1.0,2.0');
    controller.dispose();
  });

  test('address failure keeps the selected marker usable', () async {
    final lookup = _AddressLookup()..error = StateError('private provider');
    final controller = MapSelectionController(
      config: const AppMapConfig(
        apiKeyConfigured: true,
        fallbackPoint: MapPoint(30, 31),
      ),
      locationService: _LocationService(),
      addressLookup: lookup,
    );

    await controller.select(const MapPoint(1, 2));

    expect(controller.state.status, MapSelectionStatus.ready);
    expect(controller.state.selectedPoint, const MapPoint(1, 2));
    expect(controller.state.message, isNull);
    controller.dispose();
  });

  test(
    'location failures map to locationUnavailable without raw errors',
    () async {
      final service = _LocationService(currentThrows: true);
      final controller = _controller(service);

      await controller.goToCurrentLocation();

      expect(controller.state.status, MapSelectionStatus.locationUnavailable);
      expect(controller.state.message, isNull);
      controller.dispose();
    },
  );
}
