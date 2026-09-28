import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/event_date_selector.dart';
import '../../core/widgets/luxury_button.dart';
import '../../models/listing_model.dart';
import 'checkout_screen.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final ListingModel listing;

  const ProductDetailScreen({
    super.key,
    required this.listing,
  });

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  late DateTime _selectedEventDate;
  int _currentImageIndex = 0;
  int _extensionDays = 0;

  @override
  void initState() {
    super.initState();
    // Default event date to next available date (skips any booked dates)
    _selectedEventDate = widget.listing.getNextAvailableDate();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.listing.baselineImages.isNotEmpty
        ? widget.listing.baselineImages
        : ['https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?w=800'];

    return Scaffold(
      backgroundColor: AppColors.bgCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, size: 22, color: AppColors.ink),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gallery Swiper
            SizedBox(
              height: 420,
              child: Stack(
                children: [
                  PageView.builder(
                    itemCount: images.length,
                    onPageChanged: (i) => setState(() => _currentImageIndex = i),
                    itemBuilder: (context, i) {
                      return CachedNetworkImage(
                        imageUrl: images[i],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder: (context, url) => Container(
                          color: AppColors.bgCream,
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentRose),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: AppColors.bgCream,
                          child: const Icon(Icons.checkroom, color: AppColors.inkMuted, size: 64),
                        ),
                      );
                    },
                  ),
                  // Pagination dots
                  if (images.length > 1)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(images.length, (i) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentImageIndex == i ? 18 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _currentImageIndex == i ? AppColors.accentRose : Colors.white.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        }),
                      ),
                    ),
                ],
              ),
            ),

            // Content container
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Lister Shop Badge
                  Row(
                    children: [
                      const Icon(Icons.verified, size: 16, color: AppColors.accentRose),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.listing.listerShopName ?? "Lister's Curated Closet",
                          style: AppTypography.subtitleTag.copyWith(color: AppColors.accentRose),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (widget.listing.status == ListingStatus.atHub)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E0812),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.gold, width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bolt, size: 12, color: AppColors.goldLight),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'IN-STOCK AT CENTRAL HUB · SAME-DAY DISPATCH READY',
                              style: AppTypography.subtitleTag.copyWith(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: AppColors.goldLight,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Title
                  Text(
                    widget.listing.title,
                    style: AppTypography.serifHeading.copyWith(fontSize: 24, height: 1.2),
                  ),
                  const SizedBox(height: 12),

                  // Pricing Badges (Wrap to prevent overflow on narrow screens)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.ink,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '₹${widget.listing.rentalPrice.toInt()}',
                              style: AppTypography.titleLarge.copyWith(
                                color: Colors.white,
                                fontSize: 17,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '/ event package',
                              style: AppTypography.bodySmall.copyWith(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.bgCream,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          'Deposit: ₹${widget.listing.securityDeposit.toInt()} (Refundable)',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.inkSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Specifications (Size, Condition, Category)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.bgCream,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSpecItem('SIZE', widget.listing.size),
                        Container(height: 24, width: 1, color: AppColors.border),
                        _buildSpecItem('CONDITION', widget.listing.condition),
                        Container(height: 24, width: 1, color: AppColors.border),
                        _buildSpecItem('CATEGORY', widget.listing.category),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Description
                  Text('ABOUT THIS OUTFIT', style: AppTypography.subtitleTag),
                  const SizedBox(height: 6),
                  Text(
                    widget.listing.description,
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.inkSecondary, height: 1.6),
                  ),
                  const SizedBox(height: 28),

                  // Single Event Date Picker (Flat Event Package)
                  EventDateSelector(
                    selectedEventDate: _selectedEventDate,
                    isDateAvailable: widget.listing.isDateAvailable,
                    extensionDays: _extensionDays,
                    onExtensionDaysChanged: (days) {
                      setState(() => _extensionDays = days);
                    },
                    rentalPrice: widget.listing.rentalPrice,
                    onDateChanged: (newDate) {
                      setState(() => _selectedEventDate = newDate);
                    },
                  ),
                  const SizedBox(height: 28),

                  // Direct "Rent Now" Button (Single-Item Flow, NO Cart)
                  Builder(
                    builder: (context) {
                      final isAvailable = widget.listing.isDateAvailable(_selectedEventDate);
                      final extCost = _extensionDays * (widget.listing.rentalPrice * 0.25);
                      final totalRent = widget.listing.rentalPrice + extCost;
                      return LuxuryButton(
                        label: isAvailable
                            ? (_extensionDays > 0
                                ? 'Rent Now · ₹${totalRent.toInt()} (${4 + _extensionDays} Days)'
                                : 'Rent Now · Instant Booking')
                            : 'Listing Not Available for this Date',
                        icon: isAvailable ? Icons.lock_outline : Icons.event_busy,
                        color: isAvailable ? AppColors.accentRose : Colors.grey.shade500,
                        onPressed: isAvailable
                            ? () {
                                final auth = ref.read(authProvider);
                                if (auth.isAuthenticated && auth.user?.role != UserRole.renter) {
                                  final roleStr = auth.user?.role.toPrismaString().replaceAll('_', ' ') ?? 'unknown';
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Your account is registered as a $roleStr. Only Renter accounts can access the checkout.'),
                                      duration: const Duration(seconds: 4),
                                      backgroundColor: AppColors.ink,
                                    ),
                                  );
                                  return;
                                }

                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => CheckoutScreen(
                                      listing: widget.listing,
                                      eventDate: _selectedEventDate,
                                      extensionDays: _extensionDays,
                                    ),
                                  ),
                                );
                              }
                            : null,
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.shield_outlined, size: 14, color: AppColors.inkMuted),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '100% Refundable Security Deposit upon return',
                            style: AppTypography.bodySmall.copyWith(fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecItem(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTypography.subtitleTag.copyWith(fontSize: 8, color: AppColors.inkMuted),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.titleLarge.copyWith(fontSize: 13, color: AppColors.ink),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
