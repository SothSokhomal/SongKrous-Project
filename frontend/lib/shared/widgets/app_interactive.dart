import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/animations/app_animations.dart';
import '../../core/theme/app_colors.dart';

/// Shared micro-interaction vocabulary.
///
/// Every interactive element answers touch within one frame (pressed state is
/// driven by raw pointer events, not by the delayed tap-down callback), shows
/// a distinct hover state for mouse/trackpad users and fires a haptic.
/// Pressed/hover visuals are *implicit* animations, so there are no
/// controllers to leak.

// ── Haptics ──────────────────────────────────────────────────────────────

enum AppHaptic { none, selection, light, medium, heavy }

abstract final class AppHaptics {
  /// Fire-and-forget; never throws (unsupported on web/desktop/tests).
  static void fire(AppHaptic kind) {
    final Future<void>? f = switch (kind) {
      AppHaptic.none => null,
      AppHaptic.selection => HapticFeedback.selectionClick(),
      AppHaptic.light => HapticFeedback.lightImpact(),
      AppHaptic.medium => HapticFeedback.mediumImpact(),
      AppHaptic.heavy => HapticFeedback.heavyImpact(),
    };
    if (f != null) unawaited(f.catchError((Object _) {}));
  }
}

// ── Base: hover + pressed + tap + haptic ─────────────────────────────────

/// Builds its child from `(hovered, pressed)` and handles the cursor, the
/// immediate pressed state, tap and haptic.
///
/// * Pressed is set on pointer-down (<1 frame) and cleared on up/cancel — or as
///   soon as the finger drags beyond the touch slop, so scrolling a list or
///   dragging the map sheet never leaves a row stuck "pressed".
/// * [hapticOnDown] fires the haptic on touch-down (buttons); otherwise it
///   fires when the tap is confirmed (cards, pins, tabs).
class AppPressable extends StatefulWidget {
  const AppPressable({
    super.key,
    required this.builder,
    this.onTap,
    this.haptic = AppHaptic.none,
    this.hapticOnDown = false,
    this.cursor,
    this.enabled = true,
    this.behavior = HitTestBehavior.opaque,
  });

  final Widget Function(BuildContext context, bool hovered, bool pressed)
  builder;

  /// `opaque` (default) makes the whole box tappable; use `deferToChild` for
  /// shapes that must only react on their painted area (map pins).
  final HitTestBehavior behavior;
  final VoidCallback? onTap;
  final AppHaptic haptic;
  final bool hapticOnDown;

  /// Defaults to the click cursor when tappable, basic otherwise.
  final MouseCursor? cursor;
  final bool enabled;

  bool get _active => enabled && onTap != null;

  @override
  State<AppPressable> createState() => _AppPressableState();
}

class _AppPressableState extends State<AppPressable> {
  bool _hovered = false;
  bool _pressed = false;
  Offset? _downAt;

  void _set({bool? hovered, bool? pressed}) {
    final h = hovered ?? _hovered;
    final p = pressed ?? _pressed;
    if (h == _hovered && p == _pressed) return;
    setState(() {
      _hovered = h;
      _pressed = p;
    });
  }

  void _down(PointerDownEvent e) {
    if (!widget._active) return;
    _downAt = e.position;
    _set(pressed: true);
    if (widget.hapticOnDown) AppHaptics.fire(widget.haptic);
  }

  void _move(PointerMoveEvent e) {
    final start = _downAt;
    if (_pressed &&
        start != null &&
        (e.position - start).distance > kTouchSlop) {
      _set(pressed: false); // it's a scroll/drag, not a press
    }
  }

  void _up(PointerEvent _) {
    _downAt = null;
    _set(pressed: false);
  }

  void _tap() {
    if (!widget._active) return;
    if (!widget.hapticOnDown) AppHaptics.fire(widget.haptic);
    widget.onTap!();
  }

  @override
  void didUpdateWidget(AppPressable old) {
    super.didUpdateWidget(old);
    if (!widget._active && (_pressed || _hovered)) {
      _pressed = false;
      _hovered = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = widget._active;
    return MouseRegion(
      cursor:
          widget.cursor ??
          (active ? SystemMouseCursors.click : SystemMouseCursors.basic),
      onEnter: active ? (_) => _set(hovered: true) : null,
      onExit: (_) => _set(hovered: false),
      child: Listener(
        onPointerDown: _down,
        onPointerMove: _move,
        onPointerUp: _up,
        onPointerCancel: _up,
        child: GestureDetector(
          behavior: widget.behavior,
          onTap: active ? _tap : null,
          child: widget.builder(
            context,
            _hovered && active,
            _pressed && active,
          ),
        ),
      ),
    );
  }
}

// ── A. Buttons ───────────────────────────────────────────────────────────

@immutable
class AppButtonColors {
  const AppButtonColors({
    required this.bg,
    required this.hover,
    required this.pressed,
    required this.fg,
    this.border,
    this.shadow,
  });

