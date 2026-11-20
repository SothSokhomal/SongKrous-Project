import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/animations/app_animations.dart';
import '../../core/constants/app_state.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import 'app_interactive.dart';
import 'liquid_glass.dart';

/// Language pill `🇰🇭 | 🇬🇧`: country flags instead of words, with a sliding
/// active background (220 ms), a soft hover tint on the inactive flag and a
/// selection haptic.
class LanguagePill extends ConsumerWidget {
  const LanguagePill({super.key});

  static const double _segment = 56;
  static const double _height = 38;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(langProvider);
    final km = lang == AppLang.km;

    return LiquidGlassContainer(
      radius: 24,
      tint: LiquidTint.frostStrong,
      // Sits on a solid header/canvas: a backdrop blur would add nothing.
      useBlur: false,
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
                  key: const ValueKey('pill-km'),
                  flag: kFlagKh,
                  label: 'ភាសាខ្មែរ',
                  selected: km,
                  onTap: () => ref.read(langProvider.notifier).set(AppLang.km),
                ),
                _Segment(
                  key: const ValueKey('pill-en'),
                  flag: kFlagEn,
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

/// Flag emoji for each language (Cambodia / United Kingdom).
const String kFlagKh = '🇰🇭';
const String kFlagEn = '🇬🇧';

class _Segment extends StatelessWidget {
  const _Segment({
    super.key,
    required this.flag,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  /// Shown on screen.
  final String flag;

  /// The language's own name — read out by screen readers, never drawn.
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
        label: label,
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
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 220),
              opacity: selected ? 1 : 0.7,
              child: Text(
                flag,
                style: const TextStyle(fontSize: 22, height: 1.2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact `🇰🇭 🇬🇧` switch for app bars — tap a flag to pick that language.
/// The active flag sits on a deep-blue chip; hover/press give feedback.
class LanguageCompactToggle extends ConsumerWidget {
  const LanguageCompactToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(langProvider);
    return LiquidGlassContainer(
      radius: 18,
      useBlur: false,
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _FlagChip(
            key: const ValueKey('compact-km'),
            flag: kFlagKh,
            label: 'ភាសាខ្មែរ',
            selected: lang == AppLang.km,
            onTap: () => ref.read(langProvider.notifier).set(AppLang.km),
          ),
          const SizedBox(width: 2),
          _FlagChip(
            key: const ValueKey('compact-en'),
            flag: kFlagEn,
            label: 'English',
            selected: lang == AppLang.en,
            onTap: () => ref.read(langProvider.notifier).set(AppLang.en),
          ),
        ],
      ),
    );
  }
}

class _FlagChip extends StatelessWidget {
  const _FlagChip({
    super.key,
    required this.flag,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String flag;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: AppPressable(
        onTap: selected ? null : onTap,
        haptic: AppHaptic.selection,
        builder: (context, hovered, pressed) => AnimatedScale(
          duration: const Duration(milliseconds: 120),
          curve: AppCurves.out,
          scale: pressed ? 0.92 : 1.0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: AppCurves.out,
            width: 36,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.blueDeep
                  : hovered
                  ? AppColors.blueDeep.withValues(alpha: 0.10)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Opacity(
              opacity: selected ? 1 : 0.7,
              child: Text(
                flag,
                style: const TextStyle(fontSize: 18, height: 1.2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
