import 'package:flutter/material.dart';

import '../../core/constants/facilities.dart';
import '../../core/theme/app_colors.dart';

/// Vector category emblem used on home cards:
/// Medical = blue shield + red cross, Police = dark-blue shield + gold star,
/// Fire = red shield with yellow outline + flame.
class ShieldBadge extends StatelessWidget {
  const ShieldBadge({super.key, required this.type, this.size = 56});

  final FacilityType type;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size + 6,
      height: size + 6,
      child: Stack(
        alignment: Alignment.center,
        children: switch (type) {
          FacilityType.hospital => [
            Icon(Icons.shield_rounded, size: size, color: AppColors.blue),
            Container(
              width: size * 0.42,
              height: size * 0.42,
              decoration: const BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add_rounded,
                size: size * 0.36,
                color: AppColors.red,
              ),
            ),
          ],
          FacilityType.police => [
            Icon(Icons.shield_rounded, size: size, color: AppColors.blueDark),
            Icon(Icons.star_rounded, size: size * 0.46, color: AppColors.gold),
          ],
          FacilityType.fire => [
            Icon(Icons.shield_rounded, size: size + 6, color: AppColors.flame),
            Icon(Icons.shield_rounded, size: size - 2, color: AppColors.red),
            Icon(
              Icons.local_fire_department_rounded,
              size: size * 0.46,
              color: AppColors.flame,
            ),
          ],
        },
      ),
    );
  }
}
