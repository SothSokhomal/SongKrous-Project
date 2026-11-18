import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_state.dart';
import '../../../core/theme/app_colors.dart';
import '../models/chat_message.dart';
import 'location_bubble.dart';
import 'photo_bubble.dart';
import 'status_ticks.dart';
import 'voice_bubble.dart';

/// Chat palette: Trust-Blue outgoing, cool-slate incoming.
abstract final class ChatColors {
  static const outgoing = AppColors.blueDeep;
  static const outgoingText = AppColors.white;
  static const incoming = Color(0xFFF1F5F9);
  static const incomingText = AppColors.ink;

  /// Light sky blue — reads as "blue ticks" on the deep-blue bubble.
  static const readTick = Color(0xFF93C5FD);
  static const meta = Color(0xFF94A3B8);
}

/// Instagram-style grouped corners: the side facing the group tightens to
/// 5 px between consecutive bubbles; everything else stays 20 px.
BorderRadius bubbleRadius({
  required bool isMe,
  required bool first,
  required bool last,
}) {
  const big = Radius.circular(20);
  const tight = Radius.circular(5);
  final top = first ? big : tight;
  final bottom = last ? big : tight;
  return isMe
      ? BorderRadius.only(
          topLeft: big,
          bottomLeft: big,
          topRight: top,
          bottomRight: bottom,
        )
      : BorderRadius.only(
          topRight: big,
          bottomRight: big,
          topLeft: top,
          bottomLeft: bottom,
        );
}

String formatTime(DateTime t, [AppLang lang = AppLang.en]) => AppStrings.digits(
  '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}',
  lang,
);

/// Tiny `12:41 ✓✓` footer. [onDark] flips colours for the blue bubble / photo
/// overlay.
class BubbleMeta extends ConsumerWidget {
  const BubbleMeta({super.key, required this.message, this.onDark});

  final ChatMessage message;

  /// Defaults to `message.isMe`.
  final bool? onDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = onDark ?? message.isMe;
    final color = dark ? Colors.white70 : ChatColors.meta;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          formatTime(message.timestamp, ref.watch(langProvider)),
          style: TextStyle(fontSize: 10.5, color: color, height: 1.2),
        ),
        if (message.isMe) ...[
          const SizedBox(width: 3),
          StatusTicks(
            status: message.status,
            color: color,
            readColor: ChatColors.readTick,
            size: 14,
          ),
        ],
      ],
    );
  }
}

/// One message bubble of any type.
class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.message,
    required this.first,
    required this.last,
    required this.maxWidth,
  });

  final ChatMessage message;

  /// First / last bubble of its consecutive same-sender group.
  final bool first;
  final bool last;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final radius = bubbleRadius(isMe: message.isMe, first: first, last: last);
    return switch (message.type) {
      MessageType.text => _TextBubble(
        message: message,
        radius: radius,
        maxWidth: maxWidth,
      ),
      MessageType.photo => PhotoBubble(message: message, maxWidth: maxWidth),
      MessageType.voice => VoiceBubble(
        message: message,
        radius: radius,
        maxWidth: maxWidth,
      ),
      MessageType.location => LocationBubble(
        message: message,
        maxWidth: maxWidth,
      ),
    };
  }
}

class _TextBubble extends ConsumerWidget {
  const _TextBubble({
    required this.message,
    required this.radius,
    required this.maxWidth,
  });

  final ChatMessage message;
  final BorderRadius radius;
  final double maxWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = message.isMe;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 9, 12, 8),
        decoration: BoxDecoration(
          color: me ? ChatColors.outgoing : ChatColors.incoming,
          borderRadius: radius,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Text(
                message.textFor(ref.watch(langProvider)) ?? '',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.45, // Khmer stacks need the room
                  color: me ? ChatColors.outgoingText : ChatColors.incomingText,
                  fontFamilyFallback: const ['Noto Sans Khmer'],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Padding(
              padding: const EdgeInsets.only(bottom: 1),
              child: BubbleMeta(message: message),
            ),
          ],
        ),
      ),
    );
  }
}
