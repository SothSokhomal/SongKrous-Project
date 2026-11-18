import 'dart:io';

import 'package:flutter/material.dart';

import '../models/chat_message.dart';

/// Renders a message photo: the built-in sample ([kDemoPhotoPath]) or a file
/// from the image picker.
class ChatPhoto extends StatelessWidget {
  const ChatPhoto({super.key, required this.path, this.fit = BoxFit.cover});

  final String path;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (path == kDemoPhotoPath) {
      return const CustomPaint(
        painter: _DemoIncidentPainter(),
        size: Size.infinite,
      );
    }
    return Image.file(
      File(path),
      fit: fit,
      // Decode near display size, not the full camera resolution.
      cacheWidth: 900,
      errorBuilder: (_, _, _) => const ColoredBox(
        color: Color(0xFFE2E8F0),
        child: Center(
          child: Icon(Icons.broken_image_rounded, color: Color(0xFF94A3B8)),
        ),
      ),
    );
  }
}

/// A stylised dusk street scene with a stopped car and hazard lights — a
/// stand-in "incident photo" for demos (no assets, works on an empty simulator).
class _DemoIncidentPainter extends CustomPainter {
  const _DemoIncidentPainter();

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;

    // Sky.
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h * 0.55),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1E2A4A), Color(0xFF6B4E71), Color(0xFFE8956A)],
        ).createShader(Rect.fromLTWH(0, 0, w, h * 0.55)),
    );

    // Skyline silhouettes.
    final b = Paint()..color = const Color(0xFF141B2D);
    final lit = Paint()..color = const Color(0xFFFFD27A).withValues(alpha: 0.8);
    var x = 0.0;
    var i = 0;
    while (x < w) {
      final bw = w * (0.10 + (i % 3) * 0.035);
      final bh = h * (0.16 + ((i * 37) % 5) * 0.045);
      canvas.drawRect(Rect.fromLTWH(x, h * 0.55 - bh, bw, bh), b);
      for (var wy = h * 0.55 - bh + 6; wy < h * 0.55 - 8; wy += 11) {
        if ((wy.toInt() + i) % 3 != 0) {
          canvas.drawRect(Rect.fromLTWH(x + 5, wy, 4, 5), lit);
        }
      }
      x += bw + 2;
      i++;
    }

    // Road.
    final road = Path()
      ..moveTo(0, h * 0.55)
      ..lineTo(w, h * 0.55)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(road, Paint()..color = const Color(0xFF2B3040));
    final dash = Paint()..color = Colors.white.withValues(alpha: 0.7);
    for (var k = 0; k < 4; k++) {
      final y = h * (0.62 + k * 0.1);
      final dw = 6.0 + k * 5;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(w / 2, y), width: dw, height: 3.0 + k),
          const Radius.circular(2),
        ),
        dash,
      );
    }

    // Car (side-on, slightly left of centre).
    final cx = w * 0.46, cy = h * 0.74;
    final carW = w * 0.46, carH = h * 0.15;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy + carH * 0.55),
        width: carW * 1.05,
        height: carH * 0.3,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.35),
    );
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy), width: carW, height: carH),
      Radius.circular(carH * 0.35),
    );
    canvas.drawRRect(body, Paint()..color = const Color(0xFFB91C1C));
    final cabin = Path()
      ..moveTo(cx - carW * 0.28, cy - carH * 0.5)
      ..lineTo(cx - carW * 0.12, cy - carH * 1.05)
      ..lineTo(cx + carW * 0.18, cy - carH * 1.05)
      ..lineTo(cx + carW * 0.32, cy - carH * 0.5)
      ..close();
    canvas.drawPath(cabin, Paint()..color = const Color(0xFF8F1414));
    canvas.drawPath(
      Path()
        ..moveTo(cx - carW * 0.22, cy - carH * 0.55)
        ..lineTo(cx - carW * 0.10, cy - carH * 0.95)
        ..lineTo(cx + carW * 0.14, cy - carH * 0.95)
        ..lineTo(cx + carW * 0.26, cy - carH * 0.55)
        ..close(),
      Paint()..color = const Color(0xFF9DB7D5).withValues(alpha: 0.85),
    );
    final wheel = Paint()..color = const Color(0xFF0B0F1A);
    for (final dx in [-0.28, 0.28]) {
      canvas.drawCircle(
        Offset(cx + carW * dx, cy + carH * 0.5),
        carH * 0.3,
        wheel,
      );
      canvas.drawCircle(
        Offset(cx + carW * dx, cy + carH * 0.5),
        carH * 0.13,
        Paint()..color = const Color(0xFF6B7280),
      );
    }
    // Hazard glow.
    final glow = Paint()
      ..color = const Color(0xFFFFA726).withValues(alpha: 0.55)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawCircle(
      Offset(cx - carW * 0.5, cy - carH * 0.05),
      carH * 0.55,
      glow,
    );
    canvas.drawCircle(
      Offset(cx + carW * 0.5, cy - carH * 0.05),
      carH * 0.55,
      glow,
    );
    final lamp = Paint()..color = const Color(0xFFFFB74D);
    canvas.drawCircle(
      Offset(cx - carW * 0.5, cy - carH * 0.05),
      carH * 0.1,
      lamp,
    );
    canvas.drawCircle(
      Offset(cx + carW * 0.5, cy - carH * 0.05),
      carH * 0.1,
      lamp,
    );

    // Warning triangle on the road.
    final tx = w * 0.82, ty = h * 0.8, ts = h * 0.07;
    final tri = Path()
      ..moveTo(tx, ty - ts)
      ..lineTo(tx + ts * 0.9, ty + ts * 0.6)
      ..lineTo(tx - ts * 0.9, ty + ts * 0.6)
      ..close();
    canvas.drawPath(tri, Paint()..color = const Color(0xFFD91E2A));
    canvas.drawPath(
      Path()
        ..moveTo(tx, ty - ts * 0.55)
        ..lineTo(tx + ts * 0.5, ty + ts * 0.35)
        ..lineTo(tx - ts * 0.5, ty + ts * 0.35)
        ..close(),
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
