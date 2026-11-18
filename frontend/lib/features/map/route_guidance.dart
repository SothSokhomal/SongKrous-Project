import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import '../../core/constants/app_strings.dart';

/// First turn-by-turn step of a (mock) route.
class RouteInstruction {
  const RouteInstruction(this.directionKey, this.meters);

  /// String key `dir_n` … `dir_nw`.
  final String directionKey;
  final int meters;

  /// `400m` / `៤០០ ម៉ែត្រ`
  String distanceLabel(AppLang l) => l == AppLang.km
      ? '${AppStrings.digits('$meters', l)} ${AppStrings.of('unit_m', l)}'
      : '${meters}m';
}

const _dirs = ['n', 'ne', 'e', 'se', 's', 'sw', 'w', 'nw'];
const _distance = Distance();

/// Compass direction + distance of the first stretch (up to two legs) of
/// [route]. Distances are rounded to 10 m and never below 100 m.
RouteInstruction firstInstruction(List<LatLng> route) {
  if (route.length < 2) return const RouteInstruction('dir_n', 100);
  final bearing = _distance.bearing(route[0], route[1]); // -180…180°, 0 = north
  final sector = (((bearing + 360) % 360) / 45).round() % 8;

  final end = math.min(2, route.length - 1);
  var m = 0.0;
  for (var i = 1; i <= end; i++) {
    m += _distance.as(LengthUnit.Meter, route[i - 1], route[i]);
  }
  final rounded = math.max(100, (m / 10).round() * 10);
  return RouteInstruction('dir_${_dirs[sector]}', rounded);
}
