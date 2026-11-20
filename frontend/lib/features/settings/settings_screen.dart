import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/animations/app_animations.dart';
import '../../core/constants/app_state.dart';
import '../../core/router/app_routes.dart';
import '../../core/state/auth_state.dart';
import '../../core/state/location_state.dart';
import '../../core/theme/app_colors.dart';
import '../chat/services/photo_source.dart';
import 'profile_image_io.dart';
import 'widgets/avatar_viewer.dart';
import 'widgets/photo_preview_screen.dart';
import 'widgets/profile_avatar_view.dart';
import 'widgets/profile_photo_sheet.dart';
import '../../shared/widgets/app_interactive.dart';
import '../../shared/widgets/glass_back_button.dart';
import '../../shared/widgets/language_toggle.dart';
import '../../shared/widgets/liquid_glass.dart';

/// Matches `version:` in pubspec.yaml.
const String kAppVersion = '1.0.0';

/// Account, language, privacy and about — plus Log out.
///
/// Opened from the gear on Home. Works for guests (no number) and verified
/// users alike; Log out only appears when someone is actually logged in.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _back(BuildContext context) =>
      context.canPop() ? context.pop() : context.go(AppRoutes.home);

  Future<void> _confirmLogOut(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ref.tr('settings_logout_title')),
        content: Text(ref.tr('settings_logout_body')),
        actions: [
          TextButton(
            key: const ValueKey('logout-cancel'),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(ref.tr('cancel')),
          ),
          TextButton(
            key: const ValueKey('logout-confirm'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              ref.tr('settings_logout'),
              style: const TextStyle(
                color: AppColors.red,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    ref.read(authProfileProvider.notifier).logOut();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(ref.tr('settings_logged_out')),
        ),
      );
  }

  void _snack(BuildContext context, String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(behavior: SnackBarBehavior.floating, content: Text(text)),
      );
  }

  /// Action sheet → camera / gallery (→ circular preview) / preset / remove.
  Future<void> _changePhoto(BuildContext context, WidgetRef ref) async {
    final hasAvatar = ref.read(authProfileProvider).avatar != null;
    final choice = await showProfilePhotoSheet(context, hasAvatar: hasAvatar);
    if (choice == null || !context.mounted) return;
    final auth = ref.read(authProfileProvider.notifier);

    switch (choice.action) {
      case PhotoAction.preset:
        HapticFeedback.mediumImpact();
        auth.setAvatar(PresetAvatar(choice.presetIndex ?? 0));
      case PhotoAction.remove:
        HapticFeedback.selectionClick();
        auth.clearAvatar();
      case PhotoAction.camera:
      case PhotoAction.gallery:
        await _pickPhoto(
          context,
          ref,
          choice.action == PhotoAction.camera
              ? PhotoOrigin.camera
              : PhotoOrigin.library,
        );
    }
  }

  Future<void> _pickPhoto(
    BuildContext context,
    WidgetRef ref,
    PhotoOrigin origin,
  ) async {
    Uint8List bytes;
    try {
      final path = await ref.read(photoSourceProvider).pick(origin);
      if (path == null || !context.mounted) return; // cancelled
      bytes = await ref.read(profileImageLoaderProvider)(path);
    } catch (_) {
      // No camera on the simulator, permission denied, unreadable file…
      if (context.mounted) _snack(context, ref.tr('avatar_unavailable'));
      return;
    }
    if (!context.mounted) return;
    final framed = await showPhotoPreview(context, bytes);
    if (framed == null || !context.mounted) return;
    HapticFeedback.mediumImpact();
    ref.read(authProfileProvider.notifier).setAvatar(PhotoAvatar(framed));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(authProfileProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LiquidAmbientCanvas(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    GlassBackButton(
                      key: const ValueKey('settings-back'),
                      onTap: () => _back(context),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        ref.tr('settings'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                          height: 1.5,
                          fontFamilyFallback: ['Noto Sans Khmer'],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  children: [
                    _ProfileHeader(
                      profile: profile,
                      onChange: () => _changePhoto(context, ref),
                    ),
                    _Section(
                      title: ref.tr('settings_account'),
                      child: profile.isLoggedIn
                          ? _VerifiedAccount(
                              phone: ref.num('+855 ${profile.formattedPhone}'),
                            )
                          : const _GuestAccount(),
                    ),
                    _Section(
                      title: ref.tr('settings_language_h'),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              ref.tr('settings_language'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _rowTitle,
                            ),
                          ),
                          const LanguagePill(),
                        ],
                      ),
                    ),
                    _Section(
                      title: ref.tr('settings_privacy'),
                      child: _LocationRow(
                        active: ref.watch(locationEnabledProvider),
                      ),
                    ),
                    _Section(
                      title: ref.tr('settings_about'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ref.tr('app_name'), style: _rowTitle),
                          const SizedBox(height: 2),
                          Text(
                            ref
                                .tr('settings_version')
                                .replaceAll('{v}', ref.num(kAppVersion)),
                            style: _rowSub,
                          ),
                          const SizedBox(height: 8),
                          Text(ref.tr('settings_prototype'), style: _rowSub),
                        ],
                      ),
                    ),
                    if (profile.isLoggedIn) ...[
                      const SizedBox(height: 4),
                      AppInteractiveButton(
                        key: const ValueKey('settings-logout'),
                        label: ref.tr('settings_logout'),
                        leadingIcon: Icons.logout_rounded,
                        colors: AppButtonColors.outline(AppColors.red),
                        onPressed: () => _confirmLogOut(context, ref),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const TextStyle _rowTitle = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w700,
  color: AppColors.ink,
  height: 1.5,
  fontFamilyFallback: ['Noto Sans Khmer'],
);

const TextStyle _rowSub = TextStyle(
  fontSize: 13.5,
  color: Color(0xFF475569),
  height: 1.5,
  fontFamilyFallback: ['Noto Sans Khmer'],
);

/// Small caption + a frosted card.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.slate,
                letterSpacing: 0.4,
                height: 1.5,
                fontFamilyFallback: ['Noto Sans Khmer'],
              ),
            ),
          ),
          LiquidGlassContainer(
            radius: 20,
            tint: LiquidTint.frostStrong,
            useBlur: false,
            padding: const EdgeInsets.all(16),
            child: SizedBox(width: double.infinity, child: child),
          ),
        ],
      ),
    );
  }
}

