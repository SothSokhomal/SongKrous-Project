import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/animations/app_animations.dart';
import '../../core/animations/staggered_entrance.dart';
import '../../core/constants/app_state.dart';
import '../../core/router/app_routes.dart';
import '../../core/state/auth_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/phone_format.dart';
import '../../shared/widgets/app_interactive.dart';
import '../../shared/widgets/language_toggle.dart';
import '../../shared/widgets/liquid_glass.dart';
import 'widgets/otp_pin_input.dart';

enum _Phase { idle, verifying, success, error }

/// 02b_otp_verification — 6-digit code, simulated entirely on the device.
///
/// Demo rules: `000000` is rejected (shake + red), any other 6 digits verify.
/// 700 ms after arriving (and after every resend) a fake iOS notification
/// offers to AutoFill `123456`.
class OtpVerificationScreen extends ConsumerStatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen>
    with SingleTickerProviderStateMixin {
  static const _length = 6;
  static const _demoCode = '123456';
  static const _resendSeconds = 30;

  final _text = TextEditingController();
  final _focus = FocusNode();
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );

  _Phase _phase = _Phase.idle;
  String _lastText = '';
  int _secondsLeft = _resendSeconds;
  bool _bannerVisible = false;
  bool _incomplete = false;

  Timer? _countdown;
  Timer? _verifyTimer;
  Timer? _successTimer;
  Timer? _bannerShowTimer;
  Timer? _bannerHideTimer;
  Timer? _fillTimer;

  @override
  void initState() {
    super.initState();
    _text.addListener(_onText);
    _startCountdown();
    _scheduleBanner();
  }

  @override
  void dispose() {
    _countdown?.cancel();
    _verifyTimer?.cancel();
    _successTimer?.cancel();
    _bannerShowTimer?.cancel();
    _bannerHideTimer?.cancel();
    _fillTimer?.cancel();
    _text
      ..removeListener(_onText)
      ..dispose();
    _focus.dispose();
    _shake.dispose();
    super.dispose();
  }

  // ── Input ─────────────────────────────────────────────────────────────

  void _onText() {
    final t = _text.text;
    if (t == _lastText) return; // selection-only change
    _lastText = t;
    if (_phase == _Phase.verifying || _phase == _Phase.success) return;
    setState(() {
      _incomplete = false;
      if (_phase == _Phase.error && t.length < _length) _phase = _Phase.idle;
    });
    if (t.length == _length) _verify();
  }

  void _onCtaTap() {
    if (_text.text.length == _length) {
      _verify();
      return;
    }
    HapticFeedback.heavyImpact();
    setState(() => _incomplete = true);
    _shake.forward(from: 0);
    _focus.requestFocus();
  }

  void _verify() {
    if (_phase == _Phase.verifying || _phase == _Phase.success) return;
    if (_text.text.length != _length) return;
    HapticFeedback.lightImpact();
    setState(() => _phase = _Phase.verifying);
    _verifyTimer?.cancel();
    _verifyTimer = Timer(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      if (_text.text == '000000') {
        HapticFeedback.heavyImpact();
        _shake.forward(from: 0);
        setState(() => _phase = _Phase.error);
      } else {
        HapticFeedback.mediumImpact();
        ref.read(authProfileProvider.notifier).markLoggedIn();
        setState(() => _phase = _Phase.success);
        _successTimer = Timer(const Duration(milliseconds: 500), () {
          if (mounted) context.go(AppRoutes.gps);
        });
      }
    });
  }

  // ── Simulated delivery ────────────────────────────────────────────────

  void _startCountdown() {
    _countdown?.cancel();
    _secondsLeft = _resendSeconds;
    _countdown = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(
        () => _secondsLeft = (_secondsLeft - 1).clamp(0, _resendSeconds),
      );
      if (_secondsLeft == 0) t.cancel();
    });
  }

  void _scheduleBanner() {
    _bannerShowTimer?.cancel();
    _bannerHideTimer?.cancel();
    _bannerVisible = false;
    _bannerShowTimer = Timer(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      setState(() => _bannerVisible = true);
      _bannerHideTimer = Timer(const Duration(seconds: 6), () {
        if (mounted) setState(() => _bannerVisible = false);
      });
    });
  }

  /// Fresh code: clear the boxes, restart the 30 s timer, notify again.
  void _restart() {
    _verifyTimer?.cancel();
    _successTimer?.cancel();
    _fillTimer?.cancel();
    setState(() => _phase = _Phase.idle);
    _text.clear();
    _startCountdown();
    _scheduleBanner();
    _focus.requestFocus();
  }

  void _resend() {
    HapticFeedback.selectionClick();
    _restart();
  }

  void _switchChannel() {
    final next = ref.read(otpChannelProvider) == OtpChannel.sms
        ? OtpChannel.whatsapp
        : OtpChannel.sms;
    ref.read(authProfileProvider.notifier).setChannel(next);
    HapticFeedback.selectionClick();
    _restart();
  }

  void _autofill() {
    _bannerShowTimer?.cancel();
    _bannerHideTimer?.cancel();
    _fillTimer?.cancel();
    HapticFeedback.lightImpact();
    setState(() {
      _bannerVisible = false;
      _phase = _Phase.idle;
    });
    _text.clear();

    void set(String v) => _text.value = TextEditingValue(
      text: v,
      selection: TextSelection.collapsed(offset: v.length),
    );

    if (MediaQuery.disableAnimationsOf(context)) {
      set(_demoCode);
      return;
    }
    var i = 0;
    _fillTimer = Timer.periodic(const Duration(milliseconds: 50), (t) {
      if (!mounted) return t.cancel();
      i++;
      set(_demoCode.substring(0, i));
      if (i >= _length) t.cancel();
    });
  }

  // ── Navigation ────────────────────────────────────────────────────────

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.enterNumber);
    }
  }

  void _skip() {
    ref.read(authProfileProvider.notifier).continueAsGuest();
    context.go(AppRoutes.gps);
  }

  // ── Build ─────────────────────────────────────────────────────────────

  String _channelName(OtpChannel c) =>
      ref.tr(c == OtpChannel.sms ? 'channel_sms' : 'channel_whatsapp');

  String _clock(int s) => ref.num(
    '${(s ~/ 60).toString().padLeft(2, '0')}:'
    '${(s % 60).toString().padLeft(2, '0')}',
  );

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(langProvider);
    final channel = ref.watch(otpChannelProvider);
    final digits = ref.watch(userPhoneProvider);
    final media = MediaQuery.of(context);

    final boxState = switch (_phase) {
      _Phase.idle => OtpBoxState.idle,
      _Phase.verifying => OtpBoxState.verifying,
      _Phase.success => OtpBoxState.success,
      _Phase.error => OtpBoxState.error,
    };

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: LiquidAmbientCanvas(
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  _topBar(),
                  // One centred column, one thing at a time:
                  // icon → title → who we texted → the code → resend.
                  Expanded(
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(24, 4, 24, 4),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 400),
                          child: StaggerScope(
                            builder: (context, animation) => Column(
                              children: [
                                StaggeredEntrance(
                                  animation: animation,
                                  end: 0.6,
                                  child: _header(channel, digits),
                                ),
                                const SizedBox(height: 24),
                                StaggeredEntrance(
                                  animation: animation,
                                  begin: 0.2,
                                  end: 0.8,
                                  child: Column(
                                    children: [
                                      OtpPinInput(
                                        controller: _text,
                                        focusNode: _focus,
                                        state: boxState,
                                        shake: _shake,
                                        lang: lang,
                                        semanticLabel: ref.tr('otp_field'),
                                        digitLabel: (n) => ref
                                            .tr('otp_digit')
                                            .replaceAll('{n}', ref.num('$n')),
                                      ),
                                      _errorText(),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                StaggeredEntrance(
                                  animation: animation,
                                  begin: 0.4,
                                  child: _resendArea(channel),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  _bottom(),
                ],
              ),
            ),
            // Fake iOS notification. Sits below the top bar so it never
            // covers Back or the language switch.
            Positioned(
              top: media.padding.top + 60,
              left: 12,
              right: 12,
              child: _banner(channel),
            ),
          ],
        ),
      ),
    );
  }

  /// Just two controls: a round glass Back and the language switch.
  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: ref.tr('back'),
            child: AppPressable(
              key: const ValueKey('otp-back'),
              onTap: _back,
              haptic: AppHaptic.selection,
              builder: (context, hovered, pressed) => AnimatedScale(
                duration: const Duration(milliseconds: 120),
                scale: pressed ? 0.92 : 1,
                child: LiquidGlassContainer(
                  width: 40,
                  height: 40,
                  radius: 20,
                  useBlur: false,
                  hovered: hovered,
                  pressed: pressed,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.chevron_left_rounded,
                    size: 26,
                    color: AppColors.blueDeep,
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),
          const LanguageCompactToggle(),
        ],
      ),
    );
  }

  Widget _header(OtpChannel channel, String digits) {
    final isSms = channel == OtpChannel.sms;
    final shown = digits.isEmpty ? '12855706' : digits;
    final phone = ref.num('+855 ${groupPhone(shown)}');

    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
            ),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.blueDeep.withValues(alpha: 0.18),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            isSms ? Icons.sms_rounded : Icons.chat_rounded,
            size: 28,
            color: AppColors.blueDeep,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          ref.tr('otp_title'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
            height: 1.25,
            fontFamilyFallback: ['Noto Sans Khmer'],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          ref.tr('otp_sub').replaceAll('{channel}', _channelName(channel)),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14.5,
            height: 1.5,
            color: Color(0xFF475569),
            fontFamilyFallback: ['Noto Sans Khmer'],
          ),
        ),
        const SizedBox(height: 12),
        // The number and the way to change it, together on one line.
        LiquidGlassContainer(
          radius: 22,
          useBlur: false,
          padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  phone,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                    letterSpacing: 0.3,
                    fontFeatures: [FontFeature.tabularFigures()],
                    fontFamilyFallback: ['Noto Sans Khmer'],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              AppPressable(
                key: const ValueKey('otp-edit'),
                onTap: _back,
                haptic: AppHaptic.selection,
                builder: (context, hovered, pressed) => AnimatedOpacity(
                  duration: const Duration(milliseconds: 100),
                  opacity: pressed ? 0.55 : 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: hovered
                          ? const Color(0xFFDBEAFE)
                          : AppColors.blueTint,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.edit_rounded,
                          size: 14,
                          color: AppColors.blue,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          ref.tr('edit'),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.blue,
                            fontFamilyFallback: ['Noto Sans Khmer'],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _errorText() {
    final msg = _phase == _Phase.error
        ? ref.tr('otp_invalid')
        : (_incomplete ? ref.tr('otp_incomplete') : null);
    return AnimatedSize(
      duration: AppDurations.fast,
      curve: AppCurves.out,
      alignment: Alignment.topCenter,
      child: msg != null
          ? Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  msg,
                  key: const ValueKey('otp-error'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.red,
                    height: 1.4,
                    fontFamilyFallback: ['Noto Sans Khmer'],
                  ),
                ),
              ),
            )
          : const SizedBox(width: double.infinity),
    );
  }

  /// Quiet by design: a single line while waiting, then two plain text
  /// actions (primary: resend, secondary: switch channel).
  Widget _resendArea(OtpChannel channel) {
    final counting = _secondsLeft > 0;
    final other = channel == OtpChannel.sms
        ? OtpChannel.whatsapp
        : OtpChannel.sms;
    return AnimatedSwitcher(
      duration: AppDurations.medium,
      switchInCurve: AppCurves.out,
      transitionBuilder: (child, a) => FadeTransition(
        opacity: a,
        child: SizeTransition(sizeFactor: a, child: child),
      ),
      child: counting
          ? SizedBox(
              key: const ValueKey('otp-countdown'),
              width: double.infinity,
              child: Text(
                ref
                    .tr('otp_resend_in')
                    .replaceAll('{time}', _clock(_secondsLeft)),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.slate,
                  height: 1.4,
                  fontFeatures: [FontFeature.tabularFigures()],
                  fontFamilyFallback: ['Noto Sans Khmer'],
                ),
              ),
            )
          : Column(
              key: const ValueKey('otp-resend-options'),
              children: [
                _TextAction(
                  key: const ValueKey('otp-resend'),
                  icon: Icons.refresh_rounded,
                  label: ref
                      .tr('otp_resend_via')
                      .replaceAll('{channel}', _channelName(channel)),
                  color: AppColors.blue,
                  bold: true,
                  onTap: _resend,
                ),
                _TextAction(
                  key: const ValueKey('otp-switch'),
                  label: ref
                      .tr('otp_try_other')
                      .replaceAll('{channel}', _channelName(other)),
                  color: AppColors.slate,
                  onTap: _switchChannel,
                ),
              ],
            ),
    );
  }

  /// Primary action with the guest escape hatch right under it.
  Widget _bottom() {
    final (String label, Widget? lead) = switch (_phase) {
      _Phase.verifying => (
        ref.tr('otp_verifying'),
        const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            color: AppColors.white,
          ),
        ),
      ),
      _Phase.success => (ref.tr('otp_verified'), null),
      _ => (ref.tr('otp_verify'), null),
    };
    final busy = _phase == _Phase.verifying || _phase == _Phase.success;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppInteractiveButton(
                key: const ValueKey('otp-cta'),
                semanticLabel: label,
                // Never a dead button: an incomplete code gets a shake and a
                // prompt instead of silence.
                onPressed: busy ? () {} : _onCtaTap,
                haptic: busy ? AppHaptic.none : AppHaptic.light,
                child: AnimatedSwitcher(
                  duration: AppDurations.fast,
                  child: Row(
                    key: ValueKey(_phase),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (lead != null) ...[lead, const SizedBox(width: 10)],
                      Flexible(
                        child: Text(
                          label,
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
                  ),
                ),
              ),
              const SizedBox(height: 2),
              AppTextLink(
                key: const ValueKey('otp-skip'),
                label: ref.tr('skip'),
                onTap: _skip,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _banner(OtpChannel channel) {
    final show =
        _bannerVisible && (_phase == _Phase.idle || _phase == _Phase.error);
    final isSms = channel == OtpChannel.sms;
    final code = ref.num(_demoCode);
    return IgnorePointer(
      ignoring: !show,
      child: ExcludeSemantics(
        excluding: !show,
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutBack,
          offset: show ? Offset.zero : const Offset(0, -1.8),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 240),
            opacity: show ? 1 : 0,
            child: AppPressable(
              key: const ValueKey('otp-banner'),
              onTap: _autofill,
              haptic: AppHaptic.none,
              builder: (context, hovered, pressed) => AnimatedScale(
                duration: const Duration(milliseconds: 120),
                scale: pressed ? 0.98 : 1,
                child: LiquidGlassContainer(
                  radius: 24,
                  tint: LiquidTint.frostStrong,
                  hovered: hovered,
                  pressed: pressed,
                  padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: isSms
                              ? const Color(0xFF34C759)
                              : const Color(0xFF25D366),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isSms ? Icons.sms_rounded : Icons.chat_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              ref
                                  .tr('otp_banner_from')
                                  .replaceAll(
                                    '{channel}',
                                    _channelName(channel),
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                                fontFamilyFallback: ['Noto Sans Khmer'],
                              ),
                            ),
                            Text(
                              ref
                                  .tr('otp_banner_msg')
                                  .replaceAll('{code}', code),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF475569),
                                height: 1.3,
                                fontFamilyFallback: ['Noto Sans Khmer'],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.blueDeep,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          ref.tr('otp_autofill'),
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.white,
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
        ),
      ),
    );
  }
}

/// A plain, centred text action (no box) with a comfortable 44 pt target.
class _TextAction extends StatelessWidget {
  const _TextAction({
    super.key,
    required this.label,
    required this.color,
    required this.onTap,
    this.icon,
    this.bold = false,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;
  final IconData? icon;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: AppPressable(
        onTap: onTap,
        haptic: AppHaptic.selection,
        builder: (context, hovered, pressed) => AnimatedOpacity(
          duration: const Duration(milliseconds: 100),
          opacity: pressed ? 0.5 : 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: color),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
                        color: color,
                        decoration: hovered
                            ? TextDecoration.underline
                            : TextDecoration.none,
                        decorationColor: color,
                        fontFamilyFallback: const ['Noto Sans Khmer'],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
