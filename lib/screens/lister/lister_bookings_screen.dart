import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/booking_model.dart';
import '../../providers/booking_provider.dart';
import 'lister_order_detail_screen.dart';

class ListerBookingsScreen extends ConsumerStatefulWidget {
  const ListerBookingsScreen({super.key});

  @override
  ConsumerState<ListerBookingsScreen> createState() => _ListerBookingsScreenState();
}

class _ListerBookingsScreenState extends ConsumerState<ListerBookingsScreen> {
  String _selectedFilter = 'ALL';
  String? _updatingBookingId;

  Future<void> _handleMarkPacked(String bookingId) async {
    setState(() => _updatingBookingId = bookingId);
    final res = await ref.read(listerBookingsProvider.notifier).markPacked(bookingId);
    setState(() => _updatingBookingId = null);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? res['error'] ?? 'Action completed.'),
          backgroundColor: res['success'] == true ? const Color(0xFF166534) : Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(listerBookingsProvider);
    final listerOrders = bookingsAsync.value ?? [];

    final totalCount = listerOrders.length;
    final confirmedCount = listerOrders.where((b) => b.status == BookingStatus.confirmed).length;
    final inUseCount = listerOrders.where((b) => b.status == BookingStatus.inUse).length;
    final completedCount = listerOrders.where((b) => b.status == BookingStatus.completed).length;

    final filteredOrders = listerOrders.where((b) {
      if (_selectedFilter == 'TO_DISPATCH') return b.status == BookingStatus.confirmed;
      if (_selectedFilter == 'IN_USE') return b.status == BookingStatus.inUse;
      if (_selectedFilter == 'COMPLETED') return b.status == BookingStatus.completed;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.bgCream,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Orders & Bookings',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.inkSecondary),
            onPressed: () => ref.read(listerBookingsProvider.notifier).fetchBookings(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.accentRose,
        onRefresh: () => ref.read(listerBookingsProvider.notifier).fetchBookings(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('ALL', 'All ($totalCount)'),
                    const SizedBox(width: 8),
                    _buildFilterChip('TO_DISPATCH', 'To Dispatch ($confirmedCount)'),
                    const SizedBox(width: 8),
                    _buildFilterChip('IN_USE', 'In Use ($inUseCount)'),
                    const SizedBox(width: 8),
                    _buildFilterChip('COMPLETED', 'Completed ($completedCount)'),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              bookingsAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: AppColors.accentRose),
                  ),
                ),
                error: (e, _) => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text('Error loading orders: $e', style: GoogleFonts.inter(color: Colors.red)),
                ),
                data: (_) {
                  if (filteredOrders.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.receipt_long_outlined, size: 48, color: Color(0xFFCBD5E1)),
                          const SizedBox(height: 12),
                          Text(
                            'No bookings found',
                            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedFilter == 'ALL'
                                ? 'When customers rent your outfits, bookings will show up here.'
                                : 'No orders currently in this status.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkMuted),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredOrders.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (ctx, index) => _buildOrderCard(filteredOrders[index]),
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

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? Colors.white : AppColors.inkSecondary,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.accentRose,
      backgroundColor: Colors.white,
      side: BorderSide(color: isSelected ? AppColors.accentRose : AppColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onSelected: (_) => setState(() => _selectedFilter = value),
    );
  }

  Widget _buildOrderCard(BookingModel order) {
    final outfit = order.listing;
    final image = outfit?.baselineImages.isNotEmpty == true
        ? outfit!.baselineImages.first
        : null;
    final title = outfit?.title ?? 'Designer Ethnic Outfit';
    final dateFmt = DateFormat('dd MMM yyyy');
    final startDate = dateFmt.format(order.startDate);
    final endDate = dateFmt.format(order.endDate);
    final isUpdating = _updatingBookingId == order.id;

    String statusText;
    Color statusBg;
    Color statusColor;

    switch (order.status) {
      case BookingStatus.confirmed:
        statusText = 'Ready to Pack';
        statusBg = const Color(0xFFFEF3C7);
        statusColor = const Color(0xFFB45309);
        break;
      case BookingStatus.inUse:
        statusText = 'In Use by Renter';
        statusBg = const Color(0xFFEFF6FF);
        statusColor = const Color(0xFF1D4ED8);
        break;
      case BookingStatus.completed:
        statusText = 'Completed & Returned';
        statusBg = const Color(0xFFDCFCE7);
        statusColor = const Color(0xFF166534);
        break;
      case BookingStatus.cancelled:
        statusText = 'Cancelled';
        statusBg = const Color(0xFFFEE2E2);
        statusColor = const Color(0xFF991B1B);
        break;
      default:
        statusText = order.status.name;
        statusBg = const Color(0xFFF1F5F9);
        statusColor = const Color(0xFF475569);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ListerOrderDetailScreen(order: order),
            ),
          );
        },
        child: Container(
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
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 64,
                      height: 64,
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusBg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                statusText,
                                style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w600, color: statusColor),
                              ),
                            ),
                            Text(
                              '₹${order.rentAmount.toInt()}',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF16A34A),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          title,
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Rental: $startDate - $endDate',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),
              const Divider(height: 1, color: AppColors.borderLight),
              const SizedBox(height: 8),

              // Tap cue row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #${order.id.length > 8 ? order.id.substring(0, 8).toUpperCase() : order.id}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.inkMuted,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View Full Details',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accentRose,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 11,
                        color: AppColors.accentRose,
                      ),
                    ],
                  ),
                ],
              ),

              if (order.status == BookingStatus.confirmed) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton.icon(
                    icon: isUpdating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.local_shipping_outlined, size: 18),
                    label: Text(
                      isUpdating ? 'Scheduling Courier...' : 'Mark Packed & Request Pickup',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentRose,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: isUpdating ? null : () => _handleMarkPacked(order.id),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
