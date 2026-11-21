import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/animations/app_animations.dart';
import '../../core/animations/staggered_entrance.dart';
import '../../core/constants/app_state.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_interactive.dart';
import '../../shared/widgets/liquid_glass.dart';
import '../../shared/widgets/main_shell.dart';
import 'situation.dart';
import 'widgets/breathing_ring.dart';
import 'widgets/urgent_banner.dart';

/// Safety · Interactive Step-by-Step First Aid & Emergency Guide.
class SafetyTipsScreen extends ConsumerStatefulWidget {
  const SafetyTipsScreen({super.key, required this.situation});

  final Situation situation;

  @override
  ConsumerState<SafetyTipsScreen> createState() => _SafetyTipsScreenState();
}

class _SafetyTipsScreenState extends ConsumerState<SafetyTipsScreen> {
  final Set<int> _completedSteps = {};

  void _toggleStep(int stepNumber) {
    AppHaptics.fire(AppHaptic.selection);
    setState(() {
      if (_completedSteps.contains(stepNumber)) {
        _completedSteps.remove(stepNumber);
      } else {
        _completedSteps.add(stepNumber);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final situation = widget.situation;
    final steps = situation.steps;
    final totalSteps = steps.length;
    final doneSteps = _completedSteps.length;

    return LiquidAmbientCanvas(
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: StaggerScope(
              builder: (context, animation) => ListView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  4,
                  16,
                  MainShell.navClearance(context),
                ),
                children: [
                  // Back button to category hub
                  Align(
                    alignment: Alignment.centerLeft,
                    child: AppBackButton(
                      label: ref.tr('your_tips'),
                      onTap: () => context.canPop()
                          ? context.pop()
                          : context.go(AppRoutes.safety),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Category Title
                  Text(
                    ref.tr(situation.labelKey),
                    style: text.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Urgent help banner (pinned at top)
                  StaggeredEntrance(
                    animation: animation,
                    begin: 0.0,
                    end: 0.4,
                    child: const UrgentBanner(bodyKey: 'urgent_body2'),
                  ),
                  const SizedBox(height: 16),

                  // Overview card
                  StaggeredEntrance(
                    animation: animation,
                    begin: 0.1,
                    end: 0.5,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: situation.iconBgColor.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: situation.iconColor.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            situation.icon,
                            color: situation.iconColor,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              ref.tr(situation.overviewKey),
                              style: text.bodyMedium?.copyWith(
                                color: AppColors.textPrimary,
                                height: 1.4,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Step progress header
                  StaggeredEntrance(
                    animation: animation,
                    begin: 0.2,
                    end: 0.6,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          ref
                              .tr('step_progress')
                              .replaceAll('{done}', '$doneSteps')
                              .replaceAll('{total}', '$totalSteps'),
                          style: text.titleSmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (doneSteps == totalSteps && totalSteps > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: Color(0xFF16A34A),
                                  size: 14,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Complete',
                                  style: TextStyle(
                                    color: Color(0xFF16A34A),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Numbered Step Cards
                  for (var i = 0; i < steps.length; i++) ...[
                    StaggeredEntrance(
                      animation: animation,
                      begin: 0.2 + (i * 0.08).clamp(0.0, 0.5),
                      end: (0.6 + (i * 0.08)).clamp(0.0, 1.0),
                      child: _StepCard(
                        step: steps[i],
                        situation: situation,
                        isDone: _completedSteps.contains(steps[i].number),
                        onToggle: () => _toggleStep(steps[i].number),
                        onCall: () => context.push(AppRoutes.sosCall),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// An individual numbered step card in the vertical sequence.
class _StepCard extends ConsumerWidget {
  const _StepCard({
    required this.step,
    required this.situation,
    required this.isDone,
    required this.onToggle,
    required this.onCall,
  });

  final SafetyStep step;
  final Situation situation;
  final bool isDone;
  final VoidCallback onToggle;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;

    return AppInteractiveCard(
      onTap: onToggle,
      semanticLabel: 'Step ${step.number}: ${ref.tr(step.titleKey)}',
      radius: 20,
      glass: LiquidTint.frost,
      restBorder: isDone ? const Color(0xFF86EFAC) : null,
      padding: const EdgeInsets.all(16),
      builder: (context, hovered, pressed) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step pill badge & Checkbox toggle
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isDone
                      ? const Color(0xFFDCFCE7)
                      : situation.iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  ref.tr('step_n_label').replaceAll('{n}', '${step.number}'),
                  style: TextStyle(
                    color: isDone
                        ? const Color(0xFF16A34A)
                        : situation.iconColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              // Checkbox indicator (with calming breathing ring on Step 1 of Car)
              Builder(
                builder: (context) {
                  final checkbox = AnimatedContainer(
                    duration: AppDurations.fast,
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: isDone
                          ? const Color(0xFF16A34A)
                          : Colors.white.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDone
                            ? const Color(0xFF16A34A)
                            : AppColors.border,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: isDone
                          ? const Icon(
                              Icons.check_rounded,
                              size: 18,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  );

                  if (situation == Situation.car && step.number == 1) {
                    return BreathingRing(
                      size: 26,
                      color: situation.iconColor,
                      child: checkbox,
                    );
                  }
                  return checkbox;
                },
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Step Heading
          Text(
            ref.tr(step.titleKey),
            style: text.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              decoration: isDone ? TextDecoration.lineThrough : null,
              decorationColor: AppColors.textSecondary,
              color: isDone
                  ? AppColors.textSecondary
                  : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),

          // Actionable Instructions
          Text(
            ref.tr(step.bodyKey),
            style: text.bodyMedium?.copyWith(
              color: isDone
                  ? AppColors.textSecondary.withValues(alpha: 0.7)
                  : AppColors.textSecondary,
              height: 1.45,
            ),
          ),

          // If step involves emergency calling, provide direct call action
          if (step.isCallStep) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: AppInteractiveButton(
                label: ref.tr('call_emergency_now'),
                leadingIcon: Icons.phone_in_talk_rounded,
                colors: AppButtonColors.glassRed,
                height: 44,
                onPressed: onCall,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
