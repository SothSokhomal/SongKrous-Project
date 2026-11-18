import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../core/animations/app_animations.dart';
import '../../core/constants/app_state.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/facilities.dart';
import '../../core/constants/khans.dart';
import '../../core/constants/phnom_penh_data.dart';
import '../../core/router/app_routes.dart';
import '../../core/state/location_state.dart';
import '../../core/state/map_state.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_interactive.dart';
import '../../shared/widgets/khan_picker.dart';
import '../../shared/widgets/liquid_glass.dart';
import 'route_guidance.dart';
import 'widgets/facility_sheet.dart';
import 'widgets/map_markers.dart';
import 'widgets/navigation_widgets.dart';

/// Nearby Map with progressive disclosure.
///
/// **State A** (`selectedMapTargetProvider == null`): clean map — search bar,
/// Khan pill, tappable pins and the recenter button only.
///
/// **State B** (a category is selected, by tapping a pin or a Home card): a
/// Grab-style bottom sheet is docked to the bottom edge *under* the floating
/// nav bar. It peeks (`Nearby Hospitals (3)`), opens half-way (category tabs +
/// rows) and expands fully; a route line is drawn from the user to the
/// selected (nearest by default) facility, the camera frames it above the
/// sheet, and a route pill rides 12 px above the sheet's top edge.
class NearbyMapScreen extends ConsumerStatefulWidget {
  const NearbyMapScreen({super.key});

  @override
  ConsumerState<NearbyMapScreen> createState() => _NearbyMapScreenState();
}

