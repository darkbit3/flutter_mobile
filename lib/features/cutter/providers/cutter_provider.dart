import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/cutter_repository.dart';
import '../models/cutter_model.dart';

// ── List state ────────────────────────────────────────────────────────────────

class CutterListState {
  const CutterListState({
    this.cutters   = const [],
    this.isLoading = false,
    this.error,
  });

  final List<CutterModel> cutters;
  final bool              isLoading;
  final String?           error;

  CutterListState copyWith({
    List<CutterModel>? cutters,
    bool?              isLoading,
    String?            error,
  }) =>
      CutterListState(
        cutters:   cutters   ?? this.cutters,
        isLoading: isLoading ?? this.isLoading,
        error:     error,
      );
}

// ── List notifier ─────────────────────────────────────────────────────────────

class CutterListNotifier extends StateNotifier<CutterListState> {
  CutterListNotifier(this._repo) : super(const CutterListState()) {
    load();
  }

  final CutterRepository _repo;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _repo.getCutters();
      state = state.copyWith(isLoading: false, cutters: data);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> toggleStatus(String id, String current) async {
    try {
      final updated = await _repo.toggleStatus(id, current);
      state = state.copyWith(
        cutters: state.cutters.map((c) => c.id == id ? updated : c).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> editCutter(String id, String name, String phone) async {
    try {
      final updated = await _repo.editCutter(id: id, name: name, phone: phone);
      state = state.copyWith(
        cutters: state.cutters.map((c) => c.id == id ? updated : c).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<String?> resetPassword(String id, String password) async {
    try {
      await _repo.resetCutterPassword(id: id, password: password);
      await load();
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}

// ── Create state ──────────────────────────────────────────────────────────────

class CreateCutterState {
  const CreateCutterState({
    this.isLoading = false,
    this.error,
    this.success   = false,
  });

  final bool    isLoading;
  final String? error;
  final bool    success;

  CreateCutterState copyWith({
    bool?   isLoading,
    String? error,
    bool?   success,
  }) =>
      CreateCutterState(
        isLoading: isLoading ?? this.isLoading,
        error:     error,
        success:   success   ?? this.success,
      );
}

// ── Create notifier ───────────────────────────────────────────────────────────

class CreateCutterNotifier extends StateNotifier<CreateCutterState> {
  CreateCutterNotifier(this._repo, this._listNotifier)
      : super(const CreateCutterState());

  final CutterRepository   _repo;
  final CutterListNotifier _listNotifier;

  Future<void> create({
    required String name,
    required String phone,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null, success: false);
    try {
      await _repo.createCutter(name: name, phone: phone, password: password);
      state = state.copyWith(isLoading: false, success: true);
      await _listNotifier.load();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void reset() => state = const CreateCutterState();
}

// ── Providers ─────────────────────────────────────────────────────────────────

final cutterListProvider =
    StateNotifierProvider<CutterListNotifier, CutterListState>((ref) {
  return CutterListNotifier(ref.watch(cutterRepositoryProvider));
});

final createCutterProvider =
    StateNotifierProvider<CreateCutterNotifier, CreateCutterState>((ref) {
  return CreateCutterNotifier(
    ref.watch(cutterRepositoryProvider),
    ref.watch(cutterListProvider.notifier),
  );
});
