import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Tags for categorizing safety and first aid situations.
enum SafetyTag { all, medical, trauma, rescue }

/// A single step in an emergency or first-aid protocol.
class SafetyStep {
  final int number;
  final String titleKey;
  final String bodyKey;
  final bool isCallStep;

  const SafetyStep({
    required this.number,
    required this.titleKey,
    required this.bodyKey,
    this.isCallStep = false,
  });
}

/// First aid and emergency situations with authoritative step-by-step guidance.
enum Situation {
  bleeding(
    icon: Icons.water_drop_rounded,
    labelKey: 'cat_bleeding',
    subKey: 'cat_bleeding_sub',
    overviewKey: 'cat_bleeding_over',
    tag: SafetyTag.trauma,
    iconColor: AppColors.red,
    iconBgColor: AppColors.redSoft,
    steps: [
      SafetyStep(
        number: 1,
        titleKey: 'bleed_s1_t',
        bodyKey: 'bleed_s1_b',
      ),
      SafetyStep(
        number: 2,
        titleKey: 'bleed_s2_t',
        bodyKey: 'bleed_s2_b',
        isCallStep: true,
      ),
      SafetyStep(
        number: 3,
        titleKey: 'bleed_s3_t',
        bodyKey: 'bleed_s3_b',
      ),
      SafetyStep(
        number: 4,
        titleKey: 'bleed_s4_t',
        bodyKey: 'bleed_s4_b',
      ),
    ],
    tipKeys: ['bleed_s1', 'bleed_s2', 'bleed_s3', 'bleed_s4'],
  ),
  cpr(
    icon: Icons.favorite_rounded,
    labelKey: 'cat_cpr',
    subKey: 'cat_cpr_sub',
    overviewKey: 'cat_cpr_over',
    tag: SafetyTag.medical,
    iconColor: AppColors.blue,
    iconBgColor: AppColors.blueSoft,
    steps: [
      SafetyStep(number: 1, titleKey: 'cpr_s1_t', bodyKey: 'cpr_s1_b'),
      SafetyStep(number: 2, titleKey: 'cpr_s2_t', bodyKey: 'cpr_s2_b'),
      SafetyStep(
        number: 3,
        titleKey: 'cpr_s3_t',
        bodyKey: 'cpr_s3_b',
        isCallStep: true,
      ),
      SafetyStep(number: 4, titleKey: 'cpr_s4_t', bodyKey: 'cpr_s4_b'),
      SafetyStep(number: 5, titleKey: 'cpr_s5_t', bodyKey: 'cpr_s5_b'),
      SafetyStep(number: 6, titleKey: 'cpr_s6_t', bodyKey: 'cpr_s6_b'),
      SafetyStep(number: 7, titleKey: 'cpr_s7_t', bodyKey: 'cpr_s7_b'),
    ],
    tipKeys: [
      'cpr_s1',
      'cpr_s2',
      'cpr_s3',
      'cpr_s4',
      'cpr_s5',
      'cpr_s6',
      'cpr_s7',
    ],
  ),
  drowning(
    icon: Icons.pool_rounded,
    labelKey: 'cat_drowning',
    subKey: 'cat_drowning_sub',
    overviewKey: 'cat_drowning_over',
    tag: SafetyTag.rescue,
    iconColor: Color(0xFF0284C7),
    iconBgColor: Color(0xFFE0F2FE),
    steps: [
      SafetyStep(
        number: 1,
        titleKey: 'drown_s1_t',
        bodyKey: 'drown_s1_b',
        isCallStep: true,
      ),
      SafetyStep(number: 2, titleKey: 'drown_s2_t', bodyKey: 'drown_s2_b'),
      SafetyStep(number: 3, titleKey: 'drown_s3_t', bodyKey: 'drown_s3_b'),
      SafetyStep(number: 4, titleKey: 'drown_s4_t', bodyKey: 'drown_s4_b'),
      SafetyStep(number: 5, titleKey: 'drown_s5_t', bodyKey: 'drown_s5_b'),
    ],
    tipKeys: ['drown_s1', 'drown_s2', 'drown_s3', 'drown_s4', 'drown_s5'],
  ),
  fainting(
    icon: Icons.airline_seat_flat_rounded,
    labelKey: 'cat_fainting',
    subKey: 'cat_fainting_sub',
    overviewKey: 'cat_fainting_over',
    tag: SafetyTag.medical,
    iconColor: Color(0xFF6366F1),
    iconBgColor: Color(0xFFEEF2FF),
    steps: [
      SafetyStep(number: 1, titleKey: 'faint_s1_t', bodyKey: 'faint_s1_b'),
      SafetyStep(number: 2, titleKey: 'faint_s2_t', bodyKey: 'faint_s2_b'),
      SafetyStep(number: 3, titleKey: 'faint_s3_t', bodyKey: 'faint_s3_b'),
      SafetyStep(
        number: 4,
        titleKey: 'faint_s4_t',
        bodyKey: 'faint_s4_b',
        isCallStep: true,
      ),
      SafetyStep(number: 5, titleKey: 'faint_s5_t', bodyKey: 'faint_s5_b'),
    ],
    tipKeys: ['faint_s1', 'faint_s2', 'faint_s3', 'faint_s4', 'faint_s5'],
  ),
  fire(
    icon: Icons.local_fire_department_rounded,
    labelKey: 'sit_fire',
    subKey: 'sit_fire_sub',
    overviewKey: 'cat_fire_over',
    tag: SafetyTag.rescue,
    iconColor: AppColors.red,
    iconBgColor: Color(0xFFFFF1F2),
    steps: [
      SafetyStep(number: 1, titleKey: 'fire_s1_t', bodyKey: 'fire_s1_b'),
      SafetyStep(number: 2, titleKey: 'fire_s2_t', bodyKey: 'fire_s2_b'),
      SafetyStep(number: 3, titleKey: 'fire_s3_t', bodyKey: 'fire_s3_b'),
      SafetyStep(
        number: 4,
        titleKey: 'fire_s4_t',
        bodyKey: 'fire_s4_b',
        isCallStep: true,
      ),
    ],
    tipKeys: ['tip_fire_out', 'tip_fire_call', 'tip_fire_away'],
  ),
  car(
    icon: Icons.car_crash_rounded,
    labelKey: 'sit_car',
    subKey: 'sit_car_sub',
    overviewKey: 'cat_car_over',
    tag: SafetyTag.trauma,
    iconColor: AppColors.blueDeep,
    iconBgColor: Color(0xFFF1F5F9),
    steps: [
      SafetyStep(number: 1, titleKey: 'car_s1_t', bodyKey: 'car_s1_b'),
      SafetyStep(
        number: 2,
        titleKey: 'car_s2_t',
        bodyKey: 'car_s2_b',
        isCallStep: true,
      ),
      SafetyStep(number: 3, titleKey: 'car_s3_t', bodyKey: 'car_s3_b'),
      SafetyStep(number: 4, titleKey: 'car_s4_t', bodyKey: 'car_s4_b'),
    ],
    tipKeys: ['tip_breath', 'tip_car_around', 'tip_trust'],
  ),
  medical(
    icon: Icons.medical_services_rounded,
    labelKey: 'sit_medical',
    subKey: 'sit_medical_sub',
    overviewKey: 'cat_bleeding_over',
    tag: SafetyTag.trauma,
    iconColor: AppColors.red,
    iconBgColor: AppColors.redSoft,
    steps: [
      SafetyStep(
        number: 1,
        titleKey: 'bleed_s1_t',
        bodyKey: 'bleed_s1_b',
      ),
      SafetyStep(
        number: 2,
        titleKey: 'bleed_s2_t',
        bodyKey: 'bleed_s2_b',
        isCallStep: true,
      ),
      SafetyStep(
        number: 3,
        titleKey: 'bleed_s3_t',
        bodyKey: 'bleed_s3_b',
      ),
      SafetyStep(
        number: 4,
        titleKey: 'bleed_s4_t',
        bodyKey: 'bleed_s4_b',
      ),
    ],
    tipKeys: ['tip_breath', 'tip_med_stay', 'tip_med_call'],
  );

  const Situation({
    required this.icon,
    required this.labelKey,
    required this.subKey,
    required this.overviewKey,
    required this.tag,
    required this.iconColor,
    required this.iconBgColor,
    required this.steps,
    required this.tipKeys,
  });

  final IconData icon;
  final String labelKey;
  final String subKey;
  final String overviewKey;
  final SafetyTag tag;
  final Color iconColor;
  final Color iconBgColor;
  final List<SafetyStep> steps;

  /// Legacy prefixes of `<prefix>_t` / `<prefix>_b` strings.
  final List<String> tipKeys;

  /// The primary 6 categories to show on the Category Hub.
  static List<Situation> get categories => [
    bleeding,
    cpr,
    drowning,
    fainting,
    fire,
    car,
  ];

  static Situation fromName(String? name) {
    if (name == 'medical') return medical;
    return Situation.values.firstWhere(
      (s) => s.name == name,
      orElse: () => bleeding,
    );
  }
}
