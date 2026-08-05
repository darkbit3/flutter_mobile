import 'package:flutter/material.dart';

enum ToastType { success, error, warning, info }

class ToastMessage {
  const ToastMessage({
    required this.id,
    required this.message,
    required this.type,
  });

  final int       id;
  final String    message;
  final ToastType type;

  // ── Styling helpers ──────────────────────────────────────────────────────

  Color get backgroundColor {
    return switch (type) {
      ToastType.success => const Color(0xFFECFDF5),
      ToastType.error   => const Color(0xFFFEF2F2),
      ToastType.warning => const Color(0xFFFFFBEB),
      ToastType.info    => const Color(0xFFEFF6FF),
    };
  }

  Color get borderColor {
    return switch (type) {
      ToastType.success => const Color(0xFF6EE7B7),
      ToastType.error   => const Color(0xFFFCA5A5),
      ToastType.warning => const Color(0xFFFCD34D),
      ToastType.info    => const Color(0xFF93C5FD),
    };
  }

  Color get iconColor {
    return switch (type) {
      ToastType.success => const Color(0xFF059669),
      ToastType.error   => const Color(0xFFDC2626),
      ToastType.warning => const Color(0xFFD97706),
      ToastType.info    => const Color(0xFF2563EB),
    };
  }

  Color get textColor {
    return switch (type) {
      ToastType.success => const Color(0xFF065F46),
      ToastType.error   => const Color(0xFF7F1D1D),
      ToastType.warning => const Color(0xFF78350F),
      ToastType.info    => const Color(0xFF1E3A5F),
    };
  }

  IconData get icon {
    return switch (type) {
      ToastType.success => Icons.check_circle_rounded,
      ToastType.error   => Icons.cancel_rounded,
      ToastType.warning => Icons.warning_rounded,
      ToastType.info    => Icons.info_rounded,
    };
  }
}
