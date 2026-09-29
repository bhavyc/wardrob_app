import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/booking_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';
import 'my_orders_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = auth.user;

    if (!auth.isAuthenticated || user == null) {
      return _buildGuestView(context);
    }

    final bookingsAsync = ref.watch(renterBookingsProvider);
    final myBookings = bookingsAsync.value ?? [];
    final latestBooking = myBookings.isNotEmpty ? myBookings.first : null;

    return Scaffold(
      backgroundColor: AppColors.bgCream,
      appBar: AppBar(
        backgroundColor: AppColors.bgCream,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'My Wardrob',
          style: GoogleFonts.cormorantGaramond(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.ink),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined, size: 20, color: AppColors.ink),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.accentRose,
        onRefresh: () async {
          await ref.read(authProvider.notifier).checkCurrentSession();
          await ref.read(renterBookingsProvider.notifier).fetchBookings();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. USER PROFILE CARD (CLEAN MEMBER STATUS) ────────────────
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFEDE8E1), width: 0.8),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E1E2D).withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: AppColors.accentRose.withValues(alpha: 0.12),
                      child: Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : 'W',
                        style: GoogleFonts.cormorantGaramond(
                          color: AppColors.accentRose,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: GoogleFonts.cormorantGaramond(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user.email,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.inkMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          // Clean Haute Member Badge (No KYC for renter)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAF7F2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFEDE7DF), width: 0.8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.verified_rounded, size: 11, color: AppColors.gold),
                                const SizedBox(width: 4),
                                Text(
                                  'HAUTE ARCHIVE MEMBER',
                                  style: GoogleFonts.inter(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.7,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── 2. WALLET BALANCE CARD (NO OVERFLOW) ────────────────────────
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.ink, Color(0xFF2E2E42)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.ink.withValues(alpha: 0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'WARDROB WALLET BALANCE',
                            style: GoogleFonts.inter(
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                              color: AppColors.gold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '₹${user.walletBalance.toInt()}',
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Available for instant rental checkout',
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              color: Colors.white70,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_outlined,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── 3. DEDICATED ORDERS SECTION CARD ──────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'MY ORDERS',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: AppColors.inkMuted,
                    ),
                  ),
                  if (myBookings.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
                        );
                      },
                      child: Text(
                        'SEE ALL (${myBookings.length}) →',
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: AppColors.accentRose,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),

              // Orders Navigation Action Card
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
                  );
                },
                child: Container(
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
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.bgCream,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFEDE7DF), width: 0.8),
                        ),
                        child: const Icon(
                          Icons.inventory_2_outlined,
                          color: AppColors.ink,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rental Orders & Bookings',
                              style: GoogleFonts.cormorantGaramond(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              myBookings.isNotEmpty
                                  ? '${myBookings.length} orders · Tap to view tracking & details'
                                  : 'No active orders · Reserve your first outfit',
                              style: GoogleFonts.inter(
                                fontSize: 10.5,
                                color: AppColors.inkMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.ink,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'VIEW',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 3),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 11,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Recent Order Highlight (Only 1 item snippet if exists)
              if (latestBooking != null) ...[
                const SizedBox(height: 12),
                _buildLatestOrderSnippet(context, latestBooking),
              ],

              const SizedBox(height: 24),

              // ── 4. QUICK CONCIERGE & ACCOUNT TILES ────────────────────────
              Text(
                'PREFERENCES & ASSISTANCE',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: AppColors.inkMuted,
                ),
              ),
              const SizedBox(height: 10),

              _buildProfileOptionTile(
                icon: Icons.security_rounded,
                title: 'Refundable Security Deposit Policy',
                subtitle: 'Auto-credited to source within 24 hours of return',
                onTap: () => _showDepositPolicy(context),
              ),

              const SizedBox(height: 24),

              // ── 5. PRIVACY & ACCOUNT SETTINGS (APP STORE COMPLIANCE) ─────
              Text(
                'ACCOUNT & DATA PRIVACY',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: AppColors.inkMuted,
                ),
              ),
              const SizedBox(height: 10),

              _buildProfileOptionTile(
                icon: Icons.delete_outline_rounded,
                title: 'Delete Account',
                subtitle: 'Permanently remove your account & identity data',
                isDestructive: true,
                onTap: () => _showDeleteAccountDialog(context, ref),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLatestOrderSnippet(BuildContext context, BookingModel b) {
    final itemTitle = b.listing?.title ??
        (b.id == 'bk_1' ? 'Crimson Velvet Bridal Lehenga' : 'Heritage Banarasi Katan Silk Saree');
    final itemImage = (b.listing != null && b.listing!.baselineImages.isNotEmpty)
        ? b.listing!.baselineImages.first
        : null;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFAF7F2),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEDE7DF), width: 0.8),
        ),
        child: Row(
          children: [
            if (itemImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  itemImage,
                  width: 38,
                  height: 46,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                ),
              )
            else
              Container(
                width: 38,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.checkroom, color: AppColors.inkMuted, size: 20),
              ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'LATEST: ',
                        style: GoogleFonts.inter(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: AppColors.accentRose,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          itemTitle,
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${DateFormat('d MMM').format(b.startDate)} - ${DateFormat('d MMM yyyy').format(b.endDate)} · ${b.status.toDisplayString()}',
                    style: GoogleFonts.inter(fontSize: 10, color: AppColors.inkMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.inkMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDestructive ? const Color(0xFFFCA5A5) : const Color(0xFFEDE8E1),
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDestructive ? const Color(0xFFFEF2F2) : AppColors.bgCream,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isDestructive ? const Color(0xFFDC2626) : AppColors.ink,
                size: 18,
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
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDestructive ? const Color(0xFFDC2626) : AppColors.ink,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 9.5,
                      color: isDestructive ? const Color(0xFFEF4444) : AppColors.inkMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: isDestructive ? const Color(0xFFFCA5A5) : const Color(0xFFCBD5E1),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFFEF2F2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Delete Account?',
                style: GoogleFonts.cormorantGaramond(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.ink),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This action is irreversible. All your profile information, saved addresses, and archives will be permanently erased.',
              style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF4A4A58), height: 1.5),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDE68A), width: 0.8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFD97706)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Active rentals or unreturned outfits must be completed first.',
                      style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF92400E)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.inkSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Processing account deletion...'),
                  duration: Duration(seconds: 2),
                ),
              );
              final res = await ref.read(authProvider.notifier).deleteAccount();
              if (res['success'] == true) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(res['message'] ?? 'Account successfully deleted.'),
                      backgroundColor: const Color(0xFF059669),
                    ),
                  );
                }
              } else {
                if (context.mounted) {
                  showDialog(
                    context: context,
                    builder: (errCtx) => AlertDialog(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      title: Text(
                        'Cannot Delete Account',
                        style: GoogleFonts.cormorantGaramond(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFFDC2626)),
                      ),
                      content: Text(
                        res['error'] ?? 'Active bookings or unreturned items found.',
                        style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF4A4A58), height: 1.45),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(errCtx).pop(),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                }
              }
            },
            child: Text(
              'Yes, Delete',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }


  void _showDepositPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.security_rounded, color: AppColors.accentRose, size: 22),
            const SizedBox(width: 8),
            Text(
              'Caution Deposit Policy',
              style: GoogleFonts.cormorantGaramond(fontSize: 19, fontWeight: FontWeight.w700, color: AppColors.ink),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'The security deposit is 100% refundable. Once our logistics team picks up the returned garment and passes quality verification at the hub, the deposit is instantly credited back to your original payment method or wallet.',
              style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.inkSecondary, height: 1.3),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('UNDERSTOOD', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.ink)),
          ),
        ],
      ),
    );
  }

  // ── LUXURY MINIMALIST GUEST EXPERIENCE ─────────────────────────────────────
  Widget _buildGuestView(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF7F2),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          'ACCOUNT',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.5,
            color: AppColors.ink,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Minimalist Luxury Monogram
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: const Color(0xFFEBE5DF),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.ink.withValues(alpha: 0.05),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'W',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Title
              Text(
                'Welcome to Wardrob',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 10),

              // Single clean line
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Sign in to access your digital wallet, active rentals, and personal wardrobe.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.inkSecondary,
                    height: 1.5,
                  ),
                ),
              ),

              const Spacer(flex: 3),

              // Primary: Sign In
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ink,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  child: Text(
                    'SIGN IN',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Secondary: Create Account
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.ink,
                    side: const BorderSide(color: AppColors.ink, width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    );
                  },
                  child: Text(
                    'CREATE ACCOUNT',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
              ),

              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}
