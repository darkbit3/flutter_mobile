import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import '../models/sale_model.dart';

final saleRepositoryProvider = Provider<SaleRepository>((ref) {
  return SaleRepository(ref.watch(dioProvider));
});

class SaleRepository {
  SaleRepository(this._dio);
  final Dio _dio;

  Future<SaleModel> recordSale({
    required String?       customer,
    required String        paymentType,
    required String?       note,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final res = await _dio.post(ApiConstants.sales, data: {
        'customer':    customer,
        'paymentType': paymentType,
        'note':        note,
        'items':       items,
      });
      return SaleModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<SaleModel>> getSales() async {
    try {
      final res = await _dio.get(ApiConstants.sales);
      return (res.data['data'] as List<dynamic>)
          .map((j) => SaleModel.fromJson(j as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<SaleStats> getStats() async {
    try {
      final res = await _dio.get(ApiConstants.salesStats);
      return SaleStats.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<SaleModel>> getOwnerSales() async {
    try {
      final res = await _dio.get(ApiConstants.salesOwner);
      return (res.data['data'] as List<dynamic>)
          .map((j) => SaleModel.fromJson(j as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
