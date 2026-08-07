import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/error/global_error_handler.dart';
import 'core/error/app_error_screen.dart';
import 'core/network/dio_client.dart';
import 'core/theme/app_theme.dart';
import 'router/app_router.dart';

void main() async {
  // 1️⃣  Register global Flutter + platform error hooks
  GlobalErrorHandler.init();

  // 2️⃣  Wrap entire app in a guarded zone to catch async errors.
  //     ensureInitialized must be called in the same zone as runApp.
  await GlobalErrorHandler.runGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // 🚀 Kick off server warm-up immediately — runs in background while app boots
    warmUpServer();

    runApp(
      const ProviderScope(
        child: _AppErrorBoundary(
          child: ShmetaApp(),
        ),
      ),
    );
  });
}

/// Top-level error boundary — if [ShmetaApp] itself crashes, this shows
/// [AppErrorScreen] instead of the default grey/red Flutter error screen.
class _AppErrorBoundary extends StatefulWidget {
  const _AppErrorBoundary({required this.child});
  final Widget child;

  @override
  State<_AppErrorBoundary> createState() => _AppErrorBoundaryState();
}

class _AppErrorBoundaryState extends State<_AppErrorBoundary> {
  Object?      _error;
  StackTrace?  _stack;

  @override
  void initState() {
    super.initState();
    // Override Flutter's ErrorWidget for this scope
    ErrorWidget.builder = (FlutterErrorDetails details) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _error = details.exception;
            _stack = details.stack;
          });
        }
      });
      return const SizedBox.shrink();
    };
  }

  void _restart() {
    setState(() {
      _error = null;
      _stack = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return AppErrorScreen(
        error: _error!,
        stack: _stack,
        onRestart: _restart,
      );
    }
    return widget.child;
  }
}

class ShmetaApp extends ConsumerWidget {
  const ShmetaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title:                     'Shmeta',
      debugShowCheckedModeBanner: false,
      theme:                     AppTheme.theme,
      routerConfig:              router,
    );
  }
}
