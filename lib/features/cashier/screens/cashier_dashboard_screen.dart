import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../../sales/providers/sale_provider.dart';
import '../providers/credit_provider.dart';
import '../../sales/screens/new_sale_sheet.dart';

class CashierDashboardScreen extends ConsumerWidget {
  const CashierDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user          = ref.watch(authProvider).user;
    final salesState    = ref.watch(saleListProvider);
    final creditsAsync  = ref.watch(cashierCreditProvider);

    final stats         = salesState.stats;
    final salesList     = salesState.sales;

    final creditsList   = creditsAsync.valueOrNull ?? [];
    final openCredits   = creditsList.where((c) => !c.isFullyPaid).toList();
    final remainingSum  = openCredits.fold(0.0, (s, c) => s + c.remaining);

    return RefreshIndicator(
      color: const Color(0xFF10B981),
      onRefresh: () async {
        await ref.read(saleListProvider.notifier).load();
        await ref.read(cashierCreditProvider.notifier).reload();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Welcome Banner ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 54, height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        user?.name ?? '—',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.point_of_sale_rounded, size: 12, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'Cashier',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // ── Stats Cards (Real Data) ──────────────────────────────────────
          const _SectionLabel(text: 'Today\'s Overview'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => context.go('/cashier-dashboard/sales'),
                  child: _StatCard(
                    icon: Icons.sell_rounded,
                    label: 'Total Sales',
                    value: '${stats.totalRevenue.toStringAsFixed(0)} ETB',
                    sub: '${stats.totalSales} transactions →',
                    color: const Color(0xFF10B981),
                    bg: const Color(0xFFECFDF5),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => context.go('/cashier-dashboard/credits'),
                  child: _StatCard(
                    icon: Icons.account_balance_wallet_rounded,
                    label: 'Total Credit',
                    value: '${stats.totalCredit.toStringAsFixed(0)} ETB',
                    sub: '${openCredits.length} outstanding (${remainingSum.toStringAsFixed(0)} left) →',
                    color: const Color(0xFFF59E0B),
                    bg: const Color(0xFFFFFBEB),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.receipt_long_rounded,
                  label: 'Total Orders',
                  value: '${stats.totalSales}',
                  sub: 'recorded sales',
                  color: const Color(0xFF6366F1),
                  bg: const Color(0xFFEEF2FF),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.trending_up_rounded,
                  label: 'Net Cash',
                  value: '${stats.totalCash.toStringAsFixed(0)} ETB',
                  sub: 'cash collected',
                  color: const Color(0xFF3B82F6),
                  bg: const Color(0xFFEFF6FF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Recent Transactions (Real Data) ──────────────────────────────
          const _SectionLabel(text: 'Recent Sales'),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: salesList.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: Text('No sales recorded yet',
                          style: TextStyle(color: Colors.grey)),
                    ),
                  )
                : Column(
                    children: List.generate(
                      salesList.length > 5 ? 5 : salesList.length,
                      (i) {
                        final s = salesList[i];
                        final isCash = s.isCash;
                        return Column(
                          children: [
                            if (i > 0) const _Divider(),
                            _TransactionItem(
                              title: '${s.isCash ? "Sale" : "Credit"} — ${s.customer ?? "Cash Customer"}',
                              amount: '${isCash ? "+" : ""}${s.totalAmount.toStringAsFixed(0)} ETB',
                              time: _fmtDate(s.createdAt),
                              type: isCash ? _TxType.sale : _TxType.credit,
                              onTap: s.isCash
                                  ? null
                                  : () => context.go('/cashier-dashboard/credits'),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
          ),
          const SizedBox(height: 24),

          // ── Quick Actions ────────────────────────────────────────────────
          const _SectionLabel(text: 'Quick Actions'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.add_shopping_cart_rounded,
                  label: 'New Sale',
                  color: const Color(0xFF10B981),
                  onTap: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const NewSaleSheet(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  icon: Icons.credit_card_rounded,
                  label: 'View Credits',
                  color: const Color(0xFFF59E0B),
                  onTap: () => context.go('/cashier-dashboard/credits'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Enums ────────────────────────────────────────────────────────────────────

enum _TxType { sale, credit }

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 15,
        color: Color(0xFF1F2937),
        letterSpacing: 0.2,
      ),
    );
  }
}

// ── Stat Card Component ──────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
    required this.bg,
  });

  final IconData icon;
  final String   label;
  final String   value;
  final String   sub;
  final Color    color;
  final Color    bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Transaction Item Component ───────────────────────────────────────────────

class _TransactionItem extends StatelessWidget {
  const _TransactionItem({
    required this.title,
    required this.amount,
    required this.time,
    required this.type,
    this.onTap,
  });

  final String       title;
  final String       amount;
  final String       time;
  final _TxType      type;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isSale = type == _TxType.sale;
    final color  = isSale ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    final bg     = isSale ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB);
    final icon   = isSale ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: Color(0xFF1F2937),
        ),
      ),
      subtitle: Text(
        time,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
      ),
      trailing: Text(
        amount,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: color,
        ),
      ),
    );
  }
}

// ── Action Button Component ──────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData   icon;
  final String     label;
  final Color      color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared Divider ────────────────────────────────────────────────────────────

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      color: Colors.grey.shade100,
      indent: 16,
      endIndent: 16,
    );
  }
}

String _fmtDate(String iso) {
  const months = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  try {
    final dt = DateTime.parse(iso);
    return '${dt.day} ${months[dt.month]}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  } catch (_) {
    return iso;
  }
}
