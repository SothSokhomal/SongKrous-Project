import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import 'app_strings.dart';
import 'facilities.dart';

/// PROTOTYPE MOCK DATA — 100% local, no backend.
///
/// Names, phone numbers and coordinates were supplied with the design brief;
/// street waypoints are hand-placed approximations (not real routing).
/// TODO(backend): replace with the open-data + routing service and verify every
/// number before release.
abstract final class PhnomPenh {
  /// Default user GPS: St. 598, Khan Russey Keo.
  static const LatLng userDefault = LatLng(11.5813, 104.9158);
  static const LatLng center = userDefault;
  static const double zoom = 14.8;

  /// Rough bounding box — GPS fixes outside it are treated as out of area.
  static bool contains(double lat, double lng) =>
      lat > 11.40 && lat < 11.75 && lng > 104.70 && lng < 105.10;
}

abstract final class PhnomPenhData {
  static const List<Facility> facilities = [
    // ── Hospitals ────────────────────────────────────────────────────
    Facility(
      id: 'calmette',
      type: FacilityType.hospital,
      nameEn: 'Calmette Hospital',
      nameKm: 'មន្ទីរពេទ្យកាល់ម៉ែត',
      khanId: 'doun_penh',
      address: '34 Preah Monivong Blvd (93)',
      location: LatLng(11.5732, 104.9176),
      phone: '+855 23 426 948',
      altPhone: '+855 23 724 891',
      mockKm: 1.2,
      mockMinutes: 4,
      waypoints: [
        LatLng(11.5806, 104.9166),
        LatLng(11.5772, 104.9171),
        LatLng(11.5748, 104.9175),
      ],
    ),
    Facility(
      id: 'khmer_soviet',
      type: FacilityType.hospital,
      nameEn: 'Khmer-Soviet Friendship Hospital',
      nameKm: 'មន្ទីរពេទ្យមិត្តភាពខ្មែរ-សូវៀត',
      khanId: 'chamkar_mon',
      location: LatLng(11.5478, 104.9165),
      phone: '+855 23 217 524',
      mockKm: 3.8,
      mockMinutes: 11,
      waypoints: [
        LatLng(11.5765, 104.9161),
        LatLng(11.5660, 104.9167),
        LatLng(11.5545, 104.9168),
      ],
    ),
    Facility(
      id: 'sunrise_japan',
      type: FacilityType.hospital,
      nameEn: 'Sunrise Japan Hospital',
      nameKm: 'មន្ទីរពេទ្យសាន់រ៉ាយ ជប៉ុន',
      khanId: 'chroy_changvar',
      location: LatLng(11.5945, 104.9310),
      phone: '+855 23 260 152',
      mockKm: 2.9,
      mockMinutes: 8,
      waypoints: [
        LatLng(11.5822, 104.9212),
        LatLng(11.5868, 104.9262),
        LatLng(11.5928, 104.9298),
      ],
    ),

    // ── Police ───────────────────────────────────────────────────────
    Facility(
      id: 'pp_police_598',
      type: FacilityType.police,
      nameEn: 'Phnom Penh Police Station (St. 598)',
      nameKm: 'ប៉ុស្តិ៍នគរបាលភ្នំពេញ (ផ្លូវ ៥៩៨)',
      khanId: 'russey_keo',
      address: 'St. 598',
      location: LatLng(11.5846, 104.9130),
      phone: '012 855 706',
      mockKm: 0.4,
      mockMinutes: 2,
      waypoints: [LatLng(11.5818, 104.9149), LatLng(11.5832, 104.9138)],
    ),
    Facility(
      id: 'rk_police',
      type: FacilityType.police,
      nameEn: 'Khan Russey Keo Police Inspectorate',
      nameKm: 'អធិការដ្ឋាននគរបាលខណ្ឌឫស្សីកែវ',
      khanId: 'russey_keo',
      location: LatLng(11.5960, 104.9095),
      phone: EmergencyNumbers.police,
      mockKm: 1.5,
      mockMinutes: 5,
      waypoints: [
        LatLng(11.5848, 104.9148),
        LatLng(11.5895, 104.9124),
        LatLng(11.5938, 104.9104),
      ],
    ),
    Facility(
      id: 'dp_police',
      type: FacilityType.police,
      nameEn: 'Khan Daun Penh Police Station',
      nameKm: 'ប៉ុស្តិ៍នគរបាលខណ្ឌដូនពេញ',
      khanId: 'doun_penh',
      location: LatLng(11.5685, 104.9225),
      phone: EmergencyNumbers.police,
      mockKm: 2.6,
      mockMinutes: 8,
      waypoints: [
        LatLng(11.5800, 104.9175),
        LatLng(11.5742, 104.9199),
        LatLng(11.5702, 104.9217),
      ],
    ),

    // ── Fire ─────────────────────────────────────────────────────────
    Facility(
      id: 'rk_fire',
      type: FacilityType.fire,
      nameEn: 'Fire Police Office, Russey Keo',
      nameKm: 'ការិយាល័យនគរបាលពន្លត់អគ្គិភ័យ ឫស្សីកែវ',
      khanId: 'russey_keo',
      location: LatLng(11.5952, 104.9065),
      phone: EmergencyNumbers.fire,
      mockKm: 1.8,
      mockMinutes: 6,
      waypoints: [
        LatLng(11.5845, 104.9142),
        LatLng(11.5890, 104.9100),
        LatLng(11.5936, 104.9073),
      ],
    ),
    Facility(
      id: 'pp_central_fire',
      type: FacilityType.fire,
      nameEn: 'Phnom Penh Central Fire Dept',
      nameKm: 'នាយកដ្ឋានពន្លត់អគ្គិភ័យកណ្តាលភ្នំពេញ',
      khanId: 'doun_penh',
      location: LatLng(11.5690, 104.9142),
      phone: EmergencyNumbers.fire,
      mockKm: 2.4,
      mockMinutes: 7,
      waypoints: [
        LatLng(11.5790, 104.9156),
        LatLng(11.5742, 104.9150),
        LatLng(11.5706, 104.9144),
      ],
    ),
    Facility(
      id: 'koh_pich_fire',
      type: FacilityType.fire,
      nameEn: 'Koh Pich Fire Station',
      nameKm: 'ស្ថានីយ៍ពន្លត់អគ្គិភ័យកោះពេជ្រ',
      khanId: 'chamkar_mon',
      location: LatLng(11.5525, 104.9410),
      phone: EmergencyNumbers.fire,
      mockKm: 4.5,
      mockMinutes: 13,
      waypoints: [
        LatLng(11.5790, 104.9192),
        LatLng(11.5702, 104.9300),
        LatLng(11.5602, 104.9388),
        LatLng(11.5546, 104.9404),
      ],
    ),
  ];

