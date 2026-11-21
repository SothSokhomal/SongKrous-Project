import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/animations/app_animations.dart';
import '../../../core/animations/staggered_entrance.dart';
import '../../../core/constants/app_state.dart';
import '../../../core/constants/facilities.dart';
import '../../../core/constants/phnom_penh_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/floating_bottom_nav.dart';
import '../../../shared/widgets/app_interactive.dart';
import '../../../shared/widgets/liquid_glass.dart';
import 'map_markers.dart';

/// Contents of the Grab-style bottom sheet (State B).
///
/// Everything — handle, category tabs, header and rows — lives in ONE
/// [CustomScrollView] driven by the sheet's [scrollController], so a drag that
/// starts anywhere on the card moves the sheet (never gets "stuck").
///
/// [collapsed] switches between the sleek peek header (handle + `Nearby
/// Hospitals (3)` + swipe hint + ✕) and the full header (tabs + title) with
/// the facility rows.
class NearbySheet extends ConsumerWidget {
  const NearbySheet({
    super.key,
    required this.scrollController,
    required this.collapsed,
    required this.category,
    required this.results,
    required this.selectedId,
    required this.rowKeys,
    required this.onHandleTap,
    required this.onCategory,
    required this.onClose,
    required this.onSelect,
    this.onDirection,
    required this.onCall,
  });

  final ScrollController scrollController;

  /// True while the sheet is dragged down to its peek size.
  final ValueListenable<bool> collapsed;
  final EmergencyCategory category;
  final List<RankedFacility> results;

  /// Facility the route currently leads to (highlighted row).
  final String? selectedId;

  /// One key per facility id, so the map screen can scroll a row into view.
  final Map<String, GlobalKey> rowKeys;

  final VoidCallback onHandleTap;
  final ValueChanged<EmergencyCategory?> onCategory;
  final VoidCallback onClose;
  final ValueChanged<Facility> onSelect;
  final ValueChanged<Facility>? onDirection;
  final ValueChanged<Facility> onCall;

