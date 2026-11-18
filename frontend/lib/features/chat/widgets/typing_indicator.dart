import 'package:flutter/material.dart';

import '../../../core/animations/looping_animation.dart';
import '../../../core/theme/app_colors.dart';

/// Three dots bouncing in a wave, inside an incoming-style bubble.
class TypingIndicator extends StatelessWidget {
  const TypingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFFF1F5F9),
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: LoopingAnimation(
        duration: const Duration(milliseconds: 1000),
        builder: (context, a) => AnimatedBuilder(
          animation: a,
          builder: (context, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 3; i++)
                Padding(
                  padding: EdgeInsets.only(right: i == 2 ? 0 : 5),
                  child: Opacity(
                    opacity:
                        0.35 +
                        0.65 * (1 - (2 * ((a.value - i / 3) % 1.0) - 1).abs()),
                    child: Transform.translate(
                      offset: Offset(
                        0,
                        -2.5 * (1 - (2 * ((a.value - i / 3) % 1.0) - 1).abs()),
                      ),
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppColors.slate,
                          shape: BoxShape.circle,
                        ),
                      ),
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
