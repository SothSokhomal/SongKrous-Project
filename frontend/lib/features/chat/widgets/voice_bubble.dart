import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_state.dart';
import '../../../core/animations/app_animations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_interactive.dart';
import '../models/chat_message.dart';
import 'message_bubbles.dart';

/// Voice note: 32 px play/pause, 24 waveform bars that fill with playback
/// progress, and the duration (counting down while playing).
///
/// Playback is simulated — an [AnimationController] sweeps the progress over
/// the note's duration. // TODO: back this with real audio (just_audio) once
/// the voice file is available from the Telegram backend.
class VoiceBubble extends ConsumerStatefulWidget {
  const VoiceBubble({
    super.key,
    required this.message,
    required this.radius,
    required this.maxWidth,
  });

  final ChatMessage message;
  final BorderRadius radius;
  final double maxWidth;

  @override
  ConsumerState<VoiceBubble> createState() => _VoiceBubbleState();
}

class _VoiceBubbleState extends ConsumerState<VoiceBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress = AnimationController(
    vsync: this,
    duration: Duration(seconds: widget.message.voiceDurationSec ?? 1),
  )..addStatusListener(_onStatus);

  bool get _playing => _progress.isAnimating;

  void _onStatus(AnimationStatus s) {
    if (s == AnimationStatus.completed) _progress.value = 0; // rewind
    if (mounted) setState(() {});
  }

  void _toggle() {
    if (_playing) {
      _progress.stop();
    } else {
      if (_progress.value >= 1) _progress.value = 0;
      _progress.forward();
    }
    setState(() {});
  }

  @override
  void dispose() {
    _progress.removeStatusListener(_onStatus);
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.message;
    final me = m.isMe;
    final fg = me ? Colors.white : AppColors.blueDeep;
    final total = m.voiceDurationSec ?? 1;
    final samples = m.waveformSamples ?? List.filled(24, 0.4);

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: widget.maxWidth),
      child: Container(
        width: 250,
        padding: const EdgeInsets.fromLTRB(10, 9, 12, 8),
        decoration: BoxDecoration(
          color: me ? ChatColors.outgoing : ChatColors.incoming,
          borderRadius: widget.radius,
        ),
        child: Row(
          children: [
            AppScaleButton(
              semanticLabel: ref.tr('play_voice'),
              haptic: AppHaptic.light,
              hoverScale: 1.06,
              pressScale: 0.92,
              onTap: _toggle,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: me ? Colors.white : AppColors.blueDeep,
                  shape: BoxShape.circle,
                ),
                child: AnimatedSwitcher(
                  duration: AppDurations.fast,
                  transitionBuilder: (c, a) =>
                      ScaleTransition(scale: a, child: c),
                  child: Icon(
                    _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    key: ValueKey(_playing),
                    size: 20,
                    color: me ? AppColors.blueDeep : Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 28,
                child: CustomPaint(
                  painter: _WaveformPainter(
                    samples: samples,
                    progress: _progress,
                    active: fg,
                    inactive: fg.withValues(alpha: me ? 0.38 : 0.28),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AnimatedBuilder(
                  animation: _progress,
                  builder: (context, _) {
                    final left = _playing
                        ? (total * (1 - _progress.value)).ceil()
                        : total;
                    return Text(
                      ChatMessage.formatDuration(left, ref.watch(langProvider)),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: me ? Colors.white : ChatColors.incomingText,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 2),
                BubbleMeta(message: m),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 24 rounded bars; those before the playhead use the active colour.
class _WaveformPainter extends CustomPainter {
  _WaveformPainter({
    required this.samples,
    required this.progress,
    required this.active,
    required this.inactive,
  }) : super(repaint: progress);

  final List<double> samples;
  final Animation<double> progress;
  final Color active;
  final Color inactive;

  @override
  void paint(Canvas canvas, Size size) {
    const bars = 24;
    final slot = size.width / bars;
    final barW = slot * 0.55;
    final p = progress.value;
    for (var i = 0; i < bars; i++) {
      final s = samples[i % samples.length].clamp(0.0, 1.0);
      final h = 4 + s * (size.height - 4);
      final x = i * slot + (slot - barW) / 2;
      final paint = Paint()..color = (i + 0.5) / bars <= p ? active : inactive;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, (size.height - h) / 2, barW, h),
          Radius.circular(barW / 2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter old) =>
      old.samples != samples ||
      old.active != active ||
      old.inactive != inactive;
}
