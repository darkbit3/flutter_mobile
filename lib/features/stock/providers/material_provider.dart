import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/material_repository.dart';
import '../models/material_model.dart';

// ── Providers ────────────────────────────────────────────────────────────────

/// Loads all materials from server for the current user (owner view)
final materialsProvider =
    FutureProvider.autoDispose<List<MaterialItem>>((ref) async {
  return ref.watch(materialRepositoryProvider).fetchMaterials();
});

/// Loads owner's materials from cashier's perspective
final ownerMaterialsProvider =
    FutureProvider.autoDispose<List<MaterialItem>>((ref) async {
  return ref.watch(materialRepositoryProvider).fetchOwnerMaterials();
});

/// Notifier that manages create / delete with optimistic UI
class MaterialNotifier extends AsyncNotifier<List<MaterialItem>> {
  @override
  Future<List<MaterialItem>> build() async {
    return ref.watch(materialRepositoryProvider).fetchMaterials();
  }

  Future<void> create({
    required String name,
    required double quantity,
    required String unit,
    required double unitPrice,
    double? initialPrice,
    List<String>? images,
    List<Map<String, dynamic>>? colors,
  }) async {
    final repo = ref.read(materialRepositoryProvider);
    final created = await repo.createMaterial(
      name:         name,
      quantity:     quantity,
      unit:         unit,
      unitPrice:    unitPrice,
      initialPrice: initialPrice,
      images:       images,
      colors:       colors,
    );
    ref.invalidate(materialsProvider);
    state = AsyncData([created, ...state.valueOrNull ?? []]);
  }

  Future<void> delete(String id) async {
    await ref.read(materialRepositoryProvider).deleteMaterial(id);
    ref.invalidate(materialsProvider);
    state = AsyncData(
      (state.valueOrNull ?? []).where((m) => m.id != id).toList(),
    );
  }
}

final materialNotifierProvider =
    AsyncNotifierProvider<MaterialNotifier, List<MaterialItem>>(
        MaterialNotifier.new);
