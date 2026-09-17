import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import '../models/material_model.dart';
import '../../orders/models/material_order_model.dart';

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

  Future<MaterialOrder> createMaterialOrder({
    String? materialId,
    required String materialName,
    required double quantity,
    String? note,
  }) async {
    try {
      final res = await _dio.post(ApiConstants.materialOrders, data: {
        if (materialId != null) 'materialId': materialId,
        'materialName': materialName,
        'quantity': quantity,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      });
      return MaterialOrder.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) { throw ApiException.fromDio(e); }
  }

  Future<List<MaterialOrder>> fetchMaterialOrders({required bool ownerView}) async {
    try {
      final res = await _dio.get(ownerView ? ApiConstants.materialOrdersOwner : ApiConstants.materialOrdersMine);
      return (res.data['data'] as List<dynamic>)
          .map((item) => MaterialOrder.fromJson(item as Map<String, dynamic>)).toList();
    } on DioException catch (e) { throw ApiException.fromDio(e); }
  }

  Future<MaterialOrder> updateMaterialOrderStatus(String id, String status) async {
    try {
      final res = await _dio.patch('${ApiConstants.materialOrders}/$id/status', data: {'status': status});
      return MaterialOrder.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) { throw ApiException.fromDio(e); }
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

  Future<CuttingRecord> recordCut({
    required String materialId,
    required double consumedQuantity,
    required double producedCloth,
    required String outputMaterialName,
    required double wasteQuantity,
    String? note,
  }) async {
    try {
      final res = await _dio.post(ApiConstants.materialCut, data: {
        'materialId': materialId,
        'consumedQuantity': consumedQuantity,
        'producedCloth': producedCloth,
        'outputMaterialName': outputMaterialName,
        'wasteQuantity': wasteQuantity,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      });
      return CuttingRecord.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<CuttingRecord>> fetchCutHistory() async {
    try {
      final res = await _dio.get(ApiConstants.materialCutHistory);
      return (res.data['data'] as List<dynamic>)
          .map((j) => CuttingRecord.fromJson(j as Map<String, dynamic>))
          .toList();
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
