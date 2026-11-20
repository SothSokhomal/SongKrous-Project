import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_interactive.dart';

/// Telegram-style "Profile Photo" confirmation: the picked image inside a
/// bright circular viewport you can pinch-zoom and pan. Returns the framed
/// result as PNG bytes (or the original bytes if capturing fails), `null` when
/// cancelled.
Future<Uint8List?> showPhotoPreview(BuildContext context, Uint8List bytes) {
  return Navigator.of(context).push<Uint8List>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => PhotoPreviewScreen(bytes: bytes),
    ),
  );
}

class PhotoPreviewScreen extends ConsumerStatefulWidget {
  const PhotoPreviewScreen({super.key, required this.bytes});

  final Uint8List bytes;

  @override
  ConsumerState<PhotoPreviewScreen> createState() => _PhotoPreviewScreenState();
}

class _PhotoPreviewScreenState extends ConsumerState<PhotoPreviewScreen> {
  final _frameKey = GlobalKey();
  bool _saving = false;

  Future<void> _confirm() async {
    if (_saving) return;
    setState(() => _saving = true);
    HapticFeedback.mediumImpact();
    Uint8List out = widget.bytes;
    try {
      final boundary =
          _frameKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary != null) {
        final image = await boundary
            .toImage(pixelRatio: 2.5)
            .timeout(const Duration(seconds: 3));
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        if (data != null) out = data.buffer.asUint8List();
      }
    } catch (_) {
      // Keep the original bytes: the photo is still set, just un-framed.
    }
    if (mounted) Navigator.of(context).pop(out);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final viewport = math.min(width - 48, 320.0);

    return Scaffold(
      backgroundColor: const Color(0xFF05070D),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  ref.tr('profile_photo_title'),
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.5,
                    fontFamilyFallback: ['Noto Sans Khmer'],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: viewport + 12,
                      height: viewport + 12,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Bright ring.
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.blue.withValues(alpha: 0.5),
                                  blurRadius: 24,
                                ),
                              ],
                            ),
                          ),
                          RepaintBoundary(
                            key: _frameKey,
                            child: ClipOval(
                              child: SizedBox.square(
                                dimension: viewport,
                                child: InteractiveViewer(
                                  key: const ValueKey('photo-viewport'),
                                  minScale: 1,
                                  maxScale: 5,
                                  child: SizedBox.square(
                                    dimension: viewport,
                                    child: Image.memory(
                                      widget.bytes,
                                      fit: BoxFit.cover,
                                      gaplessPlayback: true,
                                      errorBuilder: (_, _, _) =>
                                          const ColoredBox(
                                            color: AppColors.blueDeep,
                                            child: Icon(
                                              Icons.broken_image_rounded,
                                              color: Colors.white54,
                                              size: 48,
                                            ),
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        ref.tr('photo_preview_hint'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13.5,
                          height: 1.5,
                          fontFamilyFallback: ['Noto Sans Khmer'],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 16, 16),
              child: Row(
                children: [
                  TextButton(
                    key: const ValueKey('photo-preview-cancel'),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      ref.tr('cancel'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamilyFallback: ['Noto Sans Khmer'],
                      ),
                    ),
                  ),
                  const Spacer(),
                  Flexible(
                    child: AppInteractiveButton(
                      key: const ValueKey('photo-preview-confirm'),
                      label: ref.tr('photo_set_profile'),
                      height: 48,
                      fontSize: 15,
                      expand: false,
                      loading: _saving,
                      onPressed: _confirm,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
