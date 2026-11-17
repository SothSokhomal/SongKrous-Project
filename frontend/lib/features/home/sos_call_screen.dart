import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/animations/staggered_entrance.dart';
import '../../core/animations/tactile_scale_button.dart';
import '../../core/constants/app_state.dart';
import '../../core/constants/facilities.dart';
import '../../core/constants/phnom_penh_data.dart';
import '../../core/router/app_routes.dart';
import '../../core/state/location_state.dart';
import '../../core/theme/app_colors.dart';
import 'widgets/sos_pulse_rings.dart';

/// SOS Direct Call (Frame 1) — pulsing SOS, address readout, call buttons.
class SosCallScreen extends ConsumerWidget {
  const SosCallScreen({super.key, this.facility});

  /// Selected facility; falls back to the default emergency desk.
  final Facility? facility;

  Facility get _f => facility ?? PhnomPenhData.defaultSos;

  void _call(BuildContext context, String number) =>
      context.push(AppRoutes.calling(_f.nameEn, number));

  Future<void> _sendMessage(WidgetRef ref) async {
    final loc = ref.read(locationProvider);
    final body = '${ref.tr('sos_sms_body')} ${loc.shareText}';
    // Built by hand: Uri.queryParameters would encode spaces as '+'.
    final uri = Uri.parse('sms:?body=${Uri.encodeComponent(body)}');
    try {
      await launchUrl(uri);
    } catch (_) {
      /* no SMS app (e.g. simulator) */
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = _f;
    final lang = ref.watch(langProvider);
    final loc = ref.watch(locationProvider);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 100,
        leading: TextButton.icon(
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.home),
          icon: const Icon(Icons.chevron_left_rounded, size: 28),
          label: Text(ref.tr('back')),
          style: TextButton.styleFrom(foregroundColor: AppColors.blue),
        ),
        actions: [
          IconButton(
            tooltip: ref.tr('share'),
            color: AppColors.blue,
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: () => SharePlus.instance.share(
              ShareParams(text: '${ref.tr('sos_sms_body')} ${loc.shareText}'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: StaggerScope(
              builder: (context, animation) => ListView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                children: [
                  Center(
                    child: LiveSosPulseRings(
                      size: 150,
                      child: _SosCore(onTap: () => _call(context, f.phone)),
                    ),
                  ),
                  Center(
                    child: Text(
                      ref.tr('tap_sos'),
                      style: text.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  StaggeredEntrance(
                    animation: animation,
                    begin: 0.0,
                    end: 0.6,
                    child: Column(
                      children: [
                        Text(
                          f.name(lang),
                          textAlign: TextAlign.center,
                          style: text.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        _AddressBox(address: f.displayAddress()),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  StaggeredEntrance(
                    animation: animation,
                    begin: 0.2,
                    end: 0.8,
                    child: _ActionButton(
                      icon: Icons.call_rounded,
                      label: f.phone,
                      filled: true,
                      color: AppColors.red,
                      onTap: () => _call(context, f.phone),
                    ),
                  ),
                  if (f.altPhone != null) ...[
                    const SizedBox(height: 12),
                    StaggeredEntrance(
                      animation: animation,
                      begin: 0.3,
                      end: 0.9,
                      child: _ActionButton(
                        icon: Icons.call_rounded,
                        label: '${ref.tr('alt_desk')} · ${f.altPhone}',
                        color: AppColors.blue,
                        onTap: () => _call(context, f.altPhone!),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  StaggeredEntrance(
                    animation: animation,
                    begin: 0.4,
                    end: 1.0,
                    child: _ActionButton(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: ref.tr('send_message'),
                      color: AppColors.slate,
                      onTap: () => _sendMessage(ref),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The solid red SOS circle (static child of the pulse rings) with tactile
/// press feedback.
class _SosCore extends StatelessWidget {
  const _SosCore({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'SOS',
      child: TactileScaleButton(
        onTap: onTap,
        pressedScale: 0.94,
        child: Container(
          width: 150,
          height: 150,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.red,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.red.withValues(alpha: 0.45),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Text(
            'SOS',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 48,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }
}

class _AddressBox extends ConsumerWidget {
  const _AddressBox({required this.address});

  final String address;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '📍 $address',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          IconButton(
            tooltip: ref.tr('copy'),
            icon: const Icon(Icons.copy_rounded, color: AppColors.blue),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: address));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(ref.tr('address_copied')),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
            },
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final fg = filled ? AppColors.white : color;
    return Semantics(
      button: true,
      label: label,
      child: TactileScaleButton(
        onTap: onTap,
        child: Container(
          height: 56,
          decoration: ShapeDecoration(
            color: filled ? color : AppColors.white,
            shape: StadiumBorder(
              side: filled
                  ? BorderSide.none
                  : BorderSide(color: color, width: 1.5),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: fg, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: fg,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamilyFallback: const ['Noto Sans Khmer'],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
