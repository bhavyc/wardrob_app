import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  static const String _storageTokenKey = 'auth_token';

  // 10.128.69.48 is the active USB Tether (Ethernet 4) IP; 192.168.88.7 is Wi-Fi LAN; 10.0.2.2 is Android Emulator
  static const String emulatorBaseUrl = 'http://10.0.2.2:3000/api';
  static const String physicalDeviceBaseUrl = 'http://10.128.69.48:3000/api';
  static const String usbTetherBaseUrl = 'http://10.128.69.48:3000/api';
  static const String wifiLanBaseUrl = 'http://192.168.88.7:3000/api';
  static const String productionBaseUrl = 'https://wardrob.in/api';
  static const String defaultBaseUrl = 'http://127.0.0.1:3000/api';
  static const String lanBaseUrl = 'http://10.128.69.48:3000/api';

  static final List<String> availableUrls = kReleaseMode
      ? [productionBaseUrl]
      : [
          usbTetherBaseUrl,
          wifiLanBaseUrl,
          emulatorBaseUrl,
          defaultBaseUrl,
          physicalDeviceBaseUrl,
        ];

  static String activeBaseUrl = kReleaseMode ? productionBaseUrl : usbTetherBaseUrl;

  final Dio dio;
  final FlutterSecureStorage secureStorage;

  ApiClient({Dio? customDio, FlutterSecureStorage? customStorage})
      : dio = customDio ??
            Dio(BaseOptions(
              baseUrl: activeBaseUrl,
              connectTimeout: const Duration(seconds: 4),
              receiveTimeout: const Duration(seconds: 4),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
            )),
        secureStorage = customStorage ?? const FlutterSecureStorage() {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await secureStorage.read(key: _storageTokenKey);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
            options.headers['Cookie'] = 'auth_token=$token';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (DioException error, handler) async {
          if (error.response?.statusCode == 401) {
            // Auto logout or token expiration handling
            await secureStorage.delete(key: _storageTokenKey);
            return handler.next(error);
          }

          // Fallback connection retry across candidate endpoints (ADB reverse -> USB tether -> Wi-Fi LAN)
          final isConnectionErr = error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.connectionError;

          if (isConnectionErr) {
            final tried = (error.requestOptions.extra['retry_candidate_index'] as int?) ?? 0;
            if (tried < availableUrls.length) {
              for (int i = 0; i < availableUrls.length; i++) {
                final candidate = availableUrls[i];
                if (candidate == error.requestOptions.baseUrl) continue;

                error.requestOptions.extra['retry_candidate_index'] = tried + 1;
                dio.options.baseUrl = candidate;
                error.requestOptions.baseUrl = candidate;

                try {
                  final response = await dio.fetch(error.requestOptions);
                  activeBaseUrl = candidate;
                  return handler.resolve(response);
                } catch (_) {
                  // Continue to next candidate
                }
              }
              // Reset back to active
              dio.options.baseUrl = activeBaseUrl;
            }
          }

          return handler.next(error);
        },
      ),
    );
  }

  Future<void> saveAuthToken(String token) async {
    await secureStorage.write(key: _storageTokenKey, value: token);
  }

  Future<String?> getAuthToken() async {
    return await secureStorage.read(key: _storageTokenKey);
  }

  Future<void> clearAuthToken() async {
    await secureStorage.delete(key: _storageTokenKey);
  }
}
