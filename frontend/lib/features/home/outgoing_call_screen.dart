import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/animations/looping_animation.dart';
import '../../core/animations/tactile_scale_button.dart';
import '../../core/constants/app_state.dart';
import '../../core/constants/facilities.dart';
import '../../core/router/app_routes.dart';
import '../../core/state/location_state.dart';
import '../../core/theme/app_colors.dart';

class _Control {
  const _Control(this.icon, this.labelKey);
  final IconData icon;
  final String labelKey;
}

const _controls = [
  _Control(Icons.mic_off_rounded, 'mute'),
  _Control(Icons.dialpad_rounded, 'keypad'),
  _Control(Icons.volume_up_rounded, 'speaker'),
  _Control(Icons.person_add_alt_1_rounded, 'add_call'),
  _Control(Icons.videocam_rounded, 'facetime'),
  _Control(Icons.account_circle_rounded, 'contacts'),
];

/// Phone · Outgoing call — dark call UI that also hands off to the dialler.
class OutgoingCallScreen extends ConsumerStatefulWidget {
  const OutgoingCallScreen({
    super.key,
    required this.name,
    required this.number,
  });

  final String name;
  final String number;

  @override
  ConsumerState<OutgoingCallScreen> createState() => _OutgoingCallScreenState();
}

class _OutgoingCallScreenState extends ConsumerState<OutgoingCallScreen> {
  final Set<int> _active = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _dial());
  }

  Future<void> _dial() async {
    try {
      await launchUrl(Uri(scheme: 'tel', path: dialable(widget.number)));
    } catch (_) {
      // Simulator / device without telephony: stay on this screen.
    }
  }

  void _hangUp() =>
      context.canPop() ? context.pop() : context.go(AppRoutes.home);

  void _readLocation() {
    final loc = ref.read(locationProvider);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ref.tr('your_location')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.headline,
              style: Theme.of(ctx).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(loc.khanLine, style: Theme.of(ctx).textTheme.bodyLarge),
            const SizedBox(height: 6),
            Text(
              '${loc.latLng.latitude.toStringAsFixed(5)}, ${loc.latLng.longitude.toStringAsFixed(5)}',
              style: Theme.of(ctx).textTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(ref.tr('close')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final title = widget.name.isEmpty ? widget.number : widget.name;

    return Scaffold(
      backgroundColor: AppColors.callBackground,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const SizedBox(height: 48),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: text.headlineMedium?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _CallingLabel(
                    label: ref.tr('calling'),
                    style: text.bodyLarge?.copyWith(color: Colors.white60),
                  ),
                  const SizedBox(height: 40),
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                    childAspectRatio: 0.9,
                    children: [
                      for (var i = 0; i < _controls.length; i++)
                        _CallControl(
                          control: _controls[i],
                          label: ref.tr(_controls[i].labelKey),
                          active: _active.contains(i),
                          onTap: () => setState(() {
                            _active.contains(i)
                                ? _active.remove(i)
                                : _active.add(i);
                          }),
                        ),
                    ],
                  ),
                  const Spacer(),
                  ActionChip(
                    avatar: const Icon(
                      Icons.location_on_rounded,
                      size: 18,
                      color: AppColors.white,
                    ),
                    label: Text(ref.tr('read_location')),
                    labelStyle: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    backgroundColor: Colors.white.withValues(alpha: 0.14),
                    side: BorderSide.none,
                    shape: const StadiumBorder(),
                    onPressed: _readLocation,
                  ),
                  const SizedBox(height: 20),
                  Semantics(
                    button: true,
                    label: 'End call',
                    child: TactileScaleButton(
                      onTap: _hangUp,
                      pressedScale: 0.92,
                      child: const CircleAvatar(
                        radius: 36,
                        backgroundColor: AppColors.red,
                        child: Icon(
                          Icons.call_end_rounded,
                          color: AppColors.white,
                          size: 34,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CallControl extends StatelessWidget {
  const _CallControl({
    required this.control,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final _Control control;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      toggled: active,
      label: label,
      child: TactileScaleButton(
        onTap: onTap,
        pressedScale: 0.93,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active
                    ? AppColors.white
                    : Colors.white.withValues(alpha: 0.14),
              ),
              child: Icon(
                control.icon,
                size: 28,
                color: active ? AppColors.callBackground : AppColors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

/// `calling` + three dots that fade in a travelling wave (1.4 s loop). The
/// word itself is static; only the dots listen to the animation.
class _CallingLabel extends StatelessWidget {
  const _CallingLabel({required this.label, this.style});

  final String label;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    // The strings already end in "..." — strip it, the dots are animated.
    final base = label.replaceFirst(RegExp(r'[.\u2026]+$'), '');
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(base, style: style),
        LoopingAnimation(
          duration: const Duration(milliseconds: 1400),
          builder: (context, animation) =>
              _CallingDots(animation: animation, style: style),
        ),
      ],
    );
  }
}

class _CallingDots extends AnimatedWidget {
  const _CallingDots({required Animation<double> animation, this.style})
    : super(listenable: animation);

  final TextStyle? style;

  Animation<double> get _animation => listenable as Animation<double>;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++)
          Opacity(
            // Triangle wave, each dot a third of a cycle behind the last.
            opacity:
                0.25 +
                0.75 * (1 - (2 * ((_animation.value - i / 3) % 1.0) - 1).abs()),
            child: Text('.', style: style),
          ),
      ],
    );
  }
}
