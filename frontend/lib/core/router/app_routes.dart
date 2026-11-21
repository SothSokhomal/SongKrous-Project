abstract final class AppRoutes {
  // Onboarding flow
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const enterNumber = '/enter-number';
  static const otp = '/otp-verification';
  static const gps = '/gps-permission';

  // Full-screen emergency flow (outside the tab shell)
  static const sosCall = '/sos'; // extra: Facility?
  static const outgoingCall = '/calling'; // ?name=&number=
  static const chat = '/chat'; // extra: Facility

  static const activityDetail = '/activity/detail'; // extra: EmergencyActivity

  static const settings = '/settings';

  // Tabs
  static const home = '/home';
  static const map = '/map';
  static const safety = '/safety';
  static const safetyTips = '/safety/tips'; // ?situation=car|fire|medical
  static const activity = '/activity';
  static const hotlines = '/hotlines';

  static String calling(String name, String number) => Uri(
    path: outgoingCall,
    queryParameters: {'name': name, 'number': number},
  ).toString();
}
