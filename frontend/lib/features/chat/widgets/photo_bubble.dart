import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_state.dart';
import '../../../core/animations/app_animations.dart';
import '../../../shared/widgets/app_interactive.dart';
import '../models/chat_message.dart';
import 'chat_photo.dart';
import 'message_bubbles.dart';

/// Edge-to-edge rounded photo (max 230 px) with an optional caption. Without a
/// caption the timestamp + ticks sit in a dark pill over the image corner.
/// Tapping opens the [PhotoLightbox] with a shared-element `Hero`.
class PhotoBubble extends ConsumerWidget {
  const PhotoBubble({super.key, required this.message, required this.maxWidth});

  final ChatMessage message;
  final double maxWidth;

  static String heroTag(ChatMessage m) => 'chat-photo-${m.id}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final w = maxWidth < 230 ? maxWidth : 230.0;
    final caption = message.textFor(ref.watch(langProvider));
    final hasCaption = caption != null && caption.isNotEmpty;
    final me = message.isMe;

    final photo = Hero(
      tag: heroTag(message),
      child: AspectRatio(
        aspectRatio: 0.86,
        child: ChatPhoto(path: message.mediaPath ?? kDemoPhotoPath),
      ),
    );

    return Semantics(
      button: true,
      label: ref.tr('photo'),
      child: AppPressable(
        haptic: AppHaptic.selection,
        onTap: () => Navigator.of(context).push(
          PageRouteBuilder<void>(
            opaque: false,
            barrierColor: Colors.transparent,
            transitionDuration: AppDurations.medium,
            reverseTransitionDuration: const Duration(milliseconds: 240),
            pageBuilder: (_, _, _) => PhotoLightbox(message: message),
            transitionsBuilder: (_, a, _, child) => FadeTransition(
              opacity: CurvedAnimation(parent: a, curve: AppCurves.out),
              child: child,
            ),
          ),
        ),
        builder: (context, hovered, pressed) => AnimatedScale(
          duration: const Duration(milliseconds: 120),
          scale: pressed ? 0.98 : 1.0,
          child: SizedBox(
            width: w,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: ColoredBox(
                color: me ? ChatColors.outgoing : ChatColors.incoming,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Stack(
                      children: [
                        photo,
                        if (!hasCaption)
                          Positioned(
                            right: 8,
                            bottom: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: BubbleMeta(message: message, onDark: true),
                            ),
                          ),
                      ],
                    ),
                    if (hasCaption)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Text(
                                caption,
                                style: TextStyle(
                                  fontSize: 15,
                                  height: 1.45,
                                  color: me
                                      ? ChatColors.outgoingText
                                      : ChatColors.incomingText,
                                  fontFamilyFallback: const ['Noto Sans Khmer'],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            BubbleMeta(message: message),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Full-screen dark viewer: pinch-zoom, tap anywhere or ✕ to close.
class PhotoLightbox extends ConsumerWidget {
  const PhotoLightbox({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final caption = message.textFor(ref.watch(langProvider));
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.94),
      body: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).maybePop(),
            child: Center(
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Hero(
                  tag: PhotoBubble.heroTag(message),
                  child: AspectRatio(
                    aspectRatio: 0.86,
                    child: ChatPhoto(
                      path: message.mediaPath ?? kDemoPhotoPath,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: AppScaleButton(
                  tooltip: ref.tr('close'),
                  semanticLabel: ref.tr('close_photo'),
                  haptic: AppHaptic.selection,
                  onTap: () => Navigator.of(context).maybePop(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
          if (caption != null && caption.isNotEmpty)
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Text(
                    caption,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.45,
                      fontFamilyFallback: ['Noto Sans Khmer'],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
