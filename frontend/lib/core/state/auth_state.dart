import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/phone_format.dart';

/// How the verification code is (pretend-)delivered.
enum OtpChannel { sms, whatsapp }

/// Who the user is for this prototype session. No backend: "logged in" just
/// means the demo OTP was accepted; everyone else is a guest.
@immutable
class AuthProfile {
  const AuthProfile({
    this.phone = '',
    this.channel = OtpChannel.sms,
    this.isLoggedIn = false,
  });

  /// National number, digits only (`12855706`).
  final String phone;
  final OtpChannel channel;
  final bool isLoggedIn;

  bool get isGuest => !isLoggedIn;

  /// `12 855 706`.
  String get formattedPhone => groupPhone(phone);

  AuthProfile copyWith({
    String? phone,
    OtpChannel? channel,
    bool? isLoggedIn,
  }) => AuthProfile(
    phone: phone ?? this.phone,
    channel: channel ?? this.channel,
    isLoggedIn: isLoggedIn ?? this.isLoggedIn,
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
