import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import 'lister_bookings_screen.dart';
import 'lister_dashboard_screen.dart';
import 'lister_kyc_screen.dart';
import 'lister_listings_screen.dart';
import 'lister_payouts_screen.dart';

final listerNavIndexProvider = StateProvider<int>((ref) => 0);

class ListerMainNav extends ConsumerWidget {
  const ListerMainNav({super.key});

  static const _screens = [
    ListerDashboardScreen(),
    ListerListingsScreen(),
    ListerBookingsScreen(),
    ListerPayoutsScreen(),
    ListerKycScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(listerNavIndexProvider);

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildFloatingCapsuleNavBar(context, ref, currentIndex),
    );
  }

  Widget _buildFloatingCapsuleNavBar(
      BuildContext context, WidgetRef ref, int currentIndex) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        height: 66,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(38),
          border: Border.all(
            color: const Color(0xFFEBE6DF),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 6),
              spreadRadius: 1,
            ),
            BoxShadow(
              color: AppColors.ink.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
        child: Row(
          children: [
            _buildNavItem(ref, currentIndex, 0, 'Home', Icons.home_outlined, Icons.home_rounded),
            _buildNavItem(ref, currentIndex, 1, 'Wardrobe', Icons.checkroom_outlined, Icons.checkroom),
            _buildNavItem(ref, currentIndex, 2, 'Orders', Icons.receipt_long_outlined, Icons.receipt_long),
            _buildNavItem(ref, currentIndex, 3, 'Earnings', Icons.account_balance_wallet_outlined, Icons.account_balance_wallet),
            _buildNavItem(ref, currentIndex, 4, 'KYC', Icons.verified_user_outlined, Icons.verified_user),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    WidgetRef ref,
    int currentIndex,
    int index,
    String label,
    IconData icon,
    IconData activeIcon,
  ) {
    final isSelected = currentIndex == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (currentIndex != index) {
            ref.read(listerNavIndexProvider.notifier).state = index;
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: isSelected
              ? BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: const Color(0xFFEAE4DC),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                    BoxShadow(
                      color: AppColors.accentRose.withValues(alpha: 0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                  ],
                )
              : const BoxDecoration(
                  color: Colors.transparent,
                ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                size: isSelected ? 21 : 20,
                color: isSelected ? AppColors.accentRose : const Color(0xFF2B2B2B),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.accentRose : const Color(0xFF555555),
                  letterSpacing: 0.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
