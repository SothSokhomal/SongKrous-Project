import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/facilities.dart';

/// The category the map is focused on.
///
/// * `null` → **State A**: clean map (pins only, no sheet / category bar).
/// * non-null → **State B**: nearby sheet + category bar + route line.
///
/// Home's Medical / Police / Fire cards set this before switching to the map
/// tab; the bottom-bar "Nearby Map" tab and the banner's "View Map" leave it
/// `null`.
class SelectedMapTargetNotifier extends Notifier<EmergencyCategory?> {
  @override
  EmergencyCategory? build() => null;

  void set(EmergencyCategory? category) => state = category;
}

final selectedMapTargetProvider =
    NotifierProvider<SelectedMapTargetNotifier, EmergencyCategory?>(
      SelectedMapTargetNotifier.new,
    );

/// The facility the route currently leads to (id). Only meaningful while
/// [selectedMapTargetProvider] is non-null; falls back to the nearest one.
class SelectedFacilityNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? id) => state = id;
}

final selectedFacilityProvider =
    NotifierProvider<SelectedFacilityNotifier, String?>(
      SelectedFacilityNotifier.new,
    );

/// State transitions for the map, so every entry point behaves the same.
extension MapTargetActions on WidgetRef {
  /// Enter State B for [category] (route goes to the nearest facility), or
  /// return to State A with `null`.
  void selectMapCategory(EmergencyCategory? category) {
    read(selectedFacilityProvider.notifier).set(null);
    read(selectedMapTargetProvider.notifier).set(category);
  }

  /// Enter State B routed to a specific [facility] (e.g. a tapped pin).
  void selectMapFacility(Facility facility) {
    read(selectedFacilityProvider.notifier).set(facility.id);
    read(selectedMapTargetProvider.notifier).set(facility.type);
  }
}
