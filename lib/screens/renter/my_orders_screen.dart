import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../models/booking_model.dart';
import '../../providers/booking_provider.dart';

class MyOrdersScreen extends ConsumerStatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  ConsumerState<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends ConsumerState<MyOrdersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(renterBookingsProvider);
    final allBookings = bookingsAsync.value ?? [];

    final filteredBookings = allBookings.where((b) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      final title = (b.listing?.title ?? '').toLowerCase();
      final id = b.id.toLowerCase();
      final status = b.status.toDisplayString().toLowerCase();
      return title.contains(query) || id.contains(query) || status.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.bgCream,
      appBar: AppBar(
        backgroundColor: AppColors.bgCream,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.ink, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'My Rental Orders',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        centerTitle: true,
        actions: [
          if (allBookings.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${allBookings.length} ORDERS',
                    style: GoogleFonts.inter(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: AppColors.goldLight,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.accentRose,
        onRefresh: () async {
          await ref.read(renterBookingsProvider.notifier).fetchBookings();
        },
        child: Column(
          children: [
            // ── Search Bar ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEDE8E1), width: 0.8),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E1E2D).withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.ink),
                  decoration: InputDecoration(
                    hintText: 'Search by outfit name, order ID, or status...',
                    hintStyle: GoogleFonts.inter(fontSize: 11.5, color: AppColors.inkMuted),
                    prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.inkMuted),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 16, color: AppColors.inkMuted),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),

            // Search query summary if filtering
            if (_searchQuery.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
                child: Row(
                  children: [
                    Text(
                      'Found ${filteredBookings.length} matching order${filteredBookings.length == 1 ? '' : 's'}',
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.inkSecondary,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                      child: Text(
                        'Clear filter',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accentRose,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ── Orders List ─────────────────────────────────────────────
            Expanded(
              child: filteredBookings.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Icon(
                                _searchQuery.isNotEmpty
                                    ? Icons.search_off_rounded
                                    : Icons.shopping_bag_outlined,
                                size: 36,
                                color: AppColors.inkMuted,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No Matching Orders'
                                  : 'No Rental Orders Yet',
                              style: GoogleFonts.cormorantGaramond(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'Try searching with another keyword or outfit name.'
                                  : 'Explore our Haute Couture archive and reserve your 4-day designer outfit.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.inkSecondary),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
                      itemCount: filteredBookings.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (context, i) {
                        final b = filteredBookings[i];
                        return _buildOrderCard(context, b);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, BookingModel b) {
    final itemTitle = b.listing?.title ??
        (b.id == 'bk_1' ? 'Crimson Velvet Bridal Lehenga' : 'Heritage Banarasi Katan Silk Saree');
    final itemImage = (b.listing != null && b.listing!.baselineImages.isNotEmpty)
        ? b.listing!.baselineImages.first
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDE8E1), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E1E2D).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order ID & Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'ORDER #${b.id.toUpperCase()}',
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.accentRose,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _buildStatusPill(b.status),
            ],
          ),
          const SizedBox(height: 12),

          // Outfit details
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (itemImage != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    itemImage,
                    width: 52,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 52,
                      height: 64,
                      color: const Color(0xFFF7F5F0),
                      child: const Icon(Icons.checkroom, color: AppColors.inkMuted, size: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      itemTitle,
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                        height: 1.15,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.inkMuted),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            '${DateFormat('d MMM').format(b.startDate)} - ${DateFormat('d MMM yyyy').format(b.endDate)}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.inkSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(color: Color(0xFFF1EDE6), height: 20),

          // Price & Deposit summary (Protected against overflow)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  b.extensionFee > 0
                      ? 'Rent: ₹${b.rentAmount.toInt()} (incl. ₹${b.extensionFee.toInt()} Ext)'
                      : 'Rent: ₹${b.rentAmount.toInt()}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Deposit: ₹${b.securityDeposit.toInt()} (Refundable)',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.inkMuted,
                  ),
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          // Live Shipment Tracking Card (Fixed overflow)
          if (b.shipmentTracking != null || b.shipmentStatus != null) ...[
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4F8),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFD0DCE5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_shipping_outlined, size: 16, color: Color(0xFF1565C0)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _formatShipmentLeg(b.shipmentLeg),
                                style: AppTypography.subtitleTag.copyWith(fontSize: 8, color: const Color(0xFF1565C0)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                b.shipmentStatus?.replaceAll('_', ' ').toUpperCase() ?? 'IN TRANSIT',
                                style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF1565C0)),
                              ),
                            ),
                          ],
                        ),
                        if (b.shipmentTracking != null && b.shipmentTracking!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Tracking AWB: ${b.shipmentTracking}',
                            style: AppTypography.bodySmall.copyWith(fontSize: 10, color: AppColors.inkSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Deposit Refund Card (Protected against overflow)
          if (b.refundStatus != null) ...[
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFC8E6C9)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_outlined, size: 16, color: Color(0xFF2E7D32)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'DEPOSIT REFUND',
                                style: AppTypography.subtitleTag.copyWith(fontSize: 8, color: const Color(0xFF2E7D32)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              b.refundStatus?.toUpperCase() ?? 'PROCESSED',
                              style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '₹${(b.refundAmount ?? b.securityDeposit).toInt()} refunded to source / wallet',
                          style: AppTypography.bodySmall.copyWith(fontSize: 10, color: const Color(0xFF1B5E20)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatShipmentLeg(String? leg) {
    switch (leg) {
      case 'LISTER_TO_HUB':
        return 'LISTER → CENTRAL HUB';
      case 'HUB_TO_RENTER':
        return 'CENTRAL HUB → YOUR DOORSTEP';
      case 'RENTER_TO_HUB':
        return 'RETURN PICKUP → CENTRAL HUB';
      case 'HUB_TO_LISTER':
        return 'CENTRAL HUB → LISTER RETURN';
      default:
        return 'LIVE LOGISTICS SHIPMENT';
    }
  }

  Widget _buildStatusPill(BookingStatus status) {
    Color bg;
    Color fg;

    switch (status) {
      case BookingStatus.confirmed:
        bg = const Color(0xFFE8F5E9);
        fg = const Color(0xFF2E7D32);
        break;
      case BookingStatus.completed:
        bg = AppColors.bgCream;
        fg = AppColors.ink;
        break;
      case BookingStatus.outForDelivery:
      case BookingStatus.inUse:
        bg = const Color(0xFFE3F2FD);
        fg = const Color(0xFF1565C0);
        break;
      case BookingStatus.atHubPre:
      case BookingStatus.returnedToHub:
        bg = const Color(0xFFFFF3E0);
        fg = const Color(0xFFE65100);
        break;
      case BookingStatus.cancelled:
      case BookingStatus.lostNotReturned:
        bg = const Color(0xFFFFEBEE);
        fg = const Color(0xFFC62828);
        break;
      case BookingStatus.pending:
        bg = const Color(0xFFFFFDE7);
        fg = const Color(0xFFF57F17);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.toDisplayString().toUpperCase(),
        style: AppTypography.subtitleTag.copyWith(color: fg, fontSize: 8),
      ),
    );
  }
}
