import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../models/listing_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/lister_provider.dart';
import 'lister_listing_detail_screen.dart';
import 'lister_main_nav.dart';

class ListerListingsScreen extends ConsumerStatefulWidget {
  const ListerListingsScreen({super.key});

  @override
  ConsumerState<ListerListingsScreen> createState() => _ListerListingsScreenState();
}

class _ListerListingsScreenState extends ConsumerState<ListerListingsScreen> {
  String _selectedFilter = 'ALL';
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _openAddListingSheet() {
    final profile = ref.read(listerProvider).profile;
    final feePaid = profile?.registrationFeePaid ?? false;
    final isApproved = profile?.status == 'APPROVED';

    if (!feePaid || !isApproved) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 85),
          dismissDirection: DismissDirection.horizontal,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(!feePaid
              ? 'Please pay the onboarding fee first.'
              : 'Your KYC is under review before you can publish.'),
          action: SnackBarAction(
            label: 'View KYC',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ref.read(listerNavIndexProvider.notifier).state = 4;
            },
          ),
          backgroundColor: const Color(0xFFD97706),
        ),
      );
      return;
    }

    final titleController = TextEditingController();
    final descController = TextEditingController();
    final rentController = TextEditingController();
    final depositController = TextEditingController();
    final uploadedImages = <String>[];
    bool isUploadingImage = false;
    bool isSubmitting = false;
    String? uploadError;
    String selectedCategory = 'Lehenga';
    String selectedSize = 'M';
    String selectedCondition = 'Pristine (Worn Once)';

    Future<void> takeCameraPhoto(StateSetter setModalState) async {
      if (uploadedImages.length >= 4) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maximum 4 photos allowed.')),
        );
        return;
      }
      try {
        final picker = ImagePicker();
        final picked = await picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
          maxWidth: 2000,
          maxHeight: 2000,
          preferredCameraDevice: CameraDevice.rear,
        );
        if (picked == null) return;

        setModalState(() {
          isUploadingImage = true;
          uploadError = null;
        });

        final client = ref.read(apiClientProvider);
        final formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(
            picked.path,
            filename: picked.name.isNotEmpty
                ? picked.name
                : 'outfit_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
          'listingId': 'lister_photo_${DateTime.now().millisecondsSinceEpoch}',
        });

        final response = await client.dio.post(
          '/uploads/listing-photo',
          data: formData,
        );

        if (response.statusCode == 200 && response.data['success'] == true) {
          final url = response.data['url'] as String;
          setModalState(() {
            uploadedImages.add(url);
            isUploadingImage = false;
          });
        } else {
          setModalState(() {
            isUploadingImage = false;
            uploadError = response.data['error']?.toString() ?? 'Failed to upload photo';
          });
        }
      } catch (e) {
        setModalState(() {
          isUploadingImage = false;
          uploadError = 'Camera error: ${e.toString()}';
        });
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag Handle
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Header
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add New Outfit',
                            style: GoogleFonts.inter(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'List your designer ethnic outfit for rentals.',
                            style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.inkMuted),
                      onPressed: () => Navigator.pop(ctx),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFF1F5F9),
                        padding: const EdgeInsets.all(6),
                        minimumSize: Size.zero,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 1. Photos Section (Camera Only)
                Row(
                  children: [
                    Text(
                      'PHOTOS (CAMERA ONLY)',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: AppColors.inkSecondary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${uploadedImages.length}/4 taken',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accentRose,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 84,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      // Camera Snap Button
                      if (uploadedImages.length < 4)
                        InkWell(
                          onTap: () => takeCameraPhoto(setModalState),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: 84,
                            height: 84,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              color: AppColors.accentRoseLight,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.accentRose.withValues(alpha: 0.45),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.camera_alt, color: AppColors.accentRose, size: 26),
                                const SizedBox(height: 4),
                                Text(
                                  'Camera',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.accentRose,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Uploaded Photos
                      ...uploadedImages.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final url = entry.value;
                        return Container(
                          width: 80,
                          height: 84,
                          margin: const EdgeInsets.only(right: 10),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: CachedNetworkImage(
                                  imageUrl: url,
                                  width: 80,
                                  height: 84,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => setModalState(() => uploadedImages.removeAt(idx)),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.black87,
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(3),
                                    child: const Icon(Icons.close_rounded, size: 12, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.camera_alt_outlined, size: 13, color: AppColors.inkMuted),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        'Live camera photos required for authentic outfit verification.',
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.inkMuted),
                      ),
                    ),
                  ],
                ),
                if (isUploadingImage) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentRose)),
                      const SizedBox(width: 8),
                      Text('Validating and uploading camera photo...', style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.inkSecondary)),
                    ],
                  ),
                ],
                if (uploadError != null) ...[
                  const SizedBox(height: 6),
                  Text(uploadError!, style: GoogleFonts.inter(fontSize: 11.5, color: Colors.red)),
                ],

                const SizedBox(height: 18),

                // 2. Outfit Title
                Text(
                  'OUTFIT TITLE',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: AppColors.inkSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: titleController,
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink),
                  decoration: InputDecoration(
                    hintText: 'e.g. Sabyasachi Royal Velvet Sherwani',
                    hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: const Color(0xFFFAF9F6),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFEBE5DB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFEBE5DB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.accentRose, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  ),
                ),

                const SizedBox(height: 16),

                // 3. Category (Full Width)
                Text(
                  'CATEGORY',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: AppColors.inkSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.ink),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFFAF9F6),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFEBE5DB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFEBE5DB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.accentRose, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Lehenga', child: Text('Lehenga')),
                    DropdownMenuItem(value: 'Sherwani', child: Text('Sherwani')),
                    DropdownMenuItem(value: 'Saree', child: Text('Saree')),
                    DropdownMenuItem(value: 'Anarkali', child: Text('Anarkali')),
                    DropdownMenuItem(value: 'Indo-Western', child: Text('Indo-Western')),
                    DropdownMenuItem(value: 'Gown', child: Text('Gown')),
                    DropdownMenuItem(value: 'Dress', child: Text('Dress')),
                  ],
                  onChanged: (val) {
                    if (val != null) setModalState(() => selectedCategory = val);
                  },
                ),

                const SizedBox(height: 16),

                // 4. Size Selection (Wrap pills - ZERO overflow)
                Text(
                  'SIZE',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: AppColors.inkSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['XS', 'S', 'M', 'L', 'XL', 'Free Size'].map((size) {
                    final isSelected = selectedSize == size;
                    return InkWell(
                      onTap: () => setModalState(() => selectedSize = size),
                      borderRadius: BorderRadius.circular(10),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.accentRose : const Color(0xFFFAF9F6),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? AppColors.accentRose : const Color(0xFFEBE5DB),
                          ),
                        ),
                        child: Text(
                          size,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? Colors.white : AppColors.ink,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                // 5. Condition
                Text(
                  'CONDITION',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: AppColors.inkSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: selectedCondition,
                  style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.ink),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFFAF9F6),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFEBE5DB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFEBE5DB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.accentRose, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Pristine (Worn Once)', child: Text('Pristine (Worn Once)')),
                    DropdownMenuItem(value: 'Excellent', child: Text('Excellent (Like New)')),
                    DropdownMenuItem(value: 'Good', child: Text('Good (Well Maintained)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setModalState(() => selectedCondition = val);
                  },
                ),

                const SizedBox(height: 16),

                // 6. Pricing & Deposit
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'RENT / 4 DAYS',
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: AppColors.inkSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: rentController,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink),
                            decoration: InputDecoration(
                              prefixText: '₹ ',
                              prefixStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink),
                              hintText: '5000',
                              hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
                              filled: true,
                              fillColor: const Color(0xFFFAF9F6),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Color(0xFFEBE5DB)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Color(0xFFEBE5DB)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: AppColors.accentRose, width: 1.5),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SECURITY DEPOSIT',
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: AppColors.inkSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: depositController,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink),
                            decoration: InputDecoration(
                              prefixText: '₹ ',
                              prefixStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink),
                              hintText: '10000',
                              hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
                              filled: true,
                              fillColor: const Color(0xFFFAF9F6),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Color(0xFFEBE5DB)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Color(0xFFEBE5DB)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: AppColors.accentRose, width: 1.5),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.shield_outlined, size: 14, color: AppColors.accentRose),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        'Minimum rental price policy is ₹5,000 for verified couture outfits.',
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.inkMuted),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 7. Description & Fabric Details
                Text(
                  'DESCRIPTION & FABRIC DETAILS',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: AppColors.inkSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: descController,
                  maxLines: 2,
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink),
                  decoration: InputDecoration(
                    hintText: 'e.g. Pure raw silk with zardozi hand embroidery. Dry-cleaned.',
                    hintStyle: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: const Color(0xFFFAF9F6),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFEBE5DB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFEBE5DB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.accentRose, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),

                const SizedBox(height: 24),

                // 8. Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentRose,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shadowColor: AppColors.accentRose.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final title = titleController.text.trim();
                            final desc = descController.text.trim();
                            final rent = double.tryParse(rentController.text.trim()) ?? 0;
                            final deposit = double.tryParse(depositController.text.trim()) ?? 0;

                            if (title.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter an outfit title.')),
                              );
                              return;
                            }
                            if (uploadedImages.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please upload at least 1 photo.')),
                              );
                              return;
                            }
                            if (rent < 5000) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Rental price must be at least ₹5,000.'),
                                  backgroundColor: Color(0xFFDC2626),
                                ),
                              );
                              return;
                            }

                            setModalState(() => isSubmitting = true);

                            final success = await ref.read(listerProvider.notifier).createListing(
                                  title: title,
                                  description: desc,
                                  category: selectedCategory,
                                  size: selectedSize,
                                  condition: selectedCondition,
                                  rentalPrice: rent,
                                  securityDeposit: deposit,
                                  images: uploadedImages,
                                );

                            setModalState(() => isSubmitting = false);

                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                            }
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(success
                                      ? 'Outfit submitted successfully!'
                                      : 'Failed to create outfit listing.'),
                                  backgroundColor: success ? const Color(0xFF166534) : Colors.red,
                                ),
                              );
                            }
                          },
                    child: isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            'Publish Outfit',
                            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleWithdraw(BuildContext context, String listingId) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Return Item to You?', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 17)),
        content: Text(
          'A courier will pick up this outfit from the Hub and return it back to your registered address.',
          style: GoogleFonts.inter(fontSize: 13.5, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.inkMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentRose,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final res = await ref.read(listerProvider.notifier).withdrawListing(listingId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(res['message'] ?? res['error'] ?? 'Withdrawal processed.'),
                    backgroundColor: res['success'] == true ? const Color(0xFF166534) : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Confirm Return'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listerState = ref.watch(listerProvider);
    final profile = listerState.profile;
    final listings = listerState.listings;
    final feePaid = profile?.registrationFeePaid ?? false;

    final availableCount = listings.where((l) => l.status == ListingStatus.available).length;
    final rentedCount = listings.where((l) => l.status == ListingStatus.rented).length;
    final atHubCount = listings.where((l) => l.status == ListingStatus.atHub).length;

    // Filter by status & search query
    final filteredListings = listings.where((l) {
      if (_selectedFilter == 'AVAILABLE' && l.status != ListingStatus.available) return false;
      if (_selectedFilter == 'RENTED' && l.status != ListingStatus.rented) return false;
      if (_selectedFilter == 'AT_HUB' && l.status != ListingStatus.atHub) return false;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchTitle = l.title.toLowerCase().contains(q);
        final matchCat = l.category.toLowerCase().contains(q);
        final matchSize = l.size.toLowerCase().contains(q);
        if (!matchTitle && !matchCat && !matchSize) return false;
      }

      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.bgCream,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Wardrobe',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            Text(
              '${listings.length} Outfits Catalogued',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                color: AppColors.inkMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.inkSecondary, size: 20),
            onPressed: () => ref.read(listerProvider.notifier).fetchListings(),
            tooltip: 'Refresh Wardrobe',
          ),
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _openAddListingSheet,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.ink,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.ink.withValues(alpha: 0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          'Add Outfit',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.accentRose,
        onRefresh: () => ref.read(listerProvider.notifier).fetchListings(),
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notice banner if onboarding fee pending
              if (!feePaid) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Onboarding fee of ₹500 required before outfits can be rented.',
                          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF92400E)),
                        ),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFD97706),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => ref.read(listerNavIndexProvider.notifier).state = 4,
                        child: const Text('Pay ₹500', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // 1. Premium Search Bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5E0D8)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim();
                    });
                  },
                  style: GoogleFonts.inter(fontSize: 13.5, color: AppColors.ink),
                  decoration: InputDecoration(
                    hintText: 'Search by outfit, category, or size...',
                    hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.accentRose, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.inkMuted),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // 2. Modern Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildFilterChip('ALL', 'All', listings.length),
                    const SizedBox(width: 8),
                    _buildFilterChip('AVAILABLE', 'Available', availableCount),
                    const SizedBox(width: 8),
                    _buildFilterChip('RENTED', 'Rented', rentedCount),
                    const SizedBox(width: 8),
                    _buildFilterChip('AT_HUB', 'In Cleaning', atHubCount),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 3. Listings Content
              if (filteredListings.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFEBE5DB)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFAF8F5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.checkroom_outlined, size: 40, color: Color(0xFFCBD5E1)),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _searchQuery.isNotEmpty ? 'No outfits match "$_searchQuery"' : 'No outfits found',
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _searchQuery.isNotEmpty
                            ? 'Try searching with another keyword or clearing filters.'
                            : 'Tap the "+ Add Outfit" button to add clothes to your wardrobe.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkMuted),
                      ),
                      if (_searchQuery.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                              _selectedFilter = 'ALL';
                            });
                          },
                          child: const Text('Clear Search & Filters', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.accentRose)),
                        ),
                      ] else ...[
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _openAddListingSheet,
                          icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                          label: Text(
                            'Add Your First Outfit',
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentRose,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                )
              else ...[
                // List of all matching items
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredListings.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (ctx, index) => _buildListingCard(ctx, filteredListings[index]),
                ),
              ],

              const SizedBox(height: 100), // padding for FAB & floating nav
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, int count) {
    final isSelected = _selectedFilter == value;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentRose : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.accentRose : const Color(0xFFE2E8F0),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.accentRose.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.inkSecondary,
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.25) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : AppColors.inkMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListingCard(BuildContext context, ListingModel item) {
    final image = item.baselineImages.isNotEmpty ? item.baselineImages.first : null;

    String statusText;
    Color statusBg;
    Color statusColor;

    switch (item.status) {
      case ListingStatus.available:
        statusText = 'Available';
        statusBg = const Color(0xFFF0FDF4);
        statusColor = const Color(0xFF15803D);
        break;
      case ListingStatus.rented:
        statusText = 'Rented Out';
        statusBg = const Color(0xFFEFF6FF);
        statusColor = const Color(0xFF1D4ED8);
        break;
      case ListingStatus.atHub:
        statusText = 'In Cleaning';
        statusBg = const Color(0xFFFAF5FF);
        statusColor = const Color(0xFF7E22CE);
        break;
      case ListingStatus.maintenance:
        statusText = 'Maintenance';
        statusBg = const Color(0xFFFFF7ED);
        statusColor = const Color(0xFFC2410C);
        break;
      case ListingStatus.unlisted:
        statusText = 'Unlisted';
        statusBg = const Color(0xFFF8FAFC);
        statusColor = const Color(0xFF475569);
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ListerListingDetailScreen(listing: item),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 100,
                    height: 125,
                    color: const Color(0xFFFAF8F5),
                    child: image != null && image.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: image,
                            fit: BoxFit.cover,
                            errorWidget: (_, _, _) => const Icon(Icons.checkroom, color: AppColors.inkMuted),
                          )
                        : const Icon(Icons.checkroom, color: AppColors.inkMuted),
                  ),
                ),
                const SizedBox(width: 16),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Badge & More Icon
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              statusText,
                              style: GoogleFonts.inter(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                                color: statusColor,
                              ),
                            ),
                          ),
                          const Icon(Icons.more_horiz_rounded, color: Color(0xFFCBD5E1), size: 20),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Title
                      Text(
                        item.title,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),

                      // Category • Size
                      Text(
                        '${item.category} • Size ${item.size}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.inkMuted,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Price & Hub Action
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '₹${item.rentalPrice.toInt()}',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Text(
                                ' / 4 days',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.inkSecondary,
                                ),
                              ),
                            ],
                          ),
                          if (item.status == ListingStatus.atHub)
                            InkWell(
                              onTap: () => _handleWithdraw(context, item.id),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.accentRoseLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Return',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.accentRose,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
