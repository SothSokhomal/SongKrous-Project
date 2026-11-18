import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_state.dart';
import '../../../shared/widgets/app_interactive.dart';

/// Minimal one-tap panic pills above the composer.
class QuickChips extends ConsumerWidget {
  const QuickChips({
    super.key,
    required this.onGps,
    required this.onAmbulance,
    required this.onBleeding,
    required this.onPolice,
  });

  final VoidCallback onGps;
  final VoidCallback onAmbulance;
  final VoidCallback onBleeding;
  final VoidCallback onPolice;

  static const _colors = AppButtonColors(
    bg: Color(0xFFF8FAFC),
    hover: Color(0xFFF1F5FF),
    pressed: Color(0xFFE0E9FF),
    fg: Color(0xFF0F172A),
    border: Color(0xFFE2E8F0),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget chip(String key, VoidCallback onTap) => AppInteractiveButton(
      height: 36,
      expand: false,
      fontSize: 13.5,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      colors: _colors,
      haptic: AppHaptic.light,
      label: ref.tr(key),
      onPressed: onTap,
    );

    return SizedBox(
      height: 40,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            chip('chip_gps', onGps),
            const SizedBox(width: 8),
            chip('chip_ambulance', onAmbulance),
            const SizedBox(width: 8),
            chip('chip_bleeding', onBleeding),
            const SizedBox(width: 8),
            chip('chip_police', onPolice),
          ],
        ),
      ),
    );
  }
}