  final Color bg;
  final Color hover;
  final Color pressed;
  final Color fg;
  final Color? border;

  /// Glow colour; null → no elevation shadow (outline / ghost buttons).
  final Color? shadow;

  /// Primary Blue `#0F3D91` → hover `#174DB3` → pressed `#0A2B66`.
  static const primary = AppButtonColors(
    bg: AppColors.blueDeep,
    hover: Color(0xFF174DB3),
    pressed: Color(0xFF0A2B66),
    fg: AppColors.white,
    shadow: AppColors.blueDeep,
  );

  /// Emergency Red `#D91E2A` → hover `#E62E3B` → pressed `#A8131D`.
  static const danger = AppButtonColors(
    bg: AppColors.red,
    hover: Color(0xFFE62E3B),
    pressed: Color(0xFFA8131D),
    fg: AppColors.white,
    shadow: AppColors.red,
  );

  /// White button with a coloured outline; hover tints soft blue `#F1F5FF`.
  static AppButtonColors outline(Color accent) => AppButtonColors(
    bg: AppColors.white,
    hover: const Color(0xFFF1F5FF),
    pressed: const Color(0xFFE0E9FF),
    fg: accent,
    border: accent,
  );

  /// White pill on a dark-blue surface (e.g. "Copy Location").
  static const onDarkSolid = AppButtonColors(
    bg: AppColors.white,
    hover: Color(0xFFF1F5FF),
    pressed: Color(0xFFDCE6FF),
    fg: AppColors.blueDeep,
  );

  /// Translucent pill on a dark-blue surface (e.g. "View Map").
  static final onDarkGlass = AppButtonColors(
    bg: Colors.white.withValues(alpha: 0.16),
    hover: Colors.white.withValues(alpha: 0.26),
    pressed: Colors.white.withValues(alpha: 0.34),
    fg: AppColors.white,
  );

  /// Light pill with a hairline border (e.g. the Khan dropdown).
  static const pill = AppButtonColors(
    bg: AppColors.white,
    hover: Color(0xFFF1F5FF),
    pressed: Color(0xFFE0E9FF),
    fg: AppColors.textPrimary,
    border: Color(0xFFE2E8F0),
  );
}

/// Pill/rounded button with Default / Hover / Pressed / Disabled states.
///
/// Hover: pointer cursor, 1.5 px lift, softer larger glow, colour shift and a
/// trailing icon that slides 4 px right. Pressed: scales to 0.965, darker fill,
/// compressed shadow, haptic. Disabled/loading: 50 % opacity, basic cursor.
class AppInteractiveButton extends StatelessWidget {
  const AppInteractiveButton({
    super.key,
    this.label,
    this.child,
    required this.onPressed,
    this.colors = AppButtonColors.primary,
    this.trailingIcon,
    this.leadingIcon,
    this.haptic = AppHaptic.light,
    this.height = 56,
    this.radius,
    this.expand = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
    this.fontSize = 16,
    this.loading = false,
    this.semanticLabel,
  }) : assert(label != null || child != null);

  final String? label;

  /// Custom content (overrides [label] / icons' layout when provided).
  final Widget? child;
  final VoidCallback? onPressed;
  final AppButtonColors colors;
  final IconData? trailingIcon;
  final IconData? leadingIcon;
  final AppHaptic haptic;
  final double height;

  /// Defaults to a full pill (`height / 2`).
  final double? radius;

  /// Fill the available width (otherwise hug the content).
  final bool expand;
  final EdgeInsetsGeometry padding;
  final double fontSize;
  final bool loading;
  final String? semanticLabel;

  static const _dur = Duration(milliseconds: 130);

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final r = radius ?? height / 2;

