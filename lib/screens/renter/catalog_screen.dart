import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/luxury_card.dart';
import '../../providers/listing_provider.dart';
import 'product_detail_screen.dart';

class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  final ScrollController _scrollController = ScrollController();
  int _displayedCount = 10;
  bool _isLoadingMore = false;
  String _lastCategory = '';
  String _lastSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final state = ref.read(listingProvider);
      final total = state.filteredListings.length;
      if (_displayedCount < total && !_isLoadingMore) {
        setState(() {
          _isLoadingMore = true;
        });
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            setState(() {
              _displayedCount = (_displayedCount + 10).clamp(0, total);
              _isLoadingMore = false;
            });
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(listingProvider);
    final notifier = ref.read(listingProvider.notifier);

    // Reset pagination batch when category or search changes
    if (_lastCategory != state.selectedCategory || _lastSearchQuery != state.searchQuery) {
      _lastCategory = state.selectedCategory;
      _lastSearchQuery = state.searchQuery;
      _displayedCount = 10;
      _isLoadingMore = false;
    }

    final totalFiltered = state.filteredListings.length;
    final displayItems = state.filteredListings.take(_displayedCount).toList();

    // Tally outfit counts per category and sort by popularity
    final Map<String, int> catCounts = {};
    for (final l in state.listings) {
      final c = l.category.trim();
      if (c.isNotEmpty) {
        final f = c[0].toUpperCase() + (c.length > 1 ? c.substring(1) : '');
        catCounts[f] = (catCounts[f] ?? 0) + 1;
      }
    }

    // Sort categories by outfit count descending (most popular first)
    final distinctCats = catCounts.keys.toList()
      ..sort((a, b) {
        final cA = catCounts[a] ?? 0;
        final cB = catCounts[b] ?? 0;
        if (cB != cA) return cB.compareTo(cA);
        return a.compareTo(b);
      });

    final categories = distinctCats.isNotEmpty
        ? ['All', ...distinctCats]
        : const ['All', 'Lehenga', 'Saree', 'Sherwani', 'Anarkali', 'Sharara'];

    final isAll = state.selectedCategory.toLowerCase() == 'all';
    final categoryTitle = isAll
        ? 'Curated Collection'
        : '${state.selectedCategory} Collection';

    return Scaffold(
      backgroundColor: AppColors.bgCream,
      appBar: AppBar(
        backgroundColor: AppColors.bgCream,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          categoryTitle,
          style: AppTypography.titleLarge.copyWith(fontSize: 18),
        ),
        centerTitle: true,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.ink),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
      ),
      body: Column(
        children: [
          // Search Box with Integrated Category Filter Action
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              onChanged: notifier.setSearchQuery,
              style: AppTypography.bodyMedium,
              decoration: InputDecoration(
                hintText: isAll
                    ? 'Search designer lehengas, sherwanis...'
                    : 'Search in ${state.selectedCategory}...',
                hintStyle: AppTypography.bodySmall,
                prefixIcon: const Icon(Icons.search, color: AppColors.inkMuted, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    Icons.tune_rounded,
                    color: !isAll ? AppColors.accentRose : AppColors.ink,
                    size: 20,
                  ),
                  tooltip: 'All Categories',
                  onPressed: () => _showCategoryFilterSheet(
                    context,
                    categories,
                    catCounts,
                    state.listings.length,
                    state.selectedCategory,
                    notifier,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.accentRose),
                ),
              ),
            ),
          ),

          // Clean, Elegant Horizontal Category Chips
          SizedBox(
            height: 42,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              itemBuilder: (context, i) {
                final cat = categories[i];
                final isSelected = state.selectedCategory.toLowerCase() == cat.toLowerCase();

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (_) => notifier.setCategory(cat),
                    backgroundColor: Colors.white,
                    selectedColor: AppColors.ink,
                    labelStyle: GoogleFonts.inter(
                      color: isSelected ? Colors.white : AppColors.ink,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 11.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? AppColors.ink : AppColors.border,
                      ),
                    ),
                    showCheckmark: false,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  ),
                );
              },
            ),
          ),

          // ━━━ Event Date Filter Bar ━━━
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: InkWell(
              onTap: () async {
                final now = DateTime.now();
                final firstAllowed = DateTime(now.year, now.month, now.day).add(const Duration(days: 4));
                final lastAllowed = DateTime(now.year, now.month, now.day).add(const Duration(days: 120));

                final picked = await showDatePicker(
                  context: context,
                  initialDate: state.selectedEventDate ?? firstAllowed,
                  firstDate: firstAllowed,
                  lastDate: lastAllowed,
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: AppColors.accentRose,
                          onPrimary: Colors.white,
                          onSurface: AppColors.ink,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );

                if (picked != null) {
                  notifier.setEventDate(picked);
                }
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: state.selectedEventDate != null
                      ? const Color(0xFFFDF2F4)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: state.selectedEventDate != null
                        ? AppColors.accentRose
                        : AppColors.border,
                    width: 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_month_outlined,
                      size: 15,
                      color: state.selectedEventDate != null
                          ? AppColors.accentRose
                          : AppColors.inkSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.selectedEventDate != null
                            ? 'Event Date: ${DateFormat('EEE, d MMM yyyy').format(state.selectedEventDate!)}'
                            : 'Filter by Event Date (Show outfits available for your date)',
                        style: GoogleFonts.inter(
                          color: state.selectedEventDate != null
                              ? AppColors.ink
                              : AppColors.inkSecondary,
                          fontWeight: state.selectedEventDate != null
                              ? FontWeight.w700
                              : FontWeight.w500,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (state.selectedEventDate != null)
                      GestureDetector(
                        onTap: () => notifier.setEventDate(null),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: AppColors.accentRose,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, size: 11, color: Colors.white),
                        ),
                      )
                    else
                      const Icon(Icons.arrow_drop_down, size: 18, color: AppColors.inkSecondary),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 4),

          // Catalog Grid with On-Demand Infinite Scroll Pagination
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.accentRose))
                : state.filteredListings.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.search_off, size: 48, color: AppColors.inkMuted),
                              const SizedBox(height: 12),
                              Text(
                                'No ${isAll ? "" : "${state.selectedCategory} "}outfits found',
                                style: AppTypography.titleLarge.copyWith(fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Try selecting another category or resetting the search filter.',
                                style: AppTypography.bodySmall,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                onPressed: () {
                                  notifier.setCategory('All');
                                  notifier.setSearchQuery('');
                                },
                                icon: const Icon(Icons.refresh, size: 16, color: AppColors.ink),
                                label: Text(
                                  'VIEW ALL OUTFITS',
                                  style: AppTypography.subtitleTag.copyWith(
                                    color: AppColors.ink,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: AppColors.ink),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        color: AppColors.accentRose,
                        onRefresh: () => notifier.fetchListings(),
                        child: CustomScrollView(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: [
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                              sliver: SliverGrid(
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 14,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: 0.68,
                                ),
                                delegate: SliverChildBuilderDelegate(
                                  (context, i) {
                                    final item = displayItems[i];
                                    return LuxuryCard(
                                      listing: item,
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => ProductDetailScreen(listing: item),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                  childCount: displayItems.length,
                                ),
                              ),
                            ),
                            if (_isLoadingMore)
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 20),
                                  child: Center(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const SizedBox(
                                          width: 15,
                                          height: 15,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.accentRose,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          'Loading more curated pieces...',
                                          style: GoogleFonts.inter(
                                            fontSize: 11.5,
                                            color: AppColors.inkMuted,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            else if (_displayedCount >= totalFiltered && totalFiltered > 6)
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 24),
                                  child: Center(
                                    child: Text(
                                      '• ALL $totalFiltered ARCHIVE PIECES LOADED •',
                                      style: GoogleFonts.inter(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.5,
                                        color: AppColors.inkMuted.withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // CATEGORY PICKER BOTTOM SHEET (For 50+ Categories with instant live search)
  // ─────────────────────────────────────────────────────────────────────────────
  void _showCategoryFilterSheet(
    BuildContext context,
    List<String> categories,
    Map<String, int> counts,
    int totalCount,
    String selectedCategory,
    ListingNotifier notifier,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String query = '';
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filtered = query.isEmpty
                ? categories
                : categories.where((c) => c.toLowerCase().contains(query.toLowerCase())).toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.75,
              minChildSize: 0.4,
              maxChildSize: 0.92,
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
                                  'FILTER BY CATEGORY',
                                  style: GoogleFonts.inter(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 2.0,
                                    color: AppColors.accentRose,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'All Categories (${categories.length - 1})',
                                  style: GoogleFonts.cormorantGaramond(
                                    fontSize: 22,
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
                      // Search Bar
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
                            hintText: 'Search categories...',
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
                      // Category List
                      Expanded(
                        child: filtered.isEmpty
                            ? Center(
                                child: Text(
                                  'No category matches "$query"',
                                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.inkMuted),
                                ),
                              )
                            : ListView.separated(
                                controller: scrollController,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                itemCount: filtered.length,
                                separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.borderLight),
                                itemBuilder: (context, idx) {
                                  final cat = filtered[idx];
                                  final isSelected = selectedCategory.toLowerCase() == cat.toLowerCase();
                                  final count = cat == 'All' ? totalCount : (counts[cat] ?? 0);

                                  return ListTile(
                                    onTap: () {
                                      Navigator.of(context).pop();
                                      notifier.setCategory(cat);
                                    },
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                    title: Text(
                                      cat == 'All' ? 'All Collections' : cat,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                        color: isSelected ? AppColors.accentRose : AppColors.ink,
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: isSelected ? AppColors.accentRose.withValues(alpha: 0.1) : Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: isSelected ? AppColors.accentRose : AppColors.border,
                                            ),
                                          ),
                                          child: Text(
                                            '$count items',
                                            style: GoogleFonts.inter(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w600,
                                              color: isSelected ? AppColors.accentRose : AppColors.inkMuted,
                                            ),
                                          ),
                                        ),
                                        if (isSelected) ...[
                                          const SizedBox(width: 8),
                                          const Icon(Icons.check_circle_rounded, color: AppColors.accentRose, size: 18),
                                        ],
                                      ],
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
}
