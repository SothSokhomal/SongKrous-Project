import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/phone_format.dart';

/// Visual state of the six boxes.
enum OtpBoxState { idle, verifying, success, error }

/// Six Liquid-Glass digit boxes driven by ONE hidden master [TextField].
///
/// Because a single real field owns the text, iOS SMS AutoFill
/// (`oneTimeCode`), backspace and pasting `123456` all behave natively —
/// there is no per-box cursor or focus juggling to get wrong.
///
/// The digits are kept as ASCII in [controller]; the boxes render them in the
/// active language's numerals.
class OtpPinInput extends StatefulWidget {
  const OtpPinInput({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.state,
    required this.shake,
    required this.lang,
    required this.semanticLabel,
    required this.digitLabel,
    this.length = 6,
    this.autofocus = true,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final OtpBoxState state;

  /// 0→1 while the error shake plays.
  final Animation<double> shake;
  final AppLang lang;
  final String semanticLabel;

  /// `n` → "Digit n of 6" (localized by the caller).
  final String Function(int n) digitLabel;
  final int length;
  final bool autofocus;

  @override
  State<OtpPinInput> createState() => _OtpPinInputState();
}

class _OtpPinInputState extends State<OtpPinInput>
    with SingleTickerProviderStateMixin {
  /// Blinking caret, only running while a box is active.
  late final AnimationController _blink = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_syncBlink);
    widget.controller.addListener(_syncBlink);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _syncBlink();
  }

