import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/animations/app_animations.dart';
import '../../core/animations/tactile_scale_button.dart';
import '../../core/constants/app_state.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/main_shell.dart';
import 'situation.dart';
import 'widgets/urgent_banner.dart';

/// Safety · What happened? — pick a situation, describe feelings (optional).
/// NOTE: the free-text answer is not analysed yet; tips depend on the
/// selected situation only.
class SafetyInputScreen extends ConsumerStatefulWidget {
  const SafetyInputScreen({super.key});

  @override
  ConsumerState<SafetyInputScreen> createState() => _SafetyInputScreenState();
}

class _SafetyInputScreenState extends ConsumerState<SafetyInputScreen> {
  Situation _selected = Situation.car;
  final _feeling = TextEditingController();

  @override
  void dispose() {
    _feeling.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              20,
              8,
              20,
              MainShell.navClearance(context),
            ),
            children: [
              Row(
                children: [
                  Text(
                    ref.tr('safety'),
                    style: text.titleMedium?.copyWith(color: AppColors.blue),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.verified_user_rounded,
                    color: AppColors.blue,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(ref.tr('what_happened'), style: text.headlineMedium),
              const SizedBox(height: 6),
              Text(
                ref.tr('what_happened_sub'),
                style: text.bodyLarge?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              const UrgentBanner(),
              const SizedBox(height: 24),
              Text(ref.tr('which_situation'), style: text.titleMedium),
              const SizedBox(height: 12),
              for (final s in Situation.values) ...[
                _SituationCard(
                  situation: s,
                  selected: s == _selected,
                  onTap: () => setState(() => _selected = s),
                ),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 14),
              Text(ref.tr('how_feeling'), style: text.titleMedium),
              const SizedBox(height: 12),
              TextField(
                controller: _feeling,
                minLines: 3,
                maxLines: 5,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: ref.tr('feeling_hint'),
                  hintStyle: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 20),
              TactileScaleButton(
                child: SizedBox(
                  height: 56,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.blueDeep,
                      shape: const StadiumBorder(),
                    ),
                    onPressed: () => context.push(
                      '${AppRoutes.safetyTips}?situation=${_selected.name}',
                    ),
                    child: Text(ref.tr('show_tips')),
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

class _SituationCard extends ConsumerWidget {
  const _SituationCard({
    required this.situation,
    required this.selected,
    required this.onTap,
  });

  final Situation situation;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      selected: selected,
      child: TactileScaleButton(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          curve: AppCurves.out,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.blue : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Check scales in when selected, empty radio scales in otherwise.
              AnimatedSwitcher(
                duration: AppDurations.fast,
                switchInCurve: Curves.easeOutBack,
                transitionBuilder: (child, animation) =>
                    ScaleTransition(scale: animation, child: child),
                child: Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  key: ValueKey(selected),
                  color: selected ? AppColors.blue : AppColors.slate,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ref.tr(situation.labelKey), style: text.titleMedium),
                    Text(
                      ref.tr(situation.subKey),
                      style: text.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _Illustration(situation: situation),
            ],
          ),
        ),
      ),
    );
  }
}

class _Illustration extends StatelessWidget {
  const _Illustration({required this.situation});

  final Situation situation;

  @override
  Widget build(BuildContext context) {
    final isFire = situation == Situation.fire;
    final color = isFire ? AppColors.red : AppColors.blue;
    return SizedBox(
      width: 60,
      height: 56,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(situation.icon, color: color, size: 28),
          ),
          if (situation == Situation.car)
            const Positioned(
              right: 0,
              top: -2,
              child: Icon(
                Icons.warning_rounded,
                color: AppColors.gold,
                size: 24,
              ),
            ),
        ],
      ),
    );
  }
}
