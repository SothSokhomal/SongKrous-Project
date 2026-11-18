import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_interactive.dart';

enum AttachChoice { library, camera, demo }

/// iOS-style "Attach a photo" action sheet.
Future<AttachChoice?> showAttachSheet(BuildContext context) {
  return showModalBottomSheet<AttachChoice>(
    context: context,
    backgroundColor: AppColors.white,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const _AttachSheet(),
  );
}

class _AttachSheet extends ConsumerWidget {
  const _AttachSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void pick(AttachChoice c) => Navigator.of(context).pop(c);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
              child: Text(
                ref.tr('attach_photo'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            _Row(
              icon: Icons.photo_library_rounded,
              title: ref.tr('attach_library'),
              onTap: () => pick(AttachChoice.library),
            ),
            const SizedBox(height: 8),
            _Row(
              icon: Icons.photo_camera_rounded,
              title: ref.tr('attach_camera'),
              onTap: () => pick(AttachChoice.camera),
            ),
            const SizedBox(height: 8),
            _Row(
              icon: Icons.auto_awesome_rounded,
              title: ref.tr('attach_demo'),
              subtitle: ref.tr('attach_demo_sub'),
              accent: AppColors.red,
              onTap: () => pick(AttachChoice.demo),
            ),
            const SizedBox(height: 12),
            AppInteractiveButton(
              height: 48,
              label: ref.tr('cancel'),
              colors: AppButtonColors.outline(AppColors.slate),
              haptic: AppHaptic.selection,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.accent = AppColors.blueDeep,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AppInteractiveCard(
      onTap: onTap,
      semanticLabel: title,
      radius: 16,
      padding: const EdgeInsets.all(12),
      builder: (context, hovered, pressed) => Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: text.titleMedium),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: text.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
