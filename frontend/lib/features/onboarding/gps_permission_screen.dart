import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/animations/app_animations.dart';
import '../../core/constants/app_state.dart';
import '../../core/router/app_routes.dart';
import '../../core/state/location_state.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_interactive.dart';
import '../../shared/widgets/songkrous_logo.dart';

/// 02_GPS_Permission — iOS-style alert over a blurred map backdrop.
/// Backdrop fades in (250 ms); the alert scales 1.06 → 1.0 + fades, like iOS.
class GpsPermissionScreen extends ConsumerStatefulWidget {
  const GpsPermissionScreen({super.key});

  @override
  ConsumerState<GpsPermissionScreen> createState() =>
      _GpsPermissionScreenState();
}

class _GpsPermissionScreenState extends ConsumerState<GpsPermissionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );
  // Backdrop: first ~250 ms.
  late final CurvedAnimation _backdrop = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.0, 0.55, curve: AppCurves.out),
  );
  // Alert: starts shortly after, ends with the controller.
  late final CurvedAnimation _alert = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.3, 1.0, curve: AppCurves.out),
  );
  static final Tween<double> _alertScale = Tween(begin: 1.06, end: 1.0);

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _backdrop.dispose();
    _alert.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _allow() async {
    await ref.read(locationProvider.notifier).requestPermission();
    if (mounted) context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          FadeTransition(
            opacity: _backdrop,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: const CustomPaint(painter: _FakeMapPainter()),
                ),
                Container(color: Colors.black.withValues(alpha: 0.25)),
              ],
            ),
          ),
          Center(
            child: FadeTransition(
              opacity: _alert,
              child: ScaleTransition(
                scale: _alertScale.animate(_alert),
                child: _alertCard(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _alertCard(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 300),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                children: [
                  const SongkrousLogo(size: 56),
                  const SizedBox(height: 14),
                  Text(
                    ref.tr('gps_dialog_title'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    ref.tr('gps_dialog_body'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(fontSize: 13),
                  ),
                ],
              ),
            ),
            _DialogButton(
              label: ref.tr('allow_while'),
              bold: true,
              onTap: _allow,
            ),
            _DialogButton(label: ref.tr('allow_once'), onTap: _allow),
            _DialogButton(
              label: ref.tr('dont_allow'),
              // Still enters the app; Home offers the Khan selector.
              onTap: () => context.go(AppRoutes.home),
            ),
          ],
        ),
      ),
    );
  }
}

/// iOS-style alert action row: `#F1F5F9` highlight on hover and press (100 ms)
/// plus a haptic tap.
class _DialogButton extends StatelessWidget {
  const _DialogButton({
    required this.label,
    required this.onTap,
    this.bold = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: AppPressable(
        onTap: onTap,
        haptic: AppHaptic.light,
        builder: (context, hovered, pressed) => AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: pressed
                ? const Color(0xFFE2E8F0)
                : hovered
                ? const Color(0xFFF1F5F9)
                : Colors.transparent,
            border: const Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.blue,
              fontSize: 16,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              fontFamilyFallback: const ['Noto Sans Khmer'],
            ),
          ),
        ),
      ),
    );
  }
}

/// Light-blue pseudo-map (roads + blocks) so the backdrop needs no network.
class _FakeMapPainter extends CustomPainter {
  const _FakeMapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFDCE9FB),
    );

    final block = Paint()..color = const Color(0xFFC9DDF7);
    for (var x = 0.0; x < size.width; x += 90) {
      for (var y = 0.0; y < size.height; y += 110) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x + 14, y + 14, 62, 82),
            const Radius.circular(8),
          ),
          block,
        );
      }
    }
    final road = Paint()
      ..color = AppColors.white
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(0, size.height * 0.3),
      Offset(size.width, size.height * 0.55),
      road,
    );
    canvas.drawLine(
      Offset(size.width * 0.25, 0),
      Offset(size.width * 0.6, size.height),
      road,
    );
    final river = Paint()
      ..color = const Color(0xFF9EC5F5)
      ..strokeWidth = 34
      ..style = PaintingStyle.stroke;
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.85, 0)
        ..quadraticBezierTo(
          size.width * 0.6,
          size.height * 0.5,
          size.width,
          size.height,
        ),
      river,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
