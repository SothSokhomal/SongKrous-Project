import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../constants/phnom_penh_data.dart';
import '../constants/khans.dart';

/// Demo street address shown until reverse-geocoding is wired up.
/// TODO(geocoding): resolve the real street address from GPS coordinates.
const String kDemoAddress = 'St. 598, ភូមិ គីឡូម៉ែត លេខ 6';

class UserLocation {
  const UserLocation({
    required this.latLng,
    required this.khan,
    this.address,
    this.gpsActive = false,
  });

  final LatLng latLng;
  final Khan khan;

  /// Street line; null when the user picked a Khan manually (no GPS).
  final String? address;
  final bool gpsActive;

  /// `ខណ្ឌឫស្សីកែវ • Khan Russey Keo`
  String get khanLine => 'ខណ្ឌ${khan.km} • Khan ${khan.en}';

  String get headline => address ?? 'ខណ្ឌ${khan.km}';

  String get mapsLink =>
      'https://maps.google.com/?q=${latLng.latitude.toStringAsFixed(6)},${latLng.longitude.toStringAsFixed(6)}';

  /// Text for the clipboard / SMS: address + GPS coordinates.
  String get shareText => '$headline, $khanLine\n$mapsLink';

  UserLocation copyWith({
    LatLng? latLng,
    Khan? khan,
    String? address,
    bool clearAddress = false,
    bool? gpsActive,
  }) => UserLocation(
    latLng: latLng ?? this.latLng,
    khan: khan ?? this.khan,
    address: clearAddress ? null : (address ?? this.address),
    gpsActive: gpsActive ?? this.gpsActive,
  );
}

class LocationNotifier extends Notifier<UserLocation> {
  @override
  UserLocation build() => const UserLocation(
    latLng: PhnomPenh.center,
    khan: PhnomPenhKhans.russeyKeo,
    address: kDemoAddress,
  );

  /// Asks for location permission. Returns true when granted.
  /// The GPS fix itself is fetched in the background so the UI never waits.
  Future<bool> requestPermission() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return false;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      final granted =
          perm == LocationPermission.whileInUse ||
          perm == LocationPermission.always;
      state = state.copyWith(gpsActive: granted);
      if (granted) unawaited(_refreshPosition());
      return granted;
    } catch (_) {
      return false;
    }
  }

  Future<void> _refreshPosition() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      // The app serves Phnom Penh; ignore fixes outside the service area
      // (e.g. a simulator parked elsewhere) and keep the fallback point.
      if (PhnomPenh.contains(pos.latitude, pos.longitude)) {
        state = state.copyWith(latLng: LatLng(pos.latitude, pos.longitude));
      }
    } catch (_) {
      // Keep the last known / fallback location.
    }
  }

  /// Manual fallback when GPS is denied.
  void setKhan(Khan khan) => state = UserLocation(
    latLng: khan.center,
    khan: khan,
    address: null,
    gpsActive: false,
  );
}

final locationProvider = NotifierProvider<LocationNotifier, UserLocation>(
  LocationNotifier.new,
);
