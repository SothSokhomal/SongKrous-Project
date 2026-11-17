import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_state.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/khans.dart';
import '../../core/theme/app_colors.dart';

/// Modal list of all 14 Phnom Penh Khans. Returns the chosen [Khan].
Future<Khan?> showKhanPicker(BuildContext context, {Khan? selected}) {
  return showModalBottomSheet<Khan>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _KhanSheet(selected: selected),
  );
}

class _KhanSheet extends ConsumerWidget {
  const _KhanSheet({this.selected});

  final Khan? selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(langProvider);
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                ref.tr('choose_khan'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final k in PhnomPenhKhans.all)
                  ListTile(
                    title: Text(lang == AppLang.km ? k.km : k.en),
                    subtitle: Text(lang == AppLang.km ? k.en : k.km),
                    trailing: k.id == selected?.id
                        ? const Icon(Icons.check_rounded, color: AppColors.blue)
                        : null,
                    onTap: () => Navigator.of(context).pop(k),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
