import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/info_card.dart';

/// Safety: "What happened?" + "Tips to stay calm".
/// TODO: have medical / safety content reviewed by a qualified professional
/// before release — the guidance below is placeholder text.
class SafetyScreen extends ConsumerWidget {
  const SafetyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 110),
        children: [
          Text(ref.tr('what_happened'), style: text.headlineMedium),
          const SizedBox(height: 16),
          const InfoCard(
            icon: Icons.local_hospital_rounded,
            accent: AppColors.red,
            title: 'Medical emergency',
          ),
          const SizedBox(height: 12),
          const InfoCard(
            icon: Icons.local_fire_department_rounded,
            accent: AppColors.fire,
            title: 'Fire',
          ),
          const SizedBox(height: 12),
          const InfoCard(
            icon: Icons.car_crash_rounded,
            accent: AppColors.blue,
            title: 'Traffic accident',
          ),
          const SizedBox(height: 32),
          Text(ref.tr('tips_calm'), style: text.titleLarge),
          const SizedBox(height: 12),
          const InfoCard(
            icon: Icons.air_rounded,
            accent: AppColors.blue,
            title: 'Breathe slowly',
            subtitle: 'In for 4 seconds, out for 6.',
          ),
        ],
      ),
    );
  }
}
