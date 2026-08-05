import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'toast_model.dart';

// ── State ────────────────────────────────────────────────────────────────────

class ToastState {
  const ToastState({this.toasts = const []});
  final List<ToastMessage> toasts;

  ToastState copyWith({List<ToastMessage>? toasts}) =>
      ToastState(toasts: toasts ?? this.toasts);
}

// ── Notifier ─────────────────────────────────────────────────────────────────

int _idCounter = 0;

class ToastNotifier extends Notifier<ToastState> {
  @override
  ToastState build() => const ToastState();

  /// Show a toast. Auto-dismisses after [duration] (default 3 seconds).
  void show(
    String message,
    ToastType type, {
    Duration duration = const Duration(seconds: 3),
  }) {
    final id = ++_idCounter;
    final toast = ToastMessage(id: id, message: message, type: type);

    state = state.copyWith(toasts: [...state.toasts, toast]);

    // Auto-dismiss
    Future.delayed(duration, () => dismiss(id));
  }

  void dismiss(int id) {
    state = state.copyWith(
      toasts: state.toasts.where((t) => t.id != id).toList(),
    );
  }

  // ── Convenience helpers ───────────────────────────────────────────────────

  void success(String message, {Duration? duration}) =>
      show(message, ToastType.success,
          duration: duration ?? const Duration(seconds: 3));

  void error(String message, {Duration? duration}) =>
      show(message, ToastType.error,
          duration: duration ?? const Duration(seconds: 3));

  void warning(String message, {Duration? duration}) =>
      show(message, ToastType.warning,
          duration: duration ?? const Duration(seconds: 3));

  void info(String message, {Duration? duration}) =>
      show(message, ToastType.info,
          duration: duration ?? const Duration(seconds: 3));
}

// ── Providers ─────────────────────────────────────────────────────────────────

final toastProvider =
    NotifierProvider<ToastNotifier, ToastState>(ToastNotifier.new);

/// Convenience accessor — use [ref.read(toastServiceProvider)] to fire toasts.
final toastServiceProvider = Provider<ToastNotifier>((ref) {
  return ref.read(toastProvider.notifier);
});
