import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/data/secure_storage.dart';

part 'dio_provider.g.dart';

// Use WSL2 IP for Android emulator running on Windows
// localhost won't work - emulator can't reach WSL2's localhost
// To find WSL2 IP: hostname -I | awk '{print $1}'
const String _baseUrl = 'http://172.22.115.44:3001/api/v1';

/// Provides the base Dio instance with auth interceptor
@riverpod
Dio dio(Ref ref) {
  // Create secure storage directly to avoid circular dependency
  // (authNotifier -> authRepository -> authApi -> dio -> authNotifier)
  const storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  final dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Skip auth header for auth endpoints
        final path = options.path;
        final isAuthEndpoint = path.contains('/auth/');

        if (!isAuthEndpoint) {
          final token = await storage.read(key: SecureStorageKeys.accessToken);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        // Handle 401 errors - token expired
        if (error.response?.statusCode == 401) {
          // For MVP: just pass through the error
          // In production: attempt token refresh and retry
          // final refreshToken = await storage.read(key: SecureStorageKeys.refreshToken);
          // if (refreshToken != null) { ... retry logic ... }
        }
        handler.next(error);
      },
    ),
  );

  return dio;
}
