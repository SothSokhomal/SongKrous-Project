import 'package:flutter/material.dart';

import '../../../core/animations/app_animations.dart';
import '../models/chat_message.dart';

/// Telegram delivery marks: clock → ✓ → ✓✓ → blue ✓✓, cross-fading as the
/// status changes.
class StatusTicks extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final (icon, c) = switch (status) {
      MessageStatus.sending => (Icons.schedule_rounded, color),
      MessageStatus.sent => (Icons.done_rounded, color),
      MessageStatus.delivered => (Icons.done_all_rounded, color),
      MessageStatus.read => (Icons.done_all_rounded, readColor),
    };
    return Semantics(
      label: switch (status) {
        MessageStatus.sending => 'Sending',
        MessageStatus.sent => 'Sent',
        MessageStatus.delivered => 'Delivered',
        MessageStatus.read => 'Read',
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
