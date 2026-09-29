import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../models/user_model.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final client = ref.watch(apiClientProvider);
  return AuthNotifier(client);
});

class AuthState {
  final bool isLoading;
  final UserModel? user;
  final String? error;

  const AuthState({
    this.isLoading = false,
    this.user,
    this.error,
  });

  bool get isAuthenticated => user != null;
  bool get isLister => user?.role == UserRole.lister;
  bool get isRenter => user?.role == UserRole.renter;

  AuthState copyWith({
    bool? isLoading,
    UserModel? user,
    String? error,
    bool clearUser = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: clearUser ? null : (user ?? this.user),
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _client;

  AuthNotifier(this._client) : super(const AuthState(isLoading: true)) {
    checkCurrentSession();
  }

  Future<void> checkCurrentSession() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final token = await _client.getAuthToken();
      if (token == null || token.isEmpty) {
        state = state.copyWith(isLoading: false, clearUser: true);
        return;
      }

      // Fetch user profile from API /auth/session
      final res = await _client.dio.get('/auth/session');
      if (res.statusCode == 200 && res.data['user'] != null) {
        final u = UserModel.fromJson(res.data['user']);
        state = state.copyWith(isLoading: false, user: u);
      } else {
        await _client.clearAuthToken();
        state = state.copyWith(isLoading: false, clearUser: true);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> login({
    required String email,
    required String password,
    bool asLister = false,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      const endpoint = '/auth/password/login';
      final res = await _client.dio.post(endpoint, data: {
        'email': email,
        'password': password,
      });

      if (res.statusCode == 200 && res.data['success'] == true) {
        final token = res.data['token']?.toString();
        if (token != null && token.isNotEmpty) {
          await _client.saveAuthToken(token);
        }

        final userData = res.data['user'] as Map<String, dynamic>;
        final u = UserModel.fromJson(userData);

        if (asLister && u.role != UserRole.lister) {
          state = state.copyWith(
            isLoading: false,
            error: 'This account is registered as RENTER. Please log in through Renter portal.',
          );
          return false;
        }

        state = state.copyWith(isLoading: false, user: u);
        return true;
      } else {
        final err = res.data['error']?.toString() ?? 'Invalid credentials.';
        state = state.copyWith(isLoading: false, error: err);
        return false;
      }
    } catch (e) {
      String errorMessage = 'Connection failed. Please check network.';
      if (e is DioException) {
        final resp = e.response?.data;
        if (resp is Map && resp['error'] != null) {
          errorMessage = resp['error'].toString();
        } else if (e.message != null && e.message!.isNotEmpty) {
          errorMessage = e.message!;
        }
      }
      state = state.copyWith(isLoading: false, error: errorMessage);
      return false;
    }
  }

  Future<bool> registerRenter({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
    required String aadhaarNumber,
    required String panNumber,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _client.dio.post('/auth/register', data: {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'confirmPassword': confirmPassword,
        'aadhaarNumber': aadhaarNumber,
        'panNumber': panNumber,
      });

      if (res.statusCode == 200 && res.data['success'] == true) {
        return await login(email: email, password: password, asLister: false);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: res.data['error']?.toString() ?? 'Registration failed',
        );
        return false;
      }
    } catch (e) {
      String errorMessage = 'Registration failed. Please check your details.';
      if (e is DioException) {
        final resp = e.response?.data;
        if (resp is Map && resp['error'] != null) {
          errorMessage = resp['error'].toString();
        } else if (e.message != null && e.message!.isNotEmpty) {
          errorMessage = e.message!;
        }
      }
      state = state.copyWith(isLoading: false, error: errorMessage);
      return false;
    }
  }

  Future<bool> registerLister({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String shopName,
    required String bio,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _client.dio.post('/lister/register', data: {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'shopName': shopName,
        'bio': bio,
      });

      if (res.statusCode == 200 && res.data['success'] == true) {
        final token = res.data['token']?.toString();
        if (token != null && token.isNotEmpty) {
          await _client.saveAuthToken(token);
        }
        if (res.data['user'] != null) {
          final u = UserModel.fromJson(res.data['user']);
          state = state.copyWith(isLoading: false, user: u, error: null);
          return true;
        }
        return await login(email: email, password: password, asLister: true);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: res.data['error']?.toString() ?? 'Lister registration failed',
        );
        return false;
      }
    } catch (e) {
      String errorMessage = 'Registration failed. Please check your details.';
      if (e is DioException) {
        final resp = e.response?.data;
        if (resp is Map && resp['error'] != null) {
          errorMessage = resp['error'].toString();
        } else if (e.message != null && e.message!.isNotEmpty) {
          errorMessage = e.message!;
        }
      }
      state = state.copyWith(isLoading: false, error: errorMessage);
      return false;
    }
  }

  Future<Map<String, dynamic>> sendForgotPasswordCode(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _client.dio.post('/auth/password/forgot', data: {
        'email': email.trim().toLowerCase(),
      });
      state = state.copyWith(isLoading: false);
      if (res.statusCode == 200 && res.data['success'] == true) {
        return {
          'success': true,
          'message': res.data['message']?.toString() ?? 'Reset code sent to your email.',
        };
      }
      return {
        'success': false,
        'error': res.data['error']?.toString() ?? 'Failed to send reset code.',
      };
    } catch (e) {
      String msg = 'Could not connect to server. Please try again.';
      if (e is DioException && e.response?.data is Map) {
        msg = e.response?.data['error']?.toString() ?? msg;
      }
      state = state.copyWith(isLoading: false, error: msg);
      return {'success': false, 'error': msg};
    }
  }

  Future<Map<String, dynamic>> resetPasswordWithCode({
    required String code,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _client.dio.post('/auth/password/reset', data: {
        'token': code.trim(),
        'newPassword': newPassword,
      });
      state = state.copyWith(isLoading: false);
      if (res.statusCode == 200 && res.data['success'] == true) {
        return {
          'success': true,
          'message': res.data['message']?.toString() ?? 'Password reset successfully.',
        };
      }
      return {
        'success': false,
        'error': res.data['error']?.toString() ?? 'Failed to reset password.',
      };
    } catch (e) {
      String msg = 'Failed to reset password. Please check your code.';
      if (e is DioException && e.response?.data is Map) {
        msg = e.response?.data['error']?.toString() ?? msg;
      }
      state = state.copyWith(isLoading: false, error: msg);
      return {'success': false, 'error': msg};
    }
  }

  void clearError() {
    if (state.error != null) {
      state = state.copyWith(error: null);
    }
  }

  Future<Map<String, dynamic>> deleteAccount() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _client.dio.post('/auth/delete-account');
      state = state.copyWith(isLoading: false);
      if (res.statusCode == 200 && res.data['success'] == true) {
        await _client.clearAuthToken();
        state = const AuthState();
        return {
          'success': true,
          'message': res.data['message']?.toString() ?? 'Account deleted successfully.',
        };
      }
      return {
        'success': false,
        'error': res.data['error']?.toString() ?? 'Failed to delete account.',
      };
    } catch (e) {
      String msg = 'Could not connect to server. Please try again.';
      if (e is DioException && e.response?.data is Map) {
        msg = e.response?.data['error']?.toString() ?? msg;
      }
      state = state.copyWith(isLoading: false, error: msg);
      return {'success': false, 'error': msg};
    }
  }

  Future<void> logout() async {
    try {
      await _client.dio.post('/auth/logout');
    } catch (_) {}
    await _client.clearAuthToken();
    state = const AuthState();
  }
}
