import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/animations/app_animations.dart';
import '../../core/constants/app_state.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_interactive.dart';
import '../../shared/widgets/liquid_glass.dart';
import '../../shared/widgets/main_shell.dart';
import 'models/emergency_activity.dart';
import 'widgets/activity_card.dart';

enum _ActivityFilter {
  all,
  hospital,
  police,
  fire,
  sos,
}

/// Recent Activity screen listing user's past emergency calls & SOS dispatches
/// with Grab-inspired clean cards and quick filters.
class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  _ActivityFilter _filter = _ActivityFilter.all;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    final filtered = kSampleActivities.where((a) {
      return switch (_filter) {
        _ActivityFilter.all => true,
        _ActivityFilter.hospital => a.type == ActivityType.hospital,
        _ActivityFilter.police => a.type == ActivityType.police,
        _ActivityFilter.fire => a.type == ActivityType.fire,
        _ActivityFilter.sos => a.type == ActivityType.sos,
      };
    }).toList();

    return LiquidAmbientCanvas(
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            MainShell.navClearance(context),
          ),
          children: [
            // Header
            Text(
              ref.tr('recent_activity'),
              style: text.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.blueDeep,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              ref.tr('activity_subtitle'),
              style: text.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),

            // Quick filter chips (wrapped for clean responsive layout)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FilterChip(
                  label: ref.tr('all'),
                  selected: _filter == _ActivityFilter.all,
                  onTap: () => setState(() => _filter = _ActivityFilter.all),
                ),
                _FilterChip(
                  label: ref.tr('filter_hospital'),
                  icon: Icons.local_hospital_rounded,
                  selected: _filter == _ActivityFilter.hospital,
                  onTap: () => setState(() => _filter = _ActivityFilter.hospital),
                ),
                _FilterChip(
                  label: ref.tr('filter_police'),
                  icon: Icons.local_police_rounded,
                  selected: _filter == _ActivityFilter.police,
                  onTap: () => setState(() => _filter = _ActivityFilter.police),
                ),
                _FilterChip(
                  label: ref.tr('filter_fire'),
                  icon: Icons.local_fire_department_rounded,
                  selected: _filter == _ActivityFilter.fire,
                  onTap: () => setState(() => _filter = _ActivityFilter.fire),
                ),
                _FilterChip(
                  label: ref.tr('filter_sos'),
                  icon: Icons.emergency_rounded,
                  selected: _filter == _ActivityFilter.sos,
                  onTap: () => setState(() => _filter = _ActivityFilter.sos),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // List of Activity Cards
            if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    ref.tr('no_activity'),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              )
            else
              for (final item in filtered) ...[
                ActivityCard(
                  activity: item,
                  onTap: () => context.push(
                    AppRoutes.activityDetail,
                    extra: item,
                  ),
                ),
                const SizedBox(height: 12),
              ],
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      onTap: onTap,
      haptic: AppHaptic.selection,
      builder: (context, hovered, pressed) => AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.blueDeep
              : (hovered ? const Color(0xFFEFF4FF) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.blueDeep : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
          boxShadow: [
            if (selected)
              BoxShadow(
                color: AppColors.blueDeep.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 15,
                color: selected ? Colors.white : AppColors.slate,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: selected ? Colors.white : AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
