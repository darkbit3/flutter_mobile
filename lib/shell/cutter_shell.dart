import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/toast/toast_overlay.dart';
import '../features/auth/providers/auth_provider.dart';

/// Full-screen shell for Cutter users — own sidebar + bottom nav
class CutterShell extends ConsumerWidget {
  const CutterShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B5CF6),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                'assets/images/logo.jpg',
                width: 28,
                height: 28,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            const Text('Shmeta',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19)),
          ],
        ),
        actions: [
          if (user != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              child: Chip(
                avatar: const Icon(Icons.content_cut, size: 14, color: Colors.white),
                label: const Text('Cutter',
                    style: TextStyle(color: Colors.white, fontSize: 11)),
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                side: BorderSide.none,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      drawer: _CutterDrawer(user: user, ref: ref),
      body: Stack(
        children: [
          child,
          const ToastOverlay(),
        ],
      ),
      bottomNavigationBar: Builder(
        builder: (ctx) {
          final loc = GoRouterState.of(ctx).matchedLocation;
          int selIdx = loc == '/cutter-dashboard/change-password' ? 1 : 0;

          return NavigationBar(
            selectedIndex: selIdx,
            backgroundColor: Colors.white,
            indicatorColor: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
            onDestinationSelected: (idx) {
              if (idx == 0) context.go('/cutter-dashboard');
              if (idx == 1) context.go('/cutter-dashboard/change-password');
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_rounded),
                label: 'Dashboard',
              ),
              NavigationDestination(
                icon: Icon(Icons.lock_reset_rounded),
                label: 'Password',
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CutterDrawer extends StatelessWidget {
  const _CutterDrawer({required this.user, required this.ref});
  final dynamic user;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF111827),
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: ClipOval(
                    child: Image.asset('assets/images/logo.jpg', width: 52, height: 52, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Shmeta',
                          style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(user?.name ?? 'Cutter',
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis),
                      Text(user?.phone ?? '',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.content_cut_rounded, size: 12, color: Colors.white),
                            SizedBox(width: 4),
                            Text('Cutter',
                                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF8B5CF6), width: 1.5),
                    ),
                    child: ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      leading: const Icon(Icons.dashboard_rounded, color: Color(0xFF8B5CF6), size: 22),
                      title: const Text('Dashboard',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
                Divider(color: Colors.white.withValues(alpha: 0.15), indent: 16, endIndent: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                    ),
                    child: ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      leading: const Icon(Icons.lock_reset_rounded, color: Colors.white, size: 22),
                      title: const Text('Change Password',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      onTap: () {
                        Navigator.of(context).pop();
                        context.go('/cutter-dashboard/change-password');
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(color: Colors.white.withValues(alpha: 0.15), height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Logout', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 15)),
            onTap: () async {
              Navigator.of(context).pop();
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
          const SizedBox(height: 8),
          Text('v1.0.0', style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.4))),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
