import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../models/listing_model.dart';
import 'auth_provider.dart';

final listingProvider = StateNotifierProvider<ListingNotifier, ListingState>((ref) {
  final client = ref.watch(apiClientProvider);
  return ListingNotifier(client);
});

class ListingState {
  final bool isLoading;
  final List<ListingModel> listings;
  final String selectedCategory;
  final String searchQuery;
  final DateTime? selectedEventDate;
  final String? error;

  const ListingState({
    this.isLoading = false,
    this.listings = const [],
    this.selectedCategory = 'All',
    this.searchQuery = '',
    this.selectedEventDate,
    this.error,
  });

  List<ListingModel> get filteredListings {
    return listings.where((item) {
      final matchesCat = selectedCategory == 'All' ||
          item.category.toLowerCase() == selectedCategory.toLowerCase();
      final matchesSearch = searchQuery.isEmpty ||
          item.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          item.description.toLowerCase().contains(searchQuery.toLowerCase());
      final matchesDate = selectedEventDate == null || item.isDateAvailable(selectedEventDate!);
      return matchesCat && matchesSearch && matchesDate;
    }).toList();
  }

  ListingState copyWith({
    bool? isLoading,
    List<ListingModel>? listings,
    String? selectedCategory,
    String? searchQuery,
    DateTime? selectedEventDate,
    bool clearEventDate = false,
    String? error,
  }) {
    return ListingState(
      isLoading: isLoading ?? this.isLoading,
      listings: listings ?? this.listings,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedEventDate: clearEventDate ? null : (selectedEventDate ?? this.selectedEventDate),
      error: error,
    );
  }
}

class ListingNotifier extends StateNotifier<ListingState> {
  final ApiClient _client;

  ListingNotifier(this._client) : super(const ListingState()) {
    fetchListings();
  }

  Future<void> fetchListings([DateTime? eventDate]) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final queryParams = <String, dynamic>{};
      final dateToQuery = eventDate ?? state.selectedEventDate;
      if (dateToQuery != null) {
        queryParams['eventDate'] = dateToQuery.toIso8601String().split('T')[0];
      }

      final res = await _client.dio.get('/products', queryParameters: queryParams.isNotEmpty ? queryParams : null);
      if (res.statusCode == 200) {
        dynamic data = res.data;
        if (data is String) {
          data = jsonDecode(data);
        }
        List raw = [];
        if (data is Map) {
          if (data['products'] is List && (data['products'] as List).isNotEmpty) {
            raw = data['products'] as List;
          } else if (data['listings'] is List && (data['listings'] as List).isNotEmpty) {
            raw = data['listings'] as List;
          }
        }
        if (raw.isNotEmpty) {
          final list = <ListingModel>[];
          for (final j in raw) {
            try {
              if (j is Map) {
                list.add(ListingModel.fromJson(Map<String, dynamic>.from(j)));
              }
            } catch (err) {
              // Ignore single malformed product and proceed
            }
          }
          state = state.copyWith(isLoading: false, listings: list);
          return;
        }
      }
      state = state.copyWith(isLoading: false, listings: []);
    } catch (e) {
      state = state.copyWith(isLoading: false, listings: [], error: e.toString());
    }
  }

  void setCategory(String cat) {
    state = state.copyWith(selectedCategory: cat);
  }

  void setSearchQuery(String q) {
    state = state.copyWith(searchQuery: q);
  }

  void setEventDate(DateTime? date) {
    if (date == null) {
      state = state.copyWith(clearEventDate: true);
      fetchListings(null);
    } else {
      state = state.copyWith(selectedEventDate: date);
      fetchListings(date);
    }
  }
}