  String _title(WidgetRef ref) => switch (category) {
    FacilityType.hospital => ref.tr('nearby_hospitals'),
    FacilityType.police => ref.tr('nearby_police'),
    FacilityType.fire => ref.tr('nearby_fire'),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = _title(ref);
    // One frosted-glass surface (σ 24, ~0.88 white) with a specular rim: the
    // map shows softly through the sheet while the rows stay ultra-clean.
    return LiquidGlassContainer(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      tint: LiquidTint.frostStrong,
      sigma: 24,
      child: ValueListenableBuilder<bool>(
        valueListenable: collapsed,
        builder: (context, isCollapsed, _) => Stack(
          children: [
            Positioned.fill(
              child: CustomScrollView(
                controller: scrollController,
                // Always scrollable so the sheet can be dragged even when the
                // content is shorter than the viewport (e.g. fully expanded).
                physics: const AlwaysScrollableScrollPhysics(
                  parent: ClampingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(child: _Handle(onTap: onHandleTap)),
                  SliverToBoxAdapter(
                    child: AnimatedCrossFade(
                      duration: const Duration(milliseconds: 200),
                      sizeCurve: AppCurves.out,
                      crossFadeState: isCollapsed
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      layoutBuilder: (top, topKey, bottom, bottomKey) => Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.topCenter,
                        children: [
                          Positioned(
                            key: bottomKey,
                            top: 0,
                            left: 0,
                            right: 0,
                            child: bottom,
                          ),
                          Positioned(key: topKey, child: top),
                        ],
                      ),
                      // The hidden header stays in the tree for the cross-fade but is
                      // inert (no taps, no screen-reader nodes).
                      firstChild: _Inert(
                        inert: isCollapsed,
                        child: _ExpandedHeader(
                          category: category,
                          title: title,
                          onCategory: onCategory,
                          onClose: onClose,
                        ),
                      ),
                      secondChild: _Inert(
                        inert: !isCollapsed,
                        child: _PeekHeader(
                          title: '$title (${ref.num('${results.length}')})',
                          onClose: onClose,
                        ),
                      ),
                    ),
                  ),
                  // Faded-out rows must not catch taps while the sheet is peeking.
                  SliverIgnorePointer(
                    ignoring: isCollapsed,
                    sliver: SliverAnimatedOpacity(
                      opacity: isCollapsed ? 0 : 1,
                      duration: const Duration(milliseconds: 200),
                      sliver: SliverToBoxAdapter(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          switchInCurve: AppCurves.out,
                          switchOutCurve: AppCurves.out,
                          layoutBuilder: (current, previous) => Stack(
                            alignment: Alignment.topCenter,
                            children: [...previous, ?current],
                          ),
                          // New key per category → cross-fade + fresh stagger.
                          child: _Rows(
                            key: ValueKey(category.name),
                            results: results,
                            selectedId: selectedId,
                            rowKeys: rowKeys,
                            onSelect: onSelect,
                            onDirection: onDirection,
                            onCall: onCall,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Last card clears the floating bottom nav bar.
                  const SliverToBoxAdapter(child: SizedBox(height: 110)),
                ],
              ),
            ),
            // The sheet extends under the floating nav; this strip hides rows
            // scrolling through the gap below the nav pill (gap + system inset).
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height:
                  (MediaQuery.paddingOf(context).bottom -
                          FloatingBottomNav.height)
                      .clamp(0.0, 200.0),
              child: const ColoredBox(color: AppColors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _Inert extends StatelessWidget {
  const _Inert({required this.inert, required this.child});

  final bool inert;
  final Widget child;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    ignoring: inert,
    child: ExcludeSemantics(excluding: inert, child: child),
  );
}

/// 36×4 grabber. Tapping toggles collapsed ⇄ open; it darkens on hover.
class _Handle extends ConsumerWidget {
  const _Handle({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Semantics(
      button: true,
      label: ref.tr('toggle_list'),
      child: AppPressable(
        onTap: onTap,
        haptic: AppHaptic.selection,
        builder: (context, hovered, pressed) => SizedBox(
          height: 26,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 130),
              width: pressed ? 44 : 36,
              height: 4,
              decoration: BoxDecoration(
                color: hovered ? AppColors.slate : AppColors.slateLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Round ✕ with hover tint, press fade and a selection haptic.
class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.tooltip, required this.onTap});

  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: AppPressable(
          onTap: onTap,
          haptic: AppHaptic.selection,
          builder: (context, hovered, pressed) => AnimatedOpacity(
            duration: const Duration(milliseconds: 100),
            opacity: pressed ? 0.5 : 1.0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 130),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: hovered
                    ? AppColors.slate.withValues(alpha: 0.12)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded, color: AppColors.slate),
            ),
          ),
        ),
      ),
    );
  }
}

/// Collapsed header: `Nearby Hospitals (3)` · `Swipe up ⌃` · ✕.
class _PeekHeader extends ConsumerWidget {
  const _PeekHeader({required this.title, required this.onClose});

  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    return SizedBox(
      height: 44,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 4, 0),
        child: Row(
          children: [
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: Align(
                  key: ValueKey(title),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleMedium,
                  ),
                ),
              ),
            ),
            Text(
              ref.tr('swipe_up'),
              style: text.bodyMedium?.copyWith(
                color: AppColors.slate,
                fontSize: 12,
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_up_rounded,
              size: 20,
              color: AppColors.slate,
            ),
            _CloseButton(tooltip: ref.tr('close_sheet'), onTap: onClose),
          ],
        ),
      ),
    );
  }
}

/// Open header: category tabs + `Nearby … / Closest first` + ✕.
class _ExpandedHeader extends ConsumerWidget {
  const _ExpandedHeader({
    required this.category,
    required this.title,
    required this.onCategory,
    required this.onClose,
  });

  final EmergencyCategory category;
  final String title;
  final ValueChanged<EmergencyCategory?> onCategory;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FilterBar(category: category, onCategory: onCategory),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 4, 0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      layoutBuilder: (current, previous) => Stack(
                        alignment: Alignment.centerLeft,
                        children: [...previous, ?current],
                      ),
                      child: Text(
                        title,
                        key: ValueKey(title),
                        style: text.titleMedium,
                      ),
                    ),
                    Text(
                      ref.tr('closest_first'),
                      style: text.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _CloseButton(tooltip: ref.tr('close_sheet'), onTap: onClose),
            ],
          ),
        ),
      ],
    );
  }
}

/// The facility rows, staggering in when the category changes.
class _Rows extends StatelessWidget {
  const _Rows({
    super.key,
    required this.results,
    required this.selectedId,
    required this.rowKeys,
    required this.onSelect,
    this.onDirection,
    required this.onCall,
  });

  final List<RankedFacility> results;
  final String? selectedId;
  final Map<String, GlobalKey> rowKeys;
  final ValueChanged<Facility> onSelect;
  final ValueChanged<Facility>? onDirection;
  final ValueChanged<Facility> onCall;

