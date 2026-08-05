import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/credit_repository.dart';
import '../models/credit_model.dart';

// ── Cashier: own credit list ─────────────────────────────────────────────────
class CashierCreditNotifier extends AsyncNotifier<List<CreditRecord>> {
  @override
  Future<List<CreditRecord>> build() =>
      ref.watch(creditRepositoryProvider).fetchMyCashierCredits();

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(creditRepositoryProvider).fetchMyCashierCredits());
  }

  Future<String?> addPayment(String creditId, double amount, {String? note}) async {
    try {
      final updated = await ref
          .read(creditRepositoryProvider)
          .addPayment(creditId, amount, note: note);
      // Replace in local list
      state = AsyncData((state.valueOrNull ?? [])
          .map((c) => c.id == creditId ? updated : c)
          .toList());
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}

final cashierCreditProvider =
    AsyncNotifierProvider<CashierCreditNotifier, List<CreditRecord>>(
        CashierCreditNotifier.new);

// ── Owner: all credits from cashiers ─────────────────────────────────────────
final ownerCreditsProvider =
    FutureProvider.autoDispose<List<CreditRecord>>((ref) =>
        ref.watch(creditRepositoryProvider).fetchOwnerCredits());

// ── Owner dashboard stats ─────────────────────────────────────────────────────
final ownerCreditStatsProvider =
    FutureProvider.autoDispose<CreditStats>((ref) =>
        ref.watch(creditRepositoryProvider).fetchOwnerStats());
