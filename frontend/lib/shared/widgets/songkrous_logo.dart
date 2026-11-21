import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import 'liquid_glass.dart';

class SongkrousLogo extends StatelessWidget {
  const SongkrousLogo({
    super.key,
    this.size = 120,
    this.assetPath = defaultAsset,
  });

  static const String defaultAsset = 'assets/images/logo.png';

  final double size;
  final String? assetPath;
  static const double _assetZoom = 1.45;
  static const Alignment _assetFocus = Alignment(0, -0.19);

  static const double _radius = 36 / 210;
  static const double _khmer = 52 / 210;
  static const double _latin = 20 / 210;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final s = constraints.hasTightWidth && constraints.hasTightHeight
            ? constraints.biggest.shortestSide
            : size;
        return Semantics(
          label: 'Songkrous',
          image: true,
          // Frosted glass card with a specular rim (near-opaque so the logo
          // artwork stays crisp).
          child: LiquidGlassContainer(
            radius: s * _radius,
            tint: LiquidTint.frostStrong,
            useBlur: false,
            width: s,
            height: s,
            padding: assetPath != null ? null : EdgeInsets.all(s * 0.08),
            child: assetPath != null
                ? Transform.scale(
                    scale: _assetZoom,
                    alignment: _assetFocus,
                    child: Image.asset(
                      assetPath!,
                      fit: BoxFit.contain,
                      // Decode near display size, not the full 2000 px.
                      cacheWidth: 900,
                      filterQuality: FilterQuality.high,
                      errorBuilder: (_, _, _) => Padding(
                        padding: EdgeInsets.all(s * 0.08),
                        child: _wordmark(s),
                      ),
                    ),
                  )
                : _wordmark(s),
          ),
        );
      },
    );
  }

  Widget _wordmark(double s) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'សង្គ្រោះ',
            style: GoogleFonts.notoSansKhmer(
              fontSize: s * _khmer,
              fontWeight: FontWeight.w800,
              color: AppColors.red,
              height: 1.5,
            ),
          ),
          SizedBox(height: s * 0.01),
          for (final word in const ['song', 'krous'])
            Text(
              word,
              style: GoogleFonts.inter(
                fontSize: s * _latin,
                fontWeight: FontWeight.w800,
                color: AppColors.blue,
                height: 1.15,
                letterSpacing: s * 0.004,
              ),
            ),
        ],
      ),
    );
  }
}
