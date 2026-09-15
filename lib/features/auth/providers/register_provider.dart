// Register provider for user registration flow
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import '../models/user_model.dart';

class RegisterState {
  const RegisterState({
    this.isLoading = false,
    this.error,
    this.success = false,
    this.user,
  });

  final bool isLoading;
  final String? error;
  final bool success;
  final UserModel? user;

  RegisterState copyWith({
    bool? isLoading,
    String? error,
    bool? success,
    UserModel? user,
  }) {
    return RegisterState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      success: success ?? this.success,
      user: user ?? this.user,
    );
  }
}

class RegisterNotifier extends StateNotifier<RegisterState> {
  RegisterNotifier(this._repo) : super(const RegisterState());

  final AuthRepository _repo;

  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null, success: false);
    try {
      final user = await _repo.register(name, email, phone, password);
      state = state.copyWith(isLoading: false, success: true, user: user);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void reset() => state = const RegisterState();
}

final registerProvider = StateNotifierProvider<RegisterNotifier, RegisterState>((ref) {
  return RegisterNotifier(ref.watch(authRepositoryProvider));
});
