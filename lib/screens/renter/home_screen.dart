import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/luxury_card.dart';
import '../../core/widgets/notification_bell_button.dart';
import '../../models/listing_model.dart';
import '../../providers/listing_provider.dart';
import 'catalog_screen.dart';
import 'product_detail_screen.dart';

class RenterHomeScreen extends ConsumerStatefulWidget {
  final VoidCallback? onOpenDrawer;
  const RenterHomeScreen({super.key, this.onOpenDrawer});

  @override
  ConsumerState<RenterHomeScreen> createState() => _RenterHomeScreenState();
}

class _RenterHomeScreenState extends ConsumerState<RenterHomeScreen> {
  String _calcSelectedCategory = 'Lehenga';
  bool _calcIsRentTab = true;
  String _selectedVaultCategory = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(listingProvider.notifier).fetchListings();
    });
  }

  // 1. Story / Category Circles
  final List<Map<String, String>> _storyCategories = const [
    {
      'name': 'All',
      'label': 'All Vault',
      'img': 'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?auto=format&fit=crop&q=80&w=400',
      'tag': 'ARCHIVE',
    },
    {
      'name': 'Lehenga',
      'label': 'Lehengas',
      'img': 'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?auto=format&fit=crop&q=80&w=400',
      'tag': 'BRIDAL',
    },
    {
      'name': 'Saree',
      'label': 'Sarees',
      'img': 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?auto=format&fit=crop&q=80&w=400',
      'tag': 'SILKS',
    },
    {
      'name': 'Sherwani',
      'label': 'Sherwanis',
      'img': 'https://images.unsplash.com/photo-1597983073493-88cd35cf93b0?auto=format&fit=crop&q=80&w=400',
      'tag': 'GROOM',
    },
    {
      'name': 'Gown',
      'label': 'Gowns',
      'img': 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?auto=format&fit=crop&q=80&w=400',
      'tag': 'COCKTAIL',
    },
    {
      'name': 'Sharara',
      'label': 'Shararas',
      'img': 'https://images.unsplash.com/photo-1566174053879-31528523f8ae?auto=format&fit=crop&q=80&w=400',
      'tag': 'FESTIVE',
    },
  ];




  @override
  Widget build(BuildContext context) {
    final state = ref.watch(listingProvider);

    final vaultListings = state.listings;

    return Scaffold(
      backgroundColor: AppColors.bgCream,
      appBar: AppBar(
        backgroundColor: AppColors.bgCream,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        toolbarHeight: 68,
        leading: Builder(
          builder: (context) => Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Center(
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border, width: 0.9),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.ink.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.menu_rounded, color: AppColors.ink, size: 20),
                  onPressed: () {
                    if (widget.onOpenDrawer != null) {
                      widget.onOpenDrawer!();
                    } else {
                      Scaffold.of(context).openDrawer();
                    }
                  },
                ),
              ),
            ),
          ),
        ),
        title: const BrandLogoWidget(
          size: LogoSize.md,
          showSubtitle: true,
          subtitle: 'HAUTE ETHNIC ARCHIVE',
        ),
        actions: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border, width: 0.9),
              boxShadow: [
                BoxShadow(
                  color: AppColors.ink.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const NotificationBellButton(),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border, width: 0.9),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.ink.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.search_rounded, color: AppColors.ink, size: 20),
                onPressed: () {
                  ref.read(listingProvider.notifier).setCategory('All');
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CatalogScreen()),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.accentRose,
        onRefresh: () => ref.read(listingProvider.notifier).fetchListings(),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              // ━━━ 1. LUXURY SEARCH & EXPLORE BAR ━━━
              _buildLuxurySearchBar(context),

              const SizedBox(height: 16),

              // ━━━ 2. HAUTE EDITORIAL STATEMENT BANNER (TYPOGRAPHIC) ━━━
              _buildHauteStatementBanner(context),

              const SizedBox(height: 32),

              // ━━━ 3. STORY CIRCLES (CATEGORY ACCESS) ━━━
              _buildStoryCategoriesBar(context, state.listings),

              const SizedBox(height: 34),

              // ━━━ 4. NEW ARRIVALS (FRESH DROPS) ━━━
              if (state.listings.isNotEmpty) ...[
                _buildNewArrivalsSection(context, state.listings),
                const SizedBox(height: 38),
              ],

              // ━━━ 5. THE VAULT (ARCHIVAL CATALOG GRID) ━━━
              _buildTheVaultGrid(context, vaultListings, state.listings),

              const SizedBox(height: 40),

              // ━━━ 6. BUY VS RENT — LUXURY SAVINGS CALCULATOR ━━━
              _buildLuxuryCalcSection(context, state.listings),

              const SizedBox(height: 40),

              // ━━━ 7. HAUTE EDITORIAL FOOTNOTE ━━━
              _buildEditorialFootnote(),

              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 1. LUXURY SEARCH BAR
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildLuxurySearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () {
          ref.read(listingProvider.notifier).setCategory('All');
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CatalogScreen()),
          );
        },
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFEDE7DF), width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, color: AppColors.ink, size: 21),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Search bridal lehengas, sarees, sherwanis...',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.inkSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.bgCream,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(Icons.tune_rounded, size: 14, color: AppColors.ink),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 2. HAUTE EDITORIAL STATEMENT BANNER (ROYAL VELVET WINE LUXURY BANNER)
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildHauteStatementBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4A182B), // Imperial velvet wine
            Color(0xFF35101E), // Royal deep burgundy
            Color(0xFF220813), // Deep nocturnal velvet
          ],
        ),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.60),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF35101E).withValues(alpha: 0.30),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Subtle Gold Ambient Glow in Top Right
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.gold.withValues(alpha: 0.16),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Tagline with Gold Diamond and Badges (Overflow-proof)
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.7),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.diamond_outlined, size: 10, color: AppColors.gold),
                          const SizedBox(width: 4),
                          Text(
                            'THE HAUTE ARCHIVE',
                            style: GoogleFonts.inter(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: AppColors.goldLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: AppColors.accentRose.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.accentRose.withValues(alpha: 0.6),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        'AUTHENTIC',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 7.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Grand Serif Statement Headline
                Text(
                  'Own The Moment,\nNot The Wardrobe.',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 27,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.08,
                    letterSpacing: -0.4,
                  ),
                ),

                const SizedBox(height: 9),

                // Gold Accent Hairline Rule
                Container(
                  width: 38,
                  height: 1.5,
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),

                const SizedBox(height: 11),

                // Subtitle Explanation
                Text(
                  'Curated bridal lehengas, pure Banarasi silks, and regal groom sherwanis — delivered pristine for your grandest ceremonies at a fraction of retail.',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: Colors.white.withValues(alpha: 0.86),
                    height: 1.45,
                    fontWeight: FontWeight.w400,
                  ),
                ),

                const SizedBox(height: 16),

                // Micro Feature Tags Row
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    _buildBannerFeatureTag(Icons.verified_outlined, 'Sanitized & Inspected'),
                    _buildBannerFeatureTag(Icons.event_seat_outlined, '4-Day Event Keep'),
                    _buildBannerFeatureTag(Icons.replay_rounded, 'Doorstep Return'),
                  ],
                ),

                const SizedBox(height: 18),

                // Premium CTA Button in Crisp White with Velvet Wine Ink Text
                GestureDetector(
                  onTap: () {
                    ref.read(listingProvider.notifier).setCategory('All');
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CatalogScreen()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'EXPLORE THE VAULT',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            color: const Color(0xFF2E0C1B),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_rounded, size: 12, color: Color(0xFF2E0C1B)),
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

  Widget _buildBannerFeatureTag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AppColors.gold),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: AppColors.goldLight,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 3. STORY CATEGORY BUBBLES (INSTAGRAM-STYLE STORY RINGS)
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildStoryCategoriesBar(BuildContext context, List<ListingModel> listings) {
    // 1. Tally counts, distinct categories, and real product images from backend listings
    final Set<String> distinctCategories = {};
    final Map<String, int> catCounts = {};
    final Map<String, String> catImages = {};

    for (final l in listings) {
      final cat = l.category.trim();
      if (cat.isNotEmpty) {
        // Standardize capitalization (e.g. 'Lehenga', 'Saree', 'Sherwani', 'Anarkali')
        final formatted = cat[0].toUpperCase() + (cat.length > 1 ? cat.substring(1) : '');
        distinctCategories.add(formatted);
        catCounts[formatted] = (catCounts[formatted] ?? 0) + 1;

        // Prioritize genuine fashion listings over quick test entries for cover photo
        final isClean = !l.title.toLowerCase().contains('test') && !l.title.toLowerCase().contains('debug');
        if (l.baselineImages.isNotEmpty) {
          final img = l.baselineImages.first.trim();
          if (img.isNotEmpty && !img.contains('sample-anarkali.jpg')) {
            if (!catImages.containsKey(formatted) || (isClean && !catImages.containsKey('${formatted}_clean'))) {
              catImages[formatted] = img;
              if (isClean) catImages['${formatted}_clean'] = img;
            }
          }
        }
      }
    }

    const Map<String, String> categoryFallbacks = {
      'Lehenga': 'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?auto=format&fit=crop&q=80&w=400',
      'Saree': 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?auto=format&fit=crop&q=80&w=400',
      'Sherwani': 'https://images.unsplash.com/photo-1597983073493-88cd35cf93b0?auto=format&fit=crop&q=80&w=400',
      'Gown': 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?auto=format&fit=crop&q=80&w=400',
      'Sharara': 'https://images.unsplash.com/photo-1566174053879-31528523f8ae?auto=format&fit=crop&q=80&w=400',
      'Anarkali': 'https://images.unsplash.com/photo-1617627143750-d86bc21e42bb?auto=format&fit=crop&q=80&w=400',
      'Kurta': 'https://images.unsplash.com/photo-1597983073493-88cd35cf93b0?auto=format&fit=crop&q=80&w=400',
      'Suit': 'https://images.unsplash.com/photo-1594938298603-c8148c4dae35?auto=format&fit=crop&q=80&w=400',
      'Dress': 'https://images.unsplash.com/photo-1539109136881-3be0616acf4b?auto=format&fit=crop&q=80&w=400',
      'All': 'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?auto=format&fit=crop&q=80&w=400',
    };

    String formatCategoryLabel(String cat) {
      if (cat == 'All') return 'All Vault';
      if (cat.endsWith('s') || cat.endsWith('S')) return cat;
      if (cat.endsWith('ss') || cat.endsWith('sh') || cat.endsWith('ch')) return '${cat}es';
      return '${cat}s';
    }

    // Sort categories by outfit count descending (most popular first)
    final sortedCategories = distinctCategories.toList()
      ..sort((a, b) {
        final cA = catCounts[a] ?? 0;
        final cB = catCounts[b] ?? 0;
        if (cB != cA) return cB.compareTo(cA);
        return a.compareTo(b);
      });

    // Full catalog list of all categories in the system
    final List<Map<String, String>> allCategoriesList = distinctCategories.isEmpty
        ? _storyCategories
        : [
            {
              'name': 'All',
              'label': 'All Vault',
              'img': listings.isNotEmpty && listings.first.baselineImages.isNotEmpty
                  ? listings.first.baselineImages.first
                  : categoryFallbacks['All']!,
              'tag': '${listings.length} PIECES',
            },
            ...sortedCategories.map((cat) {
              final count = catCounts[cat] ?? 0;
              final img = catImages[cat] ?? categoryFallbacks[cat] ?? categoryFallbacks['All']!;
              return {
                'name': cat,
                'label': formatCategoryLabel(cat),
                'img': img,
                'tag': '$count PIECES',
              };
            }),
          ];

    // Home screen horizontal story ring is capped to top 8 archives for optimal UX
    final activeCategories = allCategoriesList.take(8).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CURATED ARCHIVES',
                style: GoogleFonts.inter(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                  color: AppColors.accentRose,
                ),
              ),
              GestureDetector(
                onTap: () => _showAllCategoriesSheet(context, allCategoriesList),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'VIEW ALL',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 9, color: AppColors.ink),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 96,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: activeCategories.length,
            itemBuilder: (context, i) {
              final cat = activeCategories[i];
              final isSelected = _selectedVaultCategory.toLowerCase() == cat['name']!.toLowerCase();

              return GestureDetector(
                onTap: () {
                  final catName = cat['name']!;
                  // 1. Set Riverpod category filter so CatalogScreen immediately loads this category
                  ref.read(listingProvider.notifier).setCategory(catName);
                  ref.read(listingProvider.notifier).setSearchQuery('');

                  // 2. Keep Vault section state in sync
                  setState(() {
                    _selectedVaultCategory = catName;
                  });

                  // 3. Immediately show all products of this category in the Catalog screen
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CatalogScreen(),
                    ),
                  );
                },
                child: Container(
                  width: 72,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  child: Column(
                    children: [
                      Container(
                        width: 62,
                        height: 62,
                        padding: const EdgeInsets.all(2.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: isSelected
                                ? [AppColors.accentRose, AppColors.gold]
                                : [AppColors.gold.withValues(alpha: 0.6), AppColors.border],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.ink.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: CachedNetworkImage(
                            imageUrl: cat['img']!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(color: AppColors.bgCream),
                            errorWidget: (context, url, error) => const Icon(Icons.checkroom, size: 24),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        cat['label']!,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? AppColors.ink : AppColors.inkSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 3b. COMPLETE CATEGORIES DIRECTORY (MODAL BOTTOM SHEET)
  // ─────────────────────────────────────────────────────────────────────────────
  void _showAllCategoriesSheet(BuildContext context, List<Map<String, String>> allCategories) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String query = '';
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final displayList = query.isEmpty
                ? allCategories
                : allCategories.where((c) {
                    final q = query.toLowerCase();
                    return c['name']!.toLowerCase().contains(q) ||
                        c['label']!.toLowerCase().contains(q);
                  }).toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (_, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: AppColors.bgCream,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        width: 44,
                        height: 4.5,
                        decoration: BoxDecoration(
                          color: AppColors.inkMuted.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 16, 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'COMPLETE DIRECTORY',
                                  style: GoogleFonts.inter(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 2.0,
                                    color: AppColors.accentRose,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'All Collections',
                                  style: GoogleFonts.cormorantGaramond(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, color: AppColors.ink),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                      ),
                      // Search filter bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: TextField(
                          onChanged: (val) {
                            setSheetState(() {
                              query = val.trim();
                            });
                          },
                          style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink),
                          decoration: InputDecoration(
                            hintText: 'Search in all categories...',
                            hintStyle: GoogleFonts.inter(fontSize: 12.5, color: AppColors.inkMuted),
                            prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.inkMuted),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppColors.accentRose),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // 2-Column Grid of Category Cards
                      Expanded(
                        child: displayList.isEmpty
                            ? Center(
                                child: Text(
                                  'No categories found matching "$query"',
                                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.inkMuted),
                                ),
                              )
                            : GridView.builder(
                                controller: scrollController,
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: 1.12,
                                ),
                                itemCount: displayList.length,
                                itemBuilder: (context, idx) {
                                  final cat = displayList[idx];
                                  return GestureDetector(
                                    onTap: () {
                                      final catName = cat['name']!;
                                      Navigator.of(context).pop();
                                      ref.read(listingProvider.notifier).setCategory(catName);
                                      ref.read(listingProvider.notifier).setSearchQuery('');
                                      setState(() {
                                        _selectedVaultCategory = catName;
                                      });
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => const CatalogScreen(),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: AppColors.border),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.ink.withValues(alpha: 0.06),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          CachedNetworkImage(
                                            imageUrl: cat['img']!,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) => Container(color: AppColors.bgCream),
                                            errorWidget: (context, url, error) => Container(
                                              color: AppColors.bgCream,
                                              child: const Icon(Icons.checkroom, color: AppColors.inkMuted),
                                            ),
                                          ),
                                          Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  Colors.transparent,
                                                  Colors.black.withValues(alpha: 0.78),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 10,
                                            left: 10,
                                            right: 10,
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  cat['label']!,
                                                  style: GoogleFonts.cormorantGaramond(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white,
                                                    height: 1.1,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  cat['tag']!,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 8,
                                                    fontWeight: FontWeight.w700,
                                                    letterSpacing: 0.8,
                                                    color: AppColors.goldLight,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }



  // ─────────────────────────────────────────────────────────────────────────────
  // 5. NEW ARRIVALS (FRESH DROPS HORIZONTAL CAROUSEL)
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildNewArrivalsSection(BuildContext context, List<ListingModel> listings) {
    // Prioritize genuine fashion listings over quick debug/test entries if available
    final validItems = listings.where((l) {
      final t = l.title.trim().toLowerCase();
      return !t.contains('test') && t != 'abcd' && !t.contains('debug');
    }).toList();
    final arrivalItems = (validItems.isNotEmpty ? validItems : listings).take(8).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'JUST DROPPED',
                    style: GoogleFonts.inter(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.0,
                      color: AppColors.accentRose,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'New Arrivals',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  ref.read(listingProvider.notifier).setCategory('All');
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CatalogScreen()),
                  );
                },
                child: Text(
                  'SEE ALL',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 245,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: arrivalItems.length + 1,
            itemBuilder: (context, i) {
              // Trailing "View All Drops" editorial card
              if (i == arrivalItems.length) {
                return GestureDetector(
                  onTap: () {
                    ref.read(listingProvider.notifier).setCategory('All');
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CatalogScreen()),
                    );
                  },
                  child: Container(
                    width: 135,
                    margin: const EdgeInsets.only(right: 14),
                    decoration: BoxDecoration(
                      color: AppColors.bgCream,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFEDE8E1), width: 0.8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.ink,
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: AppColors.goldLight,
                            size: 18,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'View All\nDrops',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'EXPLORE',
                          style: GoogleFonts.inter(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: AppColors.accentRose,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final item = arrivalItems[i];
              return Container(
                width: 156,
                margin: const EdgeInsets.only(right: 12),
                child: LuxuryCard(
                  listing: item,
                  badge: 'NEW DROP',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ProductDetailScreen(listing: item),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 6. THE VAULT (ARCHIVAL CATALOG GRID)
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildTheVaultGrid(BuildContext context, List<ListingModel> listings, List<ListingModel> allListings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'THE COMPLETE COLLECTION',
                      style: GoogleFonts.inter(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.0,
                        color: AppColors.accentRose,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'The Vault',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  ref.read(listingProvider.notifier).setCategory('All');
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CatalogScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${listings.length} Outfits',
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 8, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Horizontal Slide of Outfits
        listings.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFF1EDE6), width: 0.8),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.checkroom, size: 32, color: AppColors.inkMuted),
                        const SizedBox(height: 8),
                        Text(
                          'No outfits found in this category',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : SizedBox(
                height: 245,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  itemCount: listings.length + 1,
                  itemBuilder: (context, i) {
                    if (i == listings.length) {
                      return GestureDetector(
                        onTap: () {
                          ref.read(listingProvider.notifier).setCategory('All');
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const CatalogScreen()),
                          );
                        },
                        child: Container(
                          width: 135,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFEDE8E1), width: 0.8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.ink,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.ink.withValues(alpha: 0.15),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'View All',
                                style: GoogleFonts.cormorantGaramond(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${listings.length} Outfits',
                                style: GoogleFonts.inter(
                                  fontSize: 9.5,
                                  color: AppColors.inkMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final item = listings[i];
                    return Container(
                      width: 156,
                      margin: const EdgeInsets.only(right: 12),
                      child: LuxuryCard(
                        listing: item,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ProductDetailScreen(listing: item),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 7. BUY VS RENT — LUXURY SAVINGS CALCULATOR
  // ─────────────────────────────────────────────────────────────────────────────
  double _getFallbackPrice(String cat) {
    switch (cat.toLowerCase()) {
      case 'lehenga':
        return 3999;
      case 'saree':
        return 2499;
      case 'sherwani':
        return 2999;
      case 'gown':
        return 2199;
      case 'sharara':
        return 1999;
      default:
        return 2999;
    }
  }

  Widget _buildLuxuryCalcSection(BuildContext context, List<ListingModel> listings) {
    // Dynamically calculate average rental prices from live listings
    final Map<String, List<double>> catPriceMap = {};
    for (final l in listings) {
      if (l.category.isNotEmpty && l.rentalPrice > 0) {
        catPriceMap.putIfAbsent(l.category.toLowerCase(), () => []).add(l.rentalPrice);
      }
    }

    final categories = ['Lehenga', 'Saree', 'Sherwani', 'Gown', 'Sharara'];
    final selectedCat = categories.contains(_calcSelectedCategory)
        ? _calcSelectedCategory
        : categories.first;

    final prices = catPriceMap[selectedCat.toLowerCase()];
    final double rentPrice = (prices != null && prices.isNotEmpty)
        ? (prices.reduce((a, b) => a + b) / prices.length).roundToDouble()
        : _getFallbackPrice(selectedCat);

    final double buyPrice = rentPrice * 25; // Estimated retail purchase price: 25x rental price
    final double savings = buyPrice - rentPrice;
    final int savingsPct = ((savings / buyPrice) * 100).round();
    final int eventsCount = (buyPrice / rentPrice).floor();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFEDE6DE), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E1E2D).withValues(alpha: 0.05),
            blurRadius: 28,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppColors.accentRose.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Overline Pill Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF2F5),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: AppColors.accentRose.withValues(alpha: 0.25), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('✦ ', style: TextStyle(color: AppColors.accentRose, fontSize: 8, fontWeight: FontWeight.bold)),
                Text(
                  'THE ECONOMICS OF COUTURE',
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                    color: AppColors.accentRose,
                  ),
                ),
                const Text(' ✦', style: TextStyle(color: AppColors.accentRose, fontSize: 8, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Main Heading with Italicized Accent
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.cormorantGaramond(
                fontSize: 27,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
                height: 1.15,
                letterSpacing: -0.3,
              ),
              children: [
                const TextSpan(text: 'Buy Once. Regret Forever.\n'),
                TextSpan(
                  text: 'Or Rent Smart.',
                  style: GoogleFonts.cormorantGaramond(
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accentRose,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Subtitle
          Text(
            'One designer purchase = $eventsCount+ different luxury event looks.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: AppColors.inkSecondary,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 20),

          // Horizontal Category Filter Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: categories.map((cat) {
                final isSelected = cat == selectedCat;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _calcSelectedCategory = cat;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF1B1722) : const Color(0xFFFAF7F3),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF1B1722) : const Color(0xFFE8E2D8),
                        width: 1.2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF1B1722).withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected) ...[
                          Container(
                            width: 5,
                            height: 5,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: const BoxDecoration(
                              color: AppColors.accentRose,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                        Text(
                          cat,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? Colors.white : AppColors.inkSecondary,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 18),

          // Segmented Switch: Renting vs Buying
          Container(
            height: 44,
            padding: const EdgeInsets.all(3.5),
            decoration: BoxDecoration(
              color: const Color(0xFFF3EFE9),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: const Color(0xFFE8E2D8), width: 1),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _calcIsRentTab = true),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      decoration: BoxDecoration(
                        color: _calcIsRentTab ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: _calcIsRentTab
                            ? [
                                BoxShadow(
                                  color: AppColors.accentRose.withValues(alpha: 0.12),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('✨ ', style: TextStyle(fontSize: 12)),
                            Text(
                              'Renting Atelier',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: _calcIsRentTab ? FontWeight.w700 : FontWeight.w500,
                                color: _calcIsRentTab ? AppColors.accentRose : AppColors.inkSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _calcIsRentTab = false),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      decoration: BoxDecoration(
                        color: !_calcIsRentTab ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: !_calcIsRentTab
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFDC2626).withValues(alpha: 0.10),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('🛍️ ', style: TextStyle(fontSize: 12)),
                            Text(
                              'Retail Buying',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: !_calcIsRentTab ? FontWeight.w700 : FontWeight.w500,
                                color: !_calcIsRentTab ? const Color(0xFFDC2626) : AppColors.inkSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Active Comparison Card
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _calcIsRentTab
                ? Container(
                    key: const ValueKey('rent_card'),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFFFFFF), Color(0xFFFFF8F9)],
                      ),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFF3D5DE), width: 1.4),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentRose.withValues(alpha: 0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card Header Row (Responsive Wrap prevents RenderFlex overflow on small screens)
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFFF0F3), Color(0xFFFFE8EE)],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.accentRose.withValues(alpha: 0.25)),
                              ),
                              child: Text(
                                '✨ WARDROB ATELIER',
                                style: GoogleFonts.inter(
                                  fontSize: 9.0,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.accentRose,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFA7F3D0)),
                              ),
                              child: Text(
                                'Save $savingsPct%',
                                style: GoogleFonts.inter(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF047857),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Price Row
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '₹${rentPrice.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                                style: GoogleFonts.cormorantGaramond(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.accentRose,
                                  height: 1.0,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '/ 4 days rental wear',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.inkSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.verified, size: 13, color: Color(0xFF10B981)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Hub-inspected + 72-hr complimentary event buffer',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppColors.inkMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // 2x2 Feature Grid - No truncation
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricTile(
                                icon: '🧼',
                                title: 'Hygiene',
                                value: 'Ozone Sanitized',
                                isPositive: true,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildMetricTile(
                                icon: '📦',
                                title: 'Logistics',
                                value: 'Doorstep Delivery',
                                isPositive: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricTile(
                                icon: '🔄',
                                title: 'Variety',
                                value: '$eventsCount+ Unique Looks',
                                isPositive: true,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildMetricTile(
                                icon: '🛡️',
                                title: 'Protection',
                                value: 'Hub Quality Sealed',
                                isPositive: true,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                : Container(
                    key: const ValueKey('buy_card'),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFFFFFF), Color(0xFFFFF8F8)],
                      ),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFFECACA), width: 1.4),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFDC2626).withValues(alpha: 0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card Header Row (Responsive Wrap prevents RenderFlex overflow on small screens)
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFFECACA)),
                              ),
                              child: Text(
                                '🛍️ RETAIL BUYING',
                                style: GoogleFonts.inter(
                                  fontSize: 9.0,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFFDC2626),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFFCA5A5)),
                              ),
                              child: Text(
                                'High Capital Cost',
                                style: GoogleFonts.inter(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFB91C1C),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Price Row
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '₹${buyPrice.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                                style: GoogleFonts.cormorantGaramond(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFDC2626),
                                  height: 1.0,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '/ single-use buy',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.inkSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.info_outline, size: 13, color: Color(0xFFDC2626)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Average designer showroom invoice price',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppColors.inkMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // 2x2 Pitfall Grid
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricTile(
                                icon: '🪤',
                                title: 'Usage',
                                value: 'Worn 1 Time Only',
                                isPositive: false,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildMetricTile(
                                icon: '🗄️',
                                title: 'Storage',
                                value: 'Closet Space Lost',
                                isPositive: false,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricTile(
                                icon: '🧺',
                                title: 'Maintenance',
                                value: '₹1,500+ Dry-Clean',
                                isPositive: false,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildMetricTile(
                                icon: '📉',
                                title: 'Depreciation',
                                value: '35% Resale Loss',
                                isPositive: false,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 18),

          // Obsidian Savings Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF131017), Color(0xFF26182B)],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFC5A880).withValues(alpha: 0.35), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF131017).withValues(alpha: 0.45),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('✦ ', style: TextStyle(color: Color(0xFFE8C8A3), fontSize: 9)),
                                Text(
                                  'TOTAL SMART SAVINGS',
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.0,
                                    color: const Color(0xFFE8C8A3),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '₹${savings.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                                  style: GoogleFonts.cormorantGaramond(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF064E3B),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.5)),
                                  ),
                                  child: Text(
                                    'SAVED',
                                    style: GoogleFonts.inter(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF4ADE80),
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Wear $eventsCount distinct designer outfits with the same budget.',
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              color: Colors.white.withValues(alpha: 0.75),
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Savings % Jewel Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFD4567A), Color(0xFFB8405E)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD4567A).withValues(alpha: 0.45),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$savingsPct%',
                            style: GoogleFonts.cormorantGaramond(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'SMARTER',
                            style: GoogleFonts.inter(
                              fontSize: 7.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: Colors.white.withValues(alpha: 0.95),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // CTA Button
                GestureDetector(
                  onTap: () {
                    ref.read(listingProvider.notifier).setCategory(selectedCat);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CatalogScreen()),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFD4567A), Color(0xFFB8405E)],
                      ),
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD4567A).withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Rent this $selectedCat for ₹${rentPrice.toInt()}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward_rounded, size: 15, color: Colors.white),
                        ],
                      ),
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

  Widget _buildMetricTile({
    required String icon,
    required String title,
    required String value,
    required bool isPositive,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isPositive ? const Color(0xFFFFF3F6) : const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPositive
              ? AppColors.accentRose.withValues(alpha: 0.18)
              : const Color(0xFFFECACA),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 11)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 8.0,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: isPositive ? AppColors.accentRose : const Color(0xFFDC2626),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 8. HAUTE EDITORIAL FOOTNOTE
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildEditorialFootnote() {
    return Center(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 32, height: 1, color: AppColors.gold.withValues(alpha: 0.5)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.diamond, size: 11, color: AppColors.gold),
              ),
              Container(width: 32, height: 1, color: AppColors.gold.withValues(alpha: 0.5)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'WARDROB ARCHIVES',
            style: GoogleFonts.inter(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.5,
              color: AppColors.inkMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pan-India Luxury Couture Rental',
            style: GoogleFonts.inter(
              fontSize: 10,
              color: AppColors.inkSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '100% Inspected & Sanitized Couture · Insured Doorstep Delivery',
            style: GoogleFonts.inter(
              fontSize: 8.5,
              color: AppColors.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}
