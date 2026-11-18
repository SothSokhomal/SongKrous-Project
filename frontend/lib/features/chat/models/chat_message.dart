import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_strings.dart';

enum MessageType { text, voice, photo, location }

/// Telegram-style delivery state.
/// sending → clock · sent → ✓ · delivered → ✓✓ · read → blue ✓✓
enum MessageStatus { sending, sent, delivered, read }

/// Marker path for the built-in sample incident photo (no file needed, so the
/// photo flow works on a simulator with an empty library).
const String kDemoPhotoPath = 'demo://incident';

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.isMe,
    required this.type,
    required this.timestamp,
    this.status = MessageStatus.sending,
    this.text,
    this.textKm,
    this.mediaPath,
    this.voiceDurationSec,
    this.waveformSamples,
    this.latLng,
    this.addressLabel,
    this.addressLabelKm,
  });

  final String id;
  final bool isMe;
  final MessageType type;
  final DateTime timestamp;
  final MessageStatus status;

  /// Body for `text`; caption for `photo` (optional).
  final String? text;

  /// Khmer version of [text] for system/quick messages. User-typed messages
  /// have none and show as typed.
  final String? textKm;

  /// File path from the picker, or [kDemoPhotoPath].
  final String? mediaPath;

  /// `voice` only.
  final int? voiceDurationSec;

  /// `voice` only: 0…1 bar heights.
  final List<double>? waveformSamples;

  /// `location` only.
  final LatLng? latLng;
  final String? addressLabel;
  final String? addressLabelKm;

  ChatMessage copyWith({MessageStatus? status}) => ChatMessage(
    id: id,
    isMe: isMe,
    type: type,
    timestamp: timestamp,
    status: status ?? this.status,
    text: text,
    textKm: textKm,
    mediaPath: mediaPath,
    voiceDurationSec: voiceDurationSec,
    waveformSamples: waveformSamples,
    latLng: latLng,
    addressLabel: addressLabel,
    addressLabelKm: addressLabelKm,
  );

  /// The text to show in [lang] — one language, never both.
  String? textFor(AppLang lang) => lang == AppLang.km ? (textKm ?? text) : text;

  String? addressFor(AppLang lang) =>
      lang == AppLang.km ? (addressLabelKm ?? addressLabel) : addressLabel;

  /// `m:ss`
  static String formatDuration(int seconds, [AppLang lang = AppLang.en]) =>
      AppStrings.digits(
        '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}',
        lang,
      );
}
