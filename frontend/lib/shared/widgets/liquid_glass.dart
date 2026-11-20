import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Liquid Glass design language: frosted refraction, a specular rim and a thin
/// inner top sheen, in the Red / Blue / White brand palette.
///
/// Performance rule of thumb: `BackdropFilter` blurs (`useBlur: true`) belong on
/// floating, non-scrolling surfaces — the dock, headers, hero cards, map
/// overlays, dialogs. Rows inside scrolling lists use `useBlur: false`, which
/// keeps the same translucent look and rim but costs almost nothing.

enum LiquidTint {
  /// Light frosted white (default).
  frost,

  /// Nearly opaque frost — for surfaces that must keep text/logos crisp.
  frostStrong,

  /// Glossy Trust-Blue (`#0F3D91 → #1E40AF`).
  blue,

  /// Glossy Emergency-Red (`#D91E2A → #B3121F`).
  red,

  /// Smoked glass for dark screens (`#0F172A` @ 0.65).
  dark,

  /// Translucent white glass sitting on a blue surface.
  onBlue,
}

class _Spec {
  const _Spec({
    required this.fillA,
    required this.fillB,
    required this.rimA,
    required this.rimB,
    required this.sheen,
    required this.gloss,
    required this.shadow,
  });

  final Color fillA;
  final Color fillB;
  final double rimA;
  final double rimB;
  final double sheen;

  /// Soft top-half light reflection (tinted glass only).
  final double gloss;
  final Color shadow;
}

_Spec _spec(LiquidTint t) => switch (t) {
  LiquidTint.frost => _Spec(
    fillA: Colors.white.withValues(alpha: 0.76),
    fillB: Colors.white.withValues(alpha: 0.56),
    rimA: 0.90,
    rimB: 0.25,
    sheen: 0.85,
    gloss: 0,
    shadow: const Color(0x140F3D91),
  ),
  LiquidTint.frostStrong => _Spec(
    fillA: Colors.white.withValues(alpha: 0.96),
    fillB: Colors.white.withValues(alpha: 0.88),
    rimA: 0.95,
    rimB: 0.35,
    sheen: 0.9,
    gloss: 0,
    shadow: const Color(0x1F0F3D91),
  ),
  LiquidTint.blue => _Spec(
    fillA: AppColors.blueDeep.withValues(alpha: 0.94),
    fillB: const Color(0xFF1E40AF).withValues(alpha: 0.88),
    rimA: 0.60,
    rimB: 0.14,
    sheen: 0.55,
    gloss: 0.16,
    shadow: const Color(0x330F3D91),
  ),
  LiquidTint.red => _Spec(
    fillA: AppColors.red.withValues(alpha: 0.94),
    fillB: const Color(0xFFB3121F).withValues(alpha: 0.90),
    rimA: 0.60,
    rimB: 0.14,
    sheen: 0.55,
    gloss: 0.18,
    shadow: const Color(0x33D91E2A),
  ),
  LiquidTint.dark => _Spec(
    fillA: const Color(0xFF0F172A).withValues(alpha: 0.65),
    fillB: const Color(0xFF0F172A).withValues(alpha: 0.55),
    rimA: 0.34,
    rimB: 0.07,
    sheen: 0.30,
    gloss: 0.06,
    shadow: const Color(0x33000000),
  ),
  LiquidTint.onBlue => _Spec(
    fillA: Colors.white.withValues(alpha: 0.18),
    fillB: Colors.white.withValues(alpha: 0.08),
    rimA: 0.55,
    rimB: 0.10,
    sheen: 0.5,
    gloss: 0.08,
    shadow: const Color(0x00000000),
  ),
};

/// Frosted glass surface.
///
/// * fill: translucent gradient (or tinted Blue/Red/Dark glass)
/// * rim: 1.2 px gradient border, bright top-left → faint bottom-right
/// * sheen: 1 px highlight along the inner top edge
/// * shadow: soft ambient shadow painted *outside only* (never visible through
///   the glass)
///
/// [hovered] brightens the rim and widens the shadow; [pressed] intensifies the
/// inner tint. Both animate.
class LiquidGlassContainer extends StatelessWidget {
  const LiquidGlassContainer({
    super.key,
    this.child,
    this.radius = 20,
    this.padding,
    this.tint = LiquidTint.frost,
    this.useBlur = true,
    this.sigma = 18,
    this.hovered = false,
    this.pressed = false,
    this.shadow = true,
    this.width,
    this.height,
    this.alignment,
    this.borderRadius,
  });

  final Widget? child;
  final double radius;

  /// Per-corner radii (e.g. a bottom sheet rounded only at the top). Overrides
  /// [radius].
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final LiquidTint tint;

  /// `BackdropFilter` blur. Turn off for rows in scrolling lists.
  final bool useBlur;
  final double sigma;
  final bool hovered;
  final bool pressed;

  /// Outer ambient shadow.
  final bool shadow;
  final double? width;
  final double? height;
  final AlignmentGeometry? alignment;

  @override
  Widget build(BuildContext context) {
    final spec = _spec(tint);
    final emphasis = pressed ? 1.6 : (hovered ? 1.0 : 0.0);
    final br = borderRadius ?? BorderRadius.circular(radius);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: emphasis),
      duration: const Duration(milliseconds: 130),
      curve: Curves.easeOutCubic,
      builder: (context, e, _) {
        final bump = pressed ? 0.10 : 0.0;
        final fill = DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(
                  spec.fillA,
                  tint == LiquidTint.dark ? Colors.black : AppColors.blueDeep,
                  bump,
                )!,
                Color.lerp(
                  spec.fillB,
                  tint == LiquidTint.dark ? Colors.black : AppColors.blueDeep,
                  bump,
                )!,
              ],
            ),
          ),
          child: Container(
            width: width,
            height: height,
            padding: padding,
            alignment: alignment,
            child: child,
          ),
        );

        return CustomPaint(
          painter: shadow
              ? _ShadowPainter(
                  radius: br,
                  color: spec.shadow,
                  extra: e,
                  alwaysOn: tint != LiquidTint.onBlue,
                )
              : null,
          foregroundPainter: _RimPainter(radius: br, spec: spec, emphasis: e),
          child: ClipRRect(
            borderRadius: br,
            child: useBlur
                ? BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
                    child: fill,
                  )
                : fill,
          ),
        );
      },
    );
  }
}

