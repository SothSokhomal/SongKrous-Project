import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_state.dart';
import '../../../core/constants/facilities.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_interactive.dart';
import '../../map/widgets/map_markers.dart';

/// Pure-white iOS header: back, ringed facility avatar with an active dot,
/// name + connection line, and two tactile actions (live location, call).
class ChatHeader extends ConsumerWidget {
  const ChatHeader({
    super.key,
    required this.facility,
    required this.onBack,
    required this.onSendLocation,
    required this.onCall,
  });

  final Facility facility;
  final VoidCallback onBack;
  final VoidCallback onSendLocation;
  final VoidCallback onCall;

  /// Height of the header content below the status bar (rows + padding).
  static const double contentHeight = 55;

  static const _iconColors = AppButtonColors(
    bg: Color(0xFFF1F5F9),
    hover: Color(0xFFE2E8F0),
    pressed: Color(0xFFCBD5E1),
    fg: AppColors.blueDeep,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(langProvider);
    final ring = facilityColor(facility.type);

    // Translucent Liquid Glass: messages scrolling underneath blur softly
    // behind the header.
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: 0.88),
                Colors.white.withValues(alpha: 0.74),
              ],
            ),
            border: const Border(bottom: BorderSide(color: Color(0xCCE2E8F0))),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 6, 10, 8),
              child: Row(
                children: [
                  AppPressFade(
                    semanticLabel: ref.tr('back'),
                    padding: const EdgeInsets.all(6),
                    onTap: onBack,
                    child: const Icon(
                      Icons.chevron_left_rounded,
                      size: 32,
                      color: AppColors.blue,
                    ),
                  ),
                  // Avatar with colour ring + green "connected" dot.
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: ring, width: 2),
                        ),
                        child: Icon(
                          facilityIcon(facility.type),
                          color: ring,
                          size: 20,
                        ),
                      ),
                      Positioned(
                        right: -1,
                        bottom: -1,
                        child: Container(
                          width: 11,
                          height: 11,
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.white,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          facility.name(lang),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                            height: 1.5,
                            fontFamilyFallback: ['Noto Sans Khmer'],
                          ),
                        ),
                        Text(
                          ref
                              .tr('chat_connected')
                              .replaceAll('{phone}', ref.num(facility.phone)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.slate,
                            height: 1.5,
                            fontFamilyFallback: ['Noto Sans Khmer'],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  _IconAction(
                    icon: Icons.location_on_rounded,
                    tooltip: ref.tr('send_my_location'),
                    onPressed: onSendLocation,
                    color: AppColors.red,
                  ),
                  const SizedBox(width: 8),
                  _IconAction(
                    icon: Icons.phone_rounded,
                    tooltip: ref.tr('call_dispatch'),
                    onPressed: onCall,
                    color: AppColors.blueDeep,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.color,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: AppInteractiveButton(
        height: 40,
        radius: 20,
        expand: false,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        semanticLabel: tooltip,
        colors: AppButtonColors(
          bg: ChatHeader._iconColors.bg,
          hover: ChatHeader._iconColors.hover,
          pressed: ChatHeader._iconColors.pressed,
          fg: color,
        ),
        haptic: AppHaptic.light,
        onPressed: onPressed,
        child: Icon(icon, size: 21, color: color),
      ),
    );
  }
}
