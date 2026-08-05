import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/cashier_repository.dart';
import '../models/cashier_model.dart';

// ── List state ────────────────────────────────────────────────────────────────

class CashierListState {
  const CashierListState({
    this.cashiers  = const [],
    this.isLoading = false,
    this.error,
  });

  final List<CashierModel> cashiers;
  final bool               isLoading;
  final String?            error;

  CashierListState copyWith({
    List<CashierModel>? cashiers,
    bool?               isLoading,
    String?             error,
  }) {
    return CashierListState(
      cashiers:  cashiers  ?? this.cashiers,
      isLoading: isLoading ?? this.isLoading,
      error:     error,
    );
  }
}

// ── List notifier ─────────────────────────────────────────────────────────────

class CashierListNotifier extends StateNotifier<CashierListState> {
  CashierListNotifier(this._repo) : super(const CashierListState()) {
    load();
  }

  final CashierRepository _repo;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _repo.getCashiers();
      state = state.copyWith(isLoading: false, cashiers: data);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> toggleStatus(String id, String currentStatus) async {
    try {
      final updated = await _repo.toggleStatus(id, currentStatus);
      state = state.copyWith(
        cashiers: state.cashiers.map((c) => c.id == id ? updated : c).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> editCashier(String id, String name, String phone) async {
    try {
      final updated = await _repo.editCashier(id: id, name: name, phone: phone);
      state = state.copyWith(
        cashiers: state.cashiers.map((c) => c.id == id ? updated : c).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<String?> resetPassword(String id, String password) async {
    try {
      await _repo.resetCashierPassword(id: id, password: password);
      await load();
      return null; // success
    } catch (e) {
      return e.toString(); // return error message
    }
  }
}

// ── Create state ──────────────────────────────────────────────────────────────

class CreateCashierState {
  const CreateCashierState({
    this.isLoading = false,
    this.error,
    this.success   = false,
  });

  final bool    isLoading;
  final String? error;
  final bool    success;

  CreateCashierState copyWith({
    bool?   isLoading,
    String? error,
    bool?   success,
  }) {
    return CreateCashierState(
      isLoading: isLoading ?? this.isLoading,
      error:     error,
      success:   success   ?? this.success,
    );
  }
}

// ── Create notifier ───────────────────────────────────────────────────────────

class CreateCashierNotifier extends StateNotifier<CreateCashierState> {
  CreateCashierNotifier(this._repo, this._listNotifier)
      : super(const CreateCashierState());

  final CashierRepository   _repo;
  final CashierListNotifier _listNotifier;

  Future<void> create({
    required String name,
    required String phone,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null, success: false);
    try {
      await _repo.createCashier(name: name, phone: phone, password: password);
      state = state.copyWith(isLoading: false, success: true);
      // Refresh the list so the new cashier appears
      await _listNotifier.load();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void reset() => state = const CreateCashierState();
}

// ── Providers ─────────────────────────────────────────────────────────────────

final cashierListProvider =
    StateNotifierProvider<CashierListNotifier, CashierListState>((ref) {
  return CashierListNotifier(ref.watch(cashierRepositoryProvider));
});

final createCashierProvider =
    StateNotifierProvider<CreateCashierNotifier, CreateCashierState>((ref) {
  return CreateCashierNotifier(
    ref.watch(cashierRepositoryProvider),
    ref.watch(cashierListProvider.notifier),
  );
});
