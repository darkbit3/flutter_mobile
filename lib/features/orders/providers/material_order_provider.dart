import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../stock/data/material_repository.dart';
import '../models/material_order_model.dart';

final materialOrdersProvider = FutureProvider.autoDispose<List<MaterialOrder>>((ref) {
  final user = ref.watch(authProvider).user;
  return ref.watch(materialRepositoryProvider).fetchMaterialOrders(
        ownerView: user != null && !user.isCashier,
      );
});