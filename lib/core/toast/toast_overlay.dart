import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'toast_model.dart';
import 'toast_service.dart';

/// Drop this widget at the very top of your widget tree (inside [ProviderScope]).
/// It renders the active toasts as an overlay fixed to the top of the screen,
/// exactly matching the admin's notification banner.
///
/// Usage in your shell / scaffold:
/// ```dart
/// Stack(
///   children: [
///     child,
///     const ToastOverlay(),
///   ],
/// )
/// ```
class ToastOverlay extends ConsumerWidget {
  const ToastOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toasts = ref.watch(toastProvider).toasts;

    if (toasts.isEmpty) return const SizedBox.shrink();

    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 16,
      right: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: toasts
            .map((t) => _ToastTile(
                  key: ValueKey(t.id),
                  toast: t,
                  onDismiss: () =>
                      ref.read(toastProvider.notifier).dismiss(t.id),
                ))
            .toList(),
      ),
    );
  }
}

// ── Single toast tile ─────────────────────────────────────────────────────────

class _ToastTile extends StatefulWidget {
  const _ToastTile({
    super.key,
    required this.toast,
    required this.onDismiss,
  });

  final ToastMessage toast;
  final VoidCallback onDismiss;

  @override
  State<_ToastTile> createState() => _ToastTileState();
}

class _ToastTileState extends State<_ToastTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double>   _opacity;
  late Animation<Offset>   _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    _opacity = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, -0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.toast;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: FadeTransition(
        opacity: _opacity,
        child: SlideTransition(
          position: _slide,
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: t.backgroundColor,
                border: Border.all(color: t.borderColor, width: 1.2),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon
                    Icon(t.icon, color: t.iconColor, size: 22),
                    const SizedBox(width: 10),

                    // Message
                    Expanded(
                      child: Text(
                        t.message,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: t.textColor,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // ✕ dismiss button
                    GestureDetector(
                      onTap: _dismiss,
                      child: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: t.iconColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
