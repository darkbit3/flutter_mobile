import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../models/user_model.dart';
import '../models/registration_plan.dart';
import '../models/payment_info.dart';

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
          key: 'access_token', value: data['accessToken'] as String);
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

  /// Register a new user.
  Future<List<RegistrationPlan>> getRegisterPlans() async {
    try {
      final res = await _dio.get(ApiConstants.registerPlans);
      final plans = res.data['data'] as List<dynamic>;
      return plans
          .map(
              (plan) => RegistrationPlan.fromJson(plan as Map<String, dynamic>))
          .where((plan) => plan.enabled)
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<RegistrationResult> register(String name, String email, String phone,
      String password, String role, String planKey) async {
    try {
      final res = await _dio.post(
        ApiConstants.userRegister,
        data: {
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
          'role': role,
          'plan': planKey,
        },
      );
      final data = res.data['data'] as Map<String, dynamic>;
      final pendingApproval = data['pendingApproval'] == true;
      // Store tokens if returned
      if (data.containsKey('accessToken') && data['accessToken'] != null) {
        await _storage.write(
            key: 'access_token', value: data['accessToken'] as String);
        await _storage.write(
            key: 'refresh_token', value: data['refreshToken'] as String);
      }
      return RegistrationResult(
        user: UserModel.fromJson(data['user'] as Map<String, dynamic>),
        plan: RegistrationPlan.fromJson(
            data['registrationPlan'] as Map<String, dynamic>),
        registrationFree: data['registrationFree'] == true,
        pendingApproval: pendingApproval,
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Get active payment info (bank accounts & Telegram handle) for registration payments.
  Future<PaymentInfo> getPaymentInfo() async {
    try {
      final res = await _dio.get(ApiConstants.paymentInfo);
      return PaymentInfo.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Poll registration status for pending account.
  Future<RegistrationStatusData> getRegistrationStatus(String phone) async {
    try {
      final res = await _dio.get('${ApiConstants.registrationStatus}/$phone');
      return RegistrationStatusData.fromJson(
          res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Change password for user.
  Future<void> changePassword(
      {required String current, required String next}) async {
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
