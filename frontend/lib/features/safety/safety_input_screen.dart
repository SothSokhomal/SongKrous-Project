import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/animations/app_animations.dart';
import '../../core/constants/app_state.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_interactive.dart';
import '../../shared/widgets/liquid_glass.dart';
import '../../shared/widgets/main_shell.dart';
import 'situation.dart';
import 'widgets/urgent_banner.dart';

/// Safety · Zero-friction Category Hub.
///
/// Direct 1-tap access to authoritative first aid & emergency instructions.
class SafetyInputScreen extends ConsumerStatefulWidget {
  const SafetyInputScreen({super.key});

  @override
  ConsumerState<SafetyInputScreen> createState() => _SafetyInputScreenState();
}

class _SafetyInputScreenState extends ConsumerState<SafetyInputScreen> {
  final _searchController = TextEditingController();
  SafetyTag _selectedTag = SafetyTag.all;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Situation> _filteredCategories(WidgetRef ref) {
    return Situation.categories.where((cat) {
      // 1. Tag filter
      if (_selectedTag != SafetyTag.all && cat.tag != _selectedTag) {
        return false;
      }
      // 2. Search query filter
      if (_searchQuery.isNotEmpty) {
        final title = ref.tr(cat.labelKey).toLowerCase();
        final sub = ref.tr(cat.subKey).toLowerCase();
        return title.contains(_searchQuery) || sub.contains(_searchQuery);
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final categories = _filteredCategories(ref);

    return LiquidAmbientCanvas(
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                20,
                8,
                20,
                MainShell.navClearance(context),
              ),
              children: [
                // Top branding header
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        ref.tr('safety_title'),
                        style: text.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.blueDeep,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.verified_user_rounded,
                      color: AppColors.blue,
                      size: 24,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Pinned urgent help banner
                const UrgentBanner(),
                const SizedBox(height: 18),

                // Search Bar
                _SearchBar(
                  controller: _searchController,
                  hint: ref.tr('safety_search_hint'),
                  onClear: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                ),
                const SizedBox(height: 14),

                // Quick Filter Pills
                _FilterPills(
                  selectedTag: _selectedTag,
                  onSelect: (tag) => setState(() => _selectedTag = tag),
                ),
                const SizedBox(height: 18),

                // Category list / grid
                if (categories.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(
                            Icons.search_off_rounded,
                            size: 48,
                            color: AppColors.slate,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            ref.tr('filter_no_results'),
                            style: text.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  for (final cat in categories) ...[
                    _CategoryCard(
                      situation: cat,
                      onTap: () => context.push(
                        '${AppRoutes.safetyTips}?situation=${cat.name}',
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Lightweight search bar with clean frosted look and quick clear action.
class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.hint,
    required this.onClear,
  });

  final TextEditingController controller;
  final String hint;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          const Icon(
            Icons.search_rounded,
            color: AppColors.textSecondary,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              style: const TextStyle(fontSize: 15),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: onClear,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.close_rounded,
                  color: AppColors.textSecondary,
                  size: 18,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Filter pills: All, Medical, Trauma, Rescue.
class _FilterPills extends ConsumerWidget {
  const _FilterPills({
    required this.selectedTag,
    required this.onSelect,
  });

  final SafetyTag selectedTag;
  final ValueChanged<SafetyTag> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildPill(ref, SafetyTag.all, 'filter_all'),
          const SizedBox(width: 8),
          _buildPill(ref, SafetyTag.medical, 'filter_medical'),
          const SizedBox(width: 8),
          _buildPill(ref, SafetyTag.trauma, 'filter_trauma'),
          const SizedBox(width: 8),
          _buildPill(ref, SafetyTag.rescue, 'filter_rescue'),
        ],
      ),
    );
  }

  Widget _buildPill(WidgetRef ref, SafetyTag tag, String labelKey) {
    final isSelected = selectedTag == tag;
    return GestureDetector(
      onTap: () => onSelect(tag),
      child: AnimatedContainer(
        duration: AppDurations.fast,
        curve: AppCurves.out,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.blueDeep : Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.blueDeep : AppColors.border,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.blueDeep.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          ref.tr(labelKey),
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

/// Zero-friction category card: 1 tap navigates straight to instructions.
class _CategoryCard extends ConsumerWidget {
  const _CategoryCard({
    required this.situation,
    required this.onTap,
  });

  final Situation situation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final stepCountText = ref
        .tr('step_count_label')
        .replaceAll('{n}', situation.steps.length.toString());

    return AppInteractiveCard(
      onTap: onTap,
      semanticLabel: ref.tr(situation.labelKey),
      radius: 20,
      glass: LiquidTint.frost,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      builder: (context, hovered, pressed) => Row(
        children: [
          // High-contrast circular icon badge
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: situation.iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                situation.icon,
                color: situation.iconColor,
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Title & Description & Step count chip
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        ref.tr(situation.labelKey),
                        style: text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.slateLight.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        stepCountText,
                        style: const TextStyle(
                          color: AppColors.blueDeep,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  ref.tr(situation.subKey),
                  style: text.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Subtle chevron
          AnimatedSlide(
            duration: AppDurations.fast,
            curve: AppCurves.out,
            offset: Offset(hovered ? 2 / 16 : 0, 0),
            child: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.slate,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}
