import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/data/secure_storage.dart';

part 'dio_provider.g.dart';

// API URL configuration via --dart-define
// Emulator: flutter run --dart-define=API_HOST=10.0.2.2
// Real device: flutter run --dart-define=API_HOST=192.168.1.100
// Backend (default): port 8080
// Mock API: flutter run --dart-define=API_PORT=3001
const String _apiHost = String.fromEnvironment(
  'API_HOST',
  defaultValue: '10.0.2.2',
);
const String _apiPort = String.fromEnvironment(
  'API_PORT',
  defaultValue: '8080',
);
const String _baseUrl = 'http://$_apiHost:$_apiPort/api/v1';

// Debug flag - set to true to see API calls in console
const bool _debugApi = true;

/// Provides the base Dio instance with auth interceptor
/// keepAlive: true because Dio should persist for the app lifetime
@Riverpod(keepAlive: true)
Dio dio(Ref ref) {
  if (_debugApi) {
    developer.log('🔧 API Base URL: $_baseUrl', name: 'api');
  }

  // Create secure storage directly to avoid circular dependency
  // (authNotifier -> authRepository -> authApi -> dio -> authNotifier)
  const storage = FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  final dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 60), // For file uploads
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Skip auth header for public auth endpoints only
        final path = options.path;
        final isPublicAuthEndpoint =
            path.contains('/auth/member/login') ||
            path.contains('/auth/refresh') ||
            path.contains('/auth/admin/login');

        if (!isPublicAuthEndpoint) {
          final token = await storage.read(key: SecureStorageKeys.accessToken);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }

        if (_debugApi) {
          developer.log(
            '🌐 API REQUEST: ${options.method} ${options.baseUrl}${options.path}',
            name: 'api',
          );
          developer.log('📦 Data: ${options.data}', name: 'api');
        }

        handler.next(options);
      },
      onResponse: (response, handler) {
        if (_debugApi) {
          developer.log(
            '✅ API RESPONSE: ${response.statusCode} ${response.requestOptions.path}',
            name: 'api',
          );
          developer.log('📦 Data: ${response.data}', name: 'api');
        }
        handler.next(response);
      },
      onError: (error, handler) async {
        if (_debugApi) {
          developer.log(
            '❌ API ERROR: ${error.response?.statusCode} ${error.requestOptions.path}',
            name: 'api',
          );
          developer.log(
            '📦 Error: ${error.response?.data ?? error.message}',
            name: 'api',
          );
        }

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
