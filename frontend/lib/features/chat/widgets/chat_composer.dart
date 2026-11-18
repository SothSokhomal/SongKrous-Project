import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/animations/app_animations.dart';
import '../../../core/animations/looping_animation.dart';
import '../../../core/constants/app_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_interactive.dart';
import '../models/chat_message.dart';
import '../services/photo_source.dart';
import 'attach_sheet.dart';
import 'chat_photo.dart';

/// Instagram-style pill composer.
///
/// * idle: `[camera] [ message… ] [gallery] [mic]`
/// * text typed or photo staged: the right side morphs into a blue send ↑
/// * recording: the whole pill morphs into a live voice-recording bar
///
/// Voice recording is simulated (timer + animated bars, no microphone yet).
/// // TODO: capture real audio (record package) and upload via the backend.
class ChatComposer extends ConsumerStatefulWidget {
  const ChatComposer({
    super.key,
    required this.phone,
    required this.onSendText,
    required this.onSendPhoto,
    required this.onSendVoice,
  });

  final String phone;
  final ValueChanged<String> onSendText;
  final void Function(String path, String caption) onSendPhoto;
  final void Function(int seconds, List<double> waveform) onSendVoice;

  @override
  ConsumerState<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends ConsumerState<ChatComposer> {
  static const _pill = Color(0xFFF1F5F9);

  final _text = TextEditingController();
  final _focus = FocusNode();
  String? _photo;
  bool _recording = false;
  int _seconds = 0;
  Timer? _timer;

  bool get _canSend => _text.text.trim().isNotEmpty || _photo != null;

  @override
  void dispose() {
    _timer?.cancel();
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  // ── Text / photo ──────────────────────────────────────────────────────

  void _submit() {
    if (!_canSend) return;
    final photo = _photo;
    final text = _text.text.trim();
    if (photo != null) {
      widget.onSendPhoto(photo, text);
    } else {
      widget.onSendText(text);
    }
    setState(() {
      _photo = null;
      _text.clear();
    });
  }

  Future<void> _openAttachSheet() async {
    final choice = await showAttachSheet(context);
    if (!mounted || choice == null) return;
    switch (choice) {
      case AttachChoice.demo:
        setState(() => _photo = kDemoPhotoPath);
      case AttachChoice.library:
        await _pick(PhotoOrigin.library);
      case AttachChoice.camera:
        await _pick(PhotoOrigin.camera);
    }
  }

  Future<void> _pick(PhotoOrigin origin) async {
    try {
      final path = await ref.read(photoSourceProvider).pick(origin);
      if (mounted && path != null) setState(() => _photo = path);
    } catch (_) {
      // No camera / permission denied / empty simulator library: offer the demo.
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(ref.tr('photo_unavailable')),
            action: SnackBarAction(
              label: ref.tr('use_demo'),
              onPressed: () => setState(() => _photo = kDemoPhotoPath),
            ),
          ),
        );
    }
  }

  // ── Voice (simulated) ─────────────────────────────────────────────────

