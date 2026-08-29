import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../models/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioProvider));
});

class AuthRepository {
  AuthRepository(this._dio);

  final Dio _dio;
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  /// Login as a Manufacturer / Reseller user.
  Future<UserModel> login(String phone, String password) async {
    try {
      final res = await _dio.post(
        ApiConstants.userLogin,
        data: {'phone': phone, 'password': password},
      );
      final data = res.data['data'] as Map<String, dynamic>;
      await _storage.write(
          key: 'access_token',  value: data['accessToken']  as String);
      await _storage.write(
          key: 'refresh_token', value: data['refreshToken'] as String);
      return UserModel.fromJson(data['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Clear tokens (logout is local-only for users).
  Future<void> logout() async {
    await _storage.deleteAll();
  }

  /// Get the currently logged-in user's profile.
  Future<UserModel> getMe() async {
    try {
      final res = await _dio.get(ApiConstants.userMe);
      return UserModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Change password.
  Future<void> changePassword(String current, String next) async {
    try {
      await _dio.put(
        ApiConstants.userChangePassword,
        data: {'currentPassword': current, 'newPassword': next},
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Update alert threshold percentage for low stock (5-100).
  Future<void> updateAlertThreshold(double threshold) async {
    try {
      await _dio.put(
        ApiConstants.userAlertThreshold,
        data: {'threshold': threshold},
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Returns true if an access token is stored.
  Future<bool> hasToken() async {
    final token = await _storage.read(key: 'access_token');
    return token != null;
  }

  /// Step 1 — check phone exists, get OTP issued (returns otp in dev mode).
  Future<Map<String, dynamic>> forgotPasswordCheckPhone(String phone) async {
    try {
      final res = await _dio.post(
        ApiConstants.forgotPasswordCheckPhone,
        data: {'phone': phone},
      );
      return res.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Step 2 — verify OTP and set new password.
  Future<void> forgotPasswordVerifyOtp({
    required String phone,
    required String otp,
    required String newPassword,
  }) async {
    try {
      await _dio.post(
        ApiConstants.forgotPasswordVerifyOtp,
        data: {'phone': phone, 'otp': otp, 'newPassword': newPassword},
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
