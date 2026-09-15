import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/localization/language_provider.dart';
import '../core/toast/toast_overlay.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/sales/screens/new_sale_sheet.dart';

class CashierShell extends ConsumerWidget {
  const CashierShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final text = AppText(ref.watch(languageProvider));
    final location = GoRouterState.of(context).matchedLocation;
    final title = location.contains('credits')
        ? (text.isAmharic ? 'ዱቤ' : 'Credits')
        : location.contains('sales')
            ? (text.isAmharic ? 'ሽያጭ' : 'Sales')
            : text.dashboard;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
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
              child: Image.asset('assets/images/logo.jpg', width: 28, height: 28, fit: BoxFit.cover),
            ),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 19)),
          ],
        ),
        actions: [
          if (user != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              child: Chip(
                avatar: const Icon(Icons.point_of_sale, size: 14, color: Colors.white),
                label: Text(text.cashier, style: const TextStyle(color: Colors.white, fontSize: 11)),
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                side: BorderSide.none,
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: text.logout,
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      drawer: _CashierDrawer(user: user, ref: ref, text: text),
      body: Stack(children: [child, const ToastOverlay()]),
      floatingActionButton: location.contains('sales')
          ? FloatingActionButton.extended(
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const NewSaleSheet(),
              ),
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_shopping_cart_rounded),
              label: Text(text.isAmharic ? 'አዲስ ሽያጭ' : 'New Sale'),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: NavigationBar(
        selectedIndex: location.contains('credits') ? 1 : location.contains('sales') ? 2 : 0,
        onDestinationSelected: (index) {
          if (index == 0) context.go('/cashier-dashboard');
          if (index == 1) context.go('/cashier-dashboard/credits');
          if (index == 2) context.go('/cashier-dashboard/sales');
        },
        destinations: [
          NavigationDestination(icon: const Icon(Icons.dashboard_rounded), label: text.dashboard),
          NavigationDestination(icon: const Icon(Icons.account_balance_wallet_rounded), label: text.isAmharic ? 'ዱቤ' : 'Credits'),
          NavigationDestination(icon: const Icon(Icons.sell_rounded), label: text.isAmharic ? 'ሽያጭ' : 'Sales'),
        ],
      ),
    );
  }
}

class _CashierDrawer extends StatelessWidget {
  const _CashierDrawer({required this.user, required this.ref, required this.text});
  final dynamic user;
  final WidgetRef ref;
  final AppText text;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF111827),
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF10B981)),
            child: Row(
              children: [
                ClipOval(child: Image.asset('assets/images/logo.jpg', width: 52, height: 52, fit: BoxFit.cover)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Shmeta', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold)),
                      Text(user?.name ?? text.cashier, style: const TextStyle(color: Colors.white), overflow: TextOverflow.ellipsis),
                      Text(user?.phone ?? '', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                      Text(text.cashier, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                _DrawerTile(icon: Icons.dashboard_rounded, label: text.dashboard, path: '/cashier-dashboard'),
                _DrawerTile(icon: Icons.account_balance_wallet_rounded, label: text.isAmharic ? 'ዱቤ' : 'Credits', path: '/cashier-dashboard/credits'),
                _DrawerTile(icon: Icons.sell_rounded, label: text.isAmharic ? 'ሽያጭ' : 'Sales', path: '/cashier-dashboard/sales'),
                _DrawerTile(icon: Icons.lock_reset_rounded, label: text.changePassword, path: '/cashier-dashboard/change-password'),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: Text(text.logout, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            onTap: () async {
              Navigator.of(context).pop();
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({required this.icon, required this.label, required this.path});
  final IconData icon;
  final String label;
  final String path;

  @override
  Widget build(BuildContext context) {
    final active = GoRouterState.of(context).matchedLocation == path;
    return ListTile(
      leading: Icon(icon, color: active ? const Color(0xFF10B981) : Colors.white),
      title: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      selected: active,
      onTap: () {
        Navigator.of(context).pop();
        context.go(path);
      },
    );
  }
}
