import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/animations/app_animations.dart';
import '../../core/constants/app_state.dart';
import '../../core/router/app_routes.dart';
import '../../shared/widgets/onboarding_scaffold.dart';

/// 00_Splash screen — large logo card, language pill, `Next` button.
/// The logo and pill are `Hero`s that glide into 01_Onboarding.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppDurations.entrance,
  );

  // Logo: scale 0.82 → 1.0 + fade, easeOutBack over the full 700 ms.
  late final CurvedAnimation _logoCurve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutBack,
  );
  static final Tween<double> _logoScale = Tween(begin: 0.82, end: 1.0);

  // Button: slides up + fades in over the second half.
  late final CurvedAnimation _buttonCurve = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.45, 1.0, curve: AppCurves.out),
  );
  static final Tween<Offset> _buttonSlide = Tween(
    begin: const Offset(0, 0.5),
    end: Offset.zero,
  );

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
    _logoCurve.dispose();
    _buttonCurve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      logoSize: 210,
      body: const SizedBox.shrink(),
      buttonLabel: ref.tr('next'),
      onNext: () => context.push(AppRoutes.onboarding),
      decorateLogo: (logo) => AnimatedBuilder(
        animation: _logoCurve,
        child: logo, // static: never rebuilt by the ticks
        builder: (context, child) => Opacity(
          opacity: _logoCurve.value.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: _logoScale.transform(_logoCurve.value),
            child: child,
          ),
        ),
      ),
      decorateButton: (button) => SlideTransition(
        position: _buttonSlide.animate(_buttonCurve),
        child: FadeTransition(opacity: _buttonCurve, child: button),
      ),
    );
  }
}
