import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import 'brand_logo.dart';
import '../../providers/auth_provider.dart';
import '../../screens/renter/profile_screen.dart';
import '../../screens/renter/my_orders_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/lister/lister_main_nav.dart';

class LuxuryDrawer extends ConsumerWidget {
  const LuxuryDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final topPadding = MediaQuery.of(context).padding.top;
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Drawer(
      width: (screenWidth * 0.84).clamp(290.0, 360.0),
      backgroundColor: AppColors.bgCream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // ── 1. HAUTE EDITORIAL HEADER ─────────────────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(20, topPadding + 14, 14, 20),
            decoration: const BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.only(topRight: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Brand Logo & Close Icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const BrandLogoWidget(
                      size: LogoSize.sm,
                      color: Colors.white,
                      accentColor: AppColors.goldLight,
                      showSubtitle: true,
                      subtitle: 'HAUTE ETHNIC ARCHIVE',
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // User Profile Box or Sign In Prompt
                if (auth.isAuthenticated && user != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.accentRose,
                          child: Text(
                            (user.name.isNotEmpty ? user.name[0] : 'W').toUpperCase(),
                            style: GoogleFonts.cormorantGaramond(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name,
                                style: GoogleFonts.cormorantGaramond(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 1),
                              Text(
                                (user.phone != null && user.phone!.isNotEmpty)
                                    ? user.phone!
                                    : user.email,
                                style: GoogleFonts.inter(
                                  color: Colors.white60,
                                  fontSize: 10.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.gold.withValues(alpha: 0.5),
                              width: 0.6,
                            ),
                          ),
                          child: Text(
                            'MEMBER',
                            style: GoogleFonts.inter(
                              fontSize: 7.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: AppColors.goldLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Text(
                    'Welcome to Wardrob',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'India\'s most coveted couture archives, on rent.',
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      color: Colors.white60,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        color: AppColors.accentRose,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentRose.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.login_rounded, size: 15, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            'SIGN IN / REGISTER',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── 2. SCROLLABLE SERVICES & ACCOUNT NAVIGATION ───────────────────
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(14, 16, 14, MediaQuery.paddingOf(context).bottom + 24),
              physics: const BouncingScrollPhysics(),
              children: [
                // SECTION: MY WARDROB
                _buildSectionHeader('MY WARDROB'),

                _buildDrawerTile(
                  icon: Icons.inventory_2_outlined,
                  title: 'My Bookings & Rentals',
                  subtitle: 'Live rentals, dates & return status',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
                    );
                  },
                ),

                _buildDrawerTile(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Security Deposit & Wallet',
                  subtitle: '100% refundable caution deposit',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    );
                  },
                ),

                const SizedBox(height: 12),
                const Divider(color: Color(0xFFEDE8E1), height: 1),
                const SizedBox(height: 12),

                // SECTION: LISTER PORTAL (Only shown if logged in user is a Lister)
                if (auth.isLister) ...[
                  _buildSectionHeader('LISTER PORTAL'),
                  _buildListerBannerTile(
                    context: context,
                    isLister: true,
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ListerMainNav()),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Color(0xFFEDE8E1), height: 1),
                  const SizedBox(height: 12),
                ],

                // SECTION: CONCIERGE & TRUST
                _buildSectionHeader('CONCIERGE & TRUST'),

                _buildDrawerTile(
                  icon: Icons.verified_user_outlined,
                  title: 'The Wardrob Guarantee',
                  subtitle: 'UV sanitized, insured doorstep delivery',
                  onTap: () {
                    Navigator.of(context).pop();
                    _showGuaranteeDialog(context);
                  },
                ),

                _buildDrawerTile(
                  icon: Icons.help_outline_rounded,
                  title: 'How Renting Works',
                  subtitle: 'Book, flaunt, return in 4 easy steps',
                  onTap: () {
                    Navigator.of(context).pop();
                    _showHowItWorksModal(context);
                  },
                ),

                // SECTION: LOGOUT (if authenticated)
                if (auth.isAuthenticated) ...[
                  const SizedBox(height: 12),
                  const Divider(color: Color(0xFFEDE8E1), height: 1),
                  const SizedBox(height: 12),
                  _buildDrawerTile(
                    icon: Icons.logout_rounded,
                    title: 'Sign Out',
                    subtitle: 'Securely exit current session',
                    isDestructive: true,
                    onTap: () async {
                      Navigator.of(context).pop();
                      await ref.read(authProvider.notifier).logout();
                    },
                  ),
                ],
              ],
            ),
          ),

          // ── 3. FOOTER ─────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFEDE8E1), width: 0.8)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'WARDROB ARCHIVE',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      color: AppColors.inkSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  'v1.0.0 · HAUTE ETHNIC',
                  style: GoogleFonts.inter(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 8.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: AppColors.inkMuted,
        ),
      ),
    );
  }

  Widget _buildDrawerTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDestructive
                    ? const Color(0xFFFEE2E2)
                    : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDestructive
                      ? const Color(0xFFFECACA)
                      : const Color(0xFFEDE8E1),
                  width: 0.8,
                ),
              ),
              child: Icon(
                icon,
                size: 17,
                color: isDestructive ? const Color(0xFFDC2626) : AppColors.ink,
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
                  const SizedBox(height: 1.5),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w400,
                      color: AppColors.inkMuted,
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
              color: isDestructive ? const Color(0xFFDC2626) : const Color(0xFFCBD5E1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListerBannerTile({
    required BuildContext context,
    required bool isLister,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5DECE), width: 0.9),
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
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.storefront_rounded,
                color: AppColors.goldLight,
                size: 20,
              ),
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
                          isLister ? 'Lister Dashboard' : 'Rent Out Your Closet',
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: AppColors.accentRose,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isLister ? 'ACTIVE' : 'EARN',
                          style: GoogleFonts.inter(
                            fontSize: 7.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isLister ? 'Manage listings & payouts' : 'Earn up to ₹40k/month safely',
                    style: GoogleFonts.inter(
                      fontSize: 9.5,
                      color: AppColors.inkMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 12,
              color: AppColors.ink,
            ),
          ],
        ),
      ),
    );
  }


  void _showGuaranteeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.verified_user_rounded, color: AppColors.accentRose, size: 22),
            const SizedBox(width: 10),
            Text(
              'The Wardrob Promise',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDialogBullet('100% Medical-grade dry cleaned & UV sanitized'),
            const SizedBox(height: 8),
            _buildDialogBullet('Zero stain liability — accidental wear fully insured'),
            const SizedBox(height: 8),
            _buildDialogBullet('Doorstep pickup & drop across supported pin codes'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'CLOSE',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }

  void _showHowItWorksModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDD7CC),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'How Renting Works',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 14),
            _buildStepRow('1', 'Choose Your Outfit', 'Select dates for your wedding, reception or party.'),
            const SizedBox(height: 10),
            _buildStepRow('2', 'Doorstep Delivery', 'Delivered pristine, pressed & custom altered 1 day before.'),
            const SizedBox(height: 10),
            _buildStepRow('3', 'Flaunt & Celebrate', 'Wear the archive couture and make memories.'),
            const SizedBox(height: 10),
            _buildStepRow('4', 'Effortless Return', 'Pickup from your doorstep. We take care of dry cleaning.'),
          ],
        ),
      ),
    );
  }

  Widget _buildStepRow(String num, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: AppColors.ink,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              num,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
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
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 1.5),
              Text(
                desc,
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  color: AppColors.inkSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDialogBullet(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Icon(Icons.circle, size: 5, color: AppColors.accentRose),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              color: AppColors.inkSecondary,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }
}
