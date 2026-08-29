import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import '../models/material_model.dart';

final materialRepositoryProvider = Provider<MaterialRepository>((ref) {
  return MaterialRepository(ref.watch(dioProvider));
});

class MaterialRepository {
  MaterialRepository(this._dio);
  final Dio _dio;

  Future<List<MaterialItem>> fetchMaterials() async {
    try {
      final res = await _dio.get(ApiConstants.materials);
      return (res.data['data'] as List<dynamic>)
          .map((j) => MaterialItem.fromJson(j as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Called by cashier to get owner's available stock list
  Future<List<MaterialItem>> fetchOwnerMaterials() async {
    try {
      final res = await _dio.get(ApiConstants.materialsOwnerStock);
      return (res.data['data'] as List<dynamic>)
          .map((j) => MaterialItem.fromJson(j as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<MaterialItem> createMaterial({
    required String name,
    required double quantity,
    required String unit,
    required double unitPrice,
    double? initialPrice,
    List<String>? images, // Multiple images as base64 strings
    List<Map<String, dynamic>>? colors,
  }) async {
    try {
      final res = await _dio.post(ApiConstants.materials, data: {
        'name': name,
        'quantity': quantity,
        'unit': unit,
        'unitPrice': unitPrice,
        if (initialPrice != null) 'initialPrice': initialPrice,
        if (images != null && images.isNotEmpty) 'images': images,
        if (colors != null && colors.isNotEmpty) 'colors': colors,
      });
      return MaterialItem.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> deleteMaterial(String id) async {
    try {
      await _dio.delete('${ApiConstants.materials}/$id');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<MaterialItem> updateMaterial({
    required String id,
    required String name,
    required String unit,
    required double unitPrice,
    double? initialPrice,
    List<String>? images,
    List<Map<String, dynamic>>? colors,
  }) async {
    try {
      final res = await _dio.put('${ApiConstants.materials}/$id', data: {
        'name': name,
        'unit': unit,
        'unitPrice': unitPrice,
        if (initialPrice != null) 'initialPrice': initialPrice,
        if (images != null) 'images': images,
        if (colors != null) 'colors': colors,
      });
      return MaterialItem.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