  @override
  Widget build(BuildContext context) {
    return StaggerScope(
      duration: const Duration(milliseconds: 420),
      builder: (context, animation) => Padding(
        padding: const EdgeInsets.fromLTRB(10, 4, 10, 0),
        child: Column(
          children: [
            for (var i = 0; i < results.length; i++)
              StaggeredEntrance(
                animation: animation,
                begin: (i * 0.18).clamp(0.0, 0.6),
                end: (i * 0.18).clamp(0.0, 0.6) + 0.4,
                offset: 12,
                child: Padding(
                  key: rowKeys.putIfAbsent(
                    results[i].facility.id,
                    GlobalKey.new,
                  ),
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _FacilityRow(
                    ranked: results[i],
                    selected: results[i].facility.id == selectedId,
                    onSelect: () => onSelect(results[i].facility),
                    onDirection: onDirection != null
                        ? () => onDirection!(results[i].facility)
                        : null,
                    onCall: () => onCall(results[i].facility),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Four tabs with a single underline that slides between them and takes the
/// active category's colour. `All` leaves State B.
class _FilterBar extends ConsumerWidget {
  const _FilterBar({required this.category, required this.onCategory});

  final EmergencyCategory category;
  final ValueChanged<EmergencyCategory?> onCategory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabs = <(EmergencyCategory?, String)>[
      (null, ref.tr('all')),
      (FacilityType.hospital, ref.tr('hospitals')),
      (FacilityType.police, ref.tr('police_tab')),
      (FacilityType.fire, ref.tr('fire_tab')),
    ];
    final index = category.index + 1;
    final activeColor = facilityColor(category);

    return Stack(
      children: [
        Row(
          children: [
            for (final (type, label) in tabs)
              Expanded(
                child: Semantics(
                  button: true,
                  selected: category == type,
                  child: AppPressable(
                    onTap: () => onCategory(type),
                    haptic: AppHaptic.selection,
                    builder: (context, hovered, pressed) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: AnimatedDefaultTextStyle(
                        duration: AppDurations.fast,
                        curve: AppCurves.out,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: category == type
                              ? FontWeight.w800
                              : FontWeight.w500,
                          // Inactive tabs shift toward their category colour
                          // on hover.
                          color: category == type
                              ? facilityColor(type!)
                              : hovered
                              ? Color.lerp(
                                  AppColors.slate,
                                  type == null
                                      ? AppColors.blue
                                      : facilityColor(type),
                                  0.75,
                                )!
                              : AppColors.slate,
                          fontFamilyFallback: const ['Noto Sans Khmer'],
                        ),
                        child: Opacity(
                          opacity: pressed ? 0.55 : 1,
                          child: Text(label),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedAlign(
              duration: AppDurations.medium,
              curve: AppCurves.out,
              alignment: Alignment(-1 + 2 * index / (tabs.length - 1), 1),
              child: FractionallySizedBox(
                widthFactor: 1 / tabs.length,
                child: AnimatedContainer(
                  duration: AppDurations.fast,
                  height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: activeColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FacilityRow extends ConsumerWidget {
  const _FacilityRow({
    required this.ranked,
    required this.selected,
    required this.onSelect,
    this.onDirection,
    this.onCall,
  });

  final RankedFacility ranked;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback? onDirection;
  final VoidCallback? onCall;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = ranked.facility;
    final lang = ref.watch(langProvider);
    final color = facilityColor(f.type);
    final text = Theme.of(context).textTheme;
    final tint = f.type == FacilityType.police
        ? const Color(0xFFEFF6FF)
        : const Color(0xFFFEF2F2);
    final tag = switch (f.type) {
      FacilityType.hospital => ref.tr('tag_er'),
      FacilityType.police => ref.tr('tag_police'),
      FacilityType.fire => '${ref.tr('tag_fire')} · ${ref.num(f.phone)}',
    };

    return AppInteractiveCard(
      selected: selected,
      onTap: onSelect,
      semanticLabel: f.name(lang),
      radius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      haptic: AppHaptic.selection,
      // Soft tinted selection (`#EFF6FF` police, `#FEF2F2` hospital/fire).
      surface: Colors.transparent,
      selectedSurface: tint,
      hoverSurface: f.type == FacilityType.police
          ? const Color(0xFFF8FAFF)
          : const Color(0xFFFFFBFB),
      restBorder: null,
      hoverBorder: f.type == FacilityType.police
          ? const Color(0xFF93C5FD)
          : const Color(0xFFFCA5A5),
      selectedBorder: color.withValues(alpha: 0.55),
      builder: (context, hovered, pressed) => Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(facilityIcon(f.type), color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  f.name(lang),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleMedium?.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 3),
                Wrap(
                  spacing: 8,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      ranked.summary(lang),
                      style: text.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (selected && f.type != FacilityType.fire) ...[
            const SizedBox(width: 8),
            AppScaleButton(
              tooltip: ref.tr('directions'),
              semanticLabel: '${ref.tr('directions')} ${f.name(lang)}',
              onTap: onDirection,
              hoverScale: 1.08,
              pressScale: 0.90,
              haptic: AppHaptic.medium,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.near_me_rounded,
                  size: 20,
                  color: AppColors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
