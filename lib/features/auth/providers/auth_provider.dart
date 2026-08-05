import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import '../models/user_model.dart';

// ── Auth state ────────────────────────────────────────────────────────────────

enum AuthStatus { initial, authenticated, unauthenticated }

class AuthState {
  const AuthState({
    this.status    = AuthStatus.initial,
    this.user,
    this.error,
    this.isLoading = false,
  });

  final AuthStatus status;
  final UserModel? user;
  final String?    error;
  final bool       isLoading;

  AuthState copyWith({
    AuthStatus? status,
    UserModel?  user,
    String?     error,
    bool?       isLoading,
  }) {
    return AuthState(
      status:    status    ?? this.status,
      user:      user      ?? this.user,
      error:     error,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// ── Auth notifier ─────────────────────────────────────────────────────────────

/// Extracts a clean user-facing message from any thrown object.
String _errorMessage(Object e) {
  if (e is Exception) {
    // e.toString() on ApiException returns just the message (override).
    // On base Exception it returns 'Exception: <msg>' — strip the prefix.
    final raw = e.toString();
    if (raw.startsWith('Exception: ')) return raw.substring('Exception: '.length);
    return raw;
  }
  return 'An unexpected error occurred.';
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repo) : super(const AuthState()) {
    _init();
  }

  final AuthRepository _repo;

  Future<void> _init() async {
    final has = await _repo.hasToken();
    if (has) {
      try {
        final user = await _repo.getMe();
        state = AuthState(status: AuthStatus.authenticated, user: user);
      } catch (_) {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    } else {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login(String phone, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _repo.login(phone, password);
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        status:    AuthStatus.unauthenticated,
        error:     _errorMessage(e),
      );
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

// ── Change-password state ─────────────────────────────────────────────────────

class ChangePasswordState {
  const ChangePasswordState({
    this.isLoading = false,
    this.error,
    this.success   = false,
  });

  final bool    isLoading;
  final String? error;
  final bool    success;

  ChangePasswordState copyWith({
    bool?   isLoading,
    String? error,
    bool?   success,
  }) {
    return ChangePasswordState(
      isLoading: isLoading ?? this.isLoading,
      error:     error,
      success:   success   ?? this.success,
    );
  }
}

class ChangePasswordNotifier extends StateNotifier<ChangePasswordState> {
  ChangePasswordNotifier(this._repo) : super(const ChangePasswordState());

  final AuthRepository _repo;

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, error: null, success: false);
    try {
      await _repo.changePassword(currentPassword, newPassword);
      state = state.copyWith(isLoading: false, success: true);
    } catch (e) {
      state = state.copyWith(
          isLoading: false,
          error: _errorMessage(e));
    }
  }

  void reset() => state = const ChangePasswordState();
}

// ── Providers ─────────────────────────────────────────────────────────────────

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});

final changePasswordProvider =
    StateNotifierProvider<ChangePasswordNotifier, ChangePasswordState>((ref) {
  return ChangePasswordNotifier(ref.watch(authRepositoryProvider));
});

// Keep alias so reset_password_screen still compiles
final resetPasswordProvider = changePasswordProvider;

// Alias state type
typedef ResetPasswordState = ChangePasswordState;
