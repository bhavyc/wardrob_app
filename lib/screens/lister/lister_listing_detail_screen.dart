import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../models/listing_model.dart';
import '../../providers/lister_provider.dart';

class ListerListingDetailScreen extends ConsumerStatefulWidget {
  final ListingModel listing;

  const ListerListingDetailScreen({
    super.key,
    required this.listing,
  });

  @override
  ConsumerState<ListerListingDetailScreen> createState() => _ListerListingDetailScreenState();
}

class _ListerListingDetailScreenState extends ConsumerState<ListerListingDetailScreen> {
  int _activeImageIndex = 0;
  final PageController _pageController = PageController();
  bool _isWithdrawing = false;
  bool _isTogglingStatus = false;
  late ListingStatus _currentStatus;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.listing.status;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _handleToggleStatus() async {
    final willBeAvailable = _currentStatus == ListingStatus.unlisted;
    final actionText = willBeAvailable ? 'Publish to Catalog' : 'Unlist from Catalog';
    final msg = willBeAvailable
        ? 'This outfit will become live and available for renters to book.'
        : 'This outfit will be hidden from the storefront and no new bookings can be made.';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          '$actionText?',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 17, color: AppColors.ink),
        ),
        content: Text(
          msg,
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.inkSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.inkMuted, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: willBeAvailable ? const Color(0xFF059669) : AppColors.inkSecondary,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(willBeAvailable ? 'Publish Outfit' : 'Unlist Outfit',
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isTogglingStatus = true);
    final target = willBeAvailable ? 'AVAILABLE' : 'UNLISTED';
    final res = await ref.read(listerProvider.notifier).toggleListingStatus(widget.listing.id, targetStatus: target);
    if (!mounted) return;
    setState(() => _isTogglingStatus = false);

    if (res['success'] == true) {
      setState(() {
        _currentStatus = willBeAvailable ? ListingStatus.available : ListingStatus.unlisted;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Status updated successfully.'),
          backgroundColor: willBeAvailable ? AppColors.success : AppColors.inkSecondary,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['error'] ?? 'Failed to update outfit status.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleWithdraw() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Request Return from Hub?',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 17, color: AppColors.ink),
        ),
        content: Text(
          'This outfit will be packed and returned to your registered boutique address via verified courier partner.',
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.inkSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.inkMuted, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentRose,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Confirm Return', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isWithdrawing = true);
    final res = await ref.read(listerProvider.notifier).withdrawListing(widget.listing.id);
    if (!mounted) return;
    setState(() => _isWithdrawing = false);

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Return requested successfully.'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context); // return to wardrobe
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['error'] ?? 'Failed to request return.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.listing;
    final images = item.baselineImages.isNotEmpty
        ? item.baselineImages
        : <String>[];

    // Status styling
    String statusText;
    Color statusBg;
    Color statusColor;
    Color statusDot;

    switch (_currentStatus) {
      case ListingStatus.available:
        statusText = 'Available for Rent';
        statusBg = const Color(0xFFF0FDF4);
        statusColor = const Color(0xFF166534);
        statusDot = const Color(0xFF22C55E);
        break;
      case ListingStatus.rented:
        statusText = 'Currently Rented';
        statusBg = const Color(0xFFEFF6FF);
        statusColor = const Color(0xFF1D4ED8);
        statusDot = const Color(0xFF3B82F6);
        break;
      case ListingStatus.atHub:
        statusText = 'In Cleaning at Hub';
        statusBg = const Color(0xFFFAF5FF);
        statusColor = const Color(0xFF6B21A8);
        statusDot = const Color(0xFFA855F7);
        break;
      case ListingStatus.maintenance:
        statusText = 'Under Inspection / Maintenance';
        statusBg = const Color(0xFFFFFBEB);
        statusColor = const Color(0xFFB45309);
        statusDot = const Color(0xFFF59E0B);
        break;
      case ListingStatus.unlisted:
        statusText = 'Unlisted / Hidden from Catalog';
        statusBg = const Color(0xFFF8FAFC);
        statusColor = const Color(0xFF475569);
        statusDot = const Color(0xFF94A3B8);
        break;
    }

    final commission = (item.rentalPrice * 0.35).clamp(2000.0, double.infinity);
    final listerShare = (item.rentalPrice - commission).clamp(0.0, double.infinity).toInt();

    return Scaffold(
      backgroundColor: AppColors.bgCream,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 19, color: AppColors.ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Outfit Details',
          style: GoogleFonts.inter(
            fontSize: 16.5,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_outlined, size: 20, color: AppColors.inkSecondary),
            tooltip: 'Copy Outfit ID',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: item.id));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Outfit ID copied to clipboard'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Gallery Carousel
            SizedBox(
              height: 380,
              width: double.infinity,
              child: Stack(
                children: [
                  if (images.isNotEmpty)
                    PageView.builder(
                      controller: _pageController,
                      itemCount: images.length,
                      onPageChanged: (idx) => setState(() => _activeImageIndex = idx),
                      itemBuilder: (ctx, idx) {
                        return CachedNetworkImage(
                          imageUrl: images[idx],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          placeholder: (context, url) => Container(
                            color: const Color(0xFFF1ECE5),
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentRose),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: const Color(0xFFF1ECE5),
                            child: const Icon(Icons.broken_image_outlined, size: 48, color: AppColors.inkMuted),
                          ),
                        );
                      },
                    )
                  else
                    Container(
                      color: const Color(0xFFFAF8F5),
                      child: const Center(
                        child: Icon(Icons.checkroom, size: 64, color: AppColors.inkMuted),
                      ),
                    ),

                  // Image count pill
                  if (images.length > 1)
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_activeImageIndex + 1} / ${images.length}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                  // Verified camera capture badge
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF059669)),
                          const SizedBox(width: 5),
                          Text(
                            'Live Verified Photo',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF065F46),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. Main Content Card
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusDot.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: statusDot,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          statusText,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Title
                  Text(
                    item.title,
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                      height: 1.25,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Tags row
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildPillTag(Icons.category_outlined, item.category),
                      _buildPillTag(Icons.straighten_outlined, 'Size ${item.size}'),
                      _buildPillTag(Icons.auto_awesome_outlined, item.condition),
                      if (item.listerShopName != null && item.listerShopName!.isNotEmpty)
                        _buildPillTag(Icons.storefront_outlined, item.listerShopName!),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 3. Commercial & Payout Summary Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFEBE5DB)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'COMMERCIAL DETAILS',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: AppColors.inkMuted,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Rental rate
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Event Package Rate',
                              style: GoogleFonts.inter(fontSize: 13.5, color: AppColors.inkSecondary),
                            ),
                            Text(
                              '₹${item.rentalPrice.toInt()} / 4 days',
                              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Security deposit
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Security Deposit',
                              style: GoogleFonts.inter(fontSize: 13.5, color: AppColors.inkSecondary),
                            ),
                            Text(
                              '₹${item.securityDeposit.toInt()}',
                              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink),
                            ),
                          ],
                        ),

                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(height: 1, color: Color(0xFFF1ECE5)),
                        ),

                        // Lister net earning
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFBBF7D0)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Your Net Payout',
                                      style: GoogleFonts.inter(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF166534),
                                      ),
                                    ),
                                    Text(
                                      'After 35% platform fee (min ₹2,000 floor)',
                                      style: GoogleFonts.inter(
                                        fontSize: 10.5,
                                        color: const Color(0xFF15803D),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '₹$listerShare',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF166534),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Lifetime bookings count
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Rentals Completed',
                              style: GoogleFonts.inter(fontSize: 13, color: AppColors.inkSecondary),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${item.bookingsCount} booking${item.bookingsCount == 1 ? '' : 's'}',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // 4. Description Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFEBE5DB)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'GARMENT DESCRIPTION',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: AppColors.inkMuted,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          item.description.isNotEmpty
                              ? item.description
                              : 'No detailed description provided for this outfit.',
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            color: AppColors.inkSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // 5. Outfit Identification (SKU & ID)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFEBE5DB)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'IDENTIFICATION',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: AppColors.inkMuted,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Outfit Unique ID',
                              style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.inkSecondary),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                item.id.length > 16 ? '${item.id.substring(0, 16)}...' : item.id,
                                textAlign: TextAlign.end,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.robotoMono(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 6. Action Button if at Hub
                  if (_currentStatus == ListingStatus.atHub) ...[
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentRose,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isWithdrawing ? null : _handleWithdraw,
                        child: _isWithdrawing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.local_shipping_outlined, color: Colors.white, size: 20),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'Request Return from Hub',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],

                  // 7. Publish to Catalog / Make Available button (if Unlisted)
                  if (_currentStatus == ListingStatus.unlisted) ...[
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isTogglingStatus ? null : _handleToggleStatus,
                        child: _isTogglingStatus
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'Publish & Make Available for Rent',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],

                  // 8. Pause / Unlist button (if currently Available)
                  if (_currentStatus == ListingStatus.available) ...[
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isTogglingStatus ? null : _handleToggleStatus,
                        child: _isTogglingStatus
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ink),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.pause_circle_outline, color: AppColors.inkSecondary, size: 18),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      'Pause Rentals (Unlist from Catalog)',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.inkSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPillTag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1ECE5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.inkSecondary),
          const SizedBox(width: 5),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.inkSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
