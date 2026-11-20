import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../constants/app_strings.dart';
import '../constants/phnom_penh_data.dart';
import '../constants/khans.dart';

/// Demo street address shown until reverse-geocoding is wired up — one
/// natural-language version per UI language (never mixed).
/// TODO(geocoding): resolve the real street address from GPS coordinates.
const String kDemoAddressEn = 'St. 598, Kilometer 6 Village';
const String kDemoAddressKm = 'ផ្លូវ ៥៩៨ ភូមិគីឡូម៉ែត្រ លេខ ៦';

class UserLocation {
  const UserLocation({
    required this.latLng,
    required this.khan,
    this.address,
    this.addressKm,
    this.gpsActive = false,
  });

  final LatLng latLng;
  final Khan khan;

  /// Street line in English / Khmer; null when the user picked a Khan
  /// manually (no GPS).
  final String? address;
  final String? addressKm;
  final bool gpsActive;

  bool _km(AppLang l) => l == AppLang.km;

  /// Large address line, in one language only.
  String headlineFor(AppLang l) =>
      _km(l) ? (addressKm ?? 'ខណ្ឌ${khan.km}') : (address ?? 'Khan ${khan.en}');

  /// `Khan Russey Keo` / `ខណ្ឌឫស្សីកែវ`
  String khanLineFor(AppLang l) =>
      _km(l) ? 'ខណ្ឌ${khan.km}' : 'Khan ${khan.en}';

  /// `11.5813° N, 104.9158° E` / `១១.៥៨១៣° ជើង, ១០៤.៩១៥៨° កើត`
  String coordinatesFor(AppLang l) {
    final lat = latLng.latitude, lng = latLng.longitude;
    final latS = lat.abs().toStringAsFixed(4);
    final lngS = lng.abs().toStringAsFixed(4);
    final n = _km(l) ? 'ជើង' : 'N', s = _km(l) ? 'ត្បូង' : 'S';
    final e = _km(l) ? 'កើត' : 'E', w = _km(l) ? 'លិច' : 'W';
    return AppStrings.digits(
      '$latS° ${lat >= 0 ? n : s}, $lngS° ${lng >= 0 ? e : w}',
      l,
    );
  }

  String get mapsLink =>
      'https://maps.google.com/?q=${latLng.latitude.toStringAsFixed(6)},${latLng.longitude.toStringAsFixed(6)}';

  /// Text for the clipboard / share sheet: address + map link.
  String shareTextFor(AppLang l) =>
      '${headlineFor(l)}, ${khanLineFor(l)}\n$mapsLink';

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
    addressKm: clearAddress ? null : addressKm,
    gpsActive: gpsActive ?? this.gpsActive,
  );
}

class LocationNotifier extends Notifier<UserLocation> {
  @override
  UserLocation build() => const UserLocation(
    latLng: PhnomPenh.center,
    khan: PhnomPenhKhans.russeyKeo,
    address: kDemoAddressEn,
    addressKm: kDemoAddressKm,
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
      if (!ref.mounted) return granted;
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
      if (ref.mounted && PhnomPenh.contains(pos.latitude, pos.longitude)) {
        state = state.copyWith(latLng: LatLng(pos.latitude, pos.longitude));
      }
    } catch (_) {
      // Keep the last known / fallback location.
    }
  }

  /// Settings switch. ON asks for permission (and may fail → stays off); OFF
  /// drops to manual Khan selection immediately. Home and Map watch
  /// [locationProvider], so they update live. Returns the resulting state.
  Future<bool> setEnabled(bool enabled) async {
    if (!enabled) {
      state = state.copyWith(gpsActive: false);
      return false;
    }
    return requestPermission();
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

/// Whether live device location is on (the Settings switch).
final locationEnabledProvider = Provider<bool>(
  (ref) => ref.watch(locationProvider.select((l) => l.gpsActive)),
);
