import 'package:flutter/foundation.dart';

@immutable
final class MapPoint {
  const MapPoint(this.latitude, this.longitude);

  final double latitude;
  final double longitude;

  bool get isValid =>
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;

  @override
  bool operator ==(Object other) =>
      other is MapPoint &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);
}

enum MapPermissionState { granted, denied, permanentlyDenied, undetermined }

enum MapSelectionStatus {
  idle,
  ready,
  locating,
  resolvingAddress,
  permissionDenied,
  permissionPermanentlyDenied,
  servicesDisabled,
  locationUnavailable,
  missingApiKey,
  disposed,
}

@immutable
final class AppMapMessages {
  const AppMapMessages({
    this.missingConfiguration = 'Maps are not configured.',
  });

  final String missingConfiguration;
}

@immutable
final class MapSelectionState {
  const MapSelectionState({
    required this.status,
    this.selectedPoint,
    this.address,
    this.message,
  });

  const MapSelectionState.idle() : this(status: MapSelectionStatus.idle);

  final MapSelectionStatus status;
  final MapPoint? selectedPoint;
  final String? address;
  final String? message;

  MapSelectionState copyWith({
    MapSelectionStatus? status,
    MapPoint? selectedPoint,
    String? address,
    String? message,
  }) => MapSelectionState(
    status: status ?? this.status,
    selectedPoint: selectedPoint ?? this.selectedPoint,
    address: address ?? this.address,
    message: message,
  );
}

abstract interface class MapLocationService {
  Future<bool> isServiceEnabled();
  Future<MapPermissionState> checkPermission();
  Future<MapPermissionState> requestPermission();
  Future<MapPoint> currentLocation();
  Future<bool> openAppSettings();
  Future<bool> openLocationSettings();
}

abstract interface class MapAddressLookup {
  Future<String?> lookup(MapPoint point, {required String languageCode});
}

@immutable
final class AppMapConfig {
  const AppMapConfig({
    required this.apiKeyConfigured,
    required this.fallbackPoint,
    this.initialPoint,
    this.initialZoom = 15,
    this.allowSelection = true,
    this.showConfirmation = true,
    this.languageCode = 'en',
    this.locationTimeout = const Duration(seconds: 12),
  });

  final bool apiKeyConfigured;
  final MapPoint fallbackPoint;
  final MapPoint? initialPoint;
  final double initialZoom;
  final bool allowSelection;
  final bool showConfirmation;
  final String languageCode;
  final Duration locationTimeout;
}
