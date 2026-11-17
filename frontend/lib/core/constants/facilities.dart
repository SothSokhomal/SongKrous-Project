import 'package:latlong2/latlong.dart';

import 'app_strings.dart';
import 'khans.dart';

/// Emergency facility models. The (mock) data lives in `phnom_penh_data.dart`.
enum FacilityType { hospital, police, fire }

/// Category a user can pick on Home / the map (hospital = "Medical").
typedef EmergencyCategory = FacilityType;

abstract final class EmergencyNumbers {
  static const String police = '117';
  static const String fire = '118';
  static const String ambulance = '119';

  static String forType(FacilityType t) => switch (t) {
    FacilityType.hospital => ambulance,
    FacilityType.police => police,
    FacilityType.fire => fire,
  };
}

class Facility {
  const Facility({
    required this.id,
    required this.type,
    required this.nameEn,
    required this.nameKm,
    required this.khanId,
    required this.location,
    required this.phone,
    required this.waypoints,
    required this.mockKm,
    required this.mockMinutes,
    this.address,
    this.altPhone,
  });

  final String id;
  final FacilityType type;
  final String nameEn;
  final String nameKm;
  final String khanId;
  final LatLng location;

  /// Street address (Latin), if known.
  final String? address;

  /// Primary dial number, e.g. `+855 23 426 948` or `117`.
  final String phone;
  final String? altPhone;

  /// MOCK street waypoints between the user's default GPS and [location]
  /// (exclusive of both ends) used to draw a believable route line.
  final List<LatLng> waypoints;

  /// MOCK road distance / drive time from the default GPS position.
  final double mockKm;
  final int mockMinutes;

  Khan get khan => PhnomPenhKhans.byId(khanId);

  String name(AppLang lang) => lang == AppLang.km ? nameKm : nameEn;

  /// e.g. `34 Preah Monivong Blvd (93), ខណ្ឌដូនពេញ`
  String displayAddress() => address != null
      ? '$address, ខណ្ឌ${khan.km}'
      : 'ខណ្ឌ${khan.km} • Khan ${khan.en}';
}

/// Strips spaces so a display number can be passed to `tel:`.
String dialable(String number) => number.replaceAll(RegExp(r'[^0-9+]'), '');