  void _startRecording() {
    if (_recording) return;
    setState(() {
      _recording = true;
      _seconds = 0;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
  }

  void _stopRecording() {
    _timer?.cancel();
    _timer = null;
    setState(() => _recording = false);
  }

  void _sendVoice() {
    final seconds = _seconds;
    // Stable pseudo-waveform for the recorded note.
    final rnd = math.Random(seconds * 7919 + 13);
    final wave = [for (var i = 0; i < 24; i++) 0.2 + 0.8 * rnd.nextDouble()];
    _stopRecording();
    widget.onSendVoice(seconds, wave);
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSize(
          duration: AppDurations.fast,
          curve: AppCurves.out,
          alignment: Alignment.bottomCenter,
          child: _photo == null
              ? const SizedBox(width: double.infinity)
              : _StagedPhoto(
                  key: const ValueKey('staged'),
                  path: _photo!,
                  onRemove: () => setState(() => _photo = null),
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
          child: AnimatedSwitcher(
            duration: AppDurations.fast,
            switchInCurve: AppCurves.out,
            transitionBuilder: (child, a) => FadeTransition(
              opacity: a,
              child: ScaleTransition(
                scale: Tween(begin: 0.97, end: 1.0).animate(a),
                child: child,
              ),
            ),
            child: _recording ? _recordingBar() : _composerPill(),
          ),
        ),
      ],
    );
  }

  Widget _composerPill() {
    final hint = _photo != null
        ? ref.tr('chat_caption_hint')
        : ref.tr('chat_hint').replaceAll('{phone}', widget.phone);
    return AppFocusInput(
      key: const ValueKey('pill'),
      radius: 28,
      fill: _pill,
      focusNode: _focus,
      builder: (context, node) => Padding(
        padding: const EdgeInsets.all(5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Camera / attach.
            Tooltip(
              message: ref.tr('attach_photo'),
              child: AppInteractiveButton(
                height: 34,
                radius: 17,
                expand: false,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                semanticLabel: ref.tr('attach_photo'),
                colors: AppButtonColors.primary,
                haptic: AppHaptic.light,
                onPressed: _openAttachSheet,
                child: const Icon(
                  Icons.camera_alt_rounded,
                  size: 18,
                  color: AppColors.white,
                ),
              ),
            ),
            Expanded(
              child: TextField(
                controller: _text,
                focusNode: node,
                minLines: 1,
                maxLines: 4,
                onChanged: (_) => setState(() {}),
                textInputAction: TextInputAction.newline,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.45,
                  fontFamilyFallback: ['Noto Sans Khmer'],
                ),
                decoration: AppFocusInput.bareDecoration(hintText: hint)
                    .copyWith(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                    ),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, a) => FadeTransition(
                opacity: a,
                child: ScaleTransition(scale: a, child: child),
              ),
              child: _canSend
                  ? Tooltip(
                      key: const ValueKey('send'),
                      message: ref.tr('send'),
                      child: AppInteractiveButton(
                        height: 34,
                        radius: 17,
                        expand: false,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        semanticLabel: ref.tr('send'),
                        colors: AppButtonColors.primary,
                        haptic: AppHaptic.light,
                        onPressed: _submit,
                        child: const Icon(
                          Icons.arrow_upward_rounded,
                          size: 20,
                          color: AppColors.white,
                        ),
                      ),
                    )
                  : Row(
                      key: const ValueKey('idle'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _IdleIcon(
                          icon: Icons.photo_library_outlined,
                          tooltip: ref.tr('photo_from_library'),
                          onTap: () => _pick(PhotoOrigin.library),
                        ),
                        // Tap or hold the mic to start recording.
                        GestureDetector(
                          onLongPress: _startRecording,
                          child: _IdleIcon(
                            icon: Icons.mic_rounded,
                            tooltip: ref.tr('record_voice'),
                            // Holding the mic records; don't pop a tooltip.
                            tooltipTrigger: TooltipTriggerMode.manual,
                            onTap: _startRecording,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recordingBar() {
    return Container(
      key: const ValueKey('recording'),
      height: 44,
      padding: const EdgeInsets.fromLTRB(4, 0, 5, 0),
      decoration: BoxDecoration(
        color: _pill,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          AppTextLink(
            label: ref.tr('cancel'),
            color: AppColors.slate,
            hoverColor: AppColors.red,
            haptic: AppHaptic.selection,
            onTap: _stopRecording,
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Pulsing red recording dot.
                LoopingAnimation(
                  duration: const Duration(milliseconds: 1000),
                  reverse: true,
                  curve: AppCurves.inOut,
                  builder: (context, a) => FadeTransition(
                    opacity: Tween(begin: 0.35, end: 1.0).animate(a),
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  ChatMessage.formatDuration(_seconds),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 12),
                const Flexible(child: _LiveBars()),
              ],
            ),
          ),
          Tooltip(
            message: ref.tr('send_voice'),
            child: AppInteractiveButton(
              height: 34,
              radius: 17,
              expand: false,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              semanticLabel: ref.tr('send_voice'),
              colors: AppButtonColors.primary,
              haptic: AppHaptic.light,
              onPressed: _sendVoice,
              child: const Icon(
                Icons.arrow_upward_rounded,
                size: 20,
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IdleIcon extends StatelessWidget {
  const _IdleIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.tooltipTrigger,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final TooltipTriggerMode? tooltipTrigger;

  @override
  Widget build(BuildContext context) {
    return AppScaleButton(
      tooltip: tooltip,
      tooltipTrigger: tooltipTrigger,
      semanticLabel: tooltip,
      haptic: AppHaptic.selection,
      hoverScale: 1.1,
      pressScale: 0.88,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(7),
        child: Icon(icon, size: 24, color: AppColors.blueDeep),
      ),
    );
  }
}

/// Live sound bars while recording.
class _LiveBars extends StatelessWidget {
  const _LiveBars();

  @override
  Widget build(BuildContext context) {
    return LoopingAnimation(
      duration: const Duration(milliseconds: 1100),
      builder: (context, a) => SizedBox(
        height: 24,
        width: 110,
        child: CustomPaint(painter: _LiveBarsPainter(a)),
      ),
    );
  }
}

class _LiveBarsPainter extends CustomPainter {
  _LiveBarsPainter(this.t) : super(repaint: t);

  final Animation<double> t;

  @override
  void paint(Canvas canvas, Size size) {
    const bars = 20;
    final slot = size.width / bars;
    final w = slot * 0.5;
    final paint = Paint()..color = AppColors.blueDeep;
    for (var i = 0; i < bars; i++) {
      final level =
          0.25 + 0.75 * math.sin(t.value * 2 * math.pi + i * 0.7).abs();
      final h = 4 + level * (size.height - 4);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(i * slot + (slot - w) / 2, (size.height - h) / 2, w, h),
          Radius.circular(w / 2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LiveBarsPainter old) => false;
}

/// Thumbnail strip above the composer with a remove ✕.
class _StagedPhoto extends ConsumerWidget {
  const _StagedPhoto({super.key, required this.path, required this.onRemove});

  final String path;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: 76,
          height: 76,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: ChatPhoto(path: path),
                ),
              ),
              Positioned(
                top: -6,
                right: -6,
                child: AppScaleButton(
                  tooltip: ref.tr('remove_photo'),
                  semanticLabel: ref.tr('remove_photo'),
                  haptic: AppHaptic.selection,
                  onTap: onRemove,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.ink,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: AppColors.white,
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
