import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/listing_model.dart';
import '../constants/app_colors.dart';

class LuxuryCard extends StatelessWidget {
  final ListingModel listing;
  final VoidCallback onTap;
  final String? badge;
  final bool showHeart;

  const LuxuryCard({
    super.key,
    required this.listing,
    required this.onTap,
    this.badge,
    this.showHeart = true,
  });

  @override
  Widget build(BuildContext context) {
    final image = listing.baselineImages.isNotEmpty
        ? listing.baselineImages.first
        : 'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?w=800';

    final shopLabel = (listing.listerShopName != null && listing.listerShopName!.isNotEmpty)
        ? listing.listerShopName!
        : listing.category;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFEDE8E1),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E1E2D).withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image Section (Top 65%) ────────────────────────────────────
              Expanded(
                flex: 65,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: image,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: const Color(0xFFF7F5F0)),
                      errorWidget: (context, url, error) => Container(
                        color: const Color(0xFFF7F5F0),
                        child: const Icon(Icons.checkroom, color: AppColors.inkMuted, size: 28),
                      ),
                    ),

                    // Subtle top vignette for badge & heart readability
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 48,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.28),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Badge: either custom (e.g. "NEW DROP") or category pill
                    Positioned(
                      top: 8,
                      left: 8,
                      child: badge != null
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.ink,
                                borderRadius: BorderRadius.circular(5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Text(
                                badge!.toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontSize: 7.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: AppColors.goldLight,
                                ),
                              ),
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(5),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.88),
                                    borderRadius: BorderRadius.circular(5),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.9),
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Text(
                                    listing.category.toUpperCase(),
                                    style: GoogleFonts.inter(
                                      fontSize: 7.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.6,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                    ),

                    // Availability Badge (bottom-left of image)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: listing.isAvailableNow
                                  ? const Color(0xE615803D)
                                  : const Color(0xE6B45309),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: listing.isAvailableNow
                                    ? const Color(0xFF86EFAC).withValues(alpha: 0.6)
                                    : const Color(0xFFFDE68A).withValues(alpha: 0.6),
                                width: 0.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: listing.isAvailableNow
                                        ? const Color(0xFF4ADE80)
                                        : const Color(0xFFFCD34D),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  listing.availabilityBadge,
                                  style: GoogleFonts.inter(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                  ],
                ),
              ),

              // ── Details Section (Bottom 35%) ───────────────────────────────
              Expanded(
                flex: 35,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            shopLabel.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.7,
                              color: AppColors.accentRose,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            listing.title,
                            style: GoogleFonts.cormorantGaramond(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                              height: 1.15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '₹${listing.rentalPrice.toInt()}',
                                  style: GoogleFonts.inter(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.ink,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '· 4 days',
                                  style: GoogleFonts.inter(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.inkMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: AppColors.bgCream,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.border,
                                width: 0.6,
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                size: 11,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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
