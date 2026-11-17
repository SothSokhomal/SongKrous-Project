import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_state.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';

/// Soft-red warning card — tapping it jumps straight to SOS Direct Call.
class UrgentBanner extends ConsumerWidget {
  const UrgentBanner({super.key, this.bodyKey = 'urgent_body'});

  final String bodyKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      child: Material(
        color: AppColors.redSoft,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push(AppRoutes.sosCall),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.red,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ref.tr('urgent_title'),
                        style: text.titleMedium?.copyWith(
                          color: AppColors.red,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ref.tr(bodyKey),
                        style: text.bodyMedium?.copyWith(
                          color: AppColors.redDark,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.red),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
