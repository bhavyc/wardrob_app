import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../models/listing_model.dart';
import '../models/payout_model.dart';
import 'auth_provider.dart';

class ListerProfileModel {
  final String id;
  final String userId;
  final String? shopName;
  final String? bio;
  final String? aadhaarNumber;
  final String? panNumber;
  final String? bankAccountNo;
  final String? bankIfsc;
  final String status;
  final double? commissionOverride;
  final bool registrationFeePaid;
  final int listingsCount;
  final int payoutsCount;
  final double? userRating;
  final double walletBalance;
  final String? userName;
  final String? userEmail;
  final String? userPhone;

  const ListerProfileModel({
    required this.id,
    required this.userId,
    this.shopName,
    this.bio,
    this.aadhaarNumber,
    this.panNumber,
    this.bankAccountNo,
    this.bankIfsc,
    this.status = 'PENDING',
    this.commissionOverride,
    this.registrationFeePaid = false,
    this.listingsCount = 0,
    this.payoutsCount = 0,
    this.userRating,
    this.walletBalance = 0.0,
    this.userName,
    this.userEmail,
    this.userPhone,
  });

  factory ListerProfileModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? {};
    final count = json['_count'] as Map<String, dynamic>? ?? {};
    return ListerProfileModel(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      shopName: json['shopName']?.toString(),
      bio: json['bio']?.toString(),
      aadhaarNumber: json['aadhaarNumber']?.toString(),
      panNumber: json['panNumber']?.toString(),
      bankAccountNo: json['bankAccountNo']?.toString(),
      bankIfsc: json['bankIfsc']?.toString(),
      status: json['status']?.toString().toUpperCase() ?? 'PENDING',
      commissionOverride: json['commissionOverride'] != null
          ? double.tryParse(json['commissionOverride'].toString())
          : null,
      registrationFeePaid: json['registrationFeePaid'] == true,
      listingsCount: int.tryParse(count['listings']?.toString() ?? '0') ?? 0,
      payoutsCount: int.tryParse(count['payouts']?.toString() ?? '0') ?? 0,
      userRating: user['rating'] != null ? double.tryParse(user['rating'].toString()) : null,
      walletBalance: user['walletBalance'] != null
          ? double.tryParse(user['walletBalance'].toString()) ?? 0.0
          : 0.0,
      userName: user['name']?.toString(),
      userEmail: user['email']?.toString(),
      userPhone: user['phone']?.toString(),
    );
  }
}

class ListerState {
  final bool isLoading;
  final ListerProfileModel? profile;
  final List<ListingModel> listings;
  final List<PayoutModel> payouts;
  final double totalSettled;
  final double totalPending;
  final bool isOnboarded;
  final String? error;

  const ListerState({
    this.isLoading = false,
    this.profile,
    this.listings = const [],
    this.payouts = const [],
    this.totalSettled = 0.0,
    this.totalPending = 0.0,
    this.isOnboarded = true,
    this.error,
  });

  ListerState copyWith({
    bool? isLoading,
    ListerProfileModel? profile,
    List<ListingModel>? listings,
    List<PayoutModel>? payouts,
    double? totalSettled,
    double? totalPending,
    bool? isOnboarded,
    String? error,
  }) {
    return ListerState(
      isLoading: isLoading ?? this.isLoading,
      profile: profile ?? this.profile,
      listings: listings ?? this.listings,
      payouts: payouts ?? this.payouts,
      totalSettled: totalSettled ?? this.totalSettled,
      totalPending: totalPending ?? this.totalPending,
      isOnboarded: isOnboarded ?? this.isOnboarded,
      error: error,
    );
  }
}

final listerProvider = StateNotifierProvider<ListerNotifier, ListerState>((ref) {
  final client = ref.watch(apiClientProvider);
  ref.watch(authProvider); // Automatically re-initialize on login/logout state change
  return ListerNotifier(client);
});

class ListerNotifier extends StateNotifier<ListerState> {
  final ApiClient _client;

  ListerNotifier(this._client) : super(const ListerState()) {
    refreshAll();
  }

  Future<void> refreshAll() async {
    state = state.copyWith(isLoading: true, error: null);
    await Future.wait([
      fetchProfile(),
      fetchListings(),
      fetchPayouts(),
    ]);
    state = state.copyWith(isLoading: false);
  }

  Future<void> fetchProfile() async {
    try {
      final res = await _client.dio.get('/lister/profile');
      if (res.statusCode == 200 && res.data['success'] == true && res.data['profile'] != null) {
        final prof = ListerProfileModel.fromJson(res.data['profile'] as Map<String, dynamic>);
        state = state.copyWith(
          profile: prof,
          isOnboarded: prof.registrationFeePaid && prof.status == 'APPROVED',
        );
      }
    } catch (e) {
      debugPrint('[ListerNotifier] fetchProfile error: $e');
    }
  }

