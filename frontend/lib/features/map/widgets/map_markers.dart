import 'package:flutter/material.dart';

import '../../../core/animations/app_animations.dart';
import '../../../core/animations/pulsing_beacon.dart';
import '../../../core/constants/facilities.dart';
import '../../../core/theme/app_colors.dart';

Color facilityColor(FacilityType t) => switch (t) {
  FacilityType.hospital => AppColors.red,
  FacilityType.police => AppColors.blue,
  FacilityType.fire => AppColors.red,
};

IconData facilityIcon(FacilityType t) => switch (t) {
  FacilityType.hospital => Icons.add_rounded,
  FacilityType.police => Icons.shield_rounded,
  FacilityType.fire => Icons.local_fire_department_rounded,
};

/// The user's position: white-ringed blue dot with a live pulsing ripple.
class UserBeacon extends StatelessWidget {
  const UserBeacon({super.key});

  @override
  Widget build(BuildContext context) {
    return const LiveBeacon(color: AppColors.blue, size: 20, child: _UserDot());
  }
}

class _UserDot extends StatelessWidget {
  const _UserDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: AppColors.blue,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.white, width: 3),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
    );
  }
}

/// White circular pin with a coloured border and an inline label. Scales up
/// 1.0 → 1.2 (`AnimatedScale`) when [selected].
class FacilityPin extends StatelessWidget {
  const FacilityPin({
    super.key,
    required this.facility,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final Facility facility;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = facilityColor(facility.type);
    return Semantics(
      button: true,
      selected: selected,
      label: facility.nameEn,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedScale(
          scale: selected ? 1.2 : 1.0,
          duration: AppDurations.fast,
          curve: AppCurves.out,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 3),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 6),
                  ],
                ),
                child: Icon(
                  facilityIcon(facility.type),
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 3),
                  ],
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: color,
                    fontFamilyFallback: const ['Noto Sans Khmer'],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