class _NearbyMapScreenState extends ConsumerState<NearbyMapScreen>
    with TickerProviderStateMixin {
  final _map = MapController();
  final _search = TextEditingController();
  final _searchFocus = FocusNode();

  /// Height of search bar + Khan pill (+ gaps) below the status bar.
  static const double _topUiHeight = 118;

  /// Sheet snap points (fractions of the map area's height).
  static const double _openSize = 0.45;
  static const double _hidePillAbove = 0.60;
  static const double _pillHeight = 64;

  Khan? _khan; // null = user's own khan
  bool _mapReady = false;
  bool _navigating = false;
  bool _syncPending = false;
  bool _opening = false;

  /// Category rendered while the sheet animates out (provider is already null).
  EmergencyCategory? _lastCategory;

  // ── Sheet ─────────────────────────────────────────────────────────────
  final _sheetController = DraggableScrollableController();

  /// Live sheet extent (0–1). The map never rebuilds for it — only the route
  /// pill listens.
  final _sheetExtent = ValueNotifier<double>(0.2);

  /// True while dragged down to the peek size (changes only at the threshold).
  final _collapsed = ValueNotifier<bool>(true);
  final Map<String, GlobalKey> _rowKeys = {};
  ScrollController? _sheetScroll;
  String? _currentSelectedId;
  double _bodyHeight = 800;
  double _minSize = 0.19;
  double _maxSize = 0.78;

  // Sheet + route pill fade (260 ms, ease-out).
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );
  late final CurvedAnimation _revealCurve = CurvedAnimation(
    parent: _reveal,
    curve: AppCurves.out,
  );

  // Smooth camera moves.
  late final AnimationController _cam = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );
  late final CurvedAnimation _camCurve = CurvedAnimation(
    parent: _cam,
    curve: AppCurves.out,
  );
  LatLng _fromCenter = PhnomPenh.center;
  LatLng _toCenter = PhnomPenh.center;
  double _fromZoom = PhnomPenh.zoom;
  double _toZoom = PhnomPenh.zoom;

  // Route line "draws" from the user to the destination.
  late final AnimationController _routeDraw = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  late final CurvedAnimation _routeCurve = CurvedAnimation(
    parent: _routeDraw,
    curve: AppCurves.out,
  );

  @override
  void initState() {
    super.initState();
    _cam.addListener(_onCamTick);
    _reveal.addStatusListener(_onRevealStatus);

    final initial = ref.read(selectedMapTargetProvider);
    if (initial != null) {
      // Arrived from a Home category card: animate State B in.
      _lastCategory = initial;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _reveal.forward();
        _routeDraw.forward(from: 0);
        _openSheet();
      });
    }
  }

  @override
  void dispose() {
    _cam.removeListener(_onCamTick);
    _reveal.removeStatusListener(_onRevealStatus);
    _revealCurve.dispose();
    _camCurve.dispose();
    _routeCurve.dispose();
    _reveal.dispose();
    _cam.dispose();
    _routeDraw.dispose();
    _sheetController.dispose();
    _sheetExtent.dispose();
    _collapsed.dispose();
    _search.dispose();
    _searchFocus.dispose();
    _map.dispose();
    super.dispose();
  }

  void _onRevealStatus(AnimationStatus status) {
    // Once fully hidden, forget the category so State A is truly clean.
    if (status == AnimationStatus.dismissed && mounted) {
      setState(() => _lastCategory = null);
    }
  }

  // ── Sheet control ─────────────────────────────────────────────────────

  bool _onSheetNotification(DraggableScrollableNotification n) {
    void apply() {
      if (!mounted) return;
      _sheetExtent.value = n.extent;
      _collapsed.value = n.extent <= _minSize + 0.05;
    }

    // Notifications can fire while the framework is laying out; defer then.
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => apply());
    } else {
      apply();
    }
    return false;
  }

  /// Slides the sheet from its peek position to half-open (0.45).
  Future<void> _openSheet() async {
    if (_opening) return;
    _opening = true;
    try {
      for (var i = 0; i < 10 && mounted && !_sheetController.isAttached; i++) {
        await SchedulerBinding.instance.endOfFrame;
      }
      if (!mounted || !_sheetController.isAttached) return;
      if (_sheetController.size < _openSize - 0.02) {
        if (MediaQuery.disableAnimationsOf(context)) {
          _sheetController.jumpTo(_openSize);
        } else {
          await _sheetController.animateTo(
            _openSize,
            duration: const Duration(milliseconds: 380),
            curve: AppCurves.out,
          );
        }
      }
      // After the rebuild for the new selection, so the right row is measured.
      SchedulerBinding.instance.addPostFrameCallback((_) {
        // One more frame: the sheet's scroll position is still settling the
        // layout for the new selection and would drop a just-started animation.
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) _ensureSelectedClear();
        });
        SchedulerBinding.instance.scheduleFrame();
      });
    } finally {
      _opening = false;
    }
  }

  void _animateSheet(double size, {int ms = 300}) {
    if (!_sheetController.isAttached) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _sheetController.jumpTo(size);
      return;
    }
    _sheetController.animateTo(
      size,
      duration: Duration(milliseconds: ms),
      curve: AppCurves.out,
    );
  }

  /// Handle tap: peek ⇄ half-open.
  void _toggleSheet() {
    if (!_sheetController.isAttached) return;
    if (_collapsed.value) {
      _animateSheet(_openSize);
    } else {
      _animateSheet(_minSize);
    }
  }

  /// Keeps the routed row clear of the floating nav bar (the sheet extends
  /// underneath it) by scrolling the sheet content.
  void _ensureSelectedClear() {
    final ctx = _rowKeys[_currentSelectedId]?.currentContext;
    final sc = _sheetScroll;
    if (ctx == null || sc == null || !sc.hasClients) return;
    final box = ctx.findRenderObject();
    if (box is! RenderBox || !box.attached) return;
    final bottom = box.localToGlobal(Offset(0, box.size.height)).dy;
    final limit = MediaQuery.sizeOf(context).height - _navBlock(context) - 12;
    final overflow = bottom - limit;
    if (overflow > 0) {
      sc.animateTo(
        math.min(sc.offset + overflow, sc.position.maxScrollExtent),
        duration: AppDurations.medium,
        curve: AppCurves.out,
      );
    }
  }

  /// Height of the floating nav bar (incl. its gap and the system inset) that
  /// overlays the bottom of the map area. Inside the shell body with
  /// `extendBody`, `padding.bottom` already equals exactly that.
  double _navBlock(BuildContext context) =>
      MediaQuery.paddingOf(context).bottom;

  // ── Camera ────────────────────────────────────────────────────────────

  void _onMapReady() {
    _mapReady = true;
    if (ref.read(selectedMapTargetProvider) != null) {
      _syncCamera(instant: true);
    }
  }

  void _onCamTick() {
    if (!_mapReady || !mounted) return;
    final t = _camCurve.value;
    double l(double a, double b) => a + (b - a) * t;
    _map.move(
      LatLng(
        l(_fromCenter.latitude, _toCenter.latitude),
        l(_fromCenter.longitude, _toCenter.longitude),
      ),
      l(_fromZoom, _toZoom),
    );
  }

  /// Stops a running programmatic camera move so it can't fight the user.
  void _cancelCameraAnimation() {
    if (_cam.isAnimating) _cam.stop();
  }

  void _animateTo(LatLng center, double zoom, {bool instant = false}) {
    if (!_mapReady) return;
    if (instant || MediaQuery.disableAnimationsOf(context)) {
      _cam.stop();
      _map.move(center, zoom);
      return;
    }
    final c = _map.camera;
    _fromCenter = c.center;
    _fromZoom = c.zoom;
    _toCenter = center;
    _toZoom = zoom;
    _cam.forward(from: 0);
  }

  void _scheduleSync() {
    if (_syncPending) return;
    _syncPending = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _syncPending = false;
      if (mounted) _syncCamera();
    });
  }

  /// State A → centre on the user. State B → frame user + route + destination
  /// in the area above the route pill and sheet. [keepSheet] frames for the
  /// sheet's current height (e.g. recenter while peeking) instead of the
  /// half-open one it is about to animate to.
  void _syncCamera({
    bool instant = false,
    bool redrawRoute = true,
    bool keepSheet = false,
  }) {
    if (!_mapReady) return;
    final category = ref.read(selectedMapTargetProvider);
    final loc = ref.read(locationProvider);

    if (category == null) {
      _animateTo(loc.latLng, PhnomPenh.zoom, instant: instant);
      return;
    }
    final sel = _selectedFor(loc, category, ref.read(selectedFacilityProvider));
    if (sel == null) return;

    final route = routeFor(loc.latLng, sel.facility);
    final size = _map.camera.nonRotatedSize;

    final extent = keepSheet
        ? _sheetExtent.value.clamp(_minSize, _openSize)
        : _openSize;
    // Top: search bar + Khan pill (+ pin/dot half-height). Bottom: sheet +
    // route pill + 12 px gap (+ pin half-height), so the whole route sits above.
    var top = MediaQuery.paddingOf(context).top + _topUiHeight + 36;
    var bottom = extent * _bodyHeight + _pillHeight + 12 + 20 + 44;
    final maxTotal = size.height * 0.85;
    if (top + bottom > maxTotal) {
      final k = maxTotal / (top + bottom);
      top *= k;
      bottom *= k;
    }
    final fit = CameraFit.bounds(
      bounds: LatLngBounds.fromPoints(route),
      padding: EdgeInsets.fromLTRB(44, top, 64, bottom),
      maxZoom: 16.5,
    ).fit(_map.camera);
    _animateTo(fit.center, fit.zoom, instant: instant);

    if (redrawRoute) {
      if (MediaQuery.disableAnimationsOf(context)) {
        _routeDraw.value = 1;
      } else {
        _routeDraw.forward(from: 0);
      }
    }
  }

  // ── Selection helpers ─────────────────────────────────────────────────

  RankedFacility? _selectedFor(
    UserLocation loc,
    EmergencyCategory category,
    String? id,
  ) {
    final ranked = rankFacilities(loc.latLng, type: category);
    for (final r in ranked) {
      if (r.facility.id == id) return r;
    }
    return ranked.firstOrNull; // nearest by default
  }

  void _select(Facility f) {
    _search.clear();
    _searchFocus.unfocus();
    ref.selectMapFacility(f);
  }

  /// Row tap: re-route, and bring a fully expanded sheet back down so the
  /// route is visible.
  void _selectFromSheet(Facility f) {
    ref.read(selectedFacilityProvider.notifier).set(f.id);
    if (_sheetController.isAttached &&
        _sheetController.size > _openSize + 0.05) {
      _animateSheet(_openSize);
    }
  }

  Future<void> _pickKhan() async {
    final loc = ref.read(locationProvider);
    final k = await showKhanPicker(context, selected: _khan ?? loc.khan);
    if (k == null) return;
    setState(() => _khan = k);
    _animateTo(k.center, PhnomPenh.zoom);
  }

  void _call(Facility f) =>
      context.push(AppRoutes.calling(f.name(ref.read(langProvider)), f.phone));

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Category changes drive the sheet, the fade and the camera.
    ref.listen<EmergencyCategory?>(selectedMapTargetProvider, (prev, next) {
      if (!mounted) return;
      final wasHidden = _reveal.isDismissed;
      setState(() {
        _navigating = false;
        if (next != null) _lastCategory = next;
      });
      if (next != null) {
        if (wasHidden) {
          // The sheet mounts at its peek size, then slides to half-open.
          _collapsed.value = true;
          _sheetExtent.value = _minSize;
        }
        _reveal.forward();
        _openSheet();
      } else {
        _reveal.reverse();
        _animateSheet(_minSize, ms: 260);
      }
      _scheduleSync();
    });
    ref.listen<String?>(selectedFacilityProvider, (prev, next) {
      if (!mounted) return;
      setState(() => _navigating = false);
      if (ref.read(selectedMapTargetProvider) != null) _openSheet();
      _scheduleSync();
    });

    final lang = ref.watch(langProvider);
    final loc = ref.watch(locationProvider);
    final category = ref.watch(selectedMapTargetProvider);
    final selectedId = ref.watch(selectedFacilityProvider);
    final query = _search.text;

    final shown = category ?? _lastCategory; // content while animating out
    final typeRanked = shown == null
        ? const <RankedFacility>[]
        : rankFacilities(loc.latLng, type: shown);
    final sel = category == null
        ? null
        : _selectedFor(loc, category, selectedId);
    final route = sel == null ? null : routeFor(loc.latLng, sel.facility);
    _currentSelectedId = sel?.facility.id;

    final pins = category == null
        ? rankFacilities(loc.latLng, query: query)
        : typeRanked;

    final navigating = _navigating && sel != null && route != null;

    return LayoutBuilder(
      builder: (context, box) {
        _bodyHeight = box.maxHeight;
        final safeTop = MediaQuery.paddingOf(context).top;
        // The peek bar must show handle + one row *above* the floating nav.
        _minSize = math.max(0.19, (_navBlock(context) + 72) / _bodyHeight);
        // Stop below the Khan pill and the recenter button.
        _maxSize = (1 - (safeTop + _topUiHeight + 70) / _bodyHeight)
            .clamp(_openSize + 0.1, 0.78)
            .toDouble();

        return Stack(
          children: [
            // 1 ── Map
            FlutterMap(
              mapController: _map,
              options: MapOptions(
                initialCenter: loc.latLng,
                initialZoom: PhnomPenh.zoom,
                minZoom: 10.5,
                maxZoom: 19.0,
                onMapReady: _onMapReady,
                // The user always wins: touching the map cancels any
                // in-flight programmatic camera move.
                onPointerDown: (_, _) => _cancelCameraAnimation(),
                onPositionChanged: (_, hasGesture) {
                  if (hasGesture) _cancelCameraAnimation();
                },
                // Free pan + zoom by finger, trackpad or mouse. Rotation is
                // deliberately left out (no accidental spinning).
                interactionOptions: const InteractionOptions(
                  flags:
                      InteractiveFlag.drag |
                      InteractiveFlag.flingAnimation |
                      InteractiveFlag.pinchMove |
                      InteractiveFlag.pinchZoom |
                      InteractiveFlag.doubleTapZoom |
                      InteractiveFlag.doubleTapDragZoom |
                      InteractiveFlag.scrollWheelZoom,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.songkrous.songkrous',
                ),
                if (sel != null && route != null)
                  AnimatedBuilder(
                    animation: _routeCurve,
                    builder: (context, _) => PolylineLayer(
                      polylines: _routePolylines(
                        route,
                        sel.facility.type == FacilityType.police
                            ? AppColors.blue
                            : AppColors.red,
                        _routeCurve.value,
                      ),
                    ),
                  ),
                MarkerLayer(
                  markers: [
                    for (final r in pins)
                      Marker(
                        key: ValueKey('marker-${r.facility.id}'),
                        point: r.facility.location,
                        width: 132,
                        height: 76,
                        child: FacilityPin(
                          facility: r.facility,
                          label: ref.tr(r.facility.type.name),
                          selected: sel?.facility.id == r.facility.id,
                          onTap: () => _select(r.facility),
                        ),
                      ),
                    Marker(
                      point: loc.latLng,
                      width: 64,
                      height: 64,
                      child: const UserBeacon(),
                    ),
                  ],
                ),
              ],
            ),

            // Required OpenStreetMap credit, kept to one tiny text line (no ⓘ
            // button, no flutter_map logo). Sits just above the nav bar and
            // never intercepts touches.
            Positioned(
              left: 12,
              bottom: _navBlock(context) + 6,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1.5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '© OpenStreetMap contributors',
                    style: TextStyle(
                      fontSize: 9.5,
                      color: AppColors.slate,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),

            // 2 ── Top controls: search + Khan pill, or the turn-by-turn banner
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: AnimatedSwitcher(
                    duration: AppDurations.medium,
                    switchInCurve: AppCurves.out,
                    switchOutCurve: AppCurves.out,
                    layoutBuilder: (current, previous) => Stack(
                      alignment: Alignment.topCenter,
                      children: [...previous, ?current],
                    ),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, -0.25),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: navigating
                        ? _buildBanner(route, sel, lang)
                        : _buildSearch(loc, query, lang),
                  ),
                ),
              ),
            ),

            // Recenter (right edge, below the top controls; hidden while the
            // search results or the turn-by-turn banner are open).
            Positioned(
              right: 16,
              top: safeTop + _topUiHeight + 22,
              child: AnimatedOpacity(
                opacity: (navigating || query.trim().isNotEmpty) ? 0 : 1,
                duration: AppDurations.fast,
                child: IgnorePointer(
                  ignoring: navigating || query.trim().isNotEmpty,
                  child: Tooltip(
                    message: ref.tr('recenter'),
                    child: AppInteractiveButton(
                      height: 44,
                      expand: false,
                      radius: 22,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      semanticLabel: ref.tr('recenter'),
                      colors: const AppButtonColors(
                        bg: AppColors.white,
                        hover: AppColors.white,
                        pressed: AppColors.white,
                        fg: AppColors.blueDeep,
                        glass: LiquidTint.frost,
                        blur: true,
                      ),
                      haptic: AppHaptic.light,
                      onPressed: () => category == null
                          ? _animateTo(loc.latLng, PhnomPenh.zoom)
                          : _syncCamera(redrawRoute: false, keepSheet: true),
                      child: const Icon(
                        Icons.my_location_rounded,
                        color: AppColors.blueDeep,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 3 + 4 ── Route pill (rides above the sheet) and the docked sheet.
            // Faded in/out with the reveal controller; removed once hidden.
            if (shown != null)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _reveal,
                  child: FadeTransition(
                    opacity: _revealCurve,
                    child: _buildSheetLayer(shown, typeRanked, sel, navigating),
                  ),
                  builder: (context, child) =>
                      _reveal.isDismissed ? const SizedBox.shrink() : child!,
                ),
              ),
            // 5 ── The floating bottom nav bar is drawn by MainShell on top.
          ],
        );
      },
    );
  }

  Widget _buildSheetLayer(
    EmergencyCategory shown,
    List<RankedFacility> typeRanked,
    RankedFacility? sel,
    bool navigating,
  ) {
    return Stack(
      children: [
        // Route card: 12 px above the sheet's top edge, tracking every drag
        // frame; fades out when the sheet is high enough to collide with the
        // search bar.
        if (sel != null)
          ValueListenableBuilder<double>(
            valueListenable: _sheetExtent,
            child: NavInfoPill(
              target: sel,
              navigating: navigating,
              onPrimary: () {
                if (navigating) {
                  _call(sel.facility);
                } else {
                  setState(() => _navigating = true);
                }
              },
              onDetails: () =>
                  context.push(AppRoutes.sosCall, extra: sel.facility),
            ),
            builder: (context, extent, pill) {
              final e = math.max(extent, _minSize);
              final hide = e > _hidePillAbove;
              return Positioned(
                left: 12,
                right: 12,
                bottom: e * _bodyHeight + 12,
                child: AnimatedOpacity(
                  opacity: hide ? 0 : 1,
                  duration: AppDurations.fast,
                  child: IgnorePointer(ignoring: hide, child: pill),
                ),
              );
            },
          ),

        // The sheet: full width, docked to the very bottom, under the nav bar.
        Positioned.fill(
          child: NotificationListener<DraggableScrollableNotification>(
            onNotification: _onSheetNotification,
            child: DraggableScrollableSheet(
              controller: _sheetController,
              initialChildSize: _minSize,
              minChildSize: _minSize,
              maxChildSize: _maxSize,
              snap: true,
              snapSizes: [_minSize, _openSize, _maxSize],
              snapAnimationDuration: const Duration(milliseconds: 280),
              builder: (context, scrollController) {
                _sheetScroll = scrollController;
                return NearbySheet(
                  scrollController: scrollController,
                  collapsed: _collapsed,
                  category: shown,
                  results: typeRanked,
                  selectedId: sel?.facility.id,
                  rowKeys: _rowKeys,
                  onHandleTap: _toggleSheet,
                  onCategory: (c) => ref.selectMapCategory(c),
                  onClose: () => ref.selectMapCategory(null),
                  onSelect: _selectFromSheet,
                  onCall: _call,
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBanner(List<LatLng>? route, RankedFacility? sel, AppLang lang) {
    final inst = firstInstruction(route!);
    final text = ref
        .tr('nav_head')
        .replaceAll('{dir}', ref.tr(inst.directionKey))
        .replaceAll('{dest}', sel!.facility.name(lang));
    return NavBanner(
      key: const ValueKey('nav-banner'),
      instruction: text,
      distance: inst.distanceLabel(lang),
      onExit: () => setState(() => _navigating = false),
    );
  }

  Widget _buildSearch(UserLocation loc, String query, AppLang lang) {
    final hasQuery = query.trim().isNotEmpty;
    final results = hasQuery
        ? rankFacilities(loc.latLng, query: query).take(4).toList()
        : const <RankedFacility>[];
    final khan = _khan ?? loc.khan;

    return Column(
      key: const ValueKey('search'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search: grey hairline → hover slate → focused blue ring.
        AppFocusInput(
          radius: 28,
          focusNode: _searchFocus,
          // Frosted glass: map streets refract through the bar.
          glass: true,
          builder: (context, node) => TextField(
            controller: _search,
            focusNode: node,
            onChanged: (_) => setState(() {}),
            textInputAction: TextInputAction.search,
            decoration: AppFocusInput.bareDecoration(
              hintText: ref.tr('search_hint'),
              hintMaxLines: 1,
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: !hasQuery
                  ? null
                  : AppScaleButton(
                      tooltip: ref.tr('clear_search'),
                      semanticLabel: ref.tr('clear_search'),
                      haptic: AppHaptic.selection,
                      onTap: () {
                        _search.clear();
                        setState(() {});
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Icon(Icons.close_rounded),
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (hasQuery)
          _SearchResults(results: results, lang: lang, onSelect: _select)
        else
          // Khan dropdown pill.
          AppInteractiveButton(
            height: 40,
            expand: false,
            fontSize: 14,
            padding: const EdgeInsets.fromLTRB(12, 0, 6, 0),
            colors: const AppButtonColors(
              bg: AppColors.white,
              hover: AppColors.white,
              pressed: AppColors.white,
              fg: AppColors.textPrimary,
              glass: LiquidTint.frost,
              blur: true,
            ),
            haptic: AppHaptic.selection,
            onPressed: _pickKhan,
            semanticLabel: lang == AppLang.km
                ? 'ខណ្ឌ${khan.km}'
                : 'Khan ${khan.en}',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  size: 18,
                  color: AppColors.blue,
                ),
                const SizedBox(width: 4),
                Text(
                  lang == AppLang.km ? 'ខណ្ឌ${khan.km}' : 'Khan ${khan.en}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontFamilyFallback: ['Noto Sans Khmer'],
                  ),
                ),
                const Icon(Icons.arrow_drop_down_rounded),
              ],
            ),
          ),
      ],
    );
  }

  /// White casing under a coloured line (Apple-Maps look). [progress] reveals
  /// the line from the user towards the destination.
  List<Polyline> _routePolylines(
    List<LatLng> route,
    Color color,
    double progress,
  ) {
    final pts = _partial(route, progress);
    if (pts.length < 2) return const [];
    return [
      Polyline(
        points: pts,
        strokeWidth: 6,
        color: color,
        borderStrokeWidth: 3,
        borderColor: Colors.white,
        strokeCap: StrokeCap.round,
        strokeJoin: StrokeJoin.round,
      ),
    ];
  }

  static List<LatLng> _partial(List<LatLng> route, double t) {
    if (t >= 1) return route;
    const d = Distance();
    final segs = <double>[];
    var total = 0.0;
    for (var i = 1; i < route.length; i++) {
      final m = d.as(LengthUnit.Meter, route[i - 1], route[i]);
      segs.add(m);
      total += m;
    }
    var remaining = total * t.clamp(0.0, 1.0);
    final out = <LatLng>[route.first];
    for (var i = 0; i < segs.length; i++) {
      if (remaining >= segs[i]) {
        out.add(route[i + 1]);
        remaining -= segs[i];
      } else {
        final f = segs[i] == 0 ? 0.0 : remaining / segs[i];
        out.add(
          LatLng(
            route[i].latitude + (route[i + 1].latitude - route[i].latitude) * f,
            route[i].longitude +
                (route[i + 1].longitude - route[i].longitude) * f,
          ),
        );
        break;
      }
    }
    return out;
  }
}

/// Dropdown of search matches under the search bar (State A).
class _SearchResults extends ConsumerWidget {
  const _SearchResults({
    required this.results,
    required this.lang,
    required this.onSelect,
  });

  final List<RankedFacility> results;
  final AppLang lang;
  final ValueChanged<Facility> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      elevation: 4,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(20),
      color: AppColors.white,
      clipBehavior: Clip.antiAlias,
      child: results.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: Text(ref.tr('no_results')),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final r in results)
                  ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: facilityColor(r.facility.type)
                          .withValues(alpha: 0.12),
                      child: Icon(
                        facilityIcon(r.facility.type),
                        size: 20,
                        color: facilityColor(r.facility.type),
                      ),
                    ),
                    title: Text(
                      r.facility.name(lang),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(r.summary(lang)),
                    onTap: () => onSelect(r.facility),
                  ),
              ],
            ),
    );
  }
}