    final pressable = AppPressable(
      enabled: enabled,
      onTap: onPressed,
      haptic: haptic,
      hapticOnDown: true,
      builder: (context, hovered, pressed) {
        final fill = pressed
            ? colors.pressed
            : hovered
            ? colors.hover
            : colors.bg;
        final glow = colors.shadow;
        final shadows = glow == null
            ? const <BoxShadow>[]
            : [
                BoxShadow(
                  color: glow.withValues(
                    alpha: pressed
                        ? 0.12
                        : hovered
                        ? 0.34
                        : 0.20,
                  ),
                  blurRadius: pressed
                      ? 4
                      : hovered
                      ? 20
                      : 10,
                  offset: Offset(
                    0,
                    pressed
                        ? 1
                        : hovered
                        ? 8
                        : 4,
                  ),
                ),
              ];

        final content =
            child ??
            Row(
              mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (loading)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: colors.fg,
                    ),
                  )
                else ...[
                  if (leadingIcon != null) ...[
                    Icon(leadingIcon, size: 20, color: colors.fg),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      label ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.fg,
                        fontSize: fontSize,
                        fontWeight: FontWeight.w700,
                        fontFamilyFallback: const ['Noto Sans Khmer'],
                      ),
                    ),
                  ),
                  if (trailingIcon != null) ...[
                    const SizedBox(width: 8),
                    // Nudges 4 px right on hover.
                    AnimatedSlide(
                      duration: _dur,
                      curve: AppCurves.out,
                      offset: Offset(hovered && !pressed ? 4 / 20 : 0, 0),
                      child: Icon(trailingIcon, size: 20, color: colors.fg),
                    ),
                  ],
                ],
              ],
            );

        return AnimatedOpacity(
          duration: _dur,
          opacity: enabled ? 1 : 0.5,
          child: AnimatedScale(
            duration: _dur,
            curve: AppCurves.out,
            scale: pressed ? 0.965 : 1.0,
            child: AnimatedContainer(
              duration: _dur,
              curve: AppCurves.out,
              height: height,
              padding: padding,
              // `alignment` makes a Container fill its parent — only wanted
              // for full-width buttons.
              alignment: expand ? Alignment.center : null,
              transform: Matrix4.translationValues(
                0,
                hovered && !pressed ? -1.5 : 0,
                0,
              ),
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(r),
                border: colors.border == null
                    ? null
                    : Border.all(color: colors.border!, width: 1.5),
                boxShadow: shadows,
              ),
              child: content,
            ),
          ),
        );
      },
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      // A Row with min size lets the button hug its content even inside a
      // Column (a bare Container with `alignment` would fill the width and
      // swallow map drags / clicks beside it).
      child: expand
          ? pressable
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [Flexible(child: pressable)],
            ),
    );
  }
}

// ── B. Cards & list rows ─────────────────────────────────────────────────

/// Card / list row with hover (border + surface tint + shadow lift), pressed
/// (0.98 sink + iOS-style highlight) and selected (2 px solid border + tint).
class AppInteractiveCard extends StatelessWidget {
  const AppInteractiveCard({
    super.key,
    this.child,
    this.builder,
    required this.onTap,
    this.selected = false,
    this.radius = 16,
    this.padding,
    this.haptic = AppHaptic.selection,
    this.surface = AppColors.white,
    this.hoverSurface = const Color(0xFFF8FAFF),
    this.selectedSurface = const Color(0xFFF1F5FF),
    this.restBorder = const Color(0xFFE2E8F0),
    this.hoverBorder = const Color(0xFF93C5FD),
    this.selectedBorder = AppColors.blueDeep,
    this.borderWidth = 1,
    this.pressedScale = 0.98,
    this.restShadow = const [],
    this.clip = Clip.none,
    this.semanticLabel,
  }) : assert(child != null || builder != null);

  final Widget? child;

  /// Content that reacts to hover/press (e.g. a growing accent strip).
  final Widget Function(BuildContext context, bool hovered, bool pressed)?
  builder;
  final VoidCallback? onTap;
  final bool selected;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final AppHaptic haptic;
  final Color surface;
  final Color hoverSurface;
  final Color selectedSurface;

  /// `null` → no border at rest.
  final Color? restBorder;
  final Color hoverBorder;
  final Color selectedBorder;
  final double borderWidth;
  final double pressedScale;
  final List<BoxShadow> restShadow;
  final Clip clip;
  final String? semanticLabel;

