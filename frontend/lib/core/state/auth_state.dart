import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/phone_format.dart';

/// How the verification code is (pretend-)delivered.
enum OtpChannel { sms, whatsapp }

/// The national number typed on `02_enter the number`, digits only
/// (`12855706`). Survives `Edit` so the field is pre-filled.
class UserPhoneNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String digits) => state = cleanPhoneDigits(digits);
}

final userPhoneProvider = NotifierProvider<UserPhoneNotifier, String>(
  UserPhoneNotifier.new,
);

class OtpChannelNotifier extends Notifier<OtpChannel> {
  @override
  OtpChannel build() => OtpChannel.sms;

  void set(OtpChannel channel) => state = channel;
}

final otpChannelProvider = NotifierProvider<OtpChannelNotifier, OtpChannel>(
  OtpChannelNotifier.new,
);
