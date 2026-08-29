import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/reset_password_screen.dart';
import '../features/auth/screens/change_password_screen.dart';
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/profile/screens/settings_screen.dart';
import '../features/stock/screens/stock_screen.dart';
import '../features/cashier/screens/cashier_screen.dart';
import '../features/cashier/screens/cashier_dashboard_screen.dart';
import '../features/cashier/screens/credit_list_screen.dart';
import '../features/sales/screens/sales_screen.dart';
import '../features/cutter/screens/cutter_screen.dart';
import '../features/cutter/screens/cutter_dashboard_screen.dart';
import '../shell/app_shell.dart';
import '../shell/cashier_shell.dart';
import '../shell/cutter_shell.dart';

// ── RouterNotifier watches authProvider and notifies GoRouter to re-evaluate
// the redirect — the router itself is created only once. ──────────────────────

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    _ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
  }

  final Ref _ref;

  String? redirect(BuildContext context, GoRouterState state) {
    final auth       = _ref.read(authProvider);
    final isLoggedIn = auth.status == AuthStatus.authenticated;
    final loc        = state.matchedLocation;
    final publicPages = ['/login', '/forgot-password'];

    if (auth.status == AuthStatus.initial) return null;

    if (!isLoggedIn && !publicPages.contains(loc)) return '/login';

    if (isLoggedIn && loc == '/login') {
      if (auth.user?.isCashier ?? false) return '/cashier-dashboard';
      if (auth.user?.isCutter  ?? false) return '/cutter-dashboard';
      return '/dashboard';
    }

    // Role-based route protection
    if (isLoggedIn) {
      if (auth.user?.isCashier ?? false) {
        if (!loc.startsWith('/cashier-dashboard')) return '/cashier-dashboard';
      } else if (auth.user?.isCutter ?? false) {
        if (!loc.startsWith('/cutter-dashboard')) return '/cutter-dashboard';
      }
    }

    return null;
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    initialLocation:  '/login',
    refreshListenable: notifier,
    redirect:          notifier.redirect,
    routes: [
      // ── Public ─────────────────────────────────────────────────────────
      GoRoute(
        path:        '/login',
        pageBuilder: (_, state) => _fade(state, const LoginScreen()),
      ),
      GoRoute(
        path:        '/forgot-password',
        pageBuilder: (_, state) => _fade(state, const ResetPasswordScreen()),
      ),

      // ── Protected (Manufacturer / Reseller) ─────────────────────────────
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path:        '/dashboard',
            pageBuilder: (_, state) => _noAnim(state, const DashboardScreen()),
          ),
          GoRoute(
            path:        '/stock',
            pageBuilder: (_, state) => _noAnim(state, const StockScreen()),
          ),
          GoRoute(
            path:        '/cashier',
            pageBuilder: (_, state) => _noAnim(state, const CashierScreen()),
          ),
          GoRoute(
            path:        '/cutter',
            pageBuilder: (_, state) => _noAnim(state, const CutterScreen()),
          ),
          GoRoute(
            path:        '/profile',
            pageBuilder: (_, state) => _noAnim(state, const ProfileScreen()),
          ),
          GoRoute(
            path:        '/settings',
            pageBuilder: (_, state) => _noAnim(state, const SettingsScreen()),
          ),
          GoRoute(
            path:        '/change-password',
            pageBuilder: (_, state) => _noAnim(state, const ChangePasswordScreen()),
          ),
        ],
      ),

      // ── Protected (Cashier Shell) ────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => CashierShell(child: child),
        routes: [
          GoRoute(
            path:        '/cashier-dashboard',
            pageBuilder: (_, state) => _noAnim(state, const CashierDashboardScreen()),
          ),
          GoRoute(
            path:        '/cashier-dashboard/credits',
            pageBuilder: (_, state) => _noAnim(state, const CreditListScreen()),
          ),
          GoRoute(
            path:        '/cashier-dashboard/sales',
            pageBuilder: (_, state) => _noAnim(state, const SalesScreen()),
          ),
          GoRoute(
            path:        '/cashier-dashboard/change-password',
            pageBuilder: (_, state) => _noAnim(state, const ChangePasswordScreen()),
          ),
        ],
      ),

      // ── Protected (Cutter Shell) ─────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => CutterShell(child: child),
        routes: [
          GoRoute(
            path:        '/cutter-dashboard',
            pageBuilder: (_, state) => _noAnim(state, const CutterDashboardScreen()),
          ),
          GoRoute(
            path:        '/cutter-dashboard/change-password',
            pageBuilder: (_, state) => _noAnim(state, const ChangePasswordScreen()),
          ),
        ],
      ),
    ],
  );
});

CustomTransitionPage<void> _fade(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key:               state.pageKey,
    child:             child,
    transitionsBuilder: (_, animation, __, c) =>
        FadeTransition(opacity: animation, child: c),
  );
}

NoTransitionPage<void> _noAnim(GoRouterState state, Widget child) {
  return NoTransitionPage<void>(key: state.pageKey, child: child);
}
