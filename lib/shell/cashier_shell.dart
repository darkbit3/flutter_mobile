import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/toast/toast_overlay.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/sales/screens/new_sale_sheet.dart';

/// Full-screen shell for Cashier users — own sidebar + bottom nav
class CashierShell extends ConsumerWidget {
  const CashierShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Builder(
          builder: (ctx) {
            final loc = GoRouterState.of(ctx).matchedLocation;
            final title = loc.contains('credits')
                ? 'Credits'
                : loc.contains('sales')
                    ? 'Sales'
                    : 'Dashboard';
            return Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    'assets/images/logo.jpg',
                    width: 28, height: 28,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 19, color: Colors.white)),
              ],
            );
          },
        ),
        actions: [
          if (user != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              child: Chip(
                avatar: const Icon(Icons.point_of_sale, size: 14, color: Colors.white),
                label: const Text('Cashier',
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
      drawer: _CashierDrawer(user: user, ref: ref),
      body: Stack(
        children: [
          child,
          const ToastOverlay(),
        ],
      ),
      // ── FAB: only shown on the Sales tab ──────────────────────────────
      floatingActionButton: Builder(
        builder: (ctx) {
          final loc = GoRouterState.of(ctx).matchedLocation;
          final onSales = loc.contains('sales');
          if (!onSales) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: () => showModalBottomSheet(
              context: ctx,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const NewSaleSheet(),
            ),
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_shopping_cart_rounded),
            label: const Text(
              'New Sale',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            elevation: 4,
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: Builder(
        builder: (ctx) {
          final loc = GoRouterState.of(ctx).matchedLocation;
          int selIdx = 0;
          if (loc.contains('credits')) selIdx = 1;
          if (loc.contains('sales')) selIdx = 2;

          return NavigationBar(
            selectedIndex: selIdx,
            backgroundColor: Colors.white,
            indicatorColor: const Color(0xFF10B981).withValues(alpha: 0.15),
            onDestinationSelected: (idx) {
              if (idx == 0) context.go('/cashier-dashboard');
              if (idx == 1) context.go('/cashier-dashboard/credits');
              if (idx == 2) context.go('/cashier-dashboard/sales');
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_rounded),
                label: 'Dashboard',
              ),
              NavigationDestination(
                icon: Icon(Icons.account_balance_wallet_rounded),
                label: 'Credits',
              ),
              NavigationDestination(
                icon: Icon(Icons.sell_rounded),
                label: 'Sales',
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CashierDrawer extends StatelessWidget {
  const _CashierDrawer({required this.user, required this.ref});
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
                colors: [Color(0xFF10B981), Color(0xFF059669)],
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
                      Text(user?.name ?? 'Cashier',
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
                            Icon(Icons.point_of_sale_rounded, size: 12, color: Colors.white),
                            SizedBox(width: 4),
                            Text('Cashier',
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
                const _DrawerTile(
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  path: '/cashier-dashboard',
                ),
                const _DrawerTile(
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'Credits',
                  path: '/cashier-dashboard/credits',
                  activeColor: Color(0xFFF59E0B),
                ),
                const _DrawerTile(
                  icon: Icons.sell_rounded,
                  label: 'Sales',
                  path: '/cashier-dashboard/sales',
                  activeColor: Color(0xFF10B981),
                ),
                Divider(color: Colors.white.withValues(alpha: 0.15), indent: 16, endIndent: 16),
                const _DrawerTile(
                  icon: Icons.lock_reset_rounded,
                  label: 'Change Password',
                  path: '/cashier-dashboard/change-password',
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

// ── Drawer Tile ───────────────────────────────────────────────────────────────

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.path,
    this.activeColor = const Color(0xFF10B981),
  });

  final IconData icon;
  final String   label;
  final String   path;
  final Color    activeColor;

  @override
  Widget build(BuildContext ctx) {
    final loc      = GoRouterState.of(ctx).matchedLocation;
    final isActive = loc == path;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Container(
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? activeColor : Colors.white.withValues(alpha: 0.12),
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          leading: Icon(icon, size: 22, color: isActive ? activeColor : Colors.white),
          title: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Colors.white,
            ),
          ),
          onTap: () {
            Navigator.of(ctx).pop();
            ctx.go(path);
          },
        ),
      ),
    );
  }
}
