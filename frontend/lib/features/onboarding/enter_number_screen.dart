import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/animations/staggered_entrance.dart';
import '../../core/constants/app_state.dart';
import '../../core/constants/app_strings.dart';
import '../../core/router/app_routes.dart';
import '../../core/state/auth_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/phone_format.dart';
import '../../shared/widgets/app_interactive.dart';
import '../../shared/widgets/liquid_glass.dart';
import '../../shared/widgets/onboarding_scaffold.dart';

/// 02_enter the number — phone number + delivery channel (SMS / WhatsApp) for
/// the verification code.
///
/// Verification is optional: "Skip for now" always goes straight to the GPS
/// permission so someone in danger is never blocked.
class EnterNumberScreen extends ConsumerStatefulWidget {
  const EnterNumberScreen({super.key});

  @override
  ConsumerState<EnterNumberScreen> createState() => _EnterNumberScreenState();
}

class _EnterNumberScreenState extends ConsumerState<EnterNumberScreen> {
  // Pre-filled from the provider so `Edit` on the OTP screen keeps the number.
  late final _controller = TextEditingController(
    text: AppStrings.digits(
      groupPhone(ref.read(userPhoneProvider)),
      ref.read(langProvider),
    ),
  );

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onChanged)
      ..dispose();
    super.dispose();
  }

  void _onChanged() {
    ref.read(userPhoneProvider.notifier).set(_controller.text);
    setState(() {}); // CTA enabled state
  }

  bool get _valid => isValidPhone(cleanPhoneDigits(_controller.text));

  void _sendCode() {
    if (!_valid) return;
    context.push(AppRoutes.otp);
  }

  void _skip() => context.push(AppRoutes.gps);

  @override
  Widget build(BuildContext context) {
    // Re-render what's typed in the new language's numerals.
    ref.listen(langProvider, (_, lang) {
      final t = AppStrings.digits(
        groupPhone(cleanPhoneDigits(_controller.text)),
        lang,
      );
      _controller.value = TextEditingValue(
        text: t,
        selection: TextSelection.collapsed(offset: t.length),
      );
    });
    return OnboardingScaffold(
      buttonLabel: ref.tr('send_code'),
      buttonIcon: Icons.arrow_forward_rounded,
      onNext: _valid ? _sendCode : null,
      footer: AppTextLink(label: ref.tr('skip'), onTap: _skip),
      // Card fades in with a slight upward slide (250 ms).
      body: StaggerScope(
        duration: const Duration(milliseconds: 250),
        builder: (context, animation) => StaggeredEntrance(
          animation: animation,
          offset: 14,
          child: _card(Theme.of(context).textTheme),
        ),
      ),
    );
  }

  Widget _card(TextTheme text) {
    final channel = ref.watch(otpChannelProvider);
    return LiquidGlassContainer(
      radius: 20,
      tint: LiquidTint.frostStrong,
      useBlur: false,
      padding: const EdgeInsets.all(20),
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
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.blueDeep,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppFocusInput(
                  radius: 28,
                  glass: true,
                  glassBlur: false,
                  builder: (context, node) => TextField(
                    controller: _controller,
                    focusNode: node,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [
                      AutofillHints.telephoneNumberNational,
                    ],
                    inputFormatters: [
                      PhoneInputFormatter(ref.watch(langProvider)),
                    ],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                      letterSpacing: 0.4,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                    onSubmitted: (_) => _sendCode(),
                    decoration:
                        AppFocusInput.bareDecoration(
                          counterText: '',
                          hintText: ref.num(ref.tr('phone_hint')),
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
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ChannelCard(
                  key: const ValueKey('channel-sms'),
                  icon: Icons.sms_rounded,
                  label: ref.tr('ch_sms_card'),
                  selected: channel == OtpChannel.sms,
                  onTap: () =>
                      ref.read(otpChannelProvider.notifier).set(OtpChannel.sms),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ChannelCard(
                  key: const ValueKey('channel-whatsapp'),
                  icon: Icons.chat_rounded,
                  label: ref.tr('ch_wa_card'),
                  selected: channel == OtpChannel.whatsapp,
                  onTap: () => ref
                      .read(otpChannelProvider.notifier)
                      .set(OtpChannel.whatsapp),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One SMS / WhatsApp option: frosted glass, `#0F3D91` ring + soft blue tint
/// when selected.
class _ChannelCard extends StatelessWidget {
  const _ChannelCard({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.blueDeep : AppColors.slate;
    return AppInteractiveCard(
      glass: selected ? LiquidTint.frostStrong : LiquidTint.frost,
      selected: selected,
      radius: 16,
      semanticLabel: label,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: fg,
                fontFamilyFallback: const ['Noto Sans Khmer'],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
