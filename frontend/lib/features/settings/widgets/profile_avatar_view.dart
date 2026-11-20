import 'package:flutter/material.dart';

import '../../../core/state/auth_state.dart';
import '../../../core/theme/app_colors.dart';
import '../avatar_presets.dart';

/// The profile picture as a circle with a soft white glass rim and shadow:
/// photo → crisp cover-fit image; preset → gradient emblem; none → brand-blue
/// gradient with a person glyph.
class ProfileAvatarView extends StatelessWidget {
  const ProfileAvatarView({super.key, required this.avatar, this.size = 96});

  final ProfileAvatar? avatar;
  final double size;

  static const double _rim = 2.5;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(_rim),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.92),
        boxShadow: [
          BoxShadow(
            color: AppColors.blueDeep.withValues(alpha: 0.22),
            blurRadius: size * 0.22,
            offset: Offset(0, size * 0.07),
          ),
        ],
      ),
      child: ClipOval(child: _content()),
    );
  }

  Widget _content() {
    final a = avatar;
    switch (a) {
      case PhotoAvatar(:final bytes):
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
          // Corrupt bytes never crash the screen.
          errorBuilder: (_, _, _) => _gradient(const [
            AppColors.blueDeep,
            AppColors.blue,
          ], Icons.person_rounded),
        );
      case PresetAvatar(:final index):
        final p = kAvatarPresets[index.clamp(0, kAvatarPresets.length - 1)];
        return _gradient([p.top, p.bottom], p.icon);
      case null:
        return _gradient(const [
          AppColors.blueDeep,
          AppColors.blue,
        ], Icons.person_rounded);
    }
  }

  Widget _gradient(List<Color> colors, IconData icon) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Center(
        child: Icon(icon, size: size * 0.48, color: AppColors.white),
      ),
    );
  }
}