  @override
  void didUpdateWidget(OtpPinInput old) {
    super.didUpdateWidget(old);
    if (old.focusNode != widget.focusNode) {
      old.focusNode.removeListener(_syncBlink);
      widget.focusNode.addListener(_syncBlink);
    }
    if (old.controller != widget.controller) {
      old.controller.removeListener(_syncBlink);
      widget.controller.addListener(_syncBlink);
    }
    _syncBlink();
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_syncBlink);
    widget.controller.removeListener(_syncBlink);
    _blink.dispose();
    super.dispose();
  }

  bool get _caretVisible =>
      widget.focusNode.hasFocus &&
      widget.state == OtpBoxState.idle &&
      widget.controller.text.length < widget.length;

  void _syncBlink() {
    if (!mounted) return;
    if (_caretVisible && !_reduceMotion) {
      if (!_blink.isAnimating) _blink.repeat(reverse: true);
    } else {
      if (_blink.isAnimating) _blink.stop();
      _blink.value = 1;
    }
  }

  void _focus() {
    widget.focusNode.requestFocus();
    SystemChannels.textInput.invokeMethod<void>('TextInput.show');
  }

  @override
  Widget build(BuildContext context) {
    const gap = 8.0;
    return Semantics(
      label: widget.semanticLabel,
      textField: true,
      child: AnimatedBuilder(
        animation: widget.shake,
        builder: (context, child) {
          final t = widget.shake.value;
          // Damped sine: three full swings over 380 ms.
          final dx = math.sin(t * math.pi * 6) * 10 * (1 - t);
          return Transform.translate(offset: Offset(dx, 0), child: child);
        },
        child: SizedBox(
          height: 56,
          child: Stack(
            children: [
              // The visible boxes.
              ExcludeSemantics(
                child: LayoutBuilder(
                  builder: (context, c) {
                    final w = math.min(
                      46.0,
                      (c.maxWidth - gap * (widget.length - 1)) / widget.length,
                    );
                    return AnimatedBuilder(
                      animation: Listenable.merge([
                        widget.controller,
                        widget.focusNode,
                      ]),
                      builder: (context, _) {
                        final text = widget.controller.text;
                        final focused = widget.focusNode.hasFocus;
                        final active = math.min(text.length, widget.length - 1);
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var i = 0; i < widget.length; i++) ...[
                              if (i > 0) const SizedBox(width: gap),
                              _OtpBox(
                                key: ValueKey('otp-box-$i'),
                                width: w,
                                digit: i < text.length ? text[i] : '',
                                lang: widget.lang,
                                state: widget.state,
                                isActive:
                                    focused &&
                                    i == active &&
                                    text.length < widget.length &&
                                    widget.state == OtpBoxState.idle,
                                blink: _blink,
                                semanticLabel: widget.digitLabel(i + 1),
                              ),
                            ],
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
              // The one real field, invisible, on top: taps focus it, paste and
              // AutoFill land in it.
              Positioned.fill(
                child: Theme(
                  data: Theme.of(context).copyWith(
                    textSelectionTheme: const TextSelectionThemeData(
                      cursorColor: Colors.transparent,
                      selectionColor: Colors.transparent,
                      selectionHandleColor: Colors.transparent,
                    ),
                  ),
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: _focus,
                    child: TextField(
                      key: const ValueKey('otp-field'),
                      controller: widget.controller,
                      focusNode: widget.focusNode,
                      autofocus: widget.autofocus,
                      expands: true,
                      maxLines: null,
                      minLines: null,
                      showCursor: false,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      inputFormatters: [OtpDigitsFormatter(widget.length)],
                      style: const TextStyle(
                        color: Colors.transparent,
                        fontSize: 22,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isCollapsed: true,
                        counterText: '',
                        fillColor: Colors.transparent,
                        filled: false,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OtpBox extends StatefulWidget {
  const _OtpBox({
    super.key,
    required this.width,
    required this.digit,
    required this.lang,
    required this.state,
    required this.isActive,
    required this.blink,
    required this.semanticLabel,
  });

  final double width;
  final String digit;
  final AppLang lang;
  final OtpBoxState state;
  final bool isActive;
  final Animation<double> blink;
  final String semanticLabel;

  @override
  State<_OtpBox> createState() => _OtpBoxState();
}

class _OtpBoxState extends State<_OtpBox> with SingleTickerProviderStateMixin {
  /// 1.0 → 1.08 → 1.0 in 140 ms whenever a digit lands.
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 140),
  );

  @override
  void didUpdateWidget(_OtpBox old) {
    super.didUpdateWidget(old);
    if (old.digit.isEmpty && widget.digit.isNotEmpty) {
      if (!MediaQuery.disableAnimationsOf(context)) _pop.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filled = widget.digit.isNotEmpty;
    final (
      Color border,
      double bw,
      Color? solid,
      Color ink,
    ) = switch (widget.state) {
      OtpBoxState.error => (
        AppColors.red,
        2.0,
        AppColors.redTint,
        AppColors.ink,
      ),
      OtpBoxState.success => (
        AppColors.blue,
        2.0,
        const Color(0xFFDBEAFE),
        AppColors.blueDeep,
      ),
      _ when widget.isActive => (AppColors.blueDeep, 2.0, null, AppColors.ink),
      _ when filled => (
        const Color(0xFFBFDBFE),
        1.2,
        AppColors.blueTint,
        AppColors.ink,
      ),
      _ => (AppColors.slateLight, 1.2, null, AppColors.ink),
    };

    return AnimatedBuilder(
      animation: _pop,
      builder: (context, child) => Transform.scale(
        scale: 1 + 0.08 * math.sin(_pop.value * math.pi),
        child: child,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        width: widget.width,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          // Frosted-glass fill unless a state tint overrides it.
          color: solid,
          gradient: solid != null
              ? null
              : LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.86),
                    Colors.white.withValues(alpha: 0.62),
                  ],
                ),
          border: Border.all(color: border, width: bw),
          boxShadow: [
            if (widget.isActive)
              BoxShadow(
                color: AppColors.blueDeep.withValues(alpha: 0.26),
                blurRadius: 14,
                spreadRadius: 1,
              )
            else if (widget.state == OtpBoxState.error)
              BoxShadow(
                color: AppColors.red.withValues(alpha: 0.16),
                blurRadius: 10,
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: filled
            ? Text(
                AppStrings.digits(widget.digit, widget.lang),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: ink,
                  height: 1.1,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  fontFamilyFallback: const ['Noto Sans Khmer'],
                ),
              )
            : widget.isActive
            ? FadeTransition(
                opacity: widget.blink,
                child: Container(
                  key: const ValueKey('otp-caret'),
                  width: 2,
                  height: 26,
                  decoration: BoxDecoration(
                    color: AppColors.blueDeep,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
