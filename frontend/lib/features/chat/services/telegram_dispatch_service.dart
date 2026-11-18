import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_state.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/facilities.dart';
import '../../../core/state/location_state.dart';
import '../models/chat_message.dart';

// ─────────────────────────────────────────────────────────────────────────
// Transport boundary
//
// The UI only ever talks to [ChatNotifier]; the notifier only ever talks to a
// [DispatchTransport]. Swapping the simulation for a real backend means
// providing a different transport — no widget changes.
// ─────────────────────────────────────────────────────────────────────────

/// What the dispatcher needs to know about the conversation.
class DispatchContext {
  const DispatchContext({
    required this.facility,
    required this.userAddress,
    required this.khmer,
  });

  final Facility facility;
  final String userAddress;
  final bool khmer;
}

sealed class DispatchEvent {
  const DispatchEvent();
}

/// The outgoing message advanced to [status].
class StatusChanged extends DispatchEvent {
  const StatusChanged(this.status);
  final MessageStatus status;
}

/// The dispatcher started / stopped typing.
class TypingChanged extends DispatchEvent {
  const TypingChanged(this.typing);
  final bool typing;
}

/// A message arrived from the dispatcher.
class ReplyReceived extends DispatchEvent {
  const ReplyReceived(this.message);
  final ChatMessage message;
}

abstract interface class DispatchTransport {
  /// Delivers [message] and streams everything that happens next (receipts,
  /// typing, replies). The stream completes when the exchange is over.
  Stream<DispatchEvent> deliver(ChatMessage message, DispatchContext context);
}

/// Local simulation of the Telegram dispatch pipeline.
///
/// Timeline: sending 250 ms → sent ✓ · 400 ms → delivered ✓✓ · 700 ms → read
/// (blue ✓✓) · typing indicator 1.2 s · bilingual confirmation.
///
/// TODO: Wire to Telegram Bot / MTProto Backend API — implement
/// [DispatchTransport] with `sendMessage` / `sendVoice` / `sendPhoto` /
/// `sendLocation` and map the bot's updates to [DispatchEvent]s.
class SimulatedTelegramTransport implements DispatchTransport {
  const SimulatedTelegramTransport();

  @override
  Stream<DispatchEvent> deliver(
    ChatMessage message,
    DispatchContext context,
  ) async* {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    yield const StatusChanged(MessageStatus.sent);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    yield const StatusChanged(MessageStatus.delivered);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    yield const StatusChanged(MessageStatus.read);

    await Future<void>.delayed(const Duration(milliseconds: 300));
    yield const TypingChanged(true);
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    yield const TypingChanged(false);
    yield ReplyReceived(
      ChatMessage(
        id: 'reply-${message.id}',
        isMe: false,
        type: MessageType.text,
        timestamp: DateTime.now(),
        status: MessageStatus.read,
        text: _confirmation(message, context),
      ),
    );
  }

  static String _confirmation(ChatMessage m, DispatchContext c) {
    final phone = c.facility.phone;
    final addr = c.userAddress;
    final km = c.khmer;
    final what = switch (m.type) {
      MessageType.text => km ? 'សាររបស់អ្នក' : 'your message',
      MessageType.voice =>
        km
            ? 'សារសំឡេង (${ChatMessage.formatDuration(m.voiceDurationSec ?? 0)})'
            : 'your voice note (${ChatMessage.formatDuration(m.voiceDurationSec ?? 0)})',
      MessageType.photo => km ? 'រូបថតរបស់អ្នក' : 'your photo',
      MessageType.location => km ? 'ទីតាំងរបស់អ្នក' : 'your live location',
    };
    return km
        ? 'បានទទួល$whatដោយមជ្ឈមណ្ឌលបញ្ជា ($phone)។ សូមស្នាក់នៅ $addr ជំនួយកំពុងធ្វើដំណើរមក។'
        : 'Received $what at Dispatch ($phone). Please stay at $addr, help is on the way.';
  }
}

final dispatchTransportProvider = Provider<DispatchTransport>(
  (ref) => const SimulatedTelegramTransport(),
);

