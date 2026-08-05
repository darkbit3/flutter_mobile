import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Initialises global error hooks so no crash goes unhandled.
///
/// Call [GlobalErrorHandler.init] **before** [runApp].
class GlobalErrorHandler {
  GlobalErrorHandler._();

  static void init() {
    // 1️⃣  Catches Flutter framework errors (widget build, layout, etc.)
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      _logError(
        'FlutterError',
        details.exception,
        details.stack,
      );
    };

    // 2️⃣  Catches errors thrown on the platform dispatcher (e.g. platform channels)
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      _logError('PlatformDispatcher', error, stack);
      return true; // returning true means "handled"
    };
  }

  /// Wraps [body] in a guarded zone so async errors that bubble past
  /// Futures/Streams are also captured rather than silently dropped.
  static Future<void> runGuarded(Future<void> Function() body) {
    return runZonedGuarded(
      body,
      (Object error, StackTrace stack) {
        _logError('ZonedGuarded', error, stack);
      },
    ) ??
        Future.value();
  }

  // ─── internal ────────────────────────────────────────────────────────────

  static void _logError(String origin, Object error, StackTrace? stack) {
    if (kDebugMode) {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('🔴 [$origin] Uncaught error: $error');
      if (stack != null) debugPrint(stack.toString());
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }

    // TODO: swap for Sentry / Firebase Crashlytics in production, e.g.:
    // FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  }
}
