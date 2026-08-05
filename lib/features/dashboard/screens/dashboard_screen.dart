import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../cashier/models/credit_model.dart';
import '../../cashier/providers/credit_provider.dart';
import '../../stock/providers/material_provider.dart';
import '../../sales/data/sale_repository.dart';

// ── Owner sales stats provider ────────────────────────────────────────────────
final ownerSaleStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(saleRepositoryProvider);
  final sales = await repo.getOwnerSales();
  final total   = sales.fold(0.0, (s, e) => s + e.totalAmount);
  final credit  = sales.where((e) => !e.isCash).fold(0.0, (s, e) => s + e.totalAmount);
  final cash    = total - credit;
  return {
    'total_sales':   sales.length,
    'total_revenue': total,
    'total_credit':  credit,
    'total_cash':    cash,
  };
});

// ═══════════════════════════════════════════════════════════════════════════
// DashboardScreen
// ═══════════════════════════════════════════════════════════════════════════
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user             = ref.watch(authProvider).user;
    final isManufacturer   = user?.role == 'Manufacturer';
    final saleStatsAsync   = ref.watch(ownerSaleStatsProvider);
    final creditStatsAsync = ref.watch(ownerCreditStatsProvider);
    final ownerCreditsAsync = ref.watch(ownerCreditsProvider);
    final materialsAsync   = ref.watch(materialsProvider);

    return RefreshIndicator(
      color: AppColors.gold,
      onRefresh: () async {
        ref.invalidate(ownerSaleStatsProvider);
        ref.invalidate(ownerCreditStatsProvider);
        ref.invalidate(ownerCreditsProvider);
        ref.invalidate(materialsProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // ── Welcome Banner ───────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.dark,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.dark.withValues(alpha: 0.2),
                  blurRadius: 12, offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 54, height: 54,
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.5), width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      user?.name.isNotEmpty == true
                          ? user!.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          color: AppColors.gold,
                          fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Welcome back',
                          style: TextStyle(
                              color: AppColors.cream.withValues(alpha: 0.6),
                              fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(user?.name ?? '—',
                          style: const TextStyle(
                              color: AppColors.cream,
                              fontSize: 19, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppColors.gold.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isManufacturer
                                  ? Icons.factory_rounded
                                  : Icons.storefront_rounded,
                              size: 12, color: AppColors.gold,
                            ),
                            const SizedBox(width: 4),
                            Text(user?.role ?? '',
                                style: const TextStyle(
                                    color: AppColors.gold,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Low Stock Alert Banner (if any materials ≤ 20%) ──────────────
          materialsAsync.when(
            loading: () => const SizedBox.shrink(),
            error:   (_, __) => const SizedBox.shrink(),
            data: (materials) {
              final lowStockList = materials.where((m) => m.isLowStock).toList();
              if (lowStockList.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.red.shade300, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.1),
                          blurRadius: 10, offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                color: Colors.red.shade700, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              'Low Stock Alert (≤ 20% Remaining)',
                              style: TextStyle(
                                color: Colors.red.shade900,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${lowStockList.length} material(s) need restocking urgently:',
                          style: TextStyle(
                              color: Colors.red.shade800, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        Column(
                          children: lowStockList.map((m) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  Icon(
                                    m.isMeter
                                        ? Icons.straighten_rounded
                                        : Icons.widgets_rounded,
                                    size: 16,
                                    color: Colors.red.shade700,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      '${m.name} — ${m.quantity.toStringAsFixed(m.isMeter ? 1 : 0)} ${m.unitLabel} remaining (${m.remainingPercentage.toStringAsFixed(0)}%)',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red.shade900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              );
            },
          ),

          // ── Sales Stats Row ──────────────────────────────────────────────
          const _SectionTitle(title: 'Sales Overview'),
          const SizedBox(height: 12),
          saleStatsAsync.when(
            loading: () => const _StatsShimmer(),
            error:   (_, __) => const _StatsError(),
            data: (stats) => Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Total Revenue',
                    value: '${(stats['total_revenue'] as double).toStringAsFixed(0)} ETB',
                    subtitle: '${stats['total_sales']} orders',
                    icon: Icons.payments_rounded,
                    accentColor: const Color(0xFF10B981),
                    bgColor: const Color(0xFFECFDF5),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Cash Sales',
                    value: '${(stats['total_cash'] as double).toStringAsFixed(0)} ETB',
                    subtitle: 'Cash collected',
                    icon: Icons.point_of_sale_rounded,
                    accentColor: AppColors.gold,
                    bgColor: AppColors.goldLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Credit Summary Banner ────────────────────────────────────────
          const _SectionTitle(title: 'Credit Overview'),
          const SizedBox(height: 12),
          creditStatsAsync.when(
            loading: () => const _StatsShimmer(),
            error:   (_, __) => const _StatsError(),
            data: (stats) => Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                    blurRadius: 12, offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.account_balance_wallet_rounded,
                          color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text('Credit Accounts',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _CreditBannerStat(label: 'Total Credits',
                          value: '${stats.totalCredits}'),
                      _CreditBannerStat(label: 'Total Given',
                          value: '${stats.totalAmount.toStringAsFixed(0)} ETB'),
                      _CreditBannerStat(label: 'Outstanding',
                          value: '${stats.totalRemaining.toStringAsFixed(0)} ETB'),
                    ],
                  ),
                  if (stats.totalAmount > 0) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: stats.totalAmount > 0
                            ? (stats.totalPaid / stats.totalAmount).clamp(0.0, 1.0)
                            : 0,
                        backgroundColor: Colors.white.withValues(alpha: 0.3),
                        valueColor:
                            const AlwaysStoppedAnimation(Colors.white),
                        minHeight: 7,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${stats.totalAmount > 0 ? ((stats.totalPaid / stats.totalAmount) * 100).toStringAsFixed(0) : 0}% collected  •  ${stats.totalPaid.toStringAsFixed(0)} ETB paid',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Credit List ─────────────────────────────────────────────────
          const _SectionTitle(title: 'Credit Customers'),
          const SizedBox(height: 12),
          ownerCreditsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                  child: CircularProgressIndicator(color: AppColors.gold)),
            ),
            error: (_, __) => Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border)),
              child: const Text('Could not load credits.',
                  style: TextStyle(color: Colors.grey)),
            ),
            data: (credits) {
              if (credits.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border)),
                  child: const Column(
                    children: [
                      Icon(Icons.account_balance_wallet_outlined,
                          size: 36, color: AppColors.textLight),
                      SizedBox(height: 8),
                      Text('No credit customers yet',
                          style: TextStyle(
                              color: AppColors.textMid,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: credits.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (ctx, i) => _OwnerCreditTile(
                  credit: credits[i],
                  onTap: () => _showCreditDetail(ctx, credits[i]),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // ── Account Info ─────────────────────────────────────────────────
          const _SectionTitle(title: 'Account Info'),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: const Border.fromBorderSide(
                  BorderSide(color: AppColors.border)),
            ),
            child: Column(
              children: [
                _InfoRow(icon: Icons.person_outline,  label: 'Name',  value: user?.name ?? '—'),
                const _Divider(),
                _InfoRow(icon: Icons.phone_outlined,  label: 'Phone', value: user?.phone ?? '—'),
                const _Divider(),
                _InfoRow(
                  icon: isManufacturer
                      ? Icons.factory_rounded
                      : Icons.storefront_rounded,
                  label: 'Role', value: user?.role ?? '—',
                  valueColor: AppColors.gold,
                ),
                const _Divider(),
                _InfoRow(
                  icon: user?.status == 'Active'
                      ? Icons.check_circle_outline
                      : Icons.block_rounded,
                  label: 'Status', value: user?.status ?? '—',
                  valueColor: user?.status == 'Active'
                      ? AppColors.success
                      : AppColors.warning,
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _showCreditDetail(BuildContext context, CreditRecord credit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Consumer(
        builder: (_, ref, __) =>
            _OwnerCreditDetailSheet(credit: credit, ref: ref),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Owner Credit Tile (read-only — owner cannot add payment here)
// ═══════════════════════════════════════════════════════════════════════════
class _OwnerCreditTile extends StatelessWidget {
  const _OwnerCreditTile({required this.credit, required this.onTap});
  final CreditRecord credit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final paid  = credit.isFullyPaid;
    final color = paid ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    final bg    = paid ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6, offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
              child: Center(
                child: Text(
                  credit.customer.isNotEmpty
                      ? credit.customer[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Name & cashier
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(credit.customer,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF1F2937))),
                  const SizedBox(height: 2),
                  if (credit.cashierName != null)
                    Text('by ${credit.cashierName}',
                        style: const TextStyle(
                            fontSize: 11, color: Colors.grey)),
                  Text(_fmtDate(credit.createdAt),
                      style: const TextStyle(
                          fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 4),
                  // Mini progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: credit.paidPercent,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation(color),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Amount + status
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${credit.totalAmount.toStringAsFixed(0)} ETB',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF1F2937))),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(10)),
                  child: Text(
                    paid
                        ? '✓ Paid'
                        : '${credit.remaining.toStringAsFixed(0)} left',
                    style: TextStyle(
                        fontSize: 10,
                        color: color,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 2),
                const Icon(Icons.chevron_right, color: Colors.grey, size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Owner Credit Detail Sheet (read-only — shows full payment history)
// ═══════════════════════════════════════════════════════════════════════════
class _OwnerCreditDetailSheet extends StatelessWidget {
  const _OwnerCreditDetailSheet(
      {required this.credit, required this.ref});
  final CreditRecord credit;
  final WidgetRef    ref;

  @override
  Widget build(BuildContext context) {
    final paid  = credit.isFullyPaid;
    final color = paid ? const Color(0xFF10B981) : const Color(0xFFF59E0B);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize:     0.5,
      maxChildSize:     0.95,
      builder: (ctx, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 16, 0),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        shape: BoxShape.circle),
                    child: Center(
                      child: Text(
                        credit.customer.isNotEmpty
                            ? credit.customer[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(credit.customer,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                                color: Color(0xFF1F2937))),
                        if (credit.cashierName != null)
                          Text('Cashier: ${credit.cashierName}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                        Text(_fmtDate(credit.createdAt),
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(paid ? 'PAID' : 'OUTSTANDING',
                        style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 11)),
                  ),
                ],
              ),
            ),
            const Divider(height: 20),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                children: [
                  // Amounts
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200)),
                    child: Column(
                      children: [
                        _AmountRow(label: 'Total Credit',
                            value: '${credit.totalAmount.toStringAsFixed(2)} ETB',
                            bold: true),
                        const Divider(height: 16),
                        _AmountRow(label: 'Total Paid',
                            value: '${credit.totalPaid.toStringAsFixed(2)} ETB',
                            color: const Color(0xFF10B981)),
                        const SizedBox(height: 6),
                        _AmountRow(label: 'Remaining',
                            value: '${credit.remaining.toStringAsFixed(2)} ETB',
                            color: color,
                            bold: true),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: credit.paidPercent,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation(color),
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(credit.paidPercent * 100).toStringAsFixed(0)}% collected',
                          style: TextStyle(
                              fontSize: 12, color: color,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (credit.note != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.blue.shade100)),
                      child: Row(
                        children: [
                          const Icon(Icons.notes_rounded,
                              color: Colors.blue, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(credit.note!,
                                  style: const TextStyle(
                                      fontSize: 13, color: Colors.blue))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  const Text('Payment History',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF1F2937))),
                  const SizedBox(height: 10),
                  if (credit.payments.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10)),
                      child: const Text('No payments made yet.',
                          style: TextStyle(color: Colors.grey)),
                    )
                  else
                    ...List.generate(credit.payments.length, (i) {
                      final p = credit.payments[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: const Color(0xFF10B981)
                                  .withValues(alpha: 0.25)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('Payment #${i + 1}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: Color(0xFF10B981))),
                                const Spacer(),
                                Text(
                                  '${p.amount.toStringAsFixed(2)} ETB',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Color(0xFF1F2937)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(_fmtDate(p.paidAt),
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.grey)),
                            if (p.note != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.sticky_note_2_outlined,
                                      size: 13, color: Colors.blue),
                                  const SizedBox(width: 4),
                                  Text(p.note!,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.blue)),
                                ],
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Shared widgets
// ═══════════════════════════════════════════════════════════════════════════
class _CreditBannerStat extends StatelessWidget {
  const _CreditBannerStat({required this.label, required this.value});
  final String label, value;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 10)),
          ],
        ),
      );
}

class _StatsShimmer extends StatelessWidget {
  const _StatsShimmer();
  @override
  Widget build(BuildContext context) => Row(
        children: List.generate(
          2,
          (_) => Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 90,
              decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      );
}

class _StatsError extends StatelessWidget {
  const _StatsError();
  @override
  Widget build(BuildContext context) => const Center(
        child: Text('Could not load stats',
            style: TextStyle(color: Colors.grey)),
      );
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.bgColor,
  });
  final String title, value, subtitle;
  final IconData icon;
  final Color accentColor, bgColor;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: bgColor, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: accentColor, size: 20),
            ),
            const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMid,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.dark)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: TextStyle(
                    fontSize: 11,
                    color: accentColor,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) => Text(title,
      style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: AppColors.dark,
          letterSpacing: 0.2));
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) => const Divider(
      height: 1, color: AppColors.border, indent: 16, endIndent: 16);
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });
  final IconData icon;
  final String label, value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.gold),
            const SizedBox(width: 12),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textMid, fontSize: 13)),
            const Spacer(),
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: valueColor ?? AppColors.dark)),
          ],
        ),
      );
}

class _AmountRow extends StatelessWidget {
  const _AmountRow(
      {required this.label,
      required this.value,
      this.color,
      this.bold = false});
  final String label, value;
  final Color? color;
  final bool   bold;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13, color: Colors.grey.shade600)),
          Text(value,
              style: TextStyle(
                  fontSize: bold ? 15 : 13,
                  fontWeight:
                      bold ? FontWeight.bold : FontWeight.w500,
                  color: color ?? const Color(0xFF1F2937))),
        ],
      );
}

String _fmtDate(String iso) {
  const months = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  try {
    final dt = DateTime.parse(iso);
    return '${dt.day} ${months[dt.month]} ${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  } catch (_) {
    return iso;
  }
}
