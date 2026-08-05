import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/sale_repository.dart';
import '../models/sale_model.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class SaleListState {
  const SaleListState({
    this.sales   = const [],
    this.stats   = const SaleStats(totalSales: 0, totalRevenue: 0, totalCredit: 0, totalCash: 0),
    this.loading = false,
    this.error,
  });

  final List<SaleModel> sales;
  final SaleStats       stats;
  final bool            loading;
  final String?         error;

  SaleListState copyWith({
    List<SaleModel>? sales,
    SaleStats?       stats,
    bool?            loading,
    String?          error,
  }) =>
      SaleListState(
        sales:   sales   ?? this.sales,
        stats:   stats   ?? this.stats,
        loading: loading ?? this.loading,
        error:   error,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class SaleListNotifier extends StateNotifier<SaleListState> {
  SaleListNotifier(this._repo) : super(const SaleListState()) {
    load();
  }

  final SaleRepository _repo;

  Future<void> load() async {
    state = state.copyWith(loading: true);
    try {
      final results = await Future.wait([
        _repo.getSales(),
        _repo.getStats(),
      ]);
      state = state.copyWith(
        sales:   results[0] as List<SaleModel>,
        stats:   results[1] as SaleStats,
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  /// Record a new sale and prepend it to the list.
  Future<String?> recordSale({
    required String?       customer,
    required String        paymentType,
    required String?       note,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final sale = await _repo.recordSale(
        customer:    customer,
        paymentType: paymentType,
        note:        note,
        items:       items,
      );
      // Refresh stats and prepend new sale
      final newStats = await _repo.getStats();
      state = state.copyWith(
        sales: [sale, ...state.sales],
        stats: newStats,
      );
      return null; // success
    } catch (e) {
      return e.toString();
    }
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final saleListProvider =
    StateNotifierProvider<SaleListNotifier, SaleListState>((ref) {
  return SaleListNotifier(ref.watch(saleRepositoryProvider));
});
