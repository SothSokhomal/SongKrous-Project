import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/animations/app_animations.dart';
import '../../core/constants/app_state.dart';
import '../../core/theme/app_colors.dart';
import 'app_interactive.dart';
import 'liquid_glass.dart';

class _NavItem {
  const _NavItem(this.icon, this.labelKey);
  final IconData icon;
  final String labelKey;
}

const _items = [
  _NavItem(Icons.home_outlined, 'nav_home'),
  _NavItem(Icons.map_outlined, 'nav_map'),
  _NavItem(Icons.chat_bubble_outline_rounded, 'nav_safety'),
  _NavItem(Icons.receipt_long_outlined, 'nav_activity'),
  _NavItem(Icons.settings_outlined, 'nav_settings'),
];

/// iOS 26 Liquid Glass dock floating 16 px above the bottom safe area.
///
/// A real `BackdropFilter` (σ 22) lets map roads, pins and screen colours
/// refract through the bar; a translucent "lens" capsule slides behind the
/// active tab. The red `SOS` badge stays crisp on top.
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
    final last = _items.length - 1;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, gap),
        child: LiquidGlassContainer(
          radius: 32,
          sigma: 22,
          height: height,
          child: Stack(
            children: [
              // Sliding liquid lens behind the active tab.
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 280),
                    curve: AppCurves.out,
                    alignment: Alignment(-1 + 2 * currentIndex / last, 0),
                    child: FractionallySizedBox(
                      widthFactor: 1 / _items.length,
                      heightFactor: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(26),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withValues(alpha: 0.85),
                                const Color(0xFFDBEAFE).withValues(alpha: 0.65),
                              ],
                            ),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.blue.withValues(alpha: 0.16),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Row(
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
                  ],
                ),
                const SizedBox(height: 3),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: AnimatedDefaultTextStyle(
                    duration: duration,
                    curve: AppCurves.out,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      fontFamilyFallback: const ['Noto Sans Khmer'],
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(label),
                    ),
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
