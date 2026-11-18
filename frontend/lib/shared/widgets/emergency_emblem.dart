import 'package:flutter/material.dart';

import '../../core/constants/facilities.dart';

/// Layered, glossy 3D-style shield emblem for Medical / Police / Fire:
/// drop shadow → radial-gradient body → inner bevel → specular top light →
/// rim, with crisp iconography on top.
class EmergencyEmblem extends StatelessWidget {
  const EmergencyEmblem({super.key, required this.type, this.size = 60});

  final FacilityType type;
  final double size;

  @override
  Widget build(BuildContext context) {
    final glyph = switch (type) {
      FacilityType.hospital => null, // cross is drawn on the white plate
      FacilityType.police => _GlyphIcon(
        icon: Icons.star_rounded,
        size: size * 0.40,
        colors: const [Colors.white, Color(0xFFFFE08A)],
      ),
      FacilityType.fire => _GlyphIcon(
        icon: Icons.local_fire_department_rounded,
        size: size * 0.46,
        colors: const [Color(0xFFFFF3C4), Color(0xFFFFB020)],
      ),
    };

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(child: CustomPaint(painter: _ShieldPainter(type))),
          if (type == FacilityType.hospital)
            Padding(
              padding: EdgeInsets.only(bottom: size * 0.03),
              child: _GlyphIcon(
                icon: Icons.add_rounded,
                size: size * 0.46,
                colors: const [Color(0xFFEF4444), Color(0xFFB3121F)],
              ),
            ),
          if (glyph != null)
            Padding(
              padding: EdgeInsets.only(bottom: size * 0.04),
              child: glyph,
            ),
        ],
      ),
    );
  }
}

class _GlyphIcon extends StatelessWidget {
  const _GlyphIcon({
    required this.icon,
    required this.size,
    required this.colors,
  });

  final IconData icon;
  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (r) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: colors,
      ).createShader(r),
      child: Icon(
        icon,
        size: size,
        color: Colors.white,
        shadows: const [Shadow(color: Color(0x40000000), blurRadius: 3)],
      ),
    );
  }
}

class _ShieldPainter extends CustomPainter {
  const _ShieldPainter(this.type);

  final FacilityType type;

  static Path _shield(Rect r) {
    final w = r.width, h = r.height;
    Offset p(double x, double y) => Offset(r.left + w * x, r.top + h * y);
    return Path()
      ..moveTo(p(0.5, 0).dx, p(0.5, 0).dy)
      ..cubicTo(
        p(0.68, 0.09).dx,
        p(0.68, 0.09).dy,
        p(0.84, 0.11).dx,
        p(0.84, 0.11).dy,
        p(0.95, 0.11).dx,
        p(0.95, 0.11).dy,
      )
      ..cubicTo(
        p(0.99, 0.50).dx,
        p(0.99, 0.50).dy,
        p(0.82, 0.82).dx,
        p(0.82, 0.82).dy,
        p(0.5, 1).dx,
        p(0.5, 1).dy,
      )
      ..cubicTo(
        p(0.18, 0.82).dx,
        p(0.18, 0.82).dy,
        p(0.01, 0.50).dx,
        p(0.01, 0.50).dy,
        p(0.05, 0.11).dx,
        p(0.05, 0.11).dy,
      )
      ..cubicTo(
        p(0.16, 0.11).dx,
        p(0.16, 0.11).dy,
        p(0.32, 0.09).dx,
        p(0.32, 0.09).dy,
        p(0.5, 0).dx,
        p(0.5, 0).dy,
      )
      ..close();
  }

  List<Color> get _body => switch (type) {
    FacilityType.hospital => const [
      Color(0xFF6F96F5),
      Color(0xFF1D4ED8),
      Color(0xFF0F3D91),
    ],
    FacilityType.police => const [
      Color(0xFF4A78E4),
      Color(0xFF1E40AF),
      Color(0xFF0A2A6E),
    ],
    FacilityType.fire => const [
      Color(0xFFF26A6A),
      Color(0xFFD91E2A),
      Color(0xFF991B1B),
    ],
  };

  @override
  void paint(Canvas canvas, Size size) {
    final inset = size.width * 0.04;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      size.width - inset * 2,
      size.height - inset * 2 - size.height * 0.03,
    );
    final path = _shield(rect);

    // 1. Drop shadow.
    canvas.drawPath(
      path.shift(Offset(0, size.height * 0.06)),
      Paint()
        ..color = _body[2].withValues(alpha: 0.40)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.width * 0.07),
    );

    // 2. Radial body.
    canvas.drawPath(
      path,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.55),
          radius: 1.15,
          colors: _body,
          stops: const [0, 0.5, 1],
        ).createShader(rect),
    );

    // 3. Inner bevel (dark ring just inside the edge).
    canvas.save();
    canvas.clipPath(path);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.07
        ..color = Colors.black.withValues(alpha: 0.18)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.width * 0.03),
    );

    // Medical: white plate with a soft inner shadow, for the red cross.
    if (type == FacilityType.hospital) {
      final plateRect = Rect.fromCenter(
        center: rect.center.translate(0, -size.height * 0.015),
        width: rect.width * 0.66,
        height: rect.height * 0.66,
      );
      final plate = _shield(plateRect);
      canvas.drawPath(
        plate.shift(Offset(0, size.height * 0.015)),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.18)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.width * 0.02),
      );
      canvas.drawPath(
        plate,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFDCE6FB)],
          ).createShader(plateRect),
      );
    }

    // 4. Specular light across the top half.
    canvas.drawOval(
      Rect.fromLTWH(
        rect.left + rect.width * 0.08,
        rect.top - rect.height * 0.12,
        rect.width * 0.84,
        rect.height * 0.62,
      ),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.55),
            Colors.white.withValues(alpha: 0.0),
          ],
        ).createShader(rect),
    );
    canvas.restore();

    // 5. Crisp specular rim.
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.85),
            Colors.white.withValues(alpha: 0.12),
          ],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_ShieldPainter old) => old.type != type;
}
