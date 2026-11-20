import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/animations/app_animations.dart';
import '../../../core/constants/app_state.dart';
import '../../../core/state/auth_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_interactive.dart';
import '../../../shared/widgets/liquid_glass.dart';
import '../avatar_presets.dart';
import 'profile_avatar_view.dart';

enum PhotoAction { camera, gallery, preset, remove }

/// What the user chose in the sheet. [presetIndex] is set for
/// [PhotoAction.preset].
class PhotoChoice {
  const PhotoChoice(this.action, [this.presetIndex]);
  final PhotoAction action;
  final int? presetIndex;
}

/// Telegram-style frosted Liquid Glass action sheet for the profile picture.
Future<PhotoChoice?> showProfilePhotoSheet(
  BuildContext context, {
  required bool hasAvatar,
}) {
  return showModalBottomSheet<PhotoChoice>(
    context: context,
    backgroundColor: Colors.transparent,
    elevation: 0,
    isScrollControlled: true,
    builder: (_) => _PhotoSheet(hasAvatar: hasAvatar),
  );
}

class _PhotoSheet extends ConsumerStatefulWidget {
  const _PhotoSheet({required this.hasAvatar});

  final bool hasAvatar;

  @override
  ConsumerState<_PhotoSheet> createState() => _PhotoSheetState();
}

class _PhotoSheetState extends ConsumerState<_PhotoSheet> {
  bool _showStyles = false;

  void _pick(PhotoChoice c) => Navigator.of(context).pop(c);

  @override
  Widget build(BuildContext context) {
    return LiquidGlassContainer(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      tint: LiquidTint.frostStrong,
      sigma: 24,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Grabber.
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.slateLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                child: Text(
                  ref.tr('profile_photo_title'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                    height: 1.5,
                    fontFamilyFallback: ['Noto Sans Khmer'],
                  ),
                ),
              ),
              _Row(
                key: const ValueKey('photo-camera'),
                icon: Icons.photo_camera_rounded,
                title: ref.tr('photo_take'),
                onTap: () => _pick(const PhotoChoice(PhotoAction.camera)),
              ),
              const SizedBox(height: 8),
              _Row(
                key: const ValueKey('photo-gallery'),
                icon: Icons.photo_library_rounded,
                title: ref.tr('photo_gallery'),
                onTap: () => _pick(const PhotoChoice(PhotoAction.gallery)),
              ),
              const SizedBox(height: 8),
              _Row(
                key: const ValueKey('photo-styles'),
                icon: Icons.palette_rounded,
                title: ref.tr('photo_styles'),
                subtitle: ref.tr('photo_styles_sub'),
                trailing: AnimatedRotation(
                  turns: _showStyles ? 0.25 : 0,
                  duration: AppDurations.fast,
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.slate,
                  ),
                ),
                onTap: () => setState(() => _showStyles = !_showStyles),
              ),
              AnimatedSize(
                duration: AppDurations.fast,
                curve: AppCurves.out,
                alignment: Alignment.topCenter,
                child: _showStyles
                    ? Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 4),
                        child: _PresetRow(
                          onPick: (i) =>
                              _pick(PhotoChoice(PhotoAction.preset, i)),
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),
              if (widget.hasAvatar) ...[
                const SizedBox(height: 8),
                _Row(
                  key: const ValueKey('photo-remove'),
                  icon: Icons.delete_outline_rounded,
                  title: ref.tr('photo_remove'),
                  accent: AppColors.red,
                  onTap: () => _pick(const PhotoChoice(PhotoAction.remove)),
                ),
              ],
              const SizedBox(height: 4),
              Center(
                child: AppTextLink(
                  key: const ValueKey('photo-cancel'),
                  label: ref.tr('cancel'),
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Six preset avatars in one even row that sizes itself to the sheet width.
class _PresetRow extends ConsumerWidget {
  const _PresetRow({required this.onPick});

  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, box) {
        const n = 6; // kAvatarPresets.length
        const gap = 8.0;
        final size = ((box.maxWidth - gap * (n - 1)) / n).clamp(34.0, 56.0);
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var i = 0; i < kAvatarPresets.length; i++)
              Semantics(
                button: true,
                label: ref
                    .tr('avatar_style_n')
                    .replaceAll('{n}', ref.num('${i + 1}')),
                child: AppPressable(
                  key: ValueKey('preset-$i'),
                  onTap: () => onPick(i),
                  haptic: AppHaptic.selection,
                  builder: (context, hovered, pressed) => AnimatedScale(
                    duration: AppDurations.tap,
                    scale: pressed
                        ? 0.9
                        : hovered
                        ? 1.08
                        : 1,
                    child: ProfileAvatarView(
                      avatar: PresetAvatar(i),
                      size: size,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailing,
    this.accent = AppColors.blueDeep,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppInteractiveCard(
      glass: LiquidTint.frost,
      radius: 16,
      semanticLabel: title,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: accent, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: accent == AppColors.red ? accent : AppColors.ink,
                    height: 1.5,
                    fontFamilyFallback: const ['Noto Sans Khmer'],
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.slate,
                      height: 1.5,
                      fontFamilyFallback: ['Noto Sans Khmer'],
                    ),
                  ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
