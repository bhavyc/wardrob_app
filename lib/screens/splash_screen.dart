import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import 'lister/lister_main_nav.dart';
import 'renter/renter_main_nav.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _frameFadeAnimation;
  late Animation<double> _crestScaleAnimation;
  late Animation<double> _crestFadeAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<double> _footerFadeAnimation;
  late Animation<double> _progressAnimation;
  bool _navigated = false;
  int _retryCount = 0;

  @override
  void initState() {
    super.initState();

    // Dark status bar icons for cream/ivory background
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _frameFadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.40, curve: Curves.easeOut),
    );

    _crestScaleAnimation = Tween<double>(begin: 0.84, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.10, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    _crestFadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.10, 0.60, curve: Curves.easeIn),
    );

    _textFadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 0.80, curve: Curves.easeOut),
    );

    _footerFadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.55, 0.95, curve: Curves.easeOut),
    );

    _progressAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.30, 1.0, curve: Curves.easeInOutCubic),
    );

    _controller.forward();

    _initiateNavigation();
  }

  void _initiateNavigation() {
    Timer(const Duration(milliseconds: 2500), () {
      _checkAndNavigate();
    });
  }

  void _checkAndNavigate() {
    if (!mounted || _navigated) return;

    final auth = ref.read(authProvider);

    // If still verifying on startup, retry up to 3 times (600ms)
    if (auth.isLoading && auth.user == null && _retryCount < 3) {
      _retryCount++;
      Timer(const Duration(milliseconds: 200), _checkAndNavigate);
      return;
    }

    _navigated = true;

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    final Widget destination =
        auth.isLister ? const ListerMainNav() : const RenterMainNav();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 700),
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            ),
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // ── 1. LUXURY EDITORIAL GRADIENT BASE ──
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFFFDFB), // Alabaster white-cream
                    Color(0xFFFAF6F0), // Ivory silk
                    Color(0xFFFFF2EC), // Subtle warm blush
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),

          // ── 2. AMBIENT WARM ROSE & GOLD LIGHTING BLOBS ──
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: size.width * 0.7,
              height: size.width * 0.7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accentRose.withValues(alpha: 0.07),
                    AppColors.accentRose.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -60,
            child: Container(
              width: size.width * 0.75,
              height: size.width * 0.75,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.gold.withValues(alpha: 0.08),
                    AppColors.gold.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          // ── 3. EDITORIAL INSET BORDER WITH LUXURY CORNER ACCENTS ──
          SafeArea(
            child: FadeTransition(
              opacity: _frameFadeAnimation,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.22),
                      width: 1.0,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Stack(
                    children: [
                      // Corner Diamond Ornaments
                      _buildCornerDiamond(top: 3, left: 3),
                      _buildCornerDiamond(top: 3, right: 3),
                      _buildCornerDiamond(bottom: 3, left: 3),
                      _buildCornerDiamond(bottom: 3, right: 3),

                      // Top Archival Tag
                      Positioned(
                        top: 14,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.gold.withValues(alpha: 0.25),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildMiniDiamond(AppColors.accentRose),
                                const SizedBox(width: 6),
                                Text(
                                  'EST. 2024 · ARCHIVE NO. 01',
                                  style: GoogleFonts.inter(
                                    fontSize: 8.0,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 2.0,
                                    color: AppColors.inkSecondary,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                _buildMiniDiamond(AppColors.accentRose),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── 4. CENTERPIECE: REGAL CREST & BRAND WORDMARK ──
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Monogram Medallion with Subtle Halo
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          return FadeTransition(
                            opacity: _crestFadeAnimation,
                            child: Transform.scale(
                              scale: _crestScaleAnimation.value,
                              child: child,
                            ),
                          );
                        },
                        child: _buildLuxuryCrest(),
                      ),

                      const SizedBox(height: 28),

                      // Brand Typography Block
                      FadeTransition(
                        opacity: _textFadeAnimation,
                        child: Column(
                          children: [
                            // Couture Eyebrow
                            Text(
                              'HAUTE ETHNIC ATELIER',
                              style: GoogleFonts.inter(
                                fontSize: 9.0,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 3.5,
                                color: AppColors.accentRose,
                              ),
                            ),

                            const SizedBox(height: 8),

                            // Main Brand Wordmark: WARDROB
                            Text(
                              'WARDROB',
                              style: GoogleFonts.cormorantGaramond(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 6.5,
                                color: AppColors.ink,
                                height: 1.05,
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Delicate Gold & Rose Hairline Divider
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 32,
                                  height: 0.8,
                                  color: AppColors.gold.withValues(alpha: 0.5),
                                ),
                                const SizedBox(width: 8),
                                Transform.rotate(
                                  angle: 0.785398, // 45 deg
                                  child: Container(
                                    width: 4.5,
                                    height: 4.5,
                                    decoration: BoxDecoration(
                                      color: AppColors.accentRose,
                                      borderRadius: BorderRadius.circular(0.5),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 32,
                                  height: 0.8,
                                  color: AppColors.gold.withValues(alpha: 0.5),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // Luxury Tagline
                            Text(
                              'CURATED DESIGNER RENTAL ARCHIVE',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 2.2,
                                color: AppColors.inkSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── 5. BOTTOM PROGRESS & ATELIER SIGNATURE ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 40,
            child: FadeTransition(
              opacity: _footerFadeAnimation,
              child: AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Smooth Luxury Hairline Progress Indicator
                      Container(
                        width: 96,
                        height: 2.0,
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.20),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            width: 96 * _progressAnimation.value.clamp(0.0, 1.0),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.gold,
                                  AppColors.accentRose,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(2),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accentRose.withValues(alpha: 0.35),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Curated Cities Footer
                      Text(
                        'AUTHENTICATED DESIGNER COUTURE',
                        style: GoogleFonts.inter(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.8,
                          color: AppColors.inkMuted,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        'PAN-INDIA LUXURY COUTURE',
                        style: GoogleFonts.inter(
                          fontSize: 7.5,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 2.0,
                          color: AppColors.gold.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── LUXURY MEDALLION CREST ──
  Widget _buildLuxuryCrest() {
    return Container(
      width: 78,
      height: 78,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: AppColors.accentRose.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Inner concentric delicate rose ring
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.accentRose.withValues(alpha: 0.20),
                width: 0.8,
              ),
            ),
          ),

          // Top miniature diamond on crest
          Positioned(
            top: 10,
            child: _buildMiniDiamond(AppColors.gold),
          ),

          // Central Serif Monogram 'W'
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              'W',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 38,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
                height: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCornerDiamond({double? top, double? bottom, double? left, double? right}) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Transform.rotate(
        angle: 0.785398,
        child: Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniDiamond(Color color) {
    return Transform.rotate(
      angle: 0.785398,
      child: Container(
        width: 3.5,
        height: 3.5,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(0.5),
        ),
      ),
    );
  }
}
