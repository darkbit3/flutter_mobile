import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import '../models/credit_model.dart';

final creditRepositoryProvider = Provider<CreditRepository>((ref) {
  return CreditRepository(ref.watch(dioProvider));
});

class CreditRepository {
  CreditRepository(this._dio);
  final Dio _dio;

  // Cashier: own credits
  Future<List<CreditRecord>> fetchMyCashierCredits() async {
    try {
      final res = await _dio.get(ApiConstants.credits);
      return _parseList(res.data['data']);
    } on DioException catch (e) { throw ApiException.fromDio(e); }
  }

  // Owner: all credits from all cashiers
  Future<List<CreditRecord>> fetchOwnerCredits() async {
    try {
      final res = await _dio.get(ApiConstants.creditsOwner);
      return _parseList(res.data['data']);
    } on DioException catch (e) { throw ApiException.fromDio(e); }
  }

  // Owner dashboard stats
  Future<CreditStats> fetchOwnerStats() async {
    try {
      final res = await _dio.get(ApiConstants.creditsOwnerStats);
      return CreditStats.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) { throw ApiException.fromDio(e); }
  }

  // Add a payment installment to a credit
  Future<CreditRecord> addPayment(String creditId, double amount, {String? note}) async {
    try {
      final res = await _dio.post(
        '${ApiConstants.credits}/$creditId/payments',
        data: {'amount': amount, 'note': note},
      );
      return CreditRecord.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) { throw ApiException.fromDio(e); }
  }

  List<CreditRecord> _parseList(dynamic data) =>
      (data as List<dynamic>)
          .map((j) => CreditRecord.fromJson(j as Map<String, dynamic>))
          .toList();
}