class _ShadowPainter extends CustomPainter {
  const _ShadowPainter({
    required this.radius,
    required this.color,
    required this.extra,
    required this.alwaysOn,
  });

  final BorderRadius radius;
  final Color color;
  final double extra;
  final bool alwaysOn;

  @override
  void paint(Canvas canvas, Size size) {
    if (!alwaysOn) return;
    final rrect = radius.toRRect(Offset.zero & size);
    // Only the area *outside* the glass: a shadow under translucent glass
    // would muddy it.
    canvas.save();
    canvas.clipPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(
          Rect.fromLTWH(-80, -80, size.width + 160, size.height + 200),
        ),
        Path()..addRRect(rrect),
      ),
    );
    canvas.drawRRect(
      rrect.shift(Offset(0, 8 + 2 * extra)),
      Paint()
        ..color = color.withValues(
          alpha: (color.a * (1 + 0.5 * extra)).clamp(0.0, 1.0),
        )
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 12 + 3 * extra),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ShadowPainter old) =>
      old.radius != radius || old.color != color || old.extra != extra;
}

class _RimPainter extends CustomPainter {
  const _RimPainter({
    required this.radius,
    required this.spec,
    required this.emphasis,
  });

  final BorderRadius radius;
  final _Spec spec;
  final double emphasis;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final outer = radius.toRRect(rect);

    // Soft top-half light reflection on tinted glass.
    if (spec.gloss > 0) {
      canvas.save();
      canvas.clipRRect(outer);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height * 0.55),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: spec.gloss),
              Colors.white.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.55)),
      );
      canvas.restore();
    }

    // Specular rim: bright top-left → faint bottom-right.
    final boost = 0.06 * emphasis;
    canvas.drawRRect(
      outer.deflate(0.6),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: (spec.rimA + boost).clamp(0.0, 1.0)),
            Colors.white.withValues(alpha: (spec.rimB + boost).clamp(0.0, 1.0)),
          ],
        ).createShader(rect),
    );

    // Inner top sheen: a 1 px highlight just inside the rim.
    final inset = radius.topLeft.x * 0.55 + 2;
    if (size.width > inset * 2) {
      const y = 1.8;
      canvas.drawLine(
        Offset(inset, y),
        Offset(size.width - inset, y),
        Paint()
          ..strokeWidth = 1
          ..shader = LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0),
              Colors.white.withValues(alpha: spec.sheen),
              Colors.white.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromLTWH(inset, 0, size.width - inset * 2, 1)),
      );
    }
  }

  @override
  bool shouldRepaint(_RimPainter old) =>
      old.radius != radius || old.emphasis != emphasis || old.spec != spec;
}

/// `#F4F7FB` canvas with two soft out-of-focus light orbs — Royal-Blue
/// (`#DBEAFE`, top-right) and Rose (`#FFE4E6`, bottom-left) at 40 % — so
/// glass has colour and light to refract. Wrap non-map screens in it.
class LiquidAmbientCanvas extends StatelessWidget {
  const LiquidAmbientCanvas({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xFFF4F7FB)),
        const Positioned(
          top: -140,
          right: -120,
          child: _Orb(color: Color(0xFFDBEAFE), diameter: 420),
        ),
        const Positioned(
          bottom: -160,
          left: -140,
          child: _Orb(color: Color(0xFFFFE4E6), diameter: 440),
        ),
        child,
      ],
    );
  }
}

/// Dark counterpart of [LiquidAmbientCanvas] for the call screen: the
/// slate-navy background with faint blue and red glows for smoked glass to
/// refract.
class LiquidDarkCanvas extends StatelessWidget {
  const LiquidDarkCanvas({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: AppColors.callBackground),
        Positioned(
          top: -120,
          right: -140,
          child: _GlowOrb(
            color: AppColors.blue.withValues(alpha: 0.40),
            diameter: 440,
          ),
        ),
        Positioned(
          bottom: -160,
          left: -140,
          child: _GlowOrb(
            color: AppColors.red.withValues(alpha: 0.26),
            diameter: 460,
          ),
        ),
        child,
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color, required this.diameter});

  final Color color;
  final double diameter;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.color, required this.diameter});

  final Color color;
  final double diameter;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.40),
              color.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }
}

/// Layered circular icon badge: radial colour depth, specular top highlight,
/// inner rim and a soft drop shadow, with a crisp white glyph.
class LayeredIconBadge extends StatelessWidget {
  const LayeredIconBadge({
    super.key,
    required this.icon,
    this.color = AppColors.blue,
    this.size = 44,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final light = Color.lerp(color, Colors.white, 0.35)!;
    final dark = Color.lerp(color, Colors.black, 0.30)!;
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-0.4, -0.5),
            radius: 1.1,
            colors: [light, color, dark],
            stops: const [0, 0.55, 1],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Specular highlight.
            Positioned(
              top: size * 0.06,
              left: size * 0.16,
              right: size * 0.16,
              height: size * 0.42,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.50),
                      Colors.white.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            Icon(icon, size: size * 0.5, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
