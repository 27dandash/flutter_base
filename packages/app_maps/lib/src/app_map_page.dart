import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'map_models.dart';
import 'map_selection_controller.dart';

final class GeolocatorMapLocationService implements MapLocationService {
  const GeolocatorMapLocationService();

  @override
  Future<MapPermissionState> checkPermission() async =>
      _mapPermission(await Geolocator.checkPermission());

  @override
  Future<MapPoint> currentLocation() async {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 12),
      ),
    );
    return MapPoint(position.latitude, position.longitude);
  }

  @override
  Future<bool> isServiceEnabled() => Geolocator.isLocationServiceEnabled();

  @override
  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  @override
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  @override
  Future<MapPermissionState> requestPermission() async =>
      _mapPermission(await Geolocator.requestPermission());

  static MapPermissionState _mapPermission(LocationPermission permission) =>
      switch (permission) {
        LocationPermission.always ||
        LocationPermission.whileInUse => MapPermissionState.granted,
        LocationPermission.denied => MapPermissionState.denied,
        LocationPermission.deniedForever =>
          MapPermissionState.permanentlyDenied,
        LocationPermission.unableToDetermine => MapPermissionState.undetermined,
      };
}

final class AppMapPage extends StatefulWidget {
  const AppMapPage({
    super.key,
    required this.config,
    required this.title,
    required this.confirmLabel,
    this.locationService = const GeolocatorMapLocationService(),
    this.addressLookup,
    this.messages = const AppMapMessages(),
  });

  final AppMapConfig config;
  final String title;
  final String confirmLabel;
  final MapLocationService locationService;
  final MapAddressLookup? addressLookup;
  final AppMapMessages messages;

  @override
  State<AppMapPage> createState() => _AppMapPageState();
}

final class _AppMapPageState extends State<AppMapPage>
    with WidgetsBindingObserver {
  late final MapSelectionController _selection;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selection = MapSelectionController(
      config: widget.config,
      locationService: widget.locationService,
      addressLookup: widget.addressLookup,
    )..addListener(_onStateChanged);
    unawaited(_selection.initialize());
  }

  void _onStateChanged() {
    if (!mounted) return;
    final point = _selection.state.selectedPoint;
    if (point != null) {
      unawaited(
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(LatLng(point.latitude, point.longitude)),
        ),
      );
    }
    setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        (_selection.state.status == MapSelectionStatus.servicesDisabled ||
            _selection.state.status ==
                MapSelectionStatus.permissionPermanentlyDenied)) {
      // Recheck only after the user explicitly left for Settings.
      unawaited(_selection.goToCurrentLocation());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _selection
      ..removeListener(_onStateChanged)
      ..dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = _selection.state;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: state.status == MapSelectionStatus.missingApiKey
          ? Semantics(
              liveRegion: true,
              label: widget.messages.missingConfiguration,
              child: Center(child: Text(widget.messages.missingConfiguration)),
            )
          : _buildMap(state),
      bottomNavigationBar: widget.config.showConfirmation
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton(
                  onPressed: state.selectedPoint == null
                      ? null
                      : () => Navigator.pop(context, state.selectedPoint),
                  child: Text(widget.confirmLabel),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildMap(MapSelectionState state) {
    final point = state.selectedPoint ?? widget.config.fallbackPoint;
    final statusMessage = widget.messages.messageForStatus(state.status);
    final showStatusBanner = statusMessage.isNotEmpty;
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(point.latitude, point.longitude),
            zoom: widget.config.initialZoom,
          ),
          onMapCreated: (controller) => _mapController = controller,
          onTap: widget.config.allowSelection
              ? (value) =>
                    _selection.select(MapPoint(value.latitude, value.longitude))
              : null,
          markers: {
            Marker(
              markerId: const MarkerId('selected-location'),
              position: LatLng(point.latitude, point.longitude),
              draggable: widget.config.allowSelection,
              onDragEnd: (value) =>
                  _selection.select(MapPoint(value.latitude, value.longitude)),
            ),
          },
          myLocationButtonEnabled: false,
          myLocationEnabled: false,
        ),
        PositionedDirectional(
          end: 12,
          bottom: 12,
          child: FloatingActionButton.small(
            heroTag: null,
            onPressed: state.status == MapSelectionStatus.locating
                ? null
                : _selection.goToCurrentLocation,
            child: state.status == MapSelectionStatus.locating
                ? const CircularProgressIndicator()
                : const Icon(Icons.my_location),
          ),
        ),
        if (state.address != null)
          PositionedDirectional(
            start: 12,
            end: 12,
            top: 12,
            child: Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(state.address!),
              ),
            ),
          ),
        if (showStatusBanner)
          PositionedDirectional(
            start: 12,
            end: 72,
            bottom: 12,
            child: _LocationStatusBanner(
              message: statusMessage,
              retryLabel: widget.messages.retry,
              settingsLabel: widget.messages.openSettings,
              showSettingsAction: widget.messages.showsSettingsAction(
                state.status,
              ),
              onRetry: _selection.goToCurrentLocation,
              onOpenSettings: _selection.openRequiredSettings,
            ),
          ),
      ],
    );
  }
}

final class _LocationStatusBanner extends StatelessWidget {
  const _LocationStatusBanner({
    required this.message,
    required this.retryLabel,
    required this.settingsLabel,
    required this.showSettingsAction,
    required this.onRetry,
    required this.onOpenSettings,
  });

  final String message;
  final String retryLabel;
  final String settingsLabel;
  final bool showSettingsAction;
  final VoidCallback onRetry;
  final Future<void> Function() onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      liveRegion: true,
      label: message,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.start),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  TextButton(onPressed: onRetry, child: Text(retryLabel)),
                  if (showSettingsAction)
                    FilledButton.tonal(
                      onPressed: onOpenSettings,
                      child: Text(settingsLabel),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