// ─────────────────────────────────────────────────────────────────────────
// Conversation state
// ─────────────────────────────────────────────────────────────────────────

class ChatState {
  const ChatState({this.messages = const [], this.typing = false});

  /// Oldest first.
  final List<ChatMessage> messages;
  final bool typing;

  ChatState copyWith({List<ChatMessage>? messages, bool? typing}) => ChatState(
    messages: messages ?? this.messages,
    typing: typing ?? this.typing,
  );
}

class ChatNotifier extends Notifier<ChatState> {
  ChatNotifier(this.facility);

  final Facility facility;
  int _seq = 0;

  @override
  ChatState build() {
    final loc = ref.read(locationProvider);
    final khmer = ref.read(langProvider) == AppLang.km;
    final now = DateTime.now();
    return ChatState(
      messages: [
        // Auto-attached live location pin…
        ChatMessage(
          id: 'seed-location',
          isMe: true,
          type: MessageType.location,
          timestamp: now,
          status: MessageStatus.delivered,
          latLng: loc.latLng,
          addressLabel: '${loc.headline} • ${loc.khanLine.split(' • ').first}',
        ),
        // …and a one-line welcome from the connected facility.
        ChatMessage(
          id: 'seed-welcome',
          isMe: false,
          type: MessageType.text,
          timestamp: now,
          status: MessageStatus.read,
          text:
              '${facility.name(khmer ? AppLang.km : AppLang.en)} · ${facility.phone}',
        ),
      ],
    );
  }

  DispatchContext get _context {
    final loc = ref.read(locationProvider);
    return DispatchContext(
      facility: facility,
      userAddress: loc.headline,
      khmer: ref.read(langProvider) == AppLang.km,
    );
  }

  String _nextId() => 'm${_seq++}';

  // ── Sending ───────────────────────────────────────────────────────────

  void sendText(String text) {
    final t = text.trim();
    if (t.isEmpty) return;
    _send(
      ChatMessage(
        id: _nextId(),
        isMe: true,
        type: MessageType.text,
        timestamp: DateTime.now(),
        text: t,
      ),
    );
  }

  void sendVoice({required int durationSec, required List<double> waveform}) {
    _send(
      ChatMessage(
        id: _nextId(),
        isMe: true,
        type: MessageType.voice,
        timestamp: DateTime.now(),
        voiceDurationSec: math.max(1, durationSec),
        waveformSamples: waveform,
      ),
    );
  }

  void sendPhoto(String path, {String? caption}) {
    final c = caption?.trim();
    _send(
      ChatMessage(
        id: _nextId(),
        isMe: true,
        type: MessageType.photo,
        timestamp: DateTime.now(),
        mediaPath: path,
        text: (c == null || c.isEmpty) ? null : c,
      ),
    );
  }

  /// Sends the user's current GPS position as a Telegram-style location card.
  void sendLocation() {
    final loc = ref.read(locationProvider);
    _send(
      ChatMessage(
        id: _nextId(),
        isMe: true,
        type: MessageType.location,
        timestamp: DateTime.now(),
        latLng: LatLng(loc.latLng.latitude, loc.latLng.longitude),
        addressLabel: '${loc.headline} • ${loc.khanLine.split(' • ').first}',
      ),
    );
  }

  /// Optimistically inserts the message, then follows the transport.
  void _send(ChatMessage message) {
    state = state.copyWith(messages: [...state.messages, message]);
    _follow(message);
  }

  Future<void> _follow(ChatMessage message) async {
    await for (final event
        in ref.read(dispatchTransportProvider).deliver(message, _context)) {
      if (!ref.mounted) return;
      switch (event) {
        case StatusChanged(:final status):
          state = state.copyWith(
            messages: [
              for (final m in state.messages)
                if (m.id == message.id) m.copyWith(status: status) else m,
            ],
          );
        case TypingChanged(:final typing):
          state = state.copyWith(typing: typing);
        case ReplyReceived(:final message):
          state = state.copyWith(messages: [...state.messages, message]);
      }
    }
  }
}

/// One conversation per facility, kept for the app session.
final chatProvider = NotifierProvider.family<ChatNotifier, ChatState, Facility>(
  ChatNotifier.new,
);
