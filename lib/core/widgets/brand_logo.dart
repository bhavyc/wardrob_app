import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

enum LogoSize { sm, md, lg, xl }

class BrandLogoWidget extends StatelessWidget {
  final LogoSize size;
  final Color color;
  final Color accentColor;
  final CrossAxisAlignment align;
  final bool showSubtitle;
  final String? subtitle;

  const BrandLogoWidget({
    super.key,
    this.size = LogoSize.md,
    this.color = AppColors.ink,
    this.accentColor = AppColors.accentRose,
    this.align = CrossAxisAlignment.center,
    this.showSubtitle = false,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    double ruleWidth;
    double diamondSize;
    double fontSize;
    double letterSpacing;
    double subtitleSize;

    switch (size) {
      case LogoSize.sm:
        ruleWidth = 14;
        diamondSize = 3;
        fontSize = 15;
        letterSpacing = 2.5;
        subtitleSize = 7.5;
        break;
      case LogoSize.md:
        ruleWidth = 20;
        diamondSize = 4;
        fontSize = 19;
        letterSpacing = 3.0;
        subtitleSize = 8.5;
        break;
      case LogoSize.lg:
        ruleWidth = 28;
        diamondSize = 5;
        fontSize = 24;
        letterSpacing = 4.0;
        subtitleSize = 9.5;
        break;
      case LogoSize.xl:
        ruleWidth = 36;
        diamondSize = 6;
        fontSize = 30;
        letterSpacing = 5.0;
        subtitleSize = 10.5;
        break;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: align,
      children: [
        // Diamond Crest Ornament: ─── ◆ ───
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: ruleWidth,
              height: 1.0,
              color: color.withValues(alpha: 0.85),
            ),
            const SizedBox(width: 4),
            Transform.rotate(
              angle: 0.785398, // 45 degrees
              child: Container(
                width: diamondSize,
                height: diamondSize,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(0.5),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Container(
              width: ruleWidth,
              height: 1.0,
              color: color.withValues(alpha: 0.85),
            ),
          ],
        ),
        const SizedBox(height: 3),

        // Wordmark: WARDROB
        Text(
          'WARDROB',
          style: GoogleFonts.cormorantGaramond(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: letterSpacing,
            height: 1.1,
          ),
        ),

        // Subtitle tag if enabled
        if (showSubtitle && subtitle != null) ...[
          const SizedBox(height: 3),
          Text(
            subtitle!.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: subtitleSize,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.5,
              color: accentColor,
            ),
          ),
        ],
      ],
    );
  }
}
