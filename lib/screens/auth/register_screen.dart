import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/brand_logo.dart';
import '../../providers/auth_provider.dart';
import '../lister/lister_main_nav.dart';
import '../renter/renter_main_nav.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  final bool initialAsLister;
  const RegisterScreen({super.key, this.initialAsLister = false});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Shared Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  // Renter specific
  final _confirmPasswordController = TextEditingController();
  final _aadhaarController = TextEditingController();
  final _panController = TextEditingController();

  // Lister specific
  final _shopNameController = TextEditingController();
  final _bioController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _localError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialAsLister ? 1 : 0,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref.read(authProvider.notifier).clearError();
        setState(() {
          _localError = null;
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).clearError();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _aadhaarController.dispose();
    _panController.dispose();
    _shopNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _localError = null);
    final isLister = _tabController.index == 1;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim().toLowerCase();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    // Common validations
    if (name.length < 2) {
      setState(() => _localError = 'Please enter your full name (at least 2 characters).');
      return;
    }
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(email)) {
      setState(() => _localError = 'Please enter a valid email address.');
      return;
    }
    final phoneRegex = RegExp(r'^[6-9]\d{9}$');
    if (!phoneRegex.hasMatch(phone)) {
      setState(() => _localError = 'Please enter a valid 10-digit Indian mobile number.');
      return;
    }

    if (isLister) {
      // Lister validations
      if (password.length < 6) {
        setState(() => _localError = 'Password must be at least 6 characters.');
        return;
      }
      final shopName = _shopNameController.text.trim();
      final bio = _bioController.text.trim();

      if (shopName.isEmpty) {
        setState(() => _localError = 'Boutique / Atelier Name is required.');
        return;
      }
      if (bio.length < 20) {
        setState(() => _localError = 'Please describe your designer story (min 20 characters).');
        return;
      }

      final success = await ref.read(authProvider.notifier).registerLister(
        name: name,
        email: email,
        phone: phone,
        password: password,
        shopName: shopName,
        bio: bio,
      );

      if (success && mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const ListerMainNav()),
          (route) => false,
        );
      }
    } else {
      // Renter validations
      if (password.length < 8) {
        setState(() => _localError = 'Password must be at least 8 characters long.');
        return;
      }
      final confirmPassword = _confirmPasswordController.text;
      if (password != confirmPassword) {
        setState(() => _localError = 'Passwords do not match.');
        return;
      }

      final aadhaar = _aadhaarController.text.trim();
      if (aadhaar.length != 12) {
        setState(() => _localError = 'Aadhaar number must be exactly 12 digits.');
        return;
      }

      final pan = _panController.text.trim().toUpperCase();
      if (pan.length != 10) {
        setState(() => _localError = 'PAN number must be exactly 10 characters.');
        return;
      }

      final success = await ref.read(authProvider.notifier).registerRenter(
        name: name,
        email: email,
        phone: phone,
        password: password,
        confirmPassword: confirmPassword,
        aadhaarNumber: aadhaar,
        panNumber: pan,
      );

      if (success && mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const RenterMainNav()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final isLister = _tabController.index == 1;
    final activeError = _localError ?? auth.error;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      body: Stack(
        children: [
          // Ambient Luxury Gradient Ornaments
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accentRose.withValues(alpha: 0.08),
                    AppColors.accentRose.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFC5A880).withValues(alpha: 0.09),
                    const Color(0xFFC5A880).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top Navigation Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFEBE4DA)),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.ink.withValues(alpha: 0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.arrow_back_rounded, size: 18, color: AppColors.ink),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF2F5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.accentRose.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified_user_outlined, size: 11, color: AppColors.accentRose),
                            const SizedBox(width: 4),
                            Text(
                              'VERIFIED MEMBERSHIP',
                              style: GoogleFonts.inter(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: AppColors.accentRose,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 6),

                        // Brand Logo
                        const BrandLogoWidget(
                          size: LogoSize.lg,
                          showSubtitle: true,
                          subtitle: 'THE LUXURY ETHNIC RENTAL VAULT',
                        ),
                        const SizedBox(height: 6),

                        // Subtitle
                        Text(
                          isLister ? 'Open Your Designer Atelier on Wardrob' : 'Join the Exclusive Haute Couture Circle',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 16.5,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w600,
                            color: AppColors.inkSecondary,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Main Form Card Container
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(color: const Color(0xFFEDE5DA), width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1E1E2D).withValues(alpha: 0.05),
                                blurRadius: 28,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Role Switcher Tabs
                              Container(
                                height: 46,
                                padding: const EdgeInsets.all(3.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3EFE9),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: const Color(0xFFE8E2D8), width: 1),
                                ),
                                child: TabBar(
                                  controller: _tabController,
                                  dividerColor: Colors.transparent,
                                  indicatorSize: TabBarIndicatorSize.tab,
                                  indicator: BoxDecoration(
                                    color: const Color(0xFF1B1722),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF1B1722).withValues(alpha: 0.25),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  labelColor: Colors.white,
                                  unselectedLabelColor: AppColors.inkSecondary,
                                  labelStyle: GoogleFonts.inter(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.4,
                                  ),
                                  unselectedLabelStyle: GoogleFonts.inter(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.3,
                                  ),
                                  tabs: const [
                                    Tab(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text('✨ '),
                                            Text('REGISTER RENTER'),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Tab(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text('💎 '),
                                            Text('REGISTER LISTER'),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Error Banner if present
                              if (activeError != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF0F2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFFFCCD3)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.error_outline_rounded, color: Color(0xFFC53030), size: 16),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          activeError,
                                          style: GoogleFonts.inter(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w500,
                                            color: const Color(0xFFC53030),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 14),
                              ],

                              // Form Fields
                              _buildInputField(
                                label: isLister ? 'DESIGNER / OWNER NAME' : 'FULL NAME',
                                hint: isLister ? 'Enter boutique or designer name' : 'Enter your full name',
                                icon: Icons.person_outline_rounded,
                                controller: _nameController,
                              ),
                              const SizedBox(height: 12),

                              _buildInputField(
                                label: 'EMAIL ADDRESS',
                                hint: 'Enter your email address',
                                icon: Icons.alternate_email_rounded,
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 12),

                              _buildInputField(
                                label: 'MOBILE NUMBER (10 DIGITS)',
                                hint: 'Enter 10-digit mobile number',
                                icon: Icons.phone_iphone_rounded,
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(10),
                                ],
                              ),
                              const SizedBox(height: 12),

                              _buildInputField(
                                label: 'PASSWORD (MIN 8 CHARS)',
                                hint: '••••••••',
                                icon: Icons.lock_outline_rounded,
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    color: AppColors.inkMuted,
                                    size: 19,
                                  ),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Specific fields based on mode
                              if (!isLister) ...[
                                _buildInputField(
                                  label: 'CONFIRM PASSWORD',
                                  hint: '••••••••',
                                  icon: Icons.lock_clock_outlined,
                                  controller: _confirmPasswordController,
                                  obscureText: _obscureConfirmPassword,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                      color: AppColors.inkMuted,
                                      size: 19,
                                    ),
                                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Aadhaar Card Field
                                _buildInputField(
                                  label: 'AADHAAR CARD NUMBER (12 DIGITS)',
                                  hint: 'Enter 12-digit Aadhaar number',
                                  icon: Icons.badge_outlined,
                                  controller: _aadhaarController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(12),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // PAN Card Field
                                _buildInputField(
                                  label: 'PAN CARD NUMBER (10 CHARACTERS)',
                                  hint: 'Enter 10-character PAN number',
                                  icon: Icons.credit_card_rounded,
                                  controller: _panController,
                                  textCapitalization: TextCapitalization.characters,
                                  inputFormatters: [
                                    LengthLimitingTextInputFormatter(10),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Security Note for KYC
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFBF9F5),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFEFE8DE)),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.shield_outlined, size: 14, color: AppColors.gold),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Govt KYC required for high-value designer asset security. Stored encrypted & tamper-proof.',
                                          style: GoogleFonts.inter(fontSize: 10, color: AppColors.inkSecondary),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ] else ...[
                                // Lister specific fields
                                _buildInputField(
                                  label: 'BOUTIQUE / ATELIER STUDIO NAME',
                                  hint: 'Enter boutique or studio name',
                                  icon: Icons.storefront_outlined,
                                  controller: _shopNameController,
                                ),
                                const SizedBox(height: 12),

                                _buildInputField(
                                  label: 'ATELIER STORY & BIO (MIN 20 CHARS)',
                                  hint: 'Share the history, craftsmanship, or bridal specialty of your collection...',
                                  icon: Icons.auto_awesome_outlined,
                                  controller: _bioController,
                                  maxLines: 3,
                                ),
                              ],

                              const SizedBox(height: 22),

                              // Submit Button
                              GestureDetector(
                                onTap: auth.isLoading ? null : _submit,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  height: 52,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [Color(0xFFD4567A), Color(0xFFB8405E)],
                                    ),
                                    borderRadius: BorderRadius.circular(26),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFD4567A).withValues(alpha: 0.38),
                                        blurRadius: 14,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: auth.isLoading
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                isLister ? 'CREATE LISTER ATELIER' : 'CREATE RENTER ACCOUNT',
                                                style: GoogleFonts.inter(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: 1.0,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              const Icon(
                                                Icons.arrow_forward_rounded,
                                                size: 16,
                                                color: Colors.white,
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Already have an account link
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Already have an account? ',
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5,
                                      color: AppColors.inkSecondary,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => Navigator.of(context).pop(),
                                    child: Text(
                                      'Sign In',
                                      style: GoogleFonts.inter(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.accentRose,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Security Policy Note
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.shield_outlined, size: 13, color: AppColors.inkMuted),
                              const SizedBox(width: 5),
                              Text(
                                '1 Account = 1 Role  •  Strict Identity & Anti-Theft Protection',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.inkMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    Widget? suffixIcon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.7,
            color: AppColors.inkSecondary,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFAF8F5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE8E0D5), width: 1.1),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            inputFormatters: inputFormatters,
            maxLines: maxLines,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.inkMuted.withValues(alpha: 0.8),
              ),
              prefixIcon: Icon(
                icon,
                color: AppColors.accentRose,
                size: 18,
              ),
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}
