import 'dart:async';

import 'package:flutter/foundation.dart';

import 'map_models.dart';

final class MapSelectionController extends ChangeNotifier {
  MapSelectionController({
    required this.config,
    required this.locationService,
    this.addressLookup,
  });

  final AppMapConfig config;
  final MapLocationService locationService;
  final MapAddressLookup? addressLookup;

  MapSelectionState _state = const MapSelectionState.idle();
  MapSelectionState get state => _state;
  bool _disposed = false;
  bool _locating = false;
  int _selectionGeneration = 0;

  Future<void> initialize() async {
    if (_disposed) return;
    if (!config.apiKeyConfigured) {
      _emit(const MapSelectionState(status: MapSelectionStatus.missingApiKey));
      return;
    }
    final initial = config.initialPoint;
    final point = initial != null && initial.isValid
        ? initial
        : config.fallbackPoint;
    await select(point, resolveAddress: initial != null);
  }

  Future<void> select(MapPoint point, {bool resolveAddress = true}) async {
    if (_disposed || !point.isValid) return;
    final generation = ++_selectionGeneration;
    _emit(
      MapSelectionState(
        status: resolveAddress && addressLookup != null
            ? MapSelectionStatus.resolvingAddress
            : MapSelectionStatus.ready,
        selectedPoint: point,
      ),
    );
    final lookup = addressLookup;
    if (!resolveAddress || lookup == null) return;
    try {
      final address = await lookup
          .lookup(point, languageCode: config.languageCode)
          .timeout(config.locationTimeout);
      if (_disposed || generation != _selectionGeneration) return;
      _emit(
        MapSelectionState(
          status: MapSelectionStatus.ready,
          selectedPoint: point,
          address: address,
        ),
      );
    } catch (_) {
      if (_disposed || generation != _selectionGeneration) return;
      _emit(
        MapSelectionState(
          status: MapSelectionStatus.ready,
          selectedPoint: point,
        ),
      );
    }
  }

  Future<void> goToCurrentLocation() async {
    if (_disposed || _locating) return;
    _locating = true;
    _emit(state.copyWith(status: MapSelectionStatus.locating));
    try {
      if (!await locationService.isServiceEnabled().timeout(
        config.locationTimeout,
      )) {
        _emit(state.copyWith(status: MapSelectionStatus.servicesDisabled));
        return;
      }
      var permission = await locationService.checkPermission().timeout(
        config.locationTimeout,
      );
      if (permission == MapPermissionState.undetermined ||
          permission == MapPermissionState.denied) {
        permission = await locationService.requestPermission().timeout(
          config.locationTimeout,
        );
      }
      if (permission == MapPermissionState.permanentlyDenied) {
        _emit(
          state.copyWith(
            status: MapSelectionStatus.permissionPermanentlyDenied,
          ),
        );
        return;
      }
      if (permission != MapPermissionState.granted) {
        _emit(state.copyWith(status: MapSelectionStatus.permissionDenied));
        return;
      }
      final point = await locationService.currentLocation().timeout(
        config.locationTimeout,
      );
      if (!point.isValid) {
        _emit(state.copyWith(status: MapSelectionStatus.locationUnavailable));
        return;
      }
      await select(point);
    } on TimeoutException {
      _emit(state.copyWith(status: MapSelectionStatus.locationUnavailable));
    } catch (_) {
      _emit(state.copyWith(status: MapSelectionStatus.locationUnavailable));
    } finally {
      _locating = false;
    }
  }

  Future<void> openRequiredSettings() async {
    if (_disposed) return;
    if (state.status == MapSelectionStatus.servicesDisabled) {
      await locationService.openLocationSettings();
    } else if (state.status == MapSelectionStatus.permissionPermanentlyDenied) {
      await locationService.openAppSettings();
    }
  }

  void _emit(MapSelectionState value) {
    if (_disposed) return;
    _state = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _selectionGeneration++;
    _state = state.copyWith(status: MapSelectionStatus.disposed);
    super.dispose();
  }
}
