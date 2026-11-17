import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';

/// Brand card: rounded white square showing the official logo
/// (`assets/images/logo.png`). If the asset is missing or fails to load, a
/// typographic version (red `សង្គ្រោះ` + stacked blue `song / krous`) is drawn
/// instead; pass `assetPath: null` to force that fallback.
///
/// All proportions are relative to the card size and match the 210 px splash
/// spec (radius 36). When laid out with *tight* constraints — e.g. inside a
/// `Hero` flight — the card adopts that size, so the logo scales smoothly
/// between screens.
class SongkrousLogo extends StatelessWidget {
  const SongkrousLogo({
    super.key,
    this.size = 120,
    this.assetPath = defaultAsset,
  });

  static const String defaultAsset = 'assets/images/logo.png';

  final double size;
  final String? assetPath;

  /// The PNG has generous white margins (artwork ≈ 61% of its width, centred
  /// ~3% above middle). Scale it up about that point so the wordmark fills the
  /// card; the card clips the overflow.
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
          child: Container(
            width: s,
            height: s,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(s * _radius),
              boxShadow: [
                BoxShadow(
                  color: AppColors.blueDark.withValues(alpha: 0.22),
                  blurRadius: s * 0.22,
                  offset: Offset(0, s * 0.08),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
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
