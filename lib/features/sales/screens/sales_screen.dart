import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/sale_provider.dart';
import '../models/sale_model.dart';

class SalesScreen extends ConsumerWidget {
  const SalesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(saleListProvider);

    return RefreshIndicator(
      color: const Color(0xFF10B981),
      onRefresh: () => ref.read(saleListProvider.notifier).load(),
      child: CustomScrollView(
        slivers: [
          // ── Stats Banner ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Container(
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
                      blurRadius: 14, offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.sell_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text('Sales Overview',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 17)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _BannerStat(
                            label: 'Total Sales',
                            value: '${state.stats.totalSales}',
                            icon: Icons.receipt_long_rounded,
                          ),
                        ),
                        Expanded(
                          child: _BannerStat(
                            label: 'Revenue',
                            value: '${state.stats.totalRevenue.toStringAsFixed(0)} ETB',
                            icon: Icons.trending_up_rounded,
                          ),
                        ),
                        Expanded(
                          child: _BannerStat(
                            label: 'Credit',
                            value: '${state.stats.totalCredit.toStringAsFixed(0)} ETB',
                            icon: Icons.account_balance_wallet_rounded,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // ── Loading / Error / Empty ─────────────────────────────────────
          if (state.loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: Color(0xFF10B981))),
            )
          else if (state.error != null)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 40, color: Colors.red),
                    const SizedBox(height: 8),
                    Text(state.error!, style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => ref.read(saleListProvider.notifier).load(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else if (state.sales.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.sell_rounded,
                          size: 48, color: Color(0xFF10B981)),
                    ),
                    const SizedBox(height: 16),
                    const Text('No sales recorded yet',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold,
                            color: Color(0xFF374151))),
                    const SizedBox(height: 6),
                    Text('Tap \'New Sale\' below to record your first sale',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                  ],
                ),
              ),
            )
          else ...[
            // ── Section header ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Container(width: 4, height: 16,
                        decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 8),
                    Text('${state.sales.length} records',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF10B981))),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 10)),

            // ── Sale Cards ─────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _SaleCard(
                    sale: state.sales[i],
                    onTap: () => _showDetail(context, state.sales[i]),
                  ),
                  childCount: state.sales.length,
                ),
              ),
            ),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context, SaleModel sale) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SaleDetailSheet(sale: sale),
    );
  }
}

// ── Sale Card ─────────────────────────────────────────────────────────────────

class _SaleCard extends StatelessWidget {
  const _SaleCard({required this.sale, required this.onTap});
  final SaleModel    sale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isCash   = sale.isCash;
    final color    = isCash ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    final bg       = isCash ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8, offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
                  child: Icon(
                    isCash ? Icons.sell_rounded : Icons.account_balance_wallet_rounded,
                    size: 18, color: color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sale.customer?.isNotEmpty == true
                            ? sale.customer!
                            : '${sale.items.length} item${sale.items.length != 1 ? 's' : ''}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF1F2937)),
                      ),
                      const SizedBox(height: 2),
                      Text(_fmtDate(sale.createdAt),
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${sale.totalAmount.toStringAsFixed(0)} ETB',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15, color: color),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(sale.paymentType,
                          style: TextStyle(
                              fontSize: 10, color: color, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
            if (sale.items.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: sale.items.take(3).map((item) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${item.material} ×${item.quantity.toStringAsFixed(item.quantity == item.quantity.truncate() ? 0 : 1)}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                  ),
                )).toList()
                  ..addAll(sale.items.length > 3
                      ? [Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('+${sale.items.length - 3} more',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                        )]
                      : []),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Sale Detail Sheet ─────────────────────────────────────────────────────────

class _SaleDetailSheet extends StatelessWidget {
  const _SaleDetailSheet({required this.sale});
  final SaleModel sale;

  @override
  Widget build(BuildContext context) {
    final isCash  = sale.isCash;
    final color   = isCash ? const Color(0xFF10B981) : const Color(0xFFF59E0B);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize:     0.4,
      maxChildSize:     0.95,
      builder: (ctx, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF9FAFB),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.all(20),
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isCash ? Icons.sell_rounded : Icons.account_balance_wallet_rounded,
                          color: color, size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sale.customer?.isNotEmpty == true
                                  ? sale.customer!
                                  : 'Sale Receipt',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Color(0xFF1F2937)),
                            ),
                            Text(_fmtDateFull(sale.createdAt),
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey.shade500)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(sale.paymentType,
                            style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Items
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              const Icon(Icons.list_alt_rounded, size: 16, color: Color(0xFF10B981)),
                              const SizedBox(width: 6),
                              const Text('Items',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              const Spacer(),
                              Text('${sale.items.length} item${sale.items.length != 1 ? 's' : ''}',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey.shade500)),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        // Header row
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          child: Row(
                            children: [
                              Expanded(flex: 3,
                                  child: Text('Material',
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey))),
                              Expanded(flex: 1,
                                  child: Text('Qty',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey))),
                              Expanded(flex: 2,
                                  child: Text('Unit Price',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey))),
                              Expanded(flex: 2,
                                  child: Text('Total',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey))),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        ...sale.items.asMap().entries.map((e) => Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                  child: Row(
                                    children: [
                                      Expanded(
                                          flex: 3,
                                          child: Text(e.value.material,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13))),
                                      Expanded(
                                          flex: 1,
                                          child: Text(
                                            e.value.quantity.toStringAsFixed(
                                                e.value.quantity == e.value.quantity.truncate() ? 0 : 1),
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(fontSize: 13),
                                          )),
                                      Expanded(
                                          flex: 2,
                                          child: Text(
                                            '${e.value.unitPrice.toStringAsFixed(0)} ETB',
                                            textAlign: TextAlign.right,
                                            style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey.shade600),
                                          )),
                                      Expanded(
                                          flex: 2,
                                          child: Text(
                                            '${e.value.total.toStringAsFixed(0)} ETB',
                                            textAlign: TextAlign.right,
                                            style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: color),
                                          )),
                                    ],
                                  ),
                                ),
                                if (e.key < sale.items.length - 1)
                                  Divider(height: 1, color: Colors.grey.shade100,
                                      indent: 14, endIndent: 14),
                              ],
                            )),
                        const Divider(),
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 15)),
                              Text(
                                '${sale.totalAmount.toStringAsFixed(0)} ETB',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                    color: color),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (sale.note != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.notes_rounded, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(sale.note!,
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey.shade600)),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Banner Stat ───────────────────────────────────────────────────────────────

class _BannerStat extends StatelessWidget {
  const _BannerStat({required this.label, required this.value, required this.icon});
  final String   label;
  final String   value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
              overflow: TextOverflow.ellipsis),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 10)),
        ],
      );
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _fmtDate(String iso) {
  try {
    final dt = DateTime.parse(iso);
    return '${dt.day}/${dt.month}/${dt.year}';
  } catch (_) {
    return iso;
  }
}

String _fmtDateFull(String iso) {
  const months = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  try {
    final dt = DateTime.parse(iso);
    return '${dt.day} ${months[dt.month]} ${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  } catch (_) {
    return iso;
  }
}
