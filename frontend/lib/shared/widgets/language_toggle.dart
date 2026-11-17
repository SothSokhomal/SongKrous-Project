import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_state.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';

/// White pill with two segments: `ភាសាខ្មែរ | English` (onboarding headers).
class LanguagePill extends ConsumerWidget {
  const LanguagePill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(langProvider);
    Widget seg(String label, AppLang value) {
      final selected = lang == value;
      return Semantics(
        button: true,
        selected: selected,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => ref.read(langProvider.notifier).set(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? AppColors.blueDeep : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.white : AppColors.blueDeep,
                fontFamilyFallback: const ['Noto Sans Khmer'],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [seg('ភាសាខ្មែរ', AppLang.km), seg('English', AppLang.en)],
      ),
    );
  }
}

/// Compact `ខ្មែរ / EN` pill for app bars — tap to switch language.
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
      label: 'Switch language',
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => ref.read(langProvider.notifier).toggle(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
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
    );
  }
}
