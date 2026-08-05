import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';

const _storage = FlutterSecureStorage(
  aOptions: AndroidOptions(
    encryptedSharedPreferences: true,
  ),
);

/// Provider for the configured [Dio] instance.
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl:        ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 60), // generous for Render cold-start
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout:    const Duration(seconds: 30),
      headers:        {'Content-Type': 'application/json'},
    ),
  );

  dio.interceptors.add(_AuthInterceptor());

  // Log requests / responses in debug builds only
  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(
        requestBody:  true,
        responseBody: true,
        logPrint:     (msg) => debugPrint('[DIO] $msg'),
      ),
    );
  }

  return dio;
});

/// Silently pings the backend so the Render free-tier server wakes up
/// before the user tries to log in.  Call this as early as possible.
Future<void> warmUpServer() async {
  try {
    await Dio().get(
      '${ApiConstants.baseUrl}/health',
      options: Options(
        sendTimeout:    const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 60),
        headers: {'Content-Type': 'application/json'},
      ),
    );
  } catch (_) {
    // Ignore — this is a best-effort warm-up ping
  }
}

/// Attaches the stored access token to every request.
/// On 401 — clears tokens so the router redirects to login.
class _AuthInterceptor extends QueuedInterceptorsWrapper {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read(key: 'access_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Log the error with full context in debug mode
    if (kDebugMode) {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('🔴 [DIO] ${err.requestOptions.method} '
          '${err.requestOptions.path}');
      debugPrint('   Status : ${err.response?.statusCode}');
      debugPrint('   Type   : ${err.type}');
      debugPrint('   Message: ${err.message}');
      if (err.response?.data != null) {
        debugPrint('   Body   : ${err.response?.data}');
      }
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }

    if (err.response?.statusCode == 401) {
      // Token expired or invalid — clear storage, router will redirect to login
      await _storage.deleteAll();
    }

    handler.next(err);
  }
}
