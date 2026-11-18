import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'app_interactive.dart';
import 'language_toggle.dart';
import 'liquid_glass.dart';
import 'songkrous_logo.dart';

/// Hero tags shared by splash → onboarding → enter-number so the logo glides
/// between layouts while the language pill stays anchored.
abstract final class OnboardingHero {
  static const logo = 'songkrous_logo';
  static const langPill = 'lang_pill';
}

/// Convex-bottom header clipper (deep-blue arc).
class _ArcClipper extends CustomClipper<Path> {
  const _ArcClipper();

  @override
  Path getClip(Size size) {
    const dip = 36.0;
    return Path()
      ..lineTo(0, size.height - dip)
      ..quadraticBezierTo(
        size.width / 2,
        size.height + dip,
        size.width,
        size.height - dip,
      )
      ..lineTo(size.width, 0)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Shared frame of the onboarding screens: curved deep-blue header with the
/// language pill, an overlapping logo card, a body, and a pill button anchored
/// at the bottom.
///
/// The header height is identical on every screen and the logo is centred on
/// the header's bottom edge, so only the logo *size* changes between screens —
/// which the `Hero` animates.
class OnboardingScaffold extends StatelessWidget {
  const OnboardingScaffold({
    super.key,
    required this.body,
    required this.buttonLabel,
    required this.onNext,
    this.buttonIcon,
    this.buttonChild,
    this.logoSize = 120,
    this.showLanguagePill = true,
    this.footer,
    this.decorateLogo,
    this.decorateButton,
  });

  final Widget body;
  final String buttonLabel;
  final VoidCallback? onNext;

  /// Optional trailing icon on the CTA (e.g. an arrow).
  final IconData? buttonIcon;

  /// Replaces the label (e.g. a spinner + "Sending…" while busy).
  final Widget? buttonChild;
  final double logoSize;
  final bool showLanguagePill;

  /// Optional widget between the body and the button (e.g. a text link).
  final Widget? footer;

  /// Wrap the (Hero) logo / the button in an entrance animation.
  final Widget Function(Widget logo)? decorateLogo;
  final Widget Function(Widget button)? decorateButton;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    // Responsive header: ~30% of the screen, clamped for tiny/huge devices.
    final headerH = (media.size.height * 0.3).clamp(210.0, 320.0);

    // Hero flights are drawn in the Overlay, which has no Material ancestor;
    // without this, any Text in the flying widget gets the yellow double
    // underline. The transparent Material gives it a text style.
    Widget logo = Hero(
      tag: OnboardingHero.logo,
      child: Material(
        type: MaterialType.transparency,
        child: SongkrousLogo(size: logoSize),
      ),
    );
    if (decorateLogo != null) logo = decorateLogo!(logo);

    // The only clickable element: solid deep-blue pill (hover lift, trailing
    // arrow nudge, press sink, haptic).
    final Widget button0 = AppInteractiveButton(
      label: buttonChild == null ? buttonLabel : null,
      trailingIcon: buttonIcon,
      onPressed: onNext,
      colors: AppButtonColors.primary,
      child: buttonChild,
    );
    Widget button = button0;
    if (decorateButton != null) button = decorateButton!(button);

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: LiquidAmbientCanvas(
        child: Column(
          children: [
            // Header + body scroll together; the footer link and the CTA stay
            // pinned below. With the keyboard open the content scrolls instead
            // of overflowing, and the button is never pushed off-screen.
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(
                      height: headerH + logoSize / 2,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.topCenter,
                        children: [
                          ClipPath(
                            clipper: const _ArcClipper(),
                            child: Container(
                              height: headerH,
                              width: double.infinity,
                              color: AppColors.blueDeep,
                            ),
                          ),
                          if (showLanguagePill)
                            Positioned(
                              top: media.padding.top + 16,
                              child: const Hero(
                                tag: OnboardingHero.langPill,
                                // Heroes fly in the overlay, which has no Material.
                                child: Material(
                                  type: MaterialType.transparency,
                                  child: LanguagePill(),
                                ),
                              ),
                            ),
                          Positioned(bottom: 0, child: logo),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 480),
                          child: body,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ?footer,
            SafeArea(
              top: false,
              minimum: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: button,
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
