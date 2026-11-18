import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _EnterNumberScreenState extends ConsumerState<EnterNumberScreen>
    with SingleTickerProviderStateMixin {
  static const _demoNumber = '12855706'; // shown as 012 855 706

  // Pre-filled from the profile so `Edit` on the OTP screen keeps the number.
  late final _controller = TextEditingController(
    text: AppStrings.digits(
      groupPhone(ref.read(authProfileProvider).phone),
      ref.read(langProvider),
    ),
  );
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );
  Timer? _sendTimer;
  bool _sending = false;
  bool _showError = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _sendTimer?.cancel();
    _shake.dispose();
    _controller
      ..removeListener(_onChanged)
      ..dispose();
    super.dispose();
  }

  void _onChanged() {
    ref.read(authProfileProvider.notifier).setPhone(_controller.text);
    setState(() {
      // The prompt goes away as soon as the number becomes valid.
      if (_valid) _showError = false;
    });
  }

  bool get _valid => isValidPhone(cleanPhoneDigits(_controller.text));

  /// The button is never disabled. An empty / incomplete number gets a gentle
  /// shake, a heavy haptic and an inline prompt instead of silence.
  void _sendCode() {
    if (_sending) return;
    if (!_valid) {
      HapticFeedback.heavyImpact();
      setState(() => _showError = true);
      _shake.forward(from: 0);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _sending = true;
      _showError = false;
    });
    // A beat of "Sending code…" so it feels like a real dispatch.
    _sendTimer = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      ref
          .read(authProfileProvider.notifier)
          .setPhone(cleanPhoneDigits(_controller.text));
      setState(() => _sending = false);
      context.push(AppRoutes.otp);
    });
  }

  void _skip() {
    ref.read(authProfileProvider.notifier).continueAsGuest();
    context.push(AppRoutes.gps);
  }

  void _fillDemo() {
    HapticFeedback.selectionClick();
    final t = AppStrings.digits(
      formatPhoneInput('0$_demoNumber'),
      ref.read(langProvider),
    );
    _controller.value = TextEditingValue(
      text: t,
      selection: TextSelection.collapsed(offset: t.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Re-render what's typed in the new language's numerals.
    ref.listen(langProvider, (_, lang) {
      final t = AppStrings.digits(formatPhoneInput(_controller.text), lang);
      _controller.value = TextEditingValue(
        text: t,
        selection: TextSelection.collapsed(offset: t.length),
      );
    });
    // Tapping anywhere outside the field dismisses the keyboard.
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: OnboardingScaffold(
        buttonLabel: ref.tr('send_code'),
        buttonIcon: _sending ? null : Icons.arrow_forward_rounded,
        buttonChild: _sending
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      ref.tr('sending_code'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFamilyFallback: ['Noto Sans Khmer'],
                      ),
                    ),
                  ),
                ],
              )
            : null,
        // Always tappable (while sending it just ignores extra taps).
        onNext: _sendCode,
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
      ),
    );
  }

  Widget _card(TextTheme text) {
    final channel = ref.watch(authProfileProvider.select((p) => p.channel));
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
          AnimatedBuilder(
            animation: _shake,
            builder: (context, child) {
              final t = _shake.value;
              // Gentle damped sine: ~3 swings over 380 ms.
              final dx = math.sin(t * math.pi * 6) * 8 * (1 - t);
              return Transform.translate(offset: Offset(dx, 0), child: child);
            },
            child: Row(
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
          ),
          // Inline prompt (never a silent no-op).
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _showError
                ? Padding(
                    padding: const EdgeInsets.only(top: 10, left: 4, right: 4),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        ref.tr('phone_invalid'),
                        key: const ValueKey('phone-error'),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.red,
                          height: 1.4,
                          fontFamilyFallback: ['Noto Sans Khmer'],
                        ),
                      ),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
          const SizedBox(height: 10),
          // One-tap demo number.
          Align(
            alignment: Alignment.centerLeft,
            child: AppPressable(
              key: const ValueKey('demo-chip'),
              onTap: _fillDemo,
              haptic: AppHaptic.none,
              builder: (context, hovered, pressed) => AnimatedOpacity(
                duration: const Duration(milliseconds: 100),
                opacity: pressed ? 0.55 : 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: hovered ? AppColors.blueSoft : AppColors.blueTint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.bolt_rounded,
                        size: 14,
                        color: AppColors.blue,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          ref
                              .tr('demo_fill')
                              .replaceAll(
                                '{phone}',
                                ref.num('0${groupPhone(_demoNumber)}'),
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.blue,
                            fontFamilyFallback: ['Noto Sans Khmer'],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
                  onTap: () => ref
                      .read(authProfileProvider.notifier)
                      .setChannel(OtpChannel.sms),
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
                      .read(authProfileProvider.notifier)
                      .setChannel(OtpChannel.whatsapp),
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
