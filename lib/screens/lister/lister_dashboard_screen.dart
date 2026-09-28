import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../models/booking_model.dart';
import '../../models/listing_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/lister_provider.dart';
import '../renter/renter_main_nav.dart';
import 'lister_main_nav.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/notification_bell_button.dart';

class ListerDashboardScreen extends ConsumerWidget {
  const ListerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = auth.user;

    final listerState = ref.watch(listerProvider);
    final profile = listerState.profile;
    final totalEarnings = listerState.totalSettled;
    final totalPending = listerState.totalPending;
    final closetCount = listerState.listings.length;
    final inCleaningCount = listerState.listings.where((l) => l.status == ListingStatus.atHub).length;
    final rentedCount = listerState.listings.where((l) => l.status == ListingStatus.rented).length;

    final bookingsAsync = ref.watch(listerBookingsProvider);
    final isApproved = profile?.status == 'APPROVED';
    final hasFeePaid = profile?.registrationFeePaid ?? false;

    final String displayName;
    if (profile?.shopName != null && profile!.shopName!.trim().isNotEmpty) {
      displayName = profile.shopName!;
    } else if (user?.name != null && user!.name.trim().isNotEmpty) {
      displayName = user.name;
    } else {
      displayName = 'Lister';
    }

    return Scaffold(
      backgroundColor: AppColors.bgCream,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const BrandLogoWidget(
          size: LogoSize.md,
          showSubtitle: true,
          subtitle: 'PARTNER DASHBOARD',
        ),
        actions: [
          const NotificationBellButton(),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.inkSecondary),
            tooltip: 'Refresh',
            onPressed: () {
              ref.read(listerProvider.notifier).refreshAll();
              ref.read(listerBookingsProvider.notifier).fetchBookings();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626)),
            tooltip: 'Sign Out',
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const RenterMainNav()),
                  (route) => false,
                );
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.accentRose,
        backgroundColor: Colors.white,
        onRefresh: () async {
          await ref.read(listerProvider.notifier).refreshAll();
          await ref.read(listerBookingsProvider.notifier).fetchBookings();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Welcome Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: AppColors.accentRoseLight,
                      child: Text(
                        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'W',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accentRose,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isApproved ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isApproved ? 'Verified Partner' : 'Verification Pending',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isApproved ? const Color(0xFF166534) : const Color(0xFFB45309),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // KYC or Fee Alert Banner
              if (!hasFeePaid || !isApproved) ...[
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => ref.read(listerNavIndexProvider.notifier).state = 4,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                !hasFeePaid ? 'Complete Onboarding Fee' : 'KYC Verification Needed',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF92400E),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                !hasFeePaid
                                    ? 'Pay ₹500 one-time fee to publish listings.'
                                    : 'Submit your Aadhaar, PAN and Bank account details.',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  color: const Color(0xFFB45309),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Color(0xFFB45309), size: 20),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // 2. Earnings & Balance Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'TOTAL EARNINGS',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: AppColors.inkMuted,
                          ),
                        ),
                        InkWell(
                          onTap: () => ref.read(listerNavIndexProvider.notifier).state = 3,
                          child: Text(
                            'View Details →',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.accentRose,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹${totalEarnings.toInt()}',
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Divider(height: 1, color: AppColors.borderLight),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF16A34A),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Wallet Balance',
                                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.inkMuted),
                                  ),
                                  Text(
                                    '₹${(profile?.walletBalance ?? 0).toInt()}',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF59E0B),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pending Clearance',
                                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.inkMuted),
                                  ),
                                  Text(
                                    '₹${totalPending.toInt()}',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 3. Wardrobe Quick Stats
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      label: 'Total Items',
                      count: closetCount,
                      icon: Icons.checkroom_outlined,
                      color: AppColors.ink,
                      onTap: () => ref.read(listerNavIndexProvider.notifier).state = 1,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricCard(
                      label: 'Rented Out',
                      count: rentedCount,
                      icon: Icons.sync_alt_rounded,
                      color: const Color(0xFF059669),
                      onTap: () => ref.read(listerNavIndexProvider.notifier).state = 1,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricCard(
                      label: 'At Hub',
                      count: inCleaningCount,
                      icon: Icons.local_laundry_service_outlined,
                      color: const Color(0xFF2563EB),
                      onTap: () => ref.read(listerNavIndexProvider.notifier).state = 1,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 4. Quick Action Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add_rounded, size: 20, color: Colors.white),
                  label: Text(
                    'Add New Outfit to Wardrobe',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentRose,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => ref.read(listerNavIndexProvider.notifier).state = 1,
                ),
              ),

              const SizedBox(height: 24),

              // 5. Recent Orders Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Orders',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  InkWell(
                    onTap: () => ref.read(listerNavIndexProvider.notifier).state = 2,
                    child: Text(
                      'View All Orders',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accentRose,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              bookingsAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(color: AppColors.accentRose),
                  ),
                ),
                error: (e, _) => Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text('Failed to load orders: $e', style: GoogleFonts.inter(color: Colors.red)),
                ),
                data: (bookings) {
                  if (bookings.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.inbox_outlined, size: 40, color: Color(0xFFCBD5E1)),
                          const SizedBox(height: 10),
                          Text(
                            'No orders yet',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.inkSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'When renters book your outfits, they will appear here.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkMuted),
                          ),
                        ],
                      ),
                    );
                  }

                  final previewList = bookings.take(3).toList();
                  return Column(
                    children: previewList.map((b) => _buildOrderTile(context, ref, b)).toList(),
                  );
                },
              ),

              const SizedBox(height: 90),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String label,
    required int count,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              '$count',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: AppColors.inkMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderTile(BuildContext context, WidgetRef ref, BookingModel booking) {
    final title = booking.listing?.title ?? 'Ethnic Outfit';
    final image = booking.listing?.baselineImages.isNotEmpty == true
        ? booking.listing!.baselineImages.first
        : null;
    final rent = booking.rentAmount;

    String statusText;
    Color statusBg;
    Color statusColor;

    switch (booking.status) {
      case BookingStatus.confirmed:
        statusText = 'To Dispatch';
        statusBg = const Color(0xFFFEF3C7);
        statusColor = const Color(0xFFB45309);
        break;
      case BookingStatus.inUse:
        statusText = 'In Use';
        statusBg = const Color(0xFFEFF6FF);
        statusColor = const Color(0xFF1D4ED8);
        break;
      case BookingStatus.completed:
        statusText = 'Completed';
        statusBg = const Color(0xFFDCFCE7);
        statusColor = const Color(0xFF166534);
        break;
      case BookingStatus.cancelled:
        statusText = 'Cancelled';
        statusBg = const Color(0xFFFEE2E2);
        statusColor = const Color(0xFF991B1B);
        break;
      default:
        statusText = booking.status.name;
        statusBg = const Color(0xFFF1F5F9);
        statusColor = const Color(0xFF475569);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 50,
              height: 50,
              color: AppColors.bgCream,
              child: image != null && image.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: image,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => const Icon(Icons.checkroom, color: AppColors.inkMuted),
                    )
                  : const Icon(Icons.checkroom, color: AppColors.inkMuted),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '₹${rent.toInt()} earnings',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF16A34A),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              statusText,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
