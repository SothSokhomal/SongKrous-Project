import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/animations/app_animations.dart';
import '../../core/constants/app_state.dart';
import '../../core/theme/app_colors.dart';
import 'app_interactive.dart';

class _NavItem {
  const _NavItem(this.icon, this.labelKey, {this.badge});
  final IconData icon;
  final String labelKey;
  final String? badge;
}

const _items = [
  _NavItem(Icons.shield_outlined, 'nav_home', badge: 'SOS'),
  _NavItem(Icons.map_outlined, 'nav_map'),
  _NavItem(Icons.chat_bubble_outline_rounded, 'nav_safety'),
  _NavItem(Icons.phone_outlined, 'nav_hotlines'),
];

/// White pill bar floating 16px above the bottom safe area.
class FloatingBottomNav extends ConsumerWidget {
  const FloatingBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  /// Space the bar occupies above the safe area (height + 16px gap).
  static const double height = 72;
  static const double gap = 16;

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, gap),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(
                  child: _NavButton(
                    item: _items[i],
                    label: ref.tr(_items[i].labelKey),
                    selected: i == currentIndex,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const duration = Duration(milliseconds: 200);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: AppPressable(
        onTap: onTap,
        haptic: AppHaptic.selection,
        builder: (context, hovered, pressed) {
          // Inactive tabs tint toward blue on hover; selected is solid blue.
          final color = selected
              ? AppColors.blue
              : hovered
              ? Color.lerp(AppColors.slate, AppColors.blue, 0.6)!
              : AppColors.slate;
          return AnimatedScale(
            duration: pressed ? const Duration(milliseconds: 90) : duration,
            // Sinks to 0.88 on press, springs back to 1.0 on release.
            curve: pressed ? AppCurves.out : Curves.easeOutBack,
            scale: pressed ? 0.88 : 1.0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Hover lifts the inactive icon 2 px.
                    AnimatedSlide(
                      duration: const Duration(milliseconds: 130),
                      curve: AppCurves.out,
                      offset: Offset(0, hovered && !selected ? -2 / 26 : 0),
                      child: AnimatedScale(
                        scale: selected ? 1.12 : 1.0,
                        duration: duration,
                        curve: AppCurves.out,
                        child: TweenAnimationBuilder<Color?>(
                          tween: ColorTween(end: color),
                          duration: duration,
                          builder: (context, c, _) =>
                              Icon(item.icon, color: c, size: 26),
                        ),
                      ),
                    ),
                    // The SOS badge stays crisp (not scaled/lifted).
                    if (item.badge != null)
                      Positioned(
                        top: -6,
                        right: -16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item.badge!,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: AnimatedDefaultTextStyle(
                    duration: duration,
                    curve: AppCurves.out,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 10.5,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      fontFamilyFallback: const ['Noto Sans Khmer'],
                    ),
                    child: Text(label),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
