import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_state.dart';
import '../../../core/animations/app_animations.dart';
import '../models/chat_message.dart';

/// Telegram delivery marks: clock → ✓ → ✓✓ → blue ✓✓, cross-fading as the
/// status changes.
class StatusTicks extends ConsumerWidget {
  const StatusTicks({
    super.key,
    required this.status,
    required this.color,
    required this.readColor,
    this.size = 14,
  });

  final MessageStatus status;

  /// Colour while sending / sent / delivered.
  final Color color;

  /// Colour once read.
  final Color readColor;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (icon, c) = switch (status) {
      MessageStatus.sending => (Icons.schedule_rounded, color),
      MessageStatus.sent => (Icons.done_rounded, color),
      MessageStatus.delivered => (Icons.done_all_rounded, color),
      MessageStatus.read => (Icons.done_all_rounded, readColor),
    };
    return Semantics(
      label: switch (status) {
        MessageStatus.sending => ref.tr('st_sending'),
        MessageStatus.sent => ref.tr('st_sent'),
        MessageStatus.delivered => ref.tr('st_delivered'),
        MessageStatus.read => ref.tr('st_read'),
      },
      child: AnimatedSwitcher(
        duration: AppDurations.fast,
        transitionBuilder: (child, a) => FadeTransition(
          opacity: a,
          child: ScaleTransition(scale: a, child: child),
        ),
        child: Icon(icon, key: ValueKey(status), size: size, color: c),
      ),
    );
  }
}
