// Register provider for user registration flow
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import '../models/user_model.dart';
import '../models/registration_plan.dart';

class RegisterState {
  const RegisterState({
    this.isLoading = false,
    this.error,
    this.success = false,
    this.user,
    this.plan,
    this.registrationFree = false,
  });

  final bool isLoading;
  final String? error;
  final bool success;
  final UserModel? user;
  final RegistrationPlan? plan;
  final bool registrationFree;

  RegisterState copyWith({
    bool? isLoading,
    String? error,
    bool? success,
    UserModel? user,
    RegistrationPlan? plan,
    bool? registrationFree,
  }) {
    return RegisterState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      success: success ?? this.success,
      user: user ?? this.user,
      plan: plan ?? this.plan,
      registrationFree: registrationFree ?? this.registrationFree,
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
    required String role,
    required String planKey,
  }) async {
    state = state.copyWith(isLoading: true, error: null, success: false);
    try {
      final result =
          await _repo.register(name, email, phone, password, role, planKey);
      state = state.copyWith(
        isLoading: false,
        success: true,
        user: result.user,
        plan: result.plan,
        registrationFree: result.registrationFree,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void reset() => state = const RegisterState();
}

final registerProvider =
    StateNotifierProvider<RegisterNotifier, RegisterState>((ref) {
  return RegisterNotifier(ref.watch(authRepositoryProvider));
});