  /// Default target of the SOS screen (Calmette, matches the design copy).
  static Facility get defaultSos => facilities.first;

  static Facility? byId(String? id) {
    if (id == null) return null;
    for (final f in facilities) {
      if (f.id == id) return f;
    }
    return null;
  }
}

const _distance = Distance();

/// Route line from [user] through the facility's mock street waypoints.
List<LatLng> routeFor(LatLng user, Facility f) => [
  user,
  ...f.waypoints,
  f.location,
];

double _routeKm(List<LatLng> pts) {
  var m = 0.0;
  for (var i = 1; i < pts.length; i++) {
    m += _distance.as(LengthUnit.Meter, pts[i - 1], pts[i]);
  }
  return m / 1000;
}

/// A facility with its road distance / ETA from a reference point.
class RankedFacility {
  const RankedFacility(this.facility, this.km, this.minutes);

  final Facility facility;
  final double km;
  final int minutes;

  String get kmLabel => '${km.toStringAsFixed(1)} km';

  /// `1.2 km · 4 min` (sheet rows)
  String get summary => '$kmLabel · $minutes min';

  /// `4 min • 1.2 km` (navigation pill)
  String get pillSummary => '$minutes min • $kmLabel';
}

/// Facilities sorted closest-first, optionally filtered by [type] and by a
/// free-text [query] (names in both languages + the type label).
///
/// At the default GPS position the brief's mock distances/ETAs are used; from
/// any other position they are recomputed along the route polyline.
List<RankedFacility> rankFacilities(
  LatLng from, {
  FacilityType? type,
  String query = '',
}) {
  final q = query.trim().toLowerCase();
  bool matches(Facility f) {
    if (q.isEmpty) return true;
    final typeKey = f.type.name;
    return f.nameEn.toLowerCase().contains(q) ||
        f.nameKm.contains(q) ||
        AppStrings.of(typeKey, AppLang.en).toLowerCase().contains(q) ||
        AppStrings.of(typeKey, AppLang.km).contains(q);
  }

  final atDefault =
      _distance.as(LengthUnit.Meter, from, PhnomPenh.userDefault) < 150;

  final list = [
    for (final f in PhnomPenhData.facilities)
      if ((type == null || f.type == type) && matches(f))
        if (atDefault)
          RankedFacility(f, f.mockKm, f.mockMinutes)
        else
          () {
            final km = _routeKm(routeFor(from, f));
            return RankedFacility(f, km, math.max(1, (km * 3.3).round()));
          }(),
  ]..sort((a, b) => a.km.compareTo(b.km));
  return list;
}
