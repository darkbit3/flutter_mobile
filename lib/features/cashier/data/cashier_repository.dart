import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import '../models/cashier_model.dart';

final cashierRepositoryProvider = Provider<CashierRepository>((ref) {
  return CashierRepository(ref.watch(dioProvider));
});

class CashierRepository {
  CashierRepository(this._dio);

  final Dio _dio;

  /// Fetch all cashiers belonging to the logged-in user.
  Future<List<CashierModel>> getCashiers() async {
    try {
      final res = await _dio.get(ApiConstants.cashiers);
      final list = res.data['data'] as List<dynamic>;
      return list
          .map((e) => CashierModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Create a new cashier.
  Future<CashierModel> createCashier({
    required String name,
    required String phone,
    required String password,
  }) async {
    try {
      final res = await _dio.post(
        ApiConstants.cashiers,
        data: {'name': name, 'phone': phone, 'password': password},
      );
      return CashierModel.fromJson(
          res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Toggle status (Active / Inactive) of a cashier.
  Future<CashierModel> toggleStatus(String id, String currentStatus) async {
    final nextStatus = currentStatus == 'Active' ? 'Inactive' : 'Active';
    try {
      final res = await _dio.patch(
        '${ApiConstants.cashiers}/$id/status',
        data: {'status': nextStatus},
      );
      return CashierModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Edit a cashier's name and phone.
  Future<CashierModel> editCashier({
    required String id,
    required String name,
    required String phone,
  }) async {
    try {
      final res = await _dio.put(
        '${ApiConstants.cashiers}/$id',
        data: {'name': name, 'phone': phone},
      );
      return CashierModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Reset a cashier's password.
  Future<CashierModel> resetCashierPassword({
    required String id,
    required String password,
  }) async {
    try {
      final res = await _dio.patch(
        '${ApiConstants.cashiers}/$id/reset-password',
        data: {'password': password},
      );
      return CashierModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
