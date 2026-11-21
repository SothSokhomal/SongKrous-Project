import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_interactive.dart';
import '../models/emergency_activity.dart';

Color activityColor(ActivityType type) => switch (type) {
  ActivityType.hospital => AppColors.red,
  ActivityType.police => AppColors.blue,
  ActivityType.fire => const Color(0xFFEA580C), // Orange for Fire Station
  ActivityType.sos => AppColors.red,
};

Color activityBadgeBg(ActivityType type) => switch (type) {
  ActivityType.hospital => const Color(0xFFFEE2E2),
  ActivityType.police => const Color(0xFFEFF6FF),
  ActivityType.fire => const Color(0xFFFFEDD5),
  ActivityType.sos => const Color(0xFFFEF2F2),
};

IconData activityIcon(ActivityType type) => switch (type) {
  ActivityType.hospital => Icons.local_hospital_rounded,
  ActivityType.police => Icons.local_police_rounded,
  ActivityType.fire => Icons.local_fire_department_rounded,
  ActivityType.sos => Icons.emergency_rounded,
};

class ActivityCard extends ConsumerWidget {
  const ActivityCard({
    super.key,
    required this.activity,
    required this.onTap,
  });

  final EmergencyActivity activity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = activityColor(activity.type);
    final badgeBg = activityBadgeBg(activity.type);
    final icon = activityIcon(activity.type);

    final (statusLabel, statusBg, statusFg) = switch (activity.status) {
      ActivityStatus.completed => (
        ref.tr('status_completed'),
        const Color(0xFFDCFCE7),
        const Color(0xFF16A34A),
      ),
      ActivityStatus.dispatched => (
        ref.tr('status_dispatched'),
        const Color(0xFFDBEAFE),
        const Color(0xFF1D4ED8),
      ),
      ActivityStatus.connected => (
        ref.tr('status_connected'),
        const Color(0xFFD1FAE5),
        const Color(0xFF059669),
      ),
    };

    return AppInteractiveCard(
      onTap: onTap,
      radius: 18,
      padding: const EdgeInsets.all(14),
      surface: Colors.white,
      hoverSurface: const Color(0xFFFAFCFF),
      borderWidth: 1,
      restBorder: const Color(0xFFE2E8F0),
      hoverBorder: color.withValues(alpha: 0.4),
      restShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
      semanticLabel: activity.title,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Service icon badge
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  activity.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                // Timestamp
                Text(
                  activity.timestamp,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                // Route summary
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 13,
                      color: AppColors.slate,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${activity.callerAddress} → ${activity.stationName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.slate,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2.5,
                  ),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statusLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: statusFg,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Right indicator + subtle chevron
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                activity.duration,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.blueDeep,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                activity.distance,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.slate,
                ),
              ),
              const SizedBox(height: 4),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.slateLight,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
