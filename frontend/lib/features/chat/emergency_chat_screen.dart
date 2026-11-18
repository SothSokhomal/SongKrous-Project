import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/animations/app_animations.dart';
import '../../core/constants/app_state.dart';
import '../../core/constants/facilities.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../map/widgets/map_markers.dart';
import 'models/chat_message.dart';
import 'services/telegram_dispatch_service.dart';
import 'widgets/chat_composer.dart';
import 'widgets/chat_header.dart';
import 'widgets/message_bubbles.dart';
import 'widgets/quick_chips.dart';
import 'widgets/typing_indicator.dart';

/// In-app emergency messaging with the connected facility (Telegram-style
/// dispatch, Instagram-DM look). Opened from `Send Message` on the SOS screen.
class EmergencyChatScreen extends ConsumerStatefulWidget {
  const EmergencyChatScreen({super.key, required this.facility});

  final Facility facility;

  @override
  ConsumerState<EmergencyChatScreen> createState() =>
      _EmergencyChatScreenState();
}

class _EmergencyChatScreenState extends ConsumerState<EmergencyChatScreen> {
  static const _typingKey = '__typing__';

  final _scroll = ScrollController();

  /// Messages present when the screen opened don't animate in.
  late final Set<String> _initialIds = {
    for (final m in ref.read(chatProvider(widget.facility)).messages) m.id,
  };

  ChatNotifier get _chat => ref.read(chatProvider(widget.facility).notifier);

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      _scroll.animateTo(0, duration: AppDurations.medium, curve: AppCurves.out);
    });
  }

  /// Same-sender messages within 3 minutes form one visual group.
  static bool _sameGroup(ChatMessage a, ChatMessage b) =>
      a.isMe == b.isMe &&
      b.timestamp.difference(a.timestamp).abs() < const Duration(minutes: 3);

  @override
  Widget build(BuildContext context) {
    final facility = widget.facility;
    final chat = ref.watch(chatProvider(facility));

    ref.listen(chatProvider(facility), (prev, next) {
      if (prev == null ||
          prev.messages.length != next.messages.length ||
          prev.typing != next.typing) {
        _scrollToLatest();
      }
    });

    final messages = chat.messages;
    final maxBubble = MediaQuery.sizeOf(context).width * 0.76;
    final itemCount = messages.length + (chat.typing ? 1 : 0);

    return Scaffold(
      backgroundColor: AppColors.white,
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          ChatHeader(
            facility: facility,
            onBack: () =>
                context.canPop() ? context.pop() : context.go(AppRoutes.home),
            onSendLocation: _chat.sendLocation,
            onCall: () => context.push(
              AppRoutes.calling(facility.nameEn, facility.phone),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              reverse: true,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              itemCount: itemCount,
              // Items shift by one whenever a message arrives or the typing
              // indicator toggles. Resolving by key keeps each bubble's State
              // (a playing voice note, entrance animations) instead of
              // rebuilding it from scratch.
              findChildIndexCallback: (key) {
                if (key is! ValueKey<String>) return null;
                if (key.value == _typingKey) return chat.typing ? 0 : null;
                final i = messages.indexWhere((m) => m.id == key.value);
                if (i < 0) return null;
                return messages.length - 1 - i + (chat.typing ? 1 : 0);
              },
              itemBuilder: (context, index) {
                // index 0 = bottom-most item.
                if (chat.typing && index == 0) {
                  return Padding(
                    key: const ValueKey(_typingKey),
                    padding: const EdgeInsets.only(top: 6),
                    child: Semantics(
                      liveRegion: true,
                      label: ref.tr('typing'),
                      child: _IncomingRow(
                        facility: facility,
                        showAvatar: true,
                        child: const TypingIndicator(),
                      ),
                    ),
                  );
                }
                final i = messages.length - 1 - (index - (chat.typing ? 1 : 0));
                final m = messages[i];
                final first = i == 0 || !_sameGroup(messages[i - 1], m);
                final last =
                    i == messages.length - 1 || !_sameGroup(m, messages[i + 1]);

                final bubble = ChatBubble(
                  message: m,
                  first: first,
                  last: last,
                  maxWidth: maxBubble,
                );
                final row = m.isMe
                    ? Align(alignment: Alignment.centerRight, child: bubble)
                    : _IncomingRow(
                        facility: facility,
                        showAvatar: last,
                        child: Flexible(child: bubble),
                      );

                return _Appear(
                  key: ValueKey(m.id),
                  animate: !_initialIds.contains(m.id),
                  child: Padding(
                    padding: EdgeInsets.only(top: first ? 10 : 2),
                    child: row,
                  ),
                );
              },
            ),
          ),
          QuickChips(
            onGps: _chat.sendLocation,
            onAmbulance: () => _chat.sendText(ref.tr('msg_ambulance')),
            onBleeding: () => _chat.sendText(ref.tr('msg_bleeding')),
            onPolice: () => _chat.sendText(ref.tr('msg_police')),
          ),
          SafeArea(
            top: false,
            child: ChatComposer(
              phone: facility.phone,
              onSendText: _chat.sendText,
              onSendPhoto: (path, caption) =>
                  _chat.sendPhoto(path, caption: caption),
              onSendVoice: (seconds, wave) =>
                  _chat.sendVoice(durationSec: seconds, waveform: wave),
            ),
          ),
        ],
      ),
    );
  }
}

/// Incoming message row: the 26 px facility avatar sits at the bottom-left of
/// the *last* bubble of a group; other bubbles keep an empty slot so they line
/// up.
class _IncomingRow extends StatelessWidget {
  const _IncomingRow({
    required this.facility,
    required this.showAvatar,
    required this.child,
  });

  final Facility facility;
  final bool showAvatar;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final color = facilityColor(facility.type);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox(
          width: 26,
          height: 26,
          child: showAvatar
              ? Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 1.6),
                  ),
                  child: Icon(
                    facilityIcon(facility.type),
                    size: 14,
                    color: color,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 8),
        // The typing indicator isn't flexible; bubbles are.
        child is Flexible ? child : Flexible(child: child),
      ],
    );
  }
}

/// New messages slide up 12 px and fade in (220 ms).
class _Appear extends StatelessWidget {
  const _Appear({super.key, required this.animate, required this.child});

  final bool animate;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!animate) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 220),
      curve: AppCurves.out,
      child: child,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - t)),
          child: child,
        ),
      ),
    );
  }
}
