import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_state.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/facilities.dart';
import '../../core/constants/khans.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_interactive.dart';
import '../../shared/widgets/liquid_glass.dart';
import '../../shared/widgets/main_shell.dart';

/// Hotlines tab — searchable Khan directory.
class HotlinesScreen extends ConsumerStatefulWidget {
  const HotlinesScreen({super.key});

  @override
  ConsumerState<HotlinesScreen> createState() => _HotlinesScreenState();
}

class _HotlinesScreenState extends ConsumerState<HotlinesScreen> {
  String _query = '';

  void _dial(String name, String number) =>
      context.push(AppRoutes.calling(name, number));

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final lang = ref.watch(langProvider);
    final q = _query.trim().toLowerCase();
    final khans = PhnomPenhKhans.all
        .where(
          (k) =>
              q.isEmpty || k.en.toLowerCase().contains(q) || k.km.contains(q),
        )
        .toList();

    return LiquidAmbientCanvas(
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                MainShell.navClearance(context),
              ),
              children: [
                Text(ref.tr('hotlines_title'), style: text.headlineMedium),
                const SizedBox(height: 16),
                Text(ref.tr('khan_directory'), style: text.titleLarge),
                const SizedBox(height: 12),
                AppFocusInput(
                  radius: 28,
                  glass: true,
                  glassBlur: false,
                  builder: (context, node) => TextField(
                    focusNode: node,
                    maxLength: 40,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: AppFocusInput.bareDecoration(
                      counterText: '',
                      hintText: ref.tr('search_khan'),
                      prefixIcon: const Icon(Icons.search_rounded),
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                for (final k in khans) ...[
                  _KhanTile(
                    title: lang == AppLang.km ? 'ខណ្ឌ${k.km}' : 'Khan ${k.en}',
                    subtitle:
                        '${ref.tr('khan_police')} · ${ref.num(EmergencyNumbers.police)}',
                    onCall: () => _dial(
                      lang == AppLang.km ? 'ខណ្ឌ${k.km}' : 'Khan ${k.en}',
                      // TODO(data): per-Khan station numbers; until then dial
                      // the national police line.
                      EmergencyNumbers.police,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _KhanTile extends ConsumerWidget {
  const _KhanTile({
    required this.title,
    required this.subtitle,
    required this.onCall,
  });

  final String title;
  final String subtitle;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    return AppInteractiveCard(
      semanticLabel: title,
      onTap: onCall,
      radius: 20,
      glass: LiquidTint.frost,
      haptic: AppHaptic.selection,
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      builder: (context, hovered, pressed) => Row(
        children: [
          const LayeredIconBadge(icon: Icons.location_city_rounded, size: 42),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: text.titleMedium),
                Text(subtitle, style: text.bodyMedium),
              ],
            ),
          ),
          // The call button pops independently of the row.
          AppScaleButton(
            tooltip: title,
            semanticLabel: '${ref.tr('call')} $title',
            onTap: onCall,
            haptic: AppHaptic.medium,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: hovered ? AppColors.blue : AppColors.blueSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.call_rounded,
                size: 20,
                color: hovered ? AppColors.white : AppColors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