  static const _dur = Duration(milliseconds: 160);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      selected: selected,
      label: semanticLabel,
      child: AppPressable(
        onTap: onTap,
        haptic: haptic,
        builder: (context, hovered, pressed) {
          Color fill = selected
              ? selectedSurface
              : hovered
              ? hoverSurface
              : surface;
          if (pressed) {
            fill = Color.alphaBlend(
              Colors.black.withValues(alpha: 0.045),
              fill,
            );
          }
          final borderColor = selected
              ? selectedBorder
              : hovered
              ? hoverBorder
              : restBorder;
          final shadows = hovered && !pressed
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : restShadow;

          return AnimatedScale(
            duration: const Duration(milliseconds: 120),
            curve: AppCurves.out,
            scale: pressed ? pressedScale : 1.0,
            child: AnimatedContainer(
              duration: selected ? const Duration(milliseconds: 200) : _dur,
              curve: AppCurves.out,
              padding: padding,
              clipBehavior: clip,
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(radius),
                border: borderColor == null
                    ? null
                    : Border.all(
                        color: borderColor,
                        width: selected ? 2 : borderWidth,
                      ),
                boxShadow: shadows,
              ),
              child: builder != null
                  ? builder!(context, hovered, pressed)
                  : child,
            ),
          );
        },
      ),
    );
  }
}

// ── C. Text inputs ───────────────────────────────────────────────────────

/// Gives any text field the shared focus treatment: 1 px `#E2E8F0` →
/// hover `#94A3B8` → focused 2 px `#0F3D91` with a soft blue ring. The inner
/// field must draw no border of its own — use [bareDecoration].
class AppFocusInput extends StatefulWidget {
  const AppFocusInput({
    super.key,
    required this.builder,
    this.focusNode,
    this.radius = 16,
    this.fill = AppColors.white,
    this.restShadow = const [],
  });

  /// Builds the field, wired to the focus node this widget listens to.
  final Widget Function(BuildContext context, FocusNode focusNode) builder;
  final FocusNode? focusNode;
  final double radius;
  final Color fill;
  final List<BoxShadow> restShadow;

  /// `InputDecoration` with every border removed (the wrapper draws it).
  static InputDecoration bareDecoration({
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    Widget? prefix,
    String? counterText,
    int? hintMaxLines,
    TextStyle? hintStyle,
  }) => InputDecoration(
    hintText: hintText,
    hintMaxLines: hintMaxLines,
    hintStyle: hintStyle,
    prefixIcon: prefixIcon,
    prefix: prefix,
    suffixIcon: suffixIcon,
    counterText: counterText,
    filled: false,
    border: InputBorder.none,
    enabledBorder: InputBorder.none,
    focusedBorder: InputBorder.none,
    disabledBorder: InputBorder.none,
    errorBorder: InputBorder.none,
    focusedErrorBorder: InputBorder.none,
  );

  @override
  State<AppFocusInput> createState() => _AppFocusInputState();
}

class _AppFocusInputState extends State<AppFocusInput> {
  late FocusNode _node;
  bool _ownsNode = false;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _attach();
  }

  void _attach() {
    _ownsNode = widget.focusNode == null;
    _node = widget.focusNode ?? FocusNode();
    _node.addListener(_onFocus);
  }

  void _detach() {
    _node.removeListener(_onFocus);
    if (_ownsNode) _node.dispose();
  }

  @override
  void didUpdateWidget(AppFocusInput old) {
    super.didUpdateWidget(old);
    if (old.focusNode != widget.focusNode) {
      _detach();
      _attach();
    }
  }

  @override
  void dispose() {
    _detach();
    super.dispose();
  }

  void _onFocus() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final focused = _node.hasFocus;
    final color = focused
        ? AppColors.blueDeep
        : _hovered
        ? const Color(0xFF94A3B8)
        : const Color(0xFFE2E8F0);

    return MouseRegion(
      cursor: SystemMouseCursors.text,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: AppCurves.out,
        decoration: BoxDecoration(
          color: widget.fill,
          borderRadius: BorderRadius.circular(widget.radius),
          border: Border.all(color: color, width: focused ? 2 : 1),
          boxShadow: focused
              ? [
                  BoxShadow(
                    color: AppColors.blue.withValues(alpha: 0.12),
                    spreadRadius: 4,
                    blurRadius: 0,
                  ),
                ]
              : widget.restShadow,
        ),
        child: widget.builder(context, _node),
      ),
    );
  }
}

// ── Small controls ───────────────────────────────────────────────────────

