import 'package:flutter/material.dart';

/// Built-in avatar styles: brand blue/red gradients with a service emblem, so
/// the profile picture can be changed in one tap even on an empty simulator.
class AvatarPreset {
  const AvatarPreset(this.top, this.bottom, this.icon);

  final Color top;
  final Color bottom;
  final IconData icon;

  LinearGradient get gradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [top, bottom],
  );
}

const List<AvatarPreset> kAvatarPresets = [
  AvatarPreset(Color(0xFF0F3D91), Color(0xFF1D4ED8), Icons.shield_rounded),
  AvatarPreset(
    Color(0xFFEF4444),
    Color(0xFFD91E2A),
    Icons.local_hospital_rounded,
  ),
  AvatarPreset(
    Color(0xFF0B2A6B),
    Color(0xFF1D4ED8),
    Icons.local_police_rounded,
  ),
  AvatarPreset(
    Color(0xFFF97316),
    Color(0xFFD91E2A),
    Icons.local_fire_department_rounded,
  ),
  AvatarPreset(Color(0xFFFB7185), Color(0xFFBE123C), Icons.favorite_rounded),
  AvatarPreset(Color(0xFF6366F1), Color(0xFF1D4ED8), Icons.star_rounded),
];
