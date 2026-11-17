import 'package:flutter/material.dart';

/// Situations the user can pick on the "What happened?" screen.
enum Situation {
  car(
    icon: Icons.car_crash_rounded,
    labelKey: 'sit_car',
    subKey: 'sit_car_sub',
    tipKeys: ['tip_breath', 'tip_car_around', 'tip_trust'],
  ),
  fire(
    icon: Icons.local_fire_department_rounded,
    labelKey: 'sit_fire',
    subKey: 'sit_fire_sub',
    tipKeys: ['tip_fire_out', 'tip_fire_call', 'tip_fire_away'],
  ),
  medical(
    icon: Icons.medical_services_rounded,
    labelKey: 'sit_medical',
    subKey: 'sit_medical_sub',
    tipKeys: ['tip_breath', 'tip_med_stay', 'tip_med_call'],
  );

  const Situation({
    required this.icon,
    required this.labelKey,
    required this.subKey,
    required this.tipKeys,
  });

  final IconData icon;
  final String labelKey;
  final String subKey;

  /// Prefixes of `<prefix>_t` (title) / `<prefix>_b` (body) string keys.
  final List<String> tipKeys;

  static Situation fromName(String? name) =>
      Situation.values.firstWhere((s) => s.name == name, orElse: () => car);
}