/// Circular / icon control: scales up on hover, down on press, haptic.
/// (Round call buttons, map recenter, call-screen controls.)
class AppScaleButton extends StatelessWidget {
  const AppScaleButton({
    super.key,
    required this.child,
    required this.onTap,
    this.hoverScale = 1.08,
    this.pressScale = 0.90,
    this.haptic = AppHaptic.medium,
    this.hapticOnDown = false,
    this.semanticLabel,
    this.tooltip,
    this.tooltipTrigger,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double hoverScale;
  final double pressScale;
  final AppHaptic haptic;
  final bool hapticOnDown;
  final String? semanticLabel;
  final String? tooltip;

  /// e.g. `TooltipTriggerMode.manual` when long-press has another meaning.
  final TooltipTriggerMode? tooltipTrigger;

  @override
  Widget build(BuildContext context) {
    Widget w = Semantics(
      button: true,
      label: semanticLabel,
      child: AppPressable(
        onTap: onTap,
        haptic: haptic,
        hapticOnDown: hapticOnDown,
        builder: (context, hovered, pressed) => AnimatedScale(
          duration: const Duration(milliseconds: 130),
          curve: AppCurves.out,
          scale: pressed
              ? pressScale
              : hovered
              ? hoverScale
              : 1.0,
          child: child,
        ),
      ),
    );
    if (tooltip != null) {
      w = Tooltip(message: tooltip!, triggerMode: tooltipTrigger, child: w);
    }
    return w;
  }
}

/// iOS-style text/icon action (Back, Share): fades to 50 % while pressed and
/// shows a soft pill highlight on hover.
class AppPressFade extends StatelessWidget {
  const AppPressFade({
    super.key,
    required this.child,
    required this.onTap,
    this.haptic = AppHaptic.selection,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback onTap;
  final AppHaptic haptic;
  final EdgeInsetsGeometry padding;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: AppPressable(
        onTap: onTap,
        haptic: haptic,
        builder: (context, hovered, pressed) => AnimatedOpacity(
          duration: const Duration(milliseconds: 100),
          opacity: pressed ? 0.5 : 1.0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 130),
            curve: AppCurves.out,
            padding: padding,
            decoration: BoxDecoration(
              color: hovered
                  ? AppColors.blue.withValues(alpha: 0.09)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Inline text action ("Skip for now"): underline + tint on hover, fade on
/// press.
class AppTextLink extends StatelessWidget {
  const AppTextLink({
    super.key,
    required this.label,
    required this.onTap,
    this.color = AppColors.textSecondary,
    this.hoverColor = AppColors.blueDeep,
    this.haptic = AppHaptic.selection,
  });

  final String label;
  final VoidCallback onTap;
  final Color color;
  final Color hoverColor;
  final AppHaptic haptic;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: AppPressable(
        onTap: onTap,
        haptic: haptic,
        builder: (context, hovered, pressed) => AnimatedOpacity(
          duration: const Duration(milliseconds: 100),
          opacity: pressed ? 0.5 : 1.0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 130),
              style: TextStyle(
                color: hovered ? hoverColor : color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
                decoration: hovered
                    ? TextDecoration.underline
                    : TextDecoration.none,
                decorationColor: hoverColor,
                fontFamilyFallback: const ['Noto Sans Khmer'],
              ),
              child: Text(label),
            ),
          ),
        ),
      ),
    );
  }
}

/// iOS back affordance (`‹ Label`): the chevron nudges 3 px left on hover, the
/// whole control fades to 50 % while pressed and gets a soft hover pill.
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: AppPressable(
        onTap: onTap,
        haptic: AppHaptic.selection,
        builder: (context, hovered, pressed) => AnimatedOpacity(
          duration: const Duration(milliseconds: 100),
          opacity: pressed ? 0.5 : 1.0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 130),
            curve: AppCurves.out,
            padding: const EdgeInsets.fromLTRB(4, 8, 12, 8),
            decoration: BoxDecoration(
              color: hovered
                  ? AppColors.blue.withValues(alpha: 0.09)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSlide(
                  duration: const Duration(milliseconds: 130),
                  curve: AppCurves.out,
                  offset: Offset(hovered ? -3 / 28 : 0, 0),
                  child: const Icon(
                    Icons.chevron_left_rounded,
                    size: 28,
                    color: AppColors.blue,
                  ),
                ),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.blue,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamilyFallback: ['Noto Sans Khmer'],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
