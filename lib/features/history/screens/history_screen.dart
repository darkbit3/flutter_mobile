import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../cashier/data/credit_repository.dart';
import '../../cashier/models/credit_model.dart';
import '../../cashier/providers/credit_provider.dart';
import '../../sales/data/sale_repository.dart';
import '../../sales/models/sale_model.dart';
import '../../sales/providers/sale_provider.dart';

final ownerHistorySalesProvider = FutureProvider.autoDispose<List<SaleModel>>((ref) {
  return ref.watch(saleRepositoryProvider).getOwnerSales();
});

final ownerHistoryCreditsProvider = FutureProvider.autoDispose<List<CreditRecord>>((ref) {
  return ref.watch(creditRepositoryProvider).fetchOwnerCredits();
});

class _HistoryEntry {
  const _HistoryEntry({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.timestamp,
    required this.type,
    required this.isCredit,
    required this.color,
  });

  final String id;
  final String title;
  final String subtitle;
  final double amount;
  final DateTime timestamp;
  final String type;
  final bool isCredit;
  final Color color;
}

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    if (user == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.gold)),
      );
    }

    final salesState = ref.watch(saleListProvider);
    final creditsAsync = ref.watch(cashierCreditProvider);
    final ownerSalesAsync = ref.watch(ownerHistorySalesProvider);
    final ownerCreditsAsync = ref.watch(ownerHistoryCreditsProvider);

    final List<_HistoryEntry> entries = [];

    if (user.isCashier) {
      for (final sale in salesState.sales) {
        entries.add(_HistoryEntry(
          id: 'sale-${sale.id}',
          title: sale.customer ?? 'Customer sale',
          subtitle: '${sale.items.length} item(s) • ${sale.cashierName ?? 'Cashier'}',
          amount: sale.totalAmount,
          timestamp: DateTime.tryParse(sale.createdAt) ?? DateTime.now(),
          type: 'Sale',
          isCredit: sale.isCredit,
          color: sale.isCredit ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
        ));
      }

      for (final credit in creditsAsync.valueOrNull ?? const <CreditRecord>[]) {
        entries.add(_HistoryEntry(
          id: 'credit-${credit.id}',
          title: 'Credit: ${credit.customer}',
          subtitle: 'Outstanding ${credit.remaining.toStringAsFixed(0)} ETB • ${credit.payments.length} payment(s)',
          amount: credit.totalAmount,
          timestamp: DateTime.tryParse(credit.createdAt) ?? DateTime.now(),
          type: 'Credit',
          isCredit: true,
          color: const Color(0xFFF59E0B),
        ));
      }
    } else {
      final sales = ownerSalesAsync.valueOrNull ?? const <SaleModel>[];
      for (final sale in sales) {
        entries.add(_HistoryEntry(
          id: 'sale-${sale.id}',
          title: sale.customer ?? 'Customer sale',
          subtitle: '${sale.items.length} item(s) • ${sale.cashierName ?? 'Cashier'}',
          amount: sale.totalAmount,
          timestamp: DateTime.tryParse(sale.createdAt) ?? DateTime.now(),
          type: 'Sale',
          isCredit: sale.isCredit,
          color: sale.isCredit ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
        ));
      }

      final credits = ownerCreditsAsync.valueOrNull ?? const <CreditRecord>[];
      for (final credit in credits) {
        entries.add(_HistoryEntry(
          id: 'credit-${credit.id}',
          title: 'Credit: ${credit.customer}',
          subtitle: 'Cashier: ${credit.cashierName ?? 'Owner'} • Remaining ${credit.remaining.toStringAsFixed(0)} ETB',
          amount: credit.totalAmount,
          timestamp: DateTime.tryParse(credit.createdAt) ?? DateTime.now(),
          type: 'Credit',
          isCredit: true,
          color: const Color(0xFFF59E0B),
        ));
      }
    }

    entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final summaryTotal = entries.fold<double>(0, (sum, e) => sum + e.amount);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('History'),
        backgroundColor: AppColors.dark,
        foregroundColor: AppColors.cream,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (user.isCashier) {
            await ref.read(saleListProvider.notifier).load();
            await ref.read(cashierCreditProvider.notifier).reload();
          } else {
            ref.invalidate(ownerHistorySalesProvider);
            ref.invalidate(ownerHistoryCreditsProvider);
          }
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.dark,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.dark.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Activity Summary',
                    style: TextStyle(
                      color: AppColors.cream,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          label: 'Entries',
                          value: '${entries.length}',
                          icon: Icons.history_rounded,
                          color: AppColors.gold,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SummaryCard(
                          label: 'Total',
                          value: '${summaryTotal.toStringAsFixed(0)} ETB',
                          icon: Icons.payments_rounded,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long_rounded, color: AppColors.gold, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    user.isCashier ? 'Cashier sales & credits' : 'Owner sales & credits',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.dark),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (entries.isEmpty)
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.history_rounded, size: 42, color: AppColors.textLight),
                    SizedBox(height: 12),
                    Text(
                      'No sales or credit activity yet',
                      style: TextStyle(color: AppColors.textMid, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              )
            else
              ...entries.map((entry) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: entry.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          entry.isCredit ? Icons.account_balance_wallet_rounded : Icons.sell_rounded,
                          color: entry.color,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    entry.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.dark,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${entry.amount.toStringAsFixed(0)} ETB',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: entry.color,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              entry.subtitle,
                              style: const TextStyle(fontSize: 12, color: AppColors.textMid),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${entry.type} • ${_formatDate(entry.timestamp)}',
                              style: TextStyle(fontSize: 11, color: AppColors.textLight.withValues(alpha: 0.9)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime value) {
    final now = DateTime.now();
    final diff = now.difference(value);
    if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    }
    if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    }
    if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    }
    return 'just now';
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.cream,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(color: AppColors.cream.withValues(alpha: 0.7), fontSize: 11),
          ),
        ],
      ),
    );
  }
}
