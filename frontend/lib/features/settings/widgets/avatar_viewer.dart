import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_state.dart';
import '../../../core/state/auth_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_interactive.dart';
import 'profile_avatar_view.dart';

/// Hero tag shared by the Settings avatar and the full-screen viewer.
const String kAvatarHeroTag = 'user_profile_avatar';

/// Telegram-style full-screen photo viewer. Tap anywhere or swipe down to
/// close; "Change Photo" (top right) closes it and calls [onChange].
Future<void> showAvatarViewer(
  BuildContext context, {
  required VoidCallback onChange,
}) {
  return Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, _, _) => AvatarViewer(onChange: onChange),
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}

class AvatarViewer extends ConsumerWidget {
  const AvatarViewer({super.key, required this.onChange});

  final VoidCallback onChange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatar = ref.watch(authProfileProvider.select((p) => p.avatar));
    final size = MediaQuery.sizeOf(context);
    final diameter = math.min(size.width - 32, size.height * 0.6);

    return Scaffold(
      backgroundColor: const Color(0xF2000000),
      body: GestureDetector(
        key: const ValueKey('avatar-viewer-surface'),
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).maybePop(),
        onVerticalDragEnd: (d) {
          if ((d.primaryVelocity ?? 0).abs() > 300) {
            Navigator.of(context).maybePop();
          }
        },
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: Hero(
                  tag: kAvatarHeroTag,
                  child: Material(
                    type: MaterialType.transparency,
                    child: ProfileAvatarView(avatar: avatar, size: diameter),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: AppScaleButton(
                  key: const ValueKey('avatar-viewer-close'),
                  tooltip: ref.tr('close'),
                  semanticLabel: ref.tr('close'),
                  haptic: AppHaptic.selection,
                  onTap: () => Navigator.of(context).maybePop(),
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(
                      Icons.close_rounded,
                      color: AppColors.white,
                      size: 26,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 12,
                child: AppInteractiveButton(
                  key: const ValueKey('avatar-viewer-change'),
                  label: ref.tr('photo_change'),
                  leadingIcon: Icons.photo_camera_rounded,
                  height: 40,
                  fontSize: 14,
                  expand: false,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  colors: AppButtonColors.glassDark,
                  haptic: AppHaptic.selection,
                  onPressed: () {
                    Navigator.of(context).pop();
                    onChange();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
