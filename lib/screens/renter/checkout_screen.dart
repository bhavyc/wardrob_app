import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/luxury_button.dart';
import '../../models/listing_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../models/user_model.dart';
import '../auth/login_screen.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  final ListingModel listing;
  final DateTime eventDate;
  final int extensionDays;

  const CheckoutScreen({
    super.key,
    required this.listing,
    required this.eventDate,
    this.extensionDays = 0,
  });

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _notesController = TextEditingController();
  late Razorpay _razorpay;
  String? _currentOrderId;
  bool _isProcessing = false;
  bool _useWallet = true;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = ref.read(authProvider);
      if (auth.user != null) {
        if (_nameController.text.isEmpty && auth.user!.name.isNotEmpty) {
          _nameController.text = auth.user!.name;
        }
        if (_phoneController.text.isEmpty && (auth.user!.phone?.isNotEmpty ?? false)) {
          _phoneController.text = auth.user!.phone!;
        }
      }
    });
  }

  @override
  void dispose() {
    _razorpay.clear();
    _nameController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  DateTime get deliveryDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final evDate = DateTime(widget.eventDate.year, widget.eventDate.month, widget.eventDate.day);
    final daysUntilEvent = evDate.difference(today).inDays;
    if (daysUntilEvent >= 5) {
      return evDate.subtract(const Duration(days: 2));
    } else {
      return today.add(const Duration(days: 3));
    }
  }

  DateTime get returnDate => widget.eventDate.add(Duration(days: 2 + widget.extensionDays));

  double get basePrice => widget.listing.rentalPrice;
  double get extensionFee => widget.extensionDays > 0 ? (basePrice * 0.25 * widget.extensionDays) : 0.0;
  double get rentAmount => basePrice + extensionFee;
  double get depositAmount => widget.listing.securityDeposit;
  double get grossTotal => rentAmount + depositAmount;

  double get walletBalance {
    final auth = ref.watch(authProvider);
    return auth.user?.walletBalance ?? 0.0;
  }

  double get walletDeduction {
    if (!_useWallet || walletBalance <= 0) return 0.0;
    return walletBalance > grossTotal ? grossTotal : walletBalance;
  }

  double get totalPayable => grossTotal - walletDeduction;
  double get totalAmount => totalPayable;



  Future<void> _handlePayment() async {
    final auth = ref.read(authProvider);
    if (!auth.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to complete your booking reservation.')),
      );
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    if (auth.user?.role != UserRole.renter) {
      final roleStr = auth.user?.role.toPrismaString().replaceAll('_', ' ') ?? 'unknown';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Your account is registered as a $roleStr. Only Renter accounts can access the checkout.'),
          backgroundColor: AppColors.ink,
        ),
      );
      return;
    }

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final street = _streetController.text.trim();
    final city = _cityController.text.trim();
    final state = _stateController.text.trim();
    final pincode = _pincodeController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter recipient full name.')),
      );
      return;
    }
    if (phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 10-digit mobile number.')),
      );
      return;
    }
    if (street.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter street / flat / building address.')),
      );
      return;
    }
    if (city.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter city name.')),
      );
      return;
    }
    if (state.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter state.')),
      );
      return;
    }
    if (pincode.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 6-digit PIN code.')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    final bookingNotifier = ref.read(renterBookingsProvider.notifier);
    final result = await bookingNotifier.createBookingOrder(
      productId: widget.listing.id,
      eventDate: widget.eventDate,
      extensionDays: widget.extensionDays,
      useWallet: _useWallet,
      shippingAddress: street,
      city: city,
      state: state,
      pincode: pincode,
      contactName: name,
      contactPhone: phone,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      if (result['isWalletFullPayment'] == true) {
        setState(() => _isProcessing = false);
        ref.read(authProvider.notifier).checkCurrentSession();
        _showSuccessDialog();
        return;
      }

      _currentOrderId = result['orderId'];
      final razorpayKey = result['key'] ?? 'rzp_test_placeholder';
      final amountInPaise = (result['amount'] != null)
          ? result['amount']
          : (totalPayable * 100).toInt();

      final options = {
        'key': razorpayKey,
        'amount': amountInPaise,
        'name': 'Wardrob Luxury Rentals',
        'order_id': _currentOrderId,
        'description': 'Rental: ${widget.listing.title}',
        'timeout': 300,
        'prefill': {
          'contact': auth.user?.phone ?? '',
          'email': auth.user?.email ?? '',
        },
        'theme': {
          'color': '#2C1810',
        }
      };

      try {
        _razorpay.open(options);
      } catch (e) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open payment gateway: $e')),
        );
      }
    } else {
      setState(() => _isProcessing = false);
      final errorMsg = result['error']?.toString() ?? 'Booking creation failed.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.ink,
          content: Text(errorMsg, style: const TextStyle(color: Colors.white)),
        ),
      );
    }
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final orderId = response.orderId ?? _currentOrderId;
    if (orderId == null || response.paymentId == null || response.signature == null) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment details missing from gateway response.')),
      );
      return;
    }

    final bookingNotifier = ref.read(renterBookingsProvider.notifier);
    final verifyRes = await bookingNotifier.verifyBookingPayment(
      orderId: orderId,
      paymentId: response.paymentId!,
      signature: response.signature!,
      productId: widget.listing.id,
    );

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (verifyRes['success'] == true) {
      ref.read(authProvider.notifier).checkCurrentSession();
      _showSuccessDialog();
    } else {
      final err = verifyRes['error']?.toString() ?? 'Payment verification failed.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade900,
          content: Text(err, style: const TextStyle(color: Colors.white)),
        ),
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (!mounted) return;
    setState(() => _isProcessing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red.shade900,
        content: Text('Payment failed: ${response.message ?? "Cancelled"}'),
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External wallet chosen: ${response.walletName}')),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 36),
            ),
            const SizedBox(height: 12),
            Text('Booking Confirmed!', style: AppTypography.titleLarge),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your rental for ${widget.listing.title} is locked.',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 10),
            Text('• Recipient: ${_nameController.text.trim()} (${_phoneController.text.trim()})', style: AppTypography.bodySmall),
            Text('• Deliver To: ${_streetController.text.trim()}, ${_cityController.text.trim()} - ${_pincodeController.text.trim()}', style: AppTypography.bodySmall),
            const SizedBox(height: 6),
            Text('• Delivery: ${DateFormat('EEE, d MMM').format(deliveryDate)}', style: AppTypography.bodySmall),
            Text('• Event Date: ${DateFormat('EEE, d MMM').format(widget.eventDate)}', style: AppTypography.bodySmall),
            Text('• Return Date: ${DateFormat('EEE, d MMM').format(returnDate)}', style: AppTypography.bodySmall),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.bgCream,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Security Deposit of ₹${depositAmount.toInt()} will be refunded automatically after return inspection.',
                style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.inkSecondary),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.ink,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('Back to Home', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEE, d MMM yyyy');

    return Scaffold(
      backgroundColor: AppColors.bgCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Checkout', style: AppTypography.titleLarge.copyWith(fontSize: 18)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Outfit Summary Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                      imageUrl: widget.listing.baselineImages.isNotEmpty
                          ? widget.listing.baselineImages.first
                          : 'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?w=800',
                      width: 70,
                      height: 85,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 70,
                        height: 85,
                        color: const Color(0xFFF0EBE1),
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.inkMuted),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 70,
                        height: 85,
                        color: const Color(0xFFF0EBE1),
                        child: const Icon(Icons.checkroom_outlined, color: AppColors.inkMuted, size: 28),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.listing.category.toUpperCase(), style: AppTypography.subtitleTag),
                        const SizedBox(height: 2),
                        Text(
                          widget.listing.title,
                          style: AppTypography.titleLarge.copyWith(fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Size: ${widget.listing.size} · Condition: ${widget.listing.condition}',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (!widget.listing.isDateAvailable(widget.eventDate)) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event_busy, color: Color(0xFFDC2626), size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'LISTING NOT FOUND FOR THIS DATE',
                            style: AppTypography.subtitleTag.copyWith(
                              color: const Color(0xFFB91C1C),
                              fontWeight: FontWeight.w800,
                              fontSize: 9,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'This listing is not available for your selected event date. Please go back and choose an available date.',
                            style: AppTypography.bodySmall.copyWith(
                              color: const Color(0xFF991B1B),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),

            // Event Schedule Summary (Read-Only)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('RENTAL TIMELINE (FLAT EVENT PACKAGE)', style: AppTypography.subtitleTag),
                  const SizedBox(height: 12),
                  _buildTimelineRow('Event Occasion', dateFormat.format(widget.eventDate), true),
                  const Divider(color: AppColors.borderLight, height: 16),
                  _buildTimelineRow(
                    'Rental Duration',
                    widget.extensionDays > 0
                        ? '4 Days + ${widget.extensionDays} Extension Days'
                        : 'Standard 4-Day Package',
                    false,
                  ),
                  const Divider(color: AppColors.borderLight, height: 16),
                  _buildTimelineRow('Estimated Delivery', DateFormat('EEE, d MMM yyyy').format(deliveryDate), false),
                  const Divider(color: AppColors.borderLight, height: 16),
                  _buildTimelineRow('Scheduled Return', DateFormat('EEE, d MMM yyyy').format(returnDate), false),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ━━━ 1. RECIPIENT INFORMATION ━━━
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('RECIPIENT CONTACT', style: AppTypography.subtitleTag),
                      const Icon(Icons.person_outline, size: 16, color: AppColors.accentRose),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildInputField(
                    label: 'FULL NAME * (REQUIRED)',
                    controller: _nameController,
                    hint: 'e.g. Sneha Verma',
                    icon: Icons.badge_outlined,
                  ),
                  const SizedBox(height: 12),
                  _buildInputField(
                    label: 'MOBILE NUMBER * (10 DIGITS REQUIRED)',
                    controller: _phoneController,
                    hint: '10-digit mobile number',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ━━━ 2. DELIVERY DESTINATION ━━━
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('DELIVERY DESTINATION', style: AppTypography.subtitleTag),
                      const Icon(Icons.location_on_outlined, size: 16, color: AppColors.accentRose),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildInputField(
                    label: 'STREET ADDRESS / FLAT / BUILDING * (REQUIRED)',
                    controller: _streetController,
                    hint: 'Flat/House No., Building Name, Street Landmark',
                    icon: Icons.home_outlined,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInputField(
                          label: 'CITY *',
                          controller: _cityController,
                          hint: 'Enter city',
                          icon: Icons.location_city_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInputField(
                          label: 'STATE *',
                          controller: _stateController,
                          hint: 'Enter state',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInputField(
                    label: 'PIN CODE * (6 DIGITS REQUIRED)',
                    controller: _pincodeController,
                    hint: '6-digit PIN code',
                    icon: Icons.pin_drop_outlined,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  _buildInputField(
                    label: 'DELIVERY INSTRUCTIONS (OPTIONAL)',
                    controller: _notesController,
                    hint: 'e.g. Call before arrival, leave with security',
                    icon: Icons.notes_outlined,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Wardrob Wallet Auto-Deduction Widget
            if (walletBalance > 0) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _useWallet ? const Color(0xFFF0FDF4) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _useWallet ? const Color(0xFF86EFAC) : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _useWallet ? const Color(0xFFDCFCE7) : AppColors.borderLight,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 20,
                        color: _useWallet ? const Color(0xFF15803D) : AppColors.inkSecondary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              Text(
                                'WARDROB WALLET',
                                style: AppTypography.subtitleTag.copyWith(
                                  color: _useWallet ? const Color(0xFF166534) : AppColors.inkSecondary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _useWallet ? const Color(0xFFDCFCE7) : AppColors.borderLight,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '₹${walletBalance.toInt()}',
                                  style: AppTypography.bodySmall.copyWith(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: _useWallet ? const Color(0xFF15803D) : AppColors.ink,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _useWallet
                                ? (walletDeduction >= grossTotal
                                    ? 'Full order covered by wallet balance'
                                    : '₹${walletDeduction.toInt()} auto-deducted from balance')
                                : 'Use available balance for this booking',
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 11,
                              color: AppColors.inkSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: _useWallet,
                      activeTrackColor: const Color(0xFF86EFAC),
                      activeThumbColor: const Color(0xFF15803D),
                      onChanged: (val) {
                        setState(() => _useWallet = val);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Checkout Financial Summary
            // STRICT RULE: Shows ONLY Rent Amount + Refundable Deposit (NO separate delivery fee line)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PAYMENT BREAKDOWN', style: AppTypography.subtitleTag),
                  const SizedBox(height: 14),
                  if (widget.extensionDays > 0) ...[
                    _buildPriceRow('4-Day Base Rental', '₹${basePrice.toInt()}'),
                    const SizedBox(height: 8),
                    _buildPriceRow('Extension Fee (${widget.extensionDays} Days)', '+₹${extensionFee.toInt()}'),
                  ] else ...[
                    _buildPriceRow('Rent Amount (Event Package)', '₹${rentAmount.toInt()}'),
                  ],
                  const SizedBox(height: 8),
                  _buildPriceRow('Refundable Security Deposit', '₹${depositAmount.toInt()}'),
                  if (walletDeduction > 0) ...[
                    const SizedBox(height: 8),
                    _buildPriceRow('Wallet Credit Applied', '-₹${walletDeduction.toInt()}', isDiscount: true),
                  ],
                  const Divider(color: AppColors.border, height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('TOTAL PAYABLE', style: AppTypography.titleLarge.copyWith(fontSize: 14)),
                            Text(
                              walletDeduction > 0
                                  ? 'Gross: ₹${grossTotal.toInt()} · Deposit Included'
                                  : 'Includes 100% Refundable Deposit',
                              style: AppTypography.bodySmall.copyWith(fontSize: 10),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '₹${totalPayable.toInt()}',
                        style: AppTypography.titleLarge.copyWith(
                          fontSize: 20,
                          color: AppColors.accentRose,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Pay / Reserve Button
            Builder(
              builder: (context) {
                final isDateAvailable = widget.listing.isDateAvailable(widget.eventDate);
                return LuxuryButton(
                  label: !isDateAvailable
                      ? 'Listing Not Available for This Date'
                      : (totalPayable == 0
                          ? 'Reserve with Wallet (1-Click)'
                          : 'Pay ₹${totalPayable.toInt()} with Razorpay'),
                  icon: !isDateAvailable
                      ? Icons.event_busy
                      : (totalPayable == 0 ? Icons.account_balance_wallet : Icons.payment),
                  color: !isDateAvailable ? Colors.grey.shade500 : null,
                  isLoading: _isProcessing,
                  onPressed: !isDateAvailable ? null : _handlePayment,
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.subtitleTag.copyWith(
            fontSize: 10,
            letterSpacing: 0.8,
            color: AppColors.inkSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: AppTypography.bodyMedium.copyWith(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.inkMuted, fontSize: 13),
            prefixIcon: icon != null ? Icon(icon, size: 18, color: AppColors.inkSecondary) : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            filled: true,
            fillColor: const Color(0xFFFCFAF7),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.accentRose, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineRow(String label, String value, bool isHighlight) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(color: AppColors.inkSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: AppTypography.titleLarge.copyWith(
            fontSize: 13,
            color: isHighlight ? AppColors.accentRose : AppColors.ink,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.inkSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: AppTypography.titleLarge.copyWith(
            fontSize: 14,
            color: isDiscount ? const Color(0xFF2E7D32) : AppColors.ink,
          ),
        ),
      ],
    );
  }
}
