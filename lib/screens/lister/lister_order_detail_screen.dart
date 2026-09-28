import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/booking_model.dart';
import '../../providers/booking_provider.dart';
import 'lister_listing_detail_screen.dart';

class ListerOrderDetailScreen extends ConsumerStatefulWidget {
  final BookingModel order;

  const ListerOrderDetailScreen({
    super.key,
    required this.order,
  });

  @override
  ConsumerState<ListerOrderDetailScreen> createState() => _ListerOrderDetailScreenState();
}

class _ListerOrderDetailScreenState extends ConsumerState<ListerOrderDetailScreen> {
  late BookingModel _order;
  bool _isMarkingPacked = false;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
  }

  Future<void> _handleMarkPacked() async {
    setState(() => _isMarkingPacked = true);
    final res = await ref.read(listerBookingsProvider.notifier).markPacked(_order.id);
    if (!mounted) return;
    setState(() => _isMarkingPacked = false);

    if (res['success'] == true) {
      // Re-fetch bookings to update provider
      await ref.read(listerBookingsProvider.notifier).fetchBookings();
      final updatedList = ref.read(listerBookingsProvider).value ?? [];
      final updated = updatedList.firstWhere(
        (b) => b.id == _order.id,
        orElse: () => _order,
      );

      setState(() {
        _order = updated;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Marked packed! Hub courier pickup requested.'),
            backgroundColor: const Color(0xFF166534),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['error'] ?? 'Failed to request courier pickup.'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Keep order synced with provider if updated in background
    final allBookings = ref.watch(listerBookingsProvider).value;
    if (allBookings != null) {
      final found = allBookings.where((b) => b.id == _order.id).firstOrNull;
      if (found != null && found.status != _order.status) {
        _order = found;
      }
    }

    final dateFmt = DateFormat('dd MMM yyyy');
    final startDateStr = dateFmt.format(_order.startDate);
    final endDateStr = dateFmt.format(_order.endDate);
    final eventDate = _order.startDate.add(const Duration(days: 2));
    final eventDateStr = dateFmt.format(eventDate);
    final durationDays = _order.endDate.difference(_order.startDate).inDays;

    final outfit = _order.listing;
    final image = outfit?.baselineImages.isNotEmpty == true ? outfit!.baselineImages.first : null;
    final title = outfit?.title ?? 'Luxury Designer Ethnic Outfit';
    final category = outfit?.category ?? 'Couture';
    final size = outfit?.size ?? 'M';
    final condition = outfit?.condition ?? 'LIKE_NEW';

    // Status styling
    String statusTitle;
    Color statusBg;
    Color statusColor;
    IconData statusIcon;

    switch (_order.status) {
      case BookingStatus.confirmed:
        statusTitle = 'CONFIRMED · TO DISPATCH';
        statusBg = const Color(0xFFFEF3C7);
        statusColor = const Color(0xFFB45309);
        statusIcon = Icons.inventory_2_outlined;
        break;
      case BookingStatus.atHubPre:
        statusTitle = 'PICKED UP · AWAITING HUB';
        statusBg = const Color(0xFFF3E8FF);
        statusColor = const Color(0xFF6B21A8);
        statusIcon = Icons.local_shipping_outlined;
        break;
      case BookingStatus.outForDelivery:
        statusTitle = 'DISPATCHED TO RENTER';
        statusBg = const Color(0xFFEEF2FF);
        statusColor = const Color(0xFF4338CA);
        statusIcon = Icons.delivery_dining_outlined;
        break;
      case BookingStatus.inUse:
        statusTitle = 'IN USE BY RENTER';
        statusBg = const Color(0xFFEFF6FF);
        statusColor = const Color(0xFF1D4ED8);
        statusIcon = Icons.checkroom_rounded;
        break;
      case BookingStatus.returnedToHub:
        statusTitle = 'RETURNED TO HUB · INSPECTING';
        statusBg = const Color(0xFFFDF2F8);
        statusColor = const Color(0xFF9D174D);
        statusIcon = Icons.verified_outlined;
        break;
      case BookingStatus.completed:
        statusTitle = 'COMPLETED & SETTLED';
        statusBg = const Color(0xFFDCFCE7);
        statusColor = const Color(0xFF166534);
        statusIcon = Icons.task_alt_rounded;
        break;
      case BookingStatus.cancelled:
        statusTitle = 'CANCELLED';
        statusBg = const Color(0xFFFEE2E2);
        statusColor = const Color(0xFF991B1B);
        statusIcon = Icons.cancel_outlined;
        break;
      default:
        statusTitle = _order.status.toDisplayString().toUpperCase();
        statusBg = const Color(0xFFF1F5F9);
        statusColor = const Color(0xFF475569);
        statusIcon = Icons.info_outline;
    }

    // Payout estimation (65% share, with 35% commission or min ₹2000 floor)
    final rent = _order.rentAmount;
    final commission = (rent * 0.35).clamp(2000.0, double.infinity);
    final estimatedPayout = (rent - commission).clamp(0.0, double.infinity);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          children: [
            Text(
              'ORDER DETAILS',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
                letterSpacing: 2.0,
              ),
            ),
            Text(
              '#${_order.id.length > 8 ? _order.id.substring(0, 8).toUpperCase() : _order.id}',
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: AppColors.inkMuted,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.inkSecondary),
            tooltip: 'Copy Order ID',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _order.id));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Order ID copied to clipboard'),
                  duration: Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. STATUS BANNER ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          statusTitle,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _getStatusSubtitle(_order.status),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: statusColor.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── 2. OUTFIT / PRODUCT HERO CARD ──
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image Thumbnail
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 80,
                          height: 96,
                          color: AppColors.bgCream,
                          child: image != null && image.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: image,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, _, _) => const Icon(
                                    Icons.checkroom,
                                    color: AppColors.inkMuted,
                                    size: 32,
                                  ),
                                )
                              : const Icon(Icons.checkroom, color: AppColors.inkMuted, size: 32),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF2F5),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.accentRose.withValues(alpha: 0.2)),
                              ),
                              child: Text(
                                category.toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.accentRose,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              title,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                                height: 1.25,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              children: [
                                _buildBadge('Size: $size', AppColors.inkSecondary),
                                _buildBadge(condition.replaceAll('_', ' '), const Color(0xFF059669)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  if (outfit != null) ...[
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: AppColors.borderLight),
                    const SizedBox(height: 8),
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ListerListingDetailScreen(listing: outfit),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'View Original Listing Details',
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.accentRose,
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 13,
                              color: AppColors.accentRose,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── 3. RENTAL PERIOD & TIMELINE SCHEDULE ──
            _buildSectionCard(
              title: 'RENTAL SCHEDULE',
              icon: Icons.calendar_today_rounded,
              child: Column(
                children: [
                  _buildScheduleRow(
                    label: 'Hub Pickup / Dispatch',
                    date: startDateStr,
                    subtitle: 'Item leaves your atelier for Hub inspection',
                    isHighlight: false,
                  ),
                  const Divider(height: 16, color: AppColors.borderLight),
                  _buildScheduleRow(
                    label: "Renter's Event Date",
                    date: eventDateStr,
                    subtitle: 'Main event occasion for customer wear',
                    isHighlight: true,
                  ),
                  const Divider(height: 16, color: AppColors.borderLight),
                  _buildScheduleRow(
                    label: 'Return Date (End of Rental)',
                    date: endDateStr,
                    subtitle: 'Picked up from renter and returned to hub',
                    isHighlight: false,
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.bgCream,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Rental Duration',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkSecondary),
                        ),
                        Text(
                          '$durationDays Days Rental',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── 4. FINANCIAL BREAKDOWN & ESTIMATED PAYOUT ──
            _buildSectionCard(
              title: 'FINANCIALS & LISTER EARNINGS',
              icon: Icons.account_balance_wallet_outlined,
              child: Column(
                children: [
                  _buildFinancialRow('Customer Rent Amount', '₹${_order.rentAmount.toInt()}'),
                  const SizedBox(height: 8),
                  _buildFinancialRow(
                    'Security Deposit (Escrow)',
                    '₹${_order.securityDeposit.toInt()}',
                    note: 'Held by Wardrob Hub until final return check',
                  ),
                  if (_order.extensionFee > 0) ...[
                    const SizedBox(height: 8),
                    _buildFinancialRow('Rental Extension Fee', '+₹${_order.extensionFee.toInt()}'),
                  ],
                  const SizedBox(height: 8),
                  _buildFinancialRow('Platform Commission (35% or min ₹2,000)', '-₹${commission.toInt()}', isMuted: true),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: AppColors.borderLight),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Estimated Lister Payout',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF166534),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Released after Hub Return Inspection',
                                style: GoogleFonts.inter(
                                  fontSize: 10.5,
                                  color: const Color(0xFF15803D),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '₹${estimatedPayout.toInt()}',
                          style: GoogleFonts.inter(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF15803D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── 5. RENTER & VERIFICATION DETAILS ──
            _buildSectionCard(
              title: 'CUSTOMER / RENTER DETAILS',
              icon: Icons.person_outline_rounded,
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF2F5),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.accentRose.withValues(alpha: 0.3)),
                        ),
                        child: const Icon(Icons.person, color: AppColors.accentRose, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    _order.renterName ?? 'Verified Customer',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.ink,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.verified, size: 15, color: Color(0xFF0D9488)),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _order.renterPhone ?? 'Phone on record with Hub',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.inkMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.shield_outlined, size: 12, color: Color(0xFF166534)),
                            const SizedBox(width: 4),
                            Text(
                              'VERIFIED',
                              style: GoogleFonts.inter(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF166534),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── 7. PRIMARY ACTION BUTTON (IF CONFIRMED) ──
            if (_order.status == BookingStatus.confirmed) ...[
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  icon: _isMarkingPacked
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                        )
                      : const Icon(Icons.local_shipping_rounded, size: 20),
                  label: Text(
                    _isMarkingPacked ? 'Scheduling Courier Pickup...' : 'Mark Packed & Request Hub Pickup',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentRose,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _isMarkingPacked ? null : _handleMarkPacked,
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'A verified courier will arrive at your atelier within 2-4 hours of packing.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.inkMuted),
                ),
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  String _getStatusSubtitle(BookingStatus status) {
    switch (status) {
      case BookingStatus.confirmed:
        return 'Please securely pack the outfit and tap "Mark Packed" below.';
      case BookingStatus.atHubPre:
        return 'Pickup scheduled. Outfit will be transported to the Wardrob Hub.';
      case BookingStatus.outForDelivery:
        return 'Outfit is currently on route to the customer for their event.';
      case BookingStatus.inUse:
        return 'Customer is currently wearing this outfit for their occasion.';
      case BookingStatus.returnedToHub:
        return 'Outfit safely arrived back at Hub. Undergoing return quality check.';
      case BookingStatus.completed:
        return 'Rental complete. Earnings credited to your Lister wallet.';
      case BookingStatus.cancelled:
        return 'This booking was cancelled. Item remains active in your wardrobe.';
      default:
        return 'Booking details and logistics are tracked in real-time.';
    }
  }

  Widget _buildSectionCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      width: double.infinity,
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.accentRose),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: AppColors.inkSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildScheduleRow({
    required String label,
    required String date,
    required String subtitle,
    required bool isHighlight,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w600,
                  color: isHighlight ? AppColors.accentRose : AppColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.inkMuted),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isHighlight ? const Color(0xFFFFF2F5) : AppColors.bgCream,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isHighlight ? AppColors.accentRose.withValues(alpha: 0.3) : AppColors.border,
            ),
          ),
          child: Text(
            date,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: isHighlight ? AppColors.accentRose : AppColors.ink,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialRow(String label, String value, {String? note, bool isMuted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: isMuted ? AppColors.inkMuted : AppColors.inkSecondary,
                ),
              ),
              if (note != null) ...[
                const SizedBox(height: 2),
                Text(
                  note,
                  style: GoogleFonts.inter(fontSize: 10.5, color: AppColors.inkMuted),
                ),
              ],
            ],
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isMuted ? AppColors.inkMuted : AppColors.ink,
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