class _GuestAccount extends ConsumerWidget {
  const _GuestAccount();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.person_outline_rounded,
              color: AppColors.slate,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(ref.tr('settings_guest'), style: _rowTitle)),
          ],
        ),
        const SizedBox(height: 4),
        Text(ref.tr('settings_guest_sub'), style: _rowSub),
        const SizedBox(height: 12),
        AppInteractiveButton(
          key: const ValueKey('settings-verify'),
          label: ref.tr('settings_verify'),
          height: 46,
          fontSize: 15,
          onPressed: () => context.push(AppRoutes.enterNumber),
        ),
      ],
    );
  }
}

class _VerifiedAccount extends ConsumerWidget {
  const _VerifiedAccount({required this.phone});

  final String phone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        const Icon(Icons.verified_rounded, color: AppColors.blue, size: 24),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                phone,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _rowTitle.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(ref.tr('settings_verified'), style: _rowSub),
            ],
          ),
        ),
      ],
    );
  }
}

class _LocationRow extends ConsumerWidget {
  const _LocationRow({required this.active});

  final bool active;

  Future<void> _toggle(BuildContext context, WidgetRef ref, bool on) async {
    HapticFeedback.selectionClick();
    final granted = await ref.read(locationProvider.notifier).setEnabled(on);
    if (on && !granted && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(ref.tr('settings_location_denied')),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Icon(
          Icons.my_location_rounded,
          size: 22,
          color: active ? AppColors.success : AppColors.red,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(ref.tr('settings_location'), style: _rowTitle),
              AnimatedSwitcher(
                duration: AppDurations.fast,
                child: Text(
                  ref.tr(
                    active ? 'settings_location_on' : 'settings_location_off',
                  ),
                  key: ValueKey(active),
                  style: _rowSub,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Switch.adaptive(
          key: const ValueKey('settings-location-switch'),
          value: active,
          activeTrackColor: AppColors.blueDeep,
          onChanged: (v) => _toggle(context, ref, v),
        ),
      ],
    );
  }
}

/// Telegram-style header: 96 pt avatar (tap → full-screen viewer, or the
/// picker when empty), camera badge, name + verified tick, number and a
/// "Set New Photo" action.
class _ProfileHeader extends ConsumerWidget {
  const _ProfileHeader({required this.profile, required this.onChange});

  final AuthProfile profile;
  final VoidCallback onChange;

  static const double _size = 96;

  /// Distinct per picture so the avatar cross-fades when it changes.
  Object _identity(ProfileAvatar? a) => switch (a) {
    PhotoAvatar(:final bytes) => identityHashCode(bytes),
    PresetAvatar(:final index) => 'preset-$index',
    null => 'none',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatar = profile.avatar;
    Widget view = AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      child: ProfileAvatarView(
        key: ValueKey(_identity(avatar)),
        avatar: avatar,
        size: _size,
      ),
    );
    if (avatar != null) {
      view = Hero(
        tag: kAvatarHeroTag,
        child: Material(type: MaterialType.transparency, child: view),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 22),
      child: Column(
        children: [
          SizedBox(
            width: _size + 8,
            height: _size + 8,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 4,
                  top: 4,
                  child: AppPressable(
                    key: const ValueKey('profile-avatar'),
                    // Photo/preset → expand it; empty → open the picker.
                    onTap: avatar == null
                        ? onChange
                        : () => showAvatarViewer(context, onChange: onChange),
                    haptic: AppHaptic.selection,
                    builder: (context, hovered, pressed) => AnimatedScale(
                      duration: AppDurations.tap,
                      scale: pressed
                          ? 0.96
                          : hovered
                          ? 1.03
                          : 1,
                      child: view,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: AppScaleButton(
                    key: const ValueKey('profile-camera-badge'),
                    semanticLabel: ref.tr('profile_set_photo'),
                    tooltip: ref.tr('profile_set_photo'),
                    haptic: AppHaptic.selection,
                    hoverScale: 1.1,
                    onTap: onChange,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: AppColors.blueDeep,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.photo_camera_rounded,
                        size: 15,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  ref.tr('profile_name'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                    height: 1.5,
                    fontFamilyFallback: ['Noto Sans Khmer'],
                  ),
                ),
              ),
              if (profile.isLoggedIn) ...[
                const SizedBox(width: 6),
                const Icon(
                  Icons.verified_rounded,
                  size: 20,
                  color: AppColors.blue,
                ),
              ],
            ],
          ),
          Text(
            profile.isLoggedIn
                ? ref.num('+855 ${profile.formattedPhone}')
                : ref.tr('settings_guest'),
            key: const ValueKey('profile-subtitle'),
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.slate,
              height: 1.5,
              fontFeatures: [FontFeature.tabularFigures()],
              fontFamilyFallback: ['Noto Sans Khmer'],
            ),
          ),
          const SizedBox(height: 12),
          AppInteractiveButton(
            key: const ValueKey('profile-set-photo'),
            label: ref.tr('profile_set_photo'),
            leadingIcon: Icons.photo_camera_rounded,
            height: 42,
            fontSize: 14.5,
            expand: false,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            haptic: AppHaptic.selection,
            onPressed: onChange,
          ),
        ],
      ),
    );
  }
}
