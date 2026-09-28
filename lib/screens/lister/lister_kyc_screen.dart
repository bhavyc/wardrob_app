import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/lister_provider.dart';
import 'lister_main_nav.dart';

class ListerKycScreen extends ConsumerStatefulWidget {
  const ListerKycScreen({super.key});

  @override
  ConsumerState<ListerKycScreen> createState() => _ListerKycScreenState();
}

class _ListerKycScreenState extends ConsumerState<ListerKycScreen> {
  final _bankAccController = TextEditingController();
  final _ifscController = TextEditingController();
  final _aadhaarController = TextEditingController();
  final _panController = TextEditingController();

  late Razorpay _razorpay;
  String? _pendingOrderId;
  bool _isPayingFee = false;
  bool _isSubmitting = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    _bankAccController.dispose();
    _ifscController.dispose();
    _aadhaarController.dispose();
    _panController.dispose();
    super.dispose();
  }

  void _syncFromProfile(ListerProfileModel? profile) {
    if (_initialized || profile == null) return;
    _bankAccController.text = profile.bankAccountNo ?? '';
    _ifscController.text = profile.bankIfsc ?? '';
    _aadhaarController.text = profile.aadhaarNumber ?? '';
    _panController.text = profile.panNumber ?? '';
    _initialized = true;
  }

  Future<void> _handlePayFee() async {
    final auth = ref.read(authProvider);
    setState(() => _isPayingFee = true);

    final res = await ref.read(listerProvider.notifier).createRegistrationFeeOrder();

    if (!mounted) return;

    if (res['success'] == true) {
      _pendingOrderId = res['orderId']?.toString();
      final keyId = res['keyId']?.toString() ?? 'rzp_test_placeholder';
      final amount = res['amount'] != null ? (res['amount'] * 100) : 50000;

      final options = {
        'key': keyId,
        'amount': amount,
        'name': 'Wardrob Boutique Partner',
        'order_id': _pendingOrderId,
        'description': 'Lister Onboarding Activation Fee (₹500)',
        'timeout': 300,
        'prefill': {
          'contact': auth.user?.phone ?? '',
          'email': auth.user?.email ?? '',
        },
        'theme': {
          'color': '#C5A880',
        }
      };

      try {
        _razorpay.open(options);
      } catch (e) {
        setState(() => _isPayingFee = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open payment gateway: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    } else {
      setState(() => _isPayingFee = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['error']?.toString() ?? 'Failed to initiate fee payment.'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final orderId = response.orderId ?? _pendingOrderId;
    if (orderId == null || response.paymentId == null || response.signature == null) {
      setState(() => _isPayingFee = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment details missing from gateway response.'),
            backgroundColor: Color(0xFFDC2626),
          ),
        );
      }
      return;
    }

    final res = await ref.read(listerProvider.notifier).verifyRegistrationFee(
          razorpayOrderId: orderId,
          razorpayPaymentId: response.paymentId!,
          razorpaySignature: response.signature!,
        );

    setState(() => _isPayingFee = false);

    if (mounted) {
      if (res['success'] == true) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext ctx) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 0,
              backgroundColor: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF86EFAC), width: 2),
                      ),
                      child: const Icon(Icons.check, color: Color(0xFF166534), size: 32),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Payment Successful!',
                      style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.ink),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Your ₹500 registration fee has been received.',
                      style: GoogleFonts.inter(fontSize: 14, color: AppColors.inkSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: GoogleFonts.inter(fontSize: 13, color: AppColors.inkSecondary, height: 1.5),
                        children: const [
                          TextSpan(text: 'Next Step: ', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
                          TextSpan(text: 'Please submit your KYC details below. You will be able to list items for rent only after your identity is verified and approved by our Admin team.'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E4D33), // Dark green to match web
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                        },
                        child: Text(
                          'I Understood, Proceed to KYC',
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['error']?.toString() ?? 'Fee verification failed.'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() => _isPayingFee = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment cancelled or failed: ${response.message ?? 'Unknown error'}'),
        backgroundColor: const Color(0xFFDC2626),
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    setState(() => _isPayingFee = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('External wallet chosen: ${response.walletName}'),
        backgroundColor: AppColors.ink,
      ),
    );
  }

  Future<void> _handleSubmit() async {
    final bankAcc = _bankAccController.text.trim();
    final ifsc = _ifscController.text.trim().toUpperCase();
    final aadhaar = _aadhaarController.text.trim();
    final pan = _panController.text.trim().toUpperCase();

    if (aadhaar.length != 12 || int.tryParse(aadhaar) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aadhaar number must be exactly 12 digits.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    if (pan.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PAN number must be 10 characters (e.g. ABCDE1234F).'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    if (bankAcc.isEmpty || ifsc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bank account number and IFSC code are required.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final result = await ref.read(listerProvider.notifier).submitKyc(
          aadhaarNumber: aadhaar,
          panNumber: pan,
          bankAccountNo: bankAcc,
          bankIfsc: ifsc,
        );

    setState(() => _isSubmitting = false);

    if (mounted) {
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']?.toString() ?? 'Details submitted successfully for review.'),
            backgroundColor: const Color(0xFF166534),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error']?.toString() ?? 'Failed to submit details.'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  String _maskAadhaar(String? val) {
    if (val == null || val.length < 4) return 'XXXX XXXX XXXX';
    return 'XXXX XXXX ${val.substring(val.length - 4)}';
  }

  String _maskPan(String? val) {
    if (val == null || val.length < 4) return 'XXXXXXXXXX';
    return 'XXXXX${val.substring(val.length - 4)}';
  }

  String _maskBank(String? val) {
    if (val == null || val.length < 4) return 'XXXXXXXXXXXX';
    return 'XXXX XXXX ${val.substring(val.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    final listerState = ref.watch(listerProvider);
    final profile = listerState.profile;
    _syncFromProfile(profile);

    final hasFeePaid = profile?.registrationFeePaid == true;
    final isApproved = profile?.status == 'APPROVED';
    final isPending = profile?.status == 'PENDING';
    final isRejected = profile?.status == 'REJECTED';
    final hasSubmittedKyc = (profile?.aadhaarNumber != null && profile!.aadhaarNumber!.isNotEmpty);
    final isUnderReview = isPending && hasSubmittedKyc;

    return Scaffold(
      backgroundColor: AppColors.bgCream,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          isApproved ? 'KYC & Verification' : 'Onboarding & KYC',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.inkSecondary),
            onPressed: () => ref.read(listerProvider.notifier).fetchProfile(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.accentRose,
        onRefresh: () => ref.read(listerProvider.notifier).fetchProfile(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. If account is APPROVED: show Verified Account view (no forms/inputs needed!)
              if (isApproved) ...[
                _buildApprovedView(profile),
              ]
              // 2. If account is UNDER REVIEW: show Submitted Details Review view
              else if (isUnderReview) ...[
                _buildUnderReviewView(profile),
              ]
              // 3. Otherwise: show the 2-step onboarding submission form
              else ...[
                _buildPendingSubmissionView(
                  hasFeePaid: hasFeePaid,
                  isRejected: isRejected,
                ),
              ],

              const SizedBox(height: 18),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(Icons.shield_outlined, size: 14, color: AppColors.inkMuted),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'All credentials are encrypted & stored in accordance with RBI norms.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.inkMuted),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 90),
            ],
          ),
        ),
      ),
    );
  }

  /// View when Lister is APPROVED
  Widget _buildApprovedView(ListerProfileModel? profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Green Verified Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF86EFAC)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF166534).withValues(alpha: 0.06),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: Color(0xFF166534),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.verified_rounded, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                'Account Fully Verified',
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF14532D)),
              ),
              const SizedBox(height: 4),
              Text(
                'Your KYC documents & payout account are verified. You can publish wardrobes and receive 100% of rental earnings directly.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF166534), height: 1.45),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Verified Details Summary Card
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
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Verified Details Summary',
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink),
              ),
              const SizedBox(height: 14),

              _buildSummaryRow('Aadhaar Number', _maskAadhaar(profile?.aadhaarNumber), isVerified: true),
              const Divider(height: 20),
              _buildSummaryRow('PAN Card', _maskPan(profile?.panNumber), isVerified: true),
              const Divider(height: 20),
              _buildSummaryRow('Bank Account', _maskBank(profile?.bankAccountNo), isVerified: true),
              const Divider(height: 20),
              _buildSummaryRow('IFSC Code', profile?.bankIfsc ?? 'N/A', isVerified: true),
              const Divider(height: 20),
              _buildSummaryRow('Platform Fee', '₹500.00 Paid', isVerified: true),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Add Outfits Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentRose,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              // Navigate to Wardrobe tab
              ref.read(listerNavIndexProvider.notifier).state = 1;
            },
            icon: const Icon(Icons.checkroom_outlined, size: 20),
            label: Text(
              'Go to Wardrobe & Add Outfits',
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  /// View when Lister KYC is submitted and UNDER REVIEW
  Widget _buildUnderReviewView(ListerProfileModel? profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Under Review Status Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.hourglass_top_rounded, color: Color(0xFFB45309), size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verification Under Review',
                      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF92400E)),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Your KYC documents & bank account details are currently being reviewed by our compliance team (typically 24-48 hours). Details are locked during verification.',
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFB45309), height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Submitted Details Card (Read-only summary)
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
                offset: const Offset(0, 2),
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
                    'Submitted Details',
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'LOCKED',
                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF92400E)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              _buildSummaryRow('Aadhaar Number', _maskAadhaar(profile?.aadhaarNumber), isVerified: false),
              const Divider(height: 20),
              _buildSummaryRow('PAN Card', _maskPan(profile?.panNumber), isVerified: false),
              const Divider(height: 20),
              _buildSummaryRow('Bank Account', _maskBank(profile?.bankAccountNo), isVerified: false),
              const Divider(height: 20),
              _buildSummaryRow('IFSC Code', profile?.bankIfsc ?? 'N/A', isVerified: false),
              const Divider(height: 20),
              _buildSummaryRow('Platform Fee', '₹500.00 Paid', isVerified: true),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Disabled Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF1F5F9),
              foregroundColor: const Color(0xFF64748B),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: null,
            child: Text(
              'Verification Under Review (Locked) ⏳',
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  /// View when KYC is NOT submitted or REJECTED (needs 2-step onboarding)
  Widget _buildPendingSubmissionView({
    required bool hasFeePaid,
    required bool isRejected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isRejected) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: Row(
              children: [
                const Icon(Icons.cancel_outlined, color: Color(0xFFDC2626), size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Previous submission was rejected. Please re-enter correct Aadhaar, PAN, and Bank details below.',
                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF991B1B)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Step 1: Activation Fee (₹500)
        _buildStepOneCard(hasFeePaid),

        const SizedBox(height: 20),

        // Step 2: Form Inputs (Aadhaar, PAN, Bank)
        _buildStepTwoInputs(hasFeePaid),

        const SizedBox(height: 20),

        // Submit Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: hasFeePaid ? AppColors.accentRose : const Color(0xFFE2E8F0),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: (hasFeePaid && !_isSubmitting) ? _handleSubmit : null,
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    hasFeePaid ? 'Save & Submit Details' : 'Pay ₹500 Fee in Step 1 to Unlock',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: hasFeePaid ? Colors.white : AppColors.inkMuted,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepOneCard(bool hasFeePaid) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasFeePaid ? const Color(0xFF86EFAC) : const Color(0xFFF59E0B).withValues(alpha: 0.5),
          width: hasFeePaid ? 1.0 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: hasFeePaid ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  hasFeePaid ? 'STEP 1: COMPLETED' : 'STEP 1: MANDATORY FEE',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: hasFeePaid ? const Color(0xFF166534) : const Color(0xFFB45309),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              if (hasFeePaid)
                const Icon(Icons.check_circle_rounded, color: Color(0xFF166534), size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Lister Platform Activation Fee',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink),
          ),
          const SizedBox(height: 4),
          Text(
            'A one-time platform fee of ₹500 is required before submitting your KYC details to prevent spam and ensure verified partner quality.',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkMuted, height: 1.4),
          ),
          const SizedBox(height: 14),

          // Overflow-proof Fee Summary Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Activation Fee (Non-refundable)',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.inkSecondary),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '₹500.00',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink),
                ),
              ],
            ),
          ),

          if (!hasFeePaid) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD97706),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isPayingFee ? null : _handlePayFee,
                icon: _isPayingFee
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.payment_rounded, size: 18),
                label: Text(
                  _isPayingFee ? 'Opening Gateway...' : 'Pay ₹500 via Razorpay',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded, size: 16, color: Color(0xFF166534)),
                const SizedBox(width: 6),
                Text(
                  '₹500 Fee Verified. Step 2 unlocked.',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF166534)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepTwoInputs(bool hasFeePaid) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'STEP 2: KYC & BANK DETAILS',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              if (!hasFeePaid)
                const Row(
                  children: [
                    Icon(Icons.lock, size: 14, color: AppColors.inkMuted),
                    SizedBox(width: 4),
                    Text('Locked', style: TextStyle(fontSize: 11, color: AppColors.inkMuted, fontWeight: FontWeight.w600)),
                  ],
                ),
            ],
          ),

          if (!hasFeePaid) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Color(0xFFB45309), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Please pay the ₹500 activation fee in Step 1 to unlock KYC & bank account submission.',
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF92400E)),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          Text(
            'Identity Details',
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _aadhaarController,
            enabled: hasFeePaid,
            keyboardType: TextInputType.number,
            maxLength: 12,
            decoration: InputDecoration(
              labelText: 'Aadhaar Card Number',
              hintText: '12-digit number',
              counterText: '',
              prefixIcon: const Icon(Icons.credit_card, size: 20),
              filled: !hasFeePaid,
              fillColor: !hasFeePaid ? const Color(0xFFF8FAFC) : Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 14),

          TextField(
            controller: _panController,
            enabled: hasFeePaid,
            textCapitalization: TextCapitalization.characters,
            maxLength: 10,
            decoration: InputDecoration(
              labelText: 'PAN Card Number',
              hintText: 'e.g. ABCDE1234F',
              counterText: '',
              prefixIcon: const Icon(Icons.badge_outlined, size: 20),
              filled: !hasFeePaid,
              fillColor: !hasFeePaid ? const Color(0xFFF8FAFC) : Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),

          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 20),

          Text(
            'Bank Account for Payouts',
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink),
          ),
          const SizedBox(height: 4),
          Text(
            'Your rental revenue will be credited directly to this bank account.',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkMuted),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _bankAccController,
            enabled: hasFeePaid,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Bank Account Number',
              hintText: 'Enter account number',
              prefixIcon: const Icon(Icons.account_balance, size: 20),
              filled: !hasFeePaid,
              fillColor: !hasFeePaid ? const Color(0xFFF8FAFC) : Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 14),

          TextField(
            controller: _ifscController,
            enabled: hasFeePaid,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: 'IFSC Code',
              hintText: 'e.g. HDFC0001234',
              prefixIcon: const Icon(Icons.domain, size: 20),
              filled: !hasFeePaid,
              fillColor: !hasFeePaid ? const Color(0xFFF8FAFC) : Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              border: Border.all(color: const Color(0xFFFDE68A)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('⚠️', style: TextStyle(fontSize: 16, height: 1)),
                const SizedBox(width: 10),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF92400E), height: 1.4),
                      children: const [
                        TextSpan(text: 'Important: ', style: TextStyle(fontWeight: FontWeight.w700)),
                        TextSpan(text: 'Please double-check your bank account number and IFSC code. If incorrect details are provided, payouts may be transferred to the wrong account and Wardrob will not be held responsible for the loss of funds.'),
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

  Widget _buildSummaryRow(String label, String value, {required bool isVerified}) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.inkSecondary),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
              if (isVerified) ...[
                const SizedBox(width: 5),
                const Icon(Icons.check_circle, size: 15, color: Color(0xFF166534)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
