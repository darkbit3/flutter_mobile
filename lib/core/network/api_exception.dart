import 'package:dio/dio.dart';

/// Wraps a [DioException] into a clean user-friendly message.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int?   statusCode;

  factory ApiException.fromDio(DioException e) {
    // Connection refused / no network
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.unknown) {
      return ApiException(
        'Cannot connect to server. Check your internet connection and try again.',
        statusCode: null,
      );
    }

    // Timeout — Render free tier wakes up slowly
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return ApiException(
        'Server is starting up, please try again in a few seconds.',
        statusCode: null,
      );
    }

    // Server returned a response with error status
    final code      = e.response?.statusCode;
    final serverMsg = e.response?.data is Map
        ? (e.response!.data as Map)['message'] as String?
        : null;

    // Map common HTTP codes to friendly messages if server didn't send one
    final fallback = switch (code) {
      400 => 'Invalid request. Please check your input.',
      401 => 'Invalid phone number or password.',
      403 => 'Access denied.',
      404 => 'Resource not found.',
      409 => 'This phone number is already registered.',
      429 => 'Too many attempts. Please wait and try again.',
      500 => 'Server error. Please try again later.',
      _   => 'An unexpected error occurred.',
    };

    return ApiException(serverMsg ?? fallback, statusCode: code);
  }

  /// Returns only the clean message — no class name prefix.
  @override
  String toString() => message;
}
