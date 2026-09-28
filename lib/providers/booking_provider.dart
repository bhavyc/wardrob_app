import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../models/booking_model.dart';
import 'auth_provider.dart';

String _extractError(dynamic e, String fallback) {
  if (e is DioException) {
    if (e.response?.data is Map && e.response?.data['error'] != null) {
      return e.response!.data['error'].toString();
    }
    if (e.message != null && e.message!.isNotEmpty) {
      return e.message!;
    }
  }
  return e.toString();
}

final renterBookingsProvider =
    StateNotifierProvider<RenterBookingsNotifier, AsyncValue<List<BookingModel>>>((ref) {
  final client = ref.watch(apiClientProvider);
  ref.watch(authProvider);
  return RenterBookingsNotifier(client);
});

class RenterBookingsNotifier extends StateNotifier<AsyncValue<List<BookingModel>>> {
  final ApiClient _client;

  RenterBookingsNotifier(this._client) : super(const AsyncValue.loading()) {
    fetchBookings();
  }

  Future<void> fetchBookings() async {
    state = const AsyncValue.loading();
    try {
      final res = await _client.dio.get('/user/bookings');
      if (res.statusCode == 200 && res.data['bookings'] is List) {
        final list = (res.data['bookings'] as List)
            .map((b) => BookingModel.fromJson(b as Map<String, dynamic>))
            .toList();
        state = AsyncValue.data(list);
        return;
      }
      state = const AsyncValue.data([]);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Map<String, dynamic>> createBookingOrder({
    required String productId,
    required DateTime eventDate,
    int extensionDays = 0,
    bool useWallet = false,
    String? shippingAddress,
    String? city,
    String? state,
    String? pincode,
    String? contactPhone,
    String? contactName,
  }) async {
    try {
      final payload = <String, dynamic>{
        'productId': productId,
        'eventDate': eventDate.toIso8601String(),
        'extensionDays': extensionDays,
        'useWallet': useWallet,
      };
      if (shippingAddress != null) payload['shippingAddress'] = shippingAddress;
      if (city != null) payload['city'] = city;
      if (state != null) payload['state'] = state;
      if (pincode != null) payload['pincode'] = pincode;
      if (contactPhone != null) payload['contactPhone'] = contactPhone;
      if (contactName != null) payload['contactName'] = contactName;

      final res = await _client.dio.post('/checkout/razorpay/order', data: payload);

      if (res.statusCode == 200 && res.data['success'] == true) {
        await fetchBookings();
        return {
          'success': true,
          'isWalletFullPayment': res.data['isWalletFullPayment'] == true,
          'orderId': res.data['orderId'],
          'bookingId': res.data['bookingId'],
          'amount': res.data['amount'],
          'key': res.data['keyId'] ?? res.data['key'],
          'grossTotal': res.data['grossTotal'],
          'walletDeducted': res.data['walletDeducted'],
          'finalPayable': res.data['finalPayable'],
        };
      } else {
        return {
          'success': false,
          'error': res.data['error'] ?? 'Order creation failed.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': _extractError(e, 'Order creation failed.'),
      };
    }
  }

  Future<Map<String, dynamic>> verifyBookingPayment({
    required String orderId,
    required String paymentId,
    required String signature,
    String? productId,
  }) async {
    try {
      final payload = <String, dynamic>{
        'razorpay_order_id': orderId,
        'razorpay_payment_id': paymentId,
        'razorpay_signature': signature,
      };
      if (productId != null) {
        payload['productId'] = productId;
      }
      final res = await _client.dio.post('/checkout/razorpay/verify', data: payload);

      if (res.statusCode == 200 && res.data['success'] == true) {
        await fetchBookings();
        return {
          'success': true,
          'message': res.data['message'] ?? 'Payment verified successfully.',
          'booking': res.data['booking'],
        };
      } else {
        return {
          'success': false,
          'error': res.data['error'] ?? 'Payment verification failed.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': _extractError(e, 'Payment verification failed.'),
      };
    }
  }
}

final listerBookingsProvider =
    StateNotifierProvider<ListerBookingsNotifier, AsyncValue<List<BookingModel>>>((ref) {
  final client = ref.watch(apiClientProvider);
  ref.watch(authProvider);
  return ListerBookingsNotifier(client);
});

class ListerBookingsNotifier extends StateNotifier<AsyncValue<List<BookingModel>>> {
  final ApiClient _client;

  ListerBookingsNotifier(this._client) : super(const AsyncValue.loading()) {
    fetchBookings();
  }

  Future<void> fetchBookings() async {
    state = const AsyncValue.loading();
    try {
      final res = await _client.dio.get('/lister/bookings');
      if (res.statusCode == 200 && res.data['bookings'] is List) {
        final list = (res.data['bookings'] as List)
            .map((b) => BookingModel.fromJson(b as Map<String, dynamic>))
            .toList();
        state = AsyncValue.data(list);
        return;
      }
      state = const AsyncValue.data([]);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Map<String, dynamic>> markPacked(String bookingId) async {
    try {
      final res = await _client.dio.post('/shipments/pickup', data: {
        'bookingId': bookingId,
      });
      if (res.statusCode == 200 && res.data['success'] == true) {
        await fetchBookings();
        return {
          'success': true,
          'message': res.data['message'] ?? 'Pickup requested from Lister to Hub.',
        };
      }
      return {
        'success': false,
        'error': res.data['error'] ?? 'Failed to request pickup.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': _extractError(e, 'Failed to request pickup.'),
      };
    }
  }
}
