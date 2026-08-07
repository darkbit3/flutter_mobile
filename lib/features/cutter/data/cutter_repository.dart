import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import '../models/cutter_model.dart';

final cutterRepositoryProvider = Provider<CutterRepository>((ref) {
  return CutterRepository(ref.watch(dioProvider));
});

class CutterRepository {
  CutterRepository(this._dio);
  final Dio _dio;

  Future<List<CutterModel>> getCutters() async {
    try {
      final res  = await _dio.get(ApiConstants.cutters);
      final list = res.data['data'] as List<dynamic>;
      return list.map((e) => CutterModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<CutterModel> createCutter({
    required String name,
    required String phone,
    required String password,
  }) async {
    try {
      final res = await _dio.post(
        ApiConstants.cutters,
        data: {'name': name, 'phone': phone, 'password': password},
      );
      return CutterModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<CutterModel> toggleStatus(String id, String currentStatus) async {
    final next = currentStatus == 'Active' ? 'Inactive' : 'Active';
    try {
      final res = await _dio.patch(
        '${ApiConstants.cutters}/$id/status',
        data: {'status': next},
      );
      return CutterModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<CutterModel> editCutter({
    required String id,
    required String name,
    required String phone,
  }) async {
    try {
      final res = await _dio.put(
        '${ApiConstants.cutters}/$id',
        data: {'name': name, 'phone': phone},
      );
      return CutterModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> resetCutterPassword({
    required String id,
    required String password,
  }) async {
    try {
      await _dio.patch(
        '${ApiConstants.cutters}/$id/reset-password',
        data: {'password': password},
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
