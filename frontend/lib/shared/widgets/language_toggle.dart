import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/animations/app_animations.dart';
import '../../core/constants/app_state.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import 'app_interactive.dart';
import 'liquid_glass.dart';

/// White pill `ភាសាខ្មែរ | English` with a sliding active background (220 ms),
/// a soft hover tint on the inactive language and a selection haptic.
class LanguagePill extends ConsumerWidget {
  const LanguagePill({super.key});

  static const double _segment = 88;
  static const double _height = 38;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(langProvider);
    final km = lang == AppLang.km;

    return LiquidGlassContainer(
      radius: 24,
      tint: LiquidTint.frostStrong,
      padding: const EdgeInsets.all(4),
      child: SizedBox(
        width: _segment * 2,
        height: _height,
        child: Stack(
          children: [
            // Sliding active background.
            AnimatedAlign(
              duration: const Duration(milliseconds: 220),
              curve: AppCurves.out,
              alignment: km ? Alignment.centerLeft : Alignment.centerRight,
              child: Container(
                width: _segment,
                height: _height,
                decoration: BoxDecoration(
                  color: AppColors.blueDeep,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            Row(
              children: [
                _Segment(
                  label: 'ភាសាខ្មែរ',
                  selected: km,
                  onTap: () => ref.read(langProvider.notifier).set(AppLang.km),
                ),
                _Segment(
                  label: 'English',
                  selected: !km,
                  onTap: () => ref.read(langProvider.notifier).set(AppLang.en),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: LanguagePill._segment,
      height: LanguagePill._height,
      child: Semantics(
        button: true,
        selected: selected,
        child: AppPressable(
          // Already-selected segment is inert (basic cursor, no haptic).
          onTap: selected ? null : onTap,
          haptic: AppHaptic.selection,
          builder: (context, hovered, pressed) => AnimatedContainer(
            duration: const Duration(milliseconds: 130),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: !selected && (hovered || pressed)
                  ? AppColors.blueDeep.withValues(alpha: pressed ? 0.14 : 0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.white : AppColors.blueDeep,
                fontFamilyFallback: const ['Noto Sans Khmer'],
              ),
              child: Text(label),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact `ខ្មែរ / EN` pill for app bars — tap to switch language. Hover
/// highlights it; press scales it to 0.95.
class LanguageCompactToggle extends ConsumerWidget {
  const LanguageCompactToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(langProvider);
    TextStyle s(bool active) => TextStyle(
      fontSize: 12,
      fontWeight: active ? FontWeight.w800 : FontWeight.w500,
      color: active ? AppColors.blueDeep : AppColors.slate,
      fontFamilyFallback: const ['Noto Sans Khmer'],
    );
    return Semantics(
      button: true,
      label: ref.tr('switch_language'),
      child: AppPressable(
        onTap: () => ref.read(langProvider.notifier).toggle(),
        haptic: AppHaptic.selection,
        builder: (context, hovered, pressed) => AnimatedScale(
          duration: const Duration(milliseconds: 120),
          curve: AppCurves.out,
          scale: pressed ? 0.95 : 1.0,
          child: LiquidGlassContainer(
            radius: 16,
            useBlur: false,
            hovered: hovered,
            pressed: pressed,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: 'ខ្មែរ', style: s(lang == AppLang.km)),
                  TextSpan(text: ' / ', style: s(false)),
                  TextSpan(text: 'EN', style: s(lang == AppLang.en)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
