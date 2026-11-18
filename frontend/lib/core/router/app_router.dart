import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../animations/app_animations.dart';
import '../constants/facilities.dart';
import '../constants/phnom_penh_data.dart';
import '../../features/chat/emergency_chat_screen.dart';
import '../../features/home/home_sos_screen.dart';
import '../../features/home/outgoing_call_screen.dart';
import '../../features/home/sos_call_screen.dart';
import '../../features/hotlines/hotlines_screen.dart';
import '../../features/map/nearby_map_screen.dart';
import '../../features/onboarding/enter_number_screen.dart';
import '../../features/onboarding/gps_permission_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/onboarding/otp_verification_screen.dart';
import '../../features/onboarding/splash_screen.dart';
import '../../features/safety/safety_input_screen.dart';
import '../../features/safety/safety_tips_screen.dart';
import '../../features/safety/situation.dart';
import '../../shared/widgets/main_shell.dart';
import 'app_routes.dart';

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootKey,
  initialLocation: AppRoutes.splash,
  routes: [
    // Splash → onboarding → enter number: pure cross-fade, the shared logo and
    // language-pill `Hero`s provide the continuity (no redundant slide).
    GoRoute(
      path: AppRoutes.splash,
      pageBuilder: (_, s) => buildIosPageTransition(
        state: s,
        child: const SplashScreen(),
        slide: false,
      ),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      pageBuilder: (_, s) => buildIosPageTransition(
        state: s,
        child: const OnboardingScreen(),
        slide: false,
      ),
    ),
    GoRoute(
      path: AppRoutes.enterNumber,
      pageBuilder: (_, s) => buildIosPageTransition(
        state: s,
        child: const EnterNumberScreen(),
        slide: false,
      ),
    ),
    GoRoute(
      path: AppRoutes.otp,
      pageBuilder: (_, s) => buildIosPageTransition(
        state: s,
        child: const OtpVerificationScreen(),
      ),
    ),
    // The screen animates its own backdrop + alert.
    GoRoute(
      path: AppRoutes.gps,
      pageBuilder: (_, s) => buildIosPageTransition(
        state: s,
        child: const GpsPermissionScreen(),
        slide: false,
      ),
    ),
    GoRoute(
      path: AppRoutes.sosCall,
      parentNavigatorKey: _rootKey,
      pageBuilder: (_, s) => buildIosPageTransition(
        state: s,
        child: SosCallScreen(facility: s.extra as Facility?),
      ),
    ),
    GoRoute(
      path: AppRoutes.chat,
      parentNavigatorKey: _rootKey,
      pageBuilder: (_, s) => buildIosPageTransition(
        state: s,
        child: EmergencyChatScreen(
          facility: s.extra as Facility? ?? PhnomPenhData.defaultSos,
        ),
      ),
    ),
    // Outgoing call rises from the bottom.
    GoRoute(
      path: AppRoutes.outgoingCall,
      parentNavigatorKey: _rootKey,
      pageBuilder: (_, s) => buildIosPageTransition(
        state: s,
        begin: const Offset(0, 0.1),
        child: OutgoingCallScreen(
          name: s.uri.queryParameters['name'] ?? '',
          number: s.uri.queryParameters['number'] ?? EmergencyNumbers.ambulance,
        ),
      ),
    ),
    StatefulShellRoute.indexedStack(
      builder: (_, _, shell) => MainShell(navigationShell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.home,
              builder: (_, _) => const HomeSosScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.map,
              builder: (_, _) => const NearbyMapScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.safety,
              builder: (_, _) => const SafetyInputScreen(),
              routes: [
                GoRoute(
                  path: 'tips',
                  pageBuilder: (_, s) => buildIosPageTransition(
                    state: s,
                    child: SafetyTipsScreen(
                      situation: Situation.fromName(
                        s.uri.queryParameters['situation'],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.hotlines,
              builder: (_, _) => const HotlinesScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
