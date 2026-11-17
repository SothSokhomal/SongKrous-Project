import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/animations/staggered_entrance.dart';
import '../../core/constants/app_state.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/main_shell.dart';
import 'situation.dart';
import 'widgets/breathing_ring.dart';
import 'widgets/urgent_banner.dart';

/// Safety · Your next steps — calm, situation-specific tips.
///
/// TODO(content): safety/medical wording is draft copy; have it reviewed by a
/// qualified professional (and a native Khmer speaker) before release.
class SafetyTipsScreen extends ConsumerWidget {
  const SafetyTipsScreen({super.key, required this.situation});

  final Situation situation;

  static const _tipIcons = [
    Icons.air_rounded,
    Icons.visibility_rounded,
    Icons.support_agent_rounded,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final keys = situation.tipKeys;

    // First tip stands alone; the remaining tips share one divided card.
    Widget tip(int i) => _TipRow(
      icon: _iconFor(keys[i], i),
      title: ref.tr('${keys[i]}_t'),
      body: ref.tr('${keys[i]}_b'),
      breathing: keys[i] == 'tip_breath',
    );

    return SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: StaggerScope(
            builder: (context, animation) => ListView(
              padding: EdgeInsets.fromLTRB(
                12,
                0,
                20,
                MainShell.navClearance(context),
              ),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => context.canPop()
                        ? context.pop()
                        : context.go(AppRoutes.safety),
                    icon: const Icon(Icons.chevron_left_rounded, size: 28),
                    label: Text(ref.tr('your_tips')),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.blue,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${ref.tr('for_situation')} · ${ref.tr(situation.labelKey).toUpperCase()}',
                        style: text.labelSmall?.copyWith(
                          color: AppColors.blue,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(ref.tr('tips_calm'), style: text.headlineMedium),
                      const SizedBox(height: 16),
                      StaggeredEntrance(
                        animation: animation,
                        begin: 0.0,
                        end: 0.5,
                        child: const UrgentBanner(bodyKey: 'urgent_body2'),
                      ),
                      const SizedBox(height: 20),
                      StaggeredEntrance(
                        animation: animation,
                        begin: 0.2,
                        end: 0.7,
                        child: _CardShell(child: tip(0)),
                      ),
                      const SizedBox(height: 14),
                      StaggeredEntrance(
                        animation: animation,
                        begin: 0.4,
                        end: 1.0,
                        child: _CardShell(
                          child: Column(
                            children: [
                              for (var i = 1; i < keys.length; i++) ...[
                                if (i > 1)
                                  const Divider(
                                    height: 24,
                                    color: AppColors.border,
                                  ),
                                tip(i),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconFor(String key, int i) => switch (key) {
    'tip_breath' => Icons.air_rounded,
    'tip_car_around' => Icons.visibility_rounded,
    'tip_trust' => Icons.support_agent_rounded,
    'tip_fire_out' => Icons.exit_to_app_rounded,
    'tip_fire_call' => Icons.phone_in_talk_rounded,
    'tip_fire_away' => Icons.social_distance_rounded,
    'tip_med_stay' => Icons.people_alt_rounded,
    'tip_med_call' => Icons.support_agent_rounded,
    _ => _tipIcons[i % _tipIcons.length],
  };
}

class _CardShell extends StatelessWidget {
  const _CardShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _TipRow extends StatelessWidget {
  const _TipRow({
    required this.icon,
    required this.title,
    required this.body,
    this.breathing = false,
  });

  final IconData icon;
  final String title;
  final String body;

  /// "Take a gentle breath": adds the 4-second breathing ring.
  final bool breathing;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final illustration = Container(
      width: 52,
      height: 52,
      decoration: const BoxDecoration(
        color: AppColors.blueSoft,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: AppColors.blue, size: 26),
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fixed 65 px slot so breathing and plain tips line up.
        SizedBox(
          width: 65,
          height: 65,
          child: Center(
            child: breathing
                ? BreathingRing(child: illustration)
                : illustration,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: text.titleMedium),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: text.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
