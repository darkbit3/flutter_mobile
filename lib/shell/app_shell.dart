import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_theme.dart';
import '../core/toast/toast_overlay.dart';
import '../core/widgets/notification_overlay.dart';
import '../features/auth/providers/auth_provider.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  static List<_NavDest> _getDestinations(dynamic user) {
    final list = <_NavDest>[
      const _NavDest(label: 'Home',    icon: Icons.home_rounded,         path: '/dashboard'),
    ];
    // Both roles get Stock and Cashier
    if (user?.role == 'Reseller' || user?.role == 'Manufacturer') {
      list.add(const _NavDest(
        label: 'Stock',
        icon: Icons.inventory_2,
        path: '/stock',
      ));
      list.add(const _NavDest(
        label: 'Cashier',
        icon: Icons.point_of_sale,
        path: '/cashier',
      ));
    }

    // Only Manufacturer gets Cutter
    if (user?.role == 'Manufacturer') {
      list.add(const _NavDest(
        label: 'Cutter',
        icon: Icons.content_cut,
        path: '/cutter',
      ));
    }
    list.add(const _NavDest(label: 'Profile', icon: Icons.person_rounded,         path: '/profile'));
    return list;
  }

  static int _indexOf(String location, List<_NavDest> destinations) {
    for (var i = 0; i < destinations.length; i++) {
      if (location.startsWith(destinations[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user         = ref.watch(authProvider).user;
    final location     = GoRouterState.of(context).matchedLocation;
    final destinations = _getDestinations(user);
    final selIdx       = _indexOf(location, destinations);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _AppHeader(user: user, ref: ref),
      drawer: _AppDrawer(
        user: user, destinations: destinations,
        selectedIdx: selIdx, ref: ref,
      ),
      body: Stack(
        children: [
          child,
          const ToastOverlay(),
          const NotificationOverlay(),
        ],
      ),
      bottomNavigationBar: _AppFooter(
        destinations: destinations, selectedIdx: selIdx,
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const _AppHeader({required this.user, required this.ref});

  final dynamic   user;
  final WidgetRef ref;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.dark,
      foregroundColor: AppColors.cream,
      elevation: 0,
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu_rounded),
          tooltip: 'Menu',
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      title: Row(
        children: [
          // Logo
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              color: AppColors.gold,
              borderRadius: BorderRadius.circular(7),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              'assets/images/logo.jpg',
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Shmeta',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: AppColors.cream,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
      actions: [
        if (user != null)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.4), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  user!.role == 'Manufacturer'
                      ? Icons.factory_rounded
                      : Icons.storefront_rounded,
                  size: 13,
                  color: AppColors.gold,
                ),
                const SizedBox(width: 4),
                Text(
                  user!.role,
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(width: 8),
      ],
    );
  }
}

// ── Drawer ────────────────────────────────────────────────────────────────────

class _AppDrawer extends StatelessWidget {
  const _AppDrawer({
    required this.user,
    required this.destinations,
    required this.selectedIdx,
    required this.ref,
  });

  final dynamic        user;
  final List<_NavDest> destinations;
  final int            selectedIdx;
  final WidgetRef      ref;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.dark,
      child: Column(
        children: [
          // ── Drawer header ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
            decoration: BoxDecoration(
              color: AppColors.dark,
              border: Border(
                bottom: BorderSide(
                    color: AppColors.gold.withValues(alpha: 0.2), width: 1),
              ),
            ),
            child: Row(
              children: [
                // Logo circle
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.5), width: 2),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset('assets/images/logo.jpg', fit: BoxFit.cover),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Shmeta',
                        style: TextStyle(
                          color: AppColors.cream,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.name ?? 'User',
                        style: TextStyle(
                          color: AppColors.cream.withValues(alpha: 0.8),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        user?.phone ?? '',
                        style: TextStyle(
                          color: AppColors.textLight.withValues(alpha: 0.7),
                          fontSize: 11,
                        ),
                      ),
                      if (user?.role != null) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppColors.gold.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                user!.role == 'Manufacturer'
                                    ? Icons.factory_rounded
                                    : Icons.storefront_rounded,
                                size: 11,
                                color: AppColors.gold,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                user!.role,
                                style: const TextStyle(
                                  color: AppColors.gold,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Nav items ──────────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                for (var i = 0; i < destinations.length; i++)
                  _DrawerTile(
                    icon:     destinations[i].icon,
                    label:    destinations[i].label,
                    selected: selectedIdx == i,
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go(destinations[i].path);
                    },
                  ),
                Divider(
                    color: AppColors.gold.withValues(alpha: 0.15),
                    indent: 16, endIndent: 16),
                _DrawerTile(
                  icon:     Icons.lock_reset_rounded,
                  label:    'Change Password',
                  selected: false,
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push('/change-password');
                  },
                ),
              ],
            ),
          ),

          // ── Footer ─────────────────────────────────────────────────────
          Divider(
              color: AppColors.gold.withValues(alpha: 0.15), height: 1),
          InkWell(
            onTap: () async {
              Navigator.of(context).pop();
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  const Icon(Icons.logout_rounded,
                      color: Colors.redAccent, size: 20),
                  const SizedBox(width: 14),
                  const Text('Logout',
                      style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w500)),
                  const Spacer(),
                  Text('v1.0.0',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textLight
                              .withValues(alpha: 0.5))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData     icon;
  final String       label;
  final bool         selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Container(
        decoration: BoxDecoration(
          color: selected
              ? AppColors.gold.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.gold : Colors.white.withValues(alpha: 0.12),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 22,
                    color: selected ? AppColors.gold : Colors.white,
                  ),
                  const SizedBox(width: 14),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white, // ALL PAGE NAMES IN WHITE
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  if (selected) ...[
                    const Spacer(),
                    Container(
                      width: 8, height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.gold,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Bottom nav ────────────────────────────────────────────────────────────────

class _AppFooter extends StatelessWidget {
  const _AppFooter({
    required this.destinations,
    required this.selectedIdx,
  });

  final List<_NavDest> destinations;
  final int            selectedIdx;

  @override
  Widget build(BuildContext context) {
    // Bottom bar only shows Home, Stock, and Profile
    final bottomDestinations = destinations.where((d) {
      return d.path == '/dashboard' || d.path == '/stock' || d.path == '/profile';
    }).toList();

    // Compute active index for bottom bar destinations
    var bottomIdx = 0;
    if (selectedIdx < destinations.length) {
      final currentPath = destinations[selectedIdx].path;
      final idx = bottomDestinations.indexWhere((d) => currentPath.startsWith(d.path));
      if (idx != -1) bottomIdx = idx;
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: NavigationBar(
        selectedIndex: bottomIdx,
        onDestinationSelected: (i) => context.go(bottomDestinations[i].path),
        backgroundColor: Colors.white,
        elevation: 0,
        indicatorColor: AppColors.goldLight,
        destinations: [
          for (final d in bottomDestinations)
            NavigationDestination(icon: Icon(d.icon), label: d.label),
        ],
      ),
    );
  }
}

// ── Model ─────────────────────────────────────────────────────────────────────

class _NavDest {
  const _NavDest({
    required this.label,
    required this.icon,
    required this.path,
  });

  final String   label;
  final IconData icon;
  final String   path;
}
