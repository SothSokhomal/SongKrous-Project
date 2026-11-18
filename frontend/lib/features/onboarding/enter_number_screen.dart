import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/animations/staggered_entrance.dart';
import '../../core/constants/app_state.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_interactive.dart';
import '../../shared/widgets/onboarding_scaffold.dart';

/// 02_enter the number — optional phone number for emergency callback/SMS.
/// Never blocking: `Next` works with an empty field and "Skip" is always there.
class EnterNumberScreen extends ConsumerStatefulWidget {
  const EnterNumberScreen({super.key});

  @override
  ConsumerState<EnterNumberScreen> createState() => _EnterNumberScreenState();
}

class _EnterNumberScreenState extends ConsumerState<EnterNumberScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    // TODO(backend): persist the number once the API exists.
    context.push(AppRoutes.gps);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return OnboardingScaffold(
      buttonLabel: ref.tr('next'),
      onNext: _next,
      footer: AppTextLink(label: ref.tr('skip'), onTap: _next),
      // Card fades in with a slight upward slide (250 ms).
      body: StaggerScope(
        duration: const Duration(milliseconds: 250),
        builder: (context, animation) => StaggeredEntrance(
          animation: animation,
          offset: 14,
          child: _card(text),
        ),
      ),
    );
  }

  Widget _card(TextTheme text) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(ref.tr('enter_phone'), style: text.titleLarge),
          const SizedBox(height: 4),
          Text(
            ref.tr('phone_reason'),
            style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.blueSoft,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Text(
                  '🇰🇭 ${ref.num('+855')}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.blueDeep,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppFocusInput(
                  radius: 28,
                  builder: (context, node) => TextField(
                    controller: _controller,
                    focusNode: node,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    maxLength: 11,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')),
                    ],
                    onSubmitted: (_) => _next(),
                    decoration:
                        AppFocusInput.bareDecoration(
                          counterText: '',
                          hintText: ref.tr('phone_hint'),
                        ).copyWith(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 16,
                          ),
                        ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
