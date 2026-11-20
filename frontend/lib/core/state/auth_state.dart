import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/phone_format.dart';

/// How the verification code is (pretend-)delivered.
enum OtpChannel { sms, whatsapp }

/// The user's profile picture. `null` on [AuthProfile] means "none set".
@immutable
sealed class ProfileAvatar {
  const ProfileAvatar();
}

/// One of the built-in gradient/emblem avatars (index into the preset list).
class PresetAvatar extends ProfileAvatar {
  const PresetAvatar(this.index);
  final int index;

  @override
  bool operator ==(Object other) =>
      other is PresetAvatar && other.index == index;

  @override
  int get hashCode => index;
}

/// A picked/cropped photo, kept in memory for this prototype session (nothing
/// is uploaded or written outside the app).
class PhotoAvatar extends ProfileAvatar {
  const PhotoAvatar(this.bytes);
  final Uint8List bytes;
}

/// Who the user is for this prototype session. No backend: "logged in" just
/// means the demo OTP was accepted; everyone else is a guest.
@immutable
class AuthProfile {
  const AuthProfile({
    this.phone = '',
    this.channel = OtpChannel.sms,
    this.isLoggedIn = false,
    this.avatar,
  });

  /// National number, digits only (`12855706`).
  final String phone;
  final OtpChannel channel;
  final bool isLoggedIn;
  final ProfileAvatar? avatar;

  bool get isGuest => !isLoggedIn;

  /// `12 855 706`.
  String get formattedPhone => groupPhone(phone);

  AuthProfile copyWith({
    String? phone,
    OtpChannel? channel,
    bool? isLoggedIn,
    ProfileAvatar? avatar,
    bool clearAvatar = false,
  }) => AuthProfile(
    phone: phone ?? this.phone,
    channel: channel ?? this.channel,
    isLoggedIn: isLoggedIn ?? this.isLoggedIn,
    avatar: clearAvatar ? null : (avatar ?? this.avatar),
  );
}

class AuthProfileNotifier extends Notifier<AuthProfile> {
  @override
  AuthProfile build() => const AuthProfile();

  void setPhone(String input) =>
      state = state.copyWith(phone: cleanPhoneDigits(input));

  void setChannel(OtpChannel channel) =>
      state = state.copyWith(channel: channel);

  /// OTP accepted.
  void markLoggedIn() => state = state.copyWith(isLoggedIn: true);

  /// "Skip for now": keep going without an account.
  void continueAsGuest() => state = state.copyWith(isLoggedIn: false);

  void setAvatar(ProfileAvatar avatar) =>
      state = state.copyWith(avatar: avatar);

  void clearAvatar() => state = state.copyWith(clearAvatar: true);

  /// Log out: forget the phone number, the channel, the logged-in flag and the
  /// profile picture.
  /// Dependent state (e.g. open emergency chats) watches this provider and
  /// resets itself, so nothing sensitive outlives the session.
  void logOut() => state = const AuthProfile();
}

final authProfileProvider = NotifierProvider<AuthProfileNotifier, AuthProfile>(
  AuthProfileNotifier.new,
);

/// Convenience read-only views.
final userPhoneProvider = Provider<String>(
  (ref) => ref.watch(authProfileProvider.select((p) => p.phone)),
);
final otpChannelProvider = Provider<OtpChannel>(
  (ref) => ref.watch(authProfileProvider.select((p) => p.channel)),
);
