import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/animations/staggered_entrance.dart';
import '../../core/animations/app_animations.dart';
import '../../core/constants/app_state.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/facilities.dart';
import '../../core/constants/phnom_penh_data.dart';
import '../../core/router/app_routes.dart';
import '../../core/state/location_state.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_interactive.dart';
import '../../shared/widgets/liquid_glass.dart';
import 'widgets/sos_pulse_rings.dart';

/// SOS Direct Call (Frame 1) — pulsing SOS, address readout, call buttons.
class SosCallScreen extends ConsumerWidget {
  const SosCallScreen({super.key, this.facility});

  /// Selected facility; falls back to the default emergency desk.
  final Facility? facility;

  Facility get _f => facility ?? PhnomPenhData.defaultSos;

  void _call(BuildContext context, WidgetRef ref, String number) =>
      context.push(AppRoutes.calling(_f.name(ref.read(langProvider)), number));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = _f;
    final lang = ref.watch(langProvider);
    final loc = ref.watch(locationProvider);
    final text = Theme.of(context).textTheme;

    return LiquidAmbientCanvas(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          leadingWidth: 120,
          leading: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 6),
              child: AppBackButton(
                label: ref.tr('back'),
                onTap: () => context.canPop()
                    ? context.pop()
                    : context.go(AppRoutes.home),
              ),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Tooltip(
                message: ref.tr('share'),
                child: AppPressFade(
                  semanticLabel: ref.tr('share'),
                  onTap: () => SharePlus.instance.share(
                    ShareParams(
                      text:
                          '${ref.tr('sos_sms_body')} ${loc.shareTextFor(lang)}',
                    ),
                  ),
                  child: const Icon(
                    Icons.ios_share_rounded,
                    color: AppColors.blue,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: StaggerScope(
                builder: (context, animation) => ListView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  children: [
                    Center(
                      child: LiveSosPulseRings(
                        size: 150,
                        child: _SosCore(
                          onTap: () => _call(context, ref, f.phone),
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        ref.tr('tap_sos'),
                        style: text.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    StaggeredEntrance(
                      animation: animation,
                      begin: 0.0,
                      end: 0.6,
                      child: Column(
                        children: [
                          Text(
                            f.name(lang),
                            textAlign: TextAlign.center,
                            style: text.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          _AddressBox(address: f.displayAddress(lang)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (f.altPhone != null) ...[
                      StaggeredEntrance(
                        animation: animation,
                        begin: 0.2,
                        end: 0.8,
                        child: _ActionButton(
                          icon: Icons.call_rounded,
                          label:
                              '${ref.tr('alt_desk')} · ${ref.num(f.altPhone!)}',
                          color: AppColors.blue,
                          onTap: () => _call(context, ref, f.altPhone!),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    StaggeredEntrance(
                      animation: animation,
                      begin: f.altPhone != null ? 0.3 : 0.2,
                      end: f.altPhone != null ? 0.9 : 0.8,
                      child: _ActionButton(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: ref.tr('send_message'),
                        color: AppColors.slate,
                        onTap: () => context.push(AppRoutes.chat, extra: f),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The solid red SOS circle (static child of the pulse rings).
/// Hover: grows to 1.05 with a brighter glow. Press: compresses to 0.93 and
/// fires a heavy haptic at touch-down — an unmistakable emergency confirmation.
class _SosCore extends ConsumerWidget {
  const _SosCore({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final word = ref.tr('sos_shortcut');
    final khmer = ref.watch(langProvider) == AppLang.km;
    return Semantics(
      button: true,
      label: word,
      child: AppPressable(
        onTap: onTap,
        haptic: AppHaptic.heavy,
        hapticOnDown: true,
        builder: (context, hovered, pressed) => AnimatedScale(
          duration: const Duration(milliseconds: 130),
          curve: AppCurves.out,
          scale: pressed
              ? 0.93
              : hovered
              ? 1.05
              : 1.0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 130),
            width: 150,
            height: 150,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: pressed
                  ? const Color(0xFFA8131D)
                  : hovered
                  ? const Color(0xFFE62E3B)
                  : AppColors.red,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.red.withValues(alpha: hovered ? 0.7 : 0.45),
                  blurRadius: hovered ? 38 : 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Text(
              word,
              style: TextStyle(
                color: AppColors.white,
                // The Khmer word is wider than "SOS": scale it to fit the circle.
                fontSize: khmer ? 36 : 48,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AddressBox extends ConsumerStatefulWidget {
  const _AddressBox({required this.address});

  final String address;

  @override
  ConsumerState<_AddressBox> createState() => _AddressBoxState();
}

class _AddressBoxState extends ConsumerState<_AddressBox> {
  bool _copied = false;
  Timer? _reset;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.address));
    if (!mounted) return;
    setState(() => _copied = true);
    _reset?.cancel();
    _reset = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  void dispose() {
    _reset?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LiquidGlassContainer(
      radius: 16,
      useBlur: false,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.fromLTRB(16, 4, 6, 4),
        // Soft green wash while "copied".
        color: _copied ? const Color(0x2616A34A) : Colors.transparent,
        child: Row(
          children: [
            Expanded(
              child: Text(
                '📍 ${widget.address}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            AppScaleButton(
              tooltip: ref.tr('copy'),
              semanticLabel: ref.tr('copy'),
              onTap: _copy,
              haptic: AppHaptic.medium,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, a) =>
                      ScaleTransition(scale: a, child: child),
                  child: Icon(
                    _copied ? Icons.check_rounded : Icons.copy_rounded,
                    key: ValueKey(_copied),
                    color: _copied ? AppColors.success : AppColors.blue,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppInteractiveButton(
      label: label,
      leadingIcon: icon,
      onPressed: onTap,
      colors: color == AppColors.blue
          ? AppButtonColors.glassFrostAccent(AppColors.blueDeep)
          : AppButtonColors.glassFrost,
      haptic: AppHaptic.medium,
      semanticLabel: label,
    );
  }
}
