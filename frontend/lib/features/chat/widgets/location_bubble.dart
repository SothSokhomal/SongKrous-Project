import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_state.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../models/chat_message.dart';
import 'message_bubbles.dart';
import 'status_ticks.dart';

String formatCoordinates(double lat, double lng, [AppLang l = AppLang.en]) {
  final km = l == AppLang.km;
  final n = km ? 'ជើង' : 'N', so = km ? 'ត្បូង' : 'S';
  final e = km ? 'កើត' : 'E', w = km ? 'លិច' : 'W';
  return AppStrings.digits(
    '${lat.abs().toStringAsFixed(4)}° ${lat >= 0 ? n : so}, '
    '${lng.abs().toStringAsFixed(4)}° ${lng >= 0 ? e : w}',
    l,
  );
}

/// Telegram-style live-location card: a 130 px map preview with a centred pin,
/// the address, the coordinates and a `Live Location ✓✓` footer.
class LocationBubble extends ConsumerWidget {
  const LocationBubble({
    super.key,
    required this.message,
    required this.maxWidth,
  });

  final ChatMessage message;
  final double maxWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = message.isMe;
    final fg = me ? Colors.white : ChatColors.incomingText;
    final sub = me ? Colors.white70 : AppColors.slate;
    final pos = message.latLng!;
    final w = maxWidth < 260 ? maxWidth : 260.0;

    return Container(
      width: w,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: me ? ChatColors.outgoing : ChatColors.incoming,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 130,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Static preview — taps pass through, no panning.
                  IgnorePointer(
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: pos,
                        initialZoom: 15.6,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.none,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.songkrous.songkrous',
                        ),
                      ],
                    ),
                  ),
                  // Pin: its tip sits on the exact centre.
                  Center(
                    child: Transform.translate(
                      offset: const Offset(0, -17),
                      child: Icon(
                        Icons.location_on_rounded,
                        size: 38,
                        color: me ? AppColors.red : AppColors.blue,
                        shadows: const [
                          Shadow(color: Colors.black38, blurRadius: 6),
                        ],
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 6,
                    bottom: 4,
                    child: Text(
                      '© OpenStreetMap',
                      style: TextStyle(fontSize: 8, color: Color(0xFF475569)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.addressFor(ref.watch(langProvider)) ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.45,
                    fontWeight: FontWeight.w700,
                    color: fg,
                    fontFamilyFallback: const ['Noto Sans Khmer'],
                  ),
                ),
                Text(
                  formatCoordinates(
                    pos.latitude,
                    pos.longitude,
                    ref.watch(langProvider),
                  ),
                  style: TextStyle(fontSize: 12, height: 1.5, color: sub),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.sensors_rounded, size: 14, color: sub),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        ref.tr('live_location'),
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: sub,
                          fontFamilyFallback: const ['Noto Sans Khmer'],
                        ),
                      ),
                    ),
                    Text(
                      formatTime(message.timestamp, ref.watch(langProvider)),
                      style: TextStyle(fontSize: 10.5, color: sub),
                    ),
                    if (me) ...[
                      const SizedBox(width: 3),
                      StatusTicks(
                        status: message.status,
                        color: Colors.white70,
                        readColor: ChatColors.readTick,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
