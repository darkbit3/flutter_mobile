class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'https://backend-1-khts.onrender.com/api';

  // ── User auth endpoints ─────────────────────────────────────────────────
  static const String userLogin          = '/user-auth/login';
  static const String userMe             = '/user-auth/me';
  static const String userChangePassword = '/user-auth/change-password';
  static const String userAlertThreshold = '/user-auth/alert-threshold';

  // ── Cashier endpoints ────────────────────────────────────────────────────
  static const String cashiers = '/cashiers';

  // ── Sales endpoints ──────────────────────────────────────────────────────
  static const String sales       = '/sales';
  static const String salesStats  = '/sales/stats';
  static const String salesOwner  = '/sales/owner';

  // ── Materials / Stock endpoints ──────────────────────────────────────────
  static const String materials           = '/materials';
  static const String materialsOwnerStock = '/materials/owner-stock';

  // ── Credits endpoints ──────────────────────────────────────────
  static const String credits            = '/credits';
  static const String creditsOwner       = '/credits/owner';
  static const String creditsOwnerStats  = '/credits/owner/stats';

  // ── Cutter endpoints ─────────────────────────────────────────────────────
  static const String cutters = '/cutters';
}
