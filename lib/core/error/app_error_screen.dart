import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Full-screen error page shown when the entire app crashes.
/// Displayed by [GlobalErrorHandler] via [ErrorWidget.builder].
class AppErrorScreen extends StatelessWidget {
  const AppErrorScreen({
    super.key,
    required this.error,
    this.stack,
    this.onRestart,
  });

  final Object      error;
  final StackTrace? stack;
  final VoidCallback? onRestart;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE53935),
          brightness: Brightness.dark,
        ),
      ),
      home: Scaffold(
        backgroundColor: const Color(0xFF0D0D0D),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── Icon ─────────────────────────────────────────────────
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFE53935).withValues(alpha: 0.15),
                      border: Border.all(
                        color: const Color(0xFFE53935).withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.bug_report_rounded,
                      size: 48,
                      color: Color(0xFFE53935),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Title ─────────────────────────────────────────────────
                  const Text(
                    'Oops! App Crashed',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'An unexpected error occurred.\nWe\'re sorry for the inconvenience.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF9E9E9E),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Error card (debug only) ───────────────────────────────
                  if (kDebugMode) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFE53935).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Debug Info',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFE53935),
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            error.toString(),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFCCCCCC),
                              fontFamily: 'monospace',
                              height: 1.5,
                            ),
                          ),
                          if (stack != null) ...[
                            const SizedBox(height: 10),
                            const Divider(color: Color(0xFF2A2A2A)),
                            const SizedBox(height: 8),
                            Text(
                              stack.toString().split('\n').take(8).join('\n'),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF777777),
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],

                  // ── Restart button ────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: onRestart,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFE53935),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text(
                        'Restart App',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
