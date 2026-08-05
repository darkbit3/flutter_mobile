import 'package:flutter/material.dart';

/// A widget that catches errors in its subtree and renders a styled
/// fallback UI instead of the default red error screen.
///
/// Usage:
/// ```dart
/// ErrorBoundary(
///   child: MyWidget(),
/// )
/// ```
class ErrorBoundary extends StatefulWidget {
  const ErrorBoundary({
    super.key,
    required this.child,
    this.fallback,
  });

  /// The widget subtree to protect.
  final Widget child;

  /// Optional custom fallback widget. Defaults to [_DefaultErrorCard].
  final Widget Function(Object error, StackTrace? stack)? fallback;

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object?     _error;
  StackTrace? _stack;

  void _reset() => setState(() {
        _error = null;
        _stack = null;
      });

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.fallback != null
          ? widget.fallback!(_error!, _stack)
          : _DefaultErrorCard(
              error: _error!,
              stack: _stack,
              onRetry: _reset,
            );
    }

    // Register a custom error widget builder scoped to this subtree
    return _ErrorCatcher(
      onError: (error, stack) {
        setState(() {
          _error = error;
          _stack = stack;
        });
      },
      child: widget.child,
    );
  }
}

// ─── Internal builder hook ────────────────────────────────────────────────────

class _ErrorCatcher extends StatelessWidget {
  const _ErrorCatcher({required this.child, required this.onError});

  final Widget child;
  final void Function(Object error, StackTrace? stack) onError;

  @override
  Widget build(BuildContext context) {
    ErrorWidget.builder = (FlutterErrorDetails details) {
      // Propagate to the parent StatefulWidget via post-frame callback
      // (cannot call setState inside build)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onError(details.exception, details.stack);
      });
      return const SizedBox.shrink();
    };
    return child;
  }
}

// ─── Default fallback card ────────────────────────────────────────────────────

class _DefaultErrorCard extends StatelessWidget {
  const _DefaultErrorCard({
    required this.error,
    required this.onRetry,
    this.stack,
  });

  final Object     error;
  final StackTrace? stack;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer.withValues(alpha: 0.15),
            border: Border.all(
              color: theme.colorScheme.error.withValues(alpha: 0.4),
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 12),
              Text(
                'Something went wrong',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