  Future<void> fetchListings() async {
    try {
      final res = await _client.dio.get('/lister/listings');
      if (res.statusCode == 200 && res.data['listings'] is List) {
        final list = (res.data['listings'] as List)
            .map((j) => ListingModel.fromJson(j as Map<String, dynamic>))
            .toList();
        state = state.copyWith(
          listings: list,
          isOnboarded: res.data['isOnboarded'] == true,
        );
      }
    } catch (e) {
      debugPrint('[ListerNotifier] fetchListings error: $e');
    }
  }

  Future<void> fetchPayouts() async {
    try {
      final res = await _client.dio.get('/lister/payouts');
      if (res.statusCode == 200 && res.data['payouts'] is List) {
        final list = (res.data['payouts'] as List)
            .map((j) => PayoutModel.fromJson(j as Map<String, dynamic>))
            .toList();

        final stats = res.data['stats'] as Map<String, dynamic>? ?? {};
        final settled = double.tryParse(stats['totalSettled']?.toString() ?? '0') ?? 0.0;
        final pending = double.tryParse(stats['totalPending']?.toString() ?? '0') ?? 0.0;

        state = state.copyWith(
          payouts: list,
          totalSettled: settled,
          totalPending: pending,
        );
      }
    } catch (e) {
      debugPrint('[ListerNotifier] fetchPayouts error: $e');
    }
  }

  Future<bool> createListing({
    required String title,
    required String description,
    required String category,
    required String size,
    required String condition,
    required double rentalPrice,
    required double securityDeposit,
    required List<String> images,
  }) async {
    try {
      final res = await _client.dio.post('/products', data: {
        'title': title,
        'description': description,
        'category': category,
        'size': size,
        'condition': condition,
        'rentalPrice': rentalPrice,
        'securityDeposit': securityDeposit,
        'baselineImages': images,
      });

      if (res.statusCode == 200 && res.data['success'] == true) {
        await fetchListings();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> createRegistrationFeeOrder() async {
    try {
      final res = await _client.dio.post('/lister/registration-fee/order');
      if (res.statusCode == 200 && res.data['success'] == true) {
        return {
          'success': true,
          'amount': res.data['amount'],
          'orderId': res.data['razorpayOrder']?['orderId'],
          'currency': res.data['razorpayOrder']?['currency'] ?? 'INR',
          'keyId': res.data['razorpayOrder']?['keyId'],
        };
      }
      return {
        'success': false,
        'error': res.data['error']?.toString() ?? 'Failed to create payment order.',
      };
    } catch (e) {
      debugPrint('[ListerNotifier] createRegistrationFeeOrder error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> verifyRegistrationFee({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    try {
      final res = await _client.dio.post('/lister/registration-fee/verify', data: {
        'razorpay_order_id': razorpayOrderId,
        'razorpay_payment_id': razorpayPaymentId,
        'razorpay_signature': razorpaySignature,
      });
      if (res.statusCode == 200 && res.data['success'] == true) {
        await fetchProfile();
        return {
          'success': true,
          'message': res.data['message']?.toString() ?? 'Registration fee verified successfully.',
        };
      }
      return {
        'success': false,
        'error': res.data['error']?.toString() ?? 'Payment verification failed.',
      };
    } catch (e) {
      debugPrint('[ListerNotifier] verifyRegistrationFee error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> submitKyc({
    required String aadhaarNumber,
    required String panNumber,
    required String bankAccountNo,
    required String bankIfsc,
  }) async {
    try {
      final res = await _client.dio.post('/lister/kyc', data: {
        'aadhaarNumber': aadhaarNumber,
        'panNumber': panNumber,
        'bankAccountNo': bankAccountNo,
        'bankIfsc': bankIfsc,
      });
      if (res.statusCode == 200 && res.data['success'] == true) {
        await fetchProfile();
        return {
          'success': true,
          'message': res.data['message']?.toString() ?? 'KYC submitted successfully.',
        };
      }
      return {
        'success': false,
        'error': res.data['error']?.toString() ?? 'Failed to submit KYC details.',
      };
    } catch (e) {
      debugPrint('[ListerNotifier] submitKyc error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> withdrawListing(String listingId) async {
    try {
      final res = await _client.dio.post('/lister/listings/$listingId/withdraw');
      if (res.statusCode == 200 && res.data['success'] == true) {
        await fetchListings();
        return {
          'success': true,
          'message': res.data['message'] ?? 'Withdrawal initiated. Courier will return item to your address.',
        };
      }
      return {
        'success': false,
        'error': res.data['error'] ?? 'Failed to withdraw item from Hub.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> toggleListingStatus(String listingId, {String? targetStatus}) async {
    try {
      final payload = <String, dynamic>{};
      if (targetStatus != null) {
        payload['status'] = targetStatus;
      }
      final res = await _client.dio.patch('/lister/listings/$listingId/status', data: payload);
      if (res.statusCode == 200 && res.data['success'] == true) {
        await fetchListings();
        return {
          'success': true,
          'message': res.data['message'] ?? 'Status updated successfully.',
          'status': res.data['status'],
        };
      }
      return {
        'success': false,
        'error': res.data['error'] ?? 'Failed to update outfit status.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}

