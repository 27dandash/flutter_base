import 'package:app_maps/app_maps.dart';
import 'package:flutter/material.dart';

const mapsApiKeyConfigured = bool.fromEnvironment(
  'MAPS_API_KEY_CONFIGURED',
  defaultValue: false,
);

void main() => runApp(const MapsExampleApp());

class MapsExampleApp extends StatelessWidget {
  const MapsExampleApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
    darkTheme: ThemeData(
      colorSchemeSeed: Colors.teal,
      brightness: Brightness.dark,
      useMaterial3: true,
    ),
    home: AppMapPage(
      config: const AppMapConfig(
        apiKeyConfigured: mapsApiKeyConfigured,
        fallbackPoint: MapPoint(30.0444, 31.2357),
      ),
      title: 'Optional Maps showcase',
      confirmLabel: 'Confirm',
      messages: const AppMapMessages(
        missingConfiguration: 'Maps configuration is intentionally absent.',
      ),
      locationService: const _UnavailableLocationService(),
    ),
  );
}

class _UnavailableLocationService implements MapLocationService {
  const _UnavailableLocationService();

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
