import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/credit_model.dart';
import '../providers/credit_provider.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../sales/providers/sale_provider.dart';

// ═══════════════════════════════════════════════════════════════════════════
// CreditListScreen — cashier's credit list (real backend data)
// ═══════════════════════════════════════════════════════════════════════════
class CreditListScreen extends ConsumerWidget {
  const CreditListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final creditsAsync = ref.watch(cashierCreditProvider);

    return RefreshIndicator(
      color: const Color(0xFFF59E0B),
      onRefresh: () => ref.read(cashierCreditProvider.notifier).reload(),
      child: creditsAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFFF59E0B))),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 40, color: Colors.red),
              const SizedBox(height: 8),
              Text('$e', style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () =>
                    ref.read(cashierCreditProvider.notifier).reload(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (credits) => _CreditListView(credits: credits),
      ),
    );
  }
}

// ── List view with summary banner ────────────────────────────────────────────
class _CreditListView extends ConsumerWidget {
  const _CreditListView({required this.credits});
  final List<CreditRecord> credits;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final open   = credits.where((c) => !c.isFullyPaid).toList();
    final closed = credits.where((c) => c.isFullyPaid).toList();
    final totalRemaining =
        open.fold(0.0, (s, c) => s + c.remaining);
    final totalCredit = credits.fold(0.0, (s, c) => s + c.totalAmount);

    return CustomScrollView(
      slivers: [
        // ── Summary banner ───────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Container(
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
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
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
                      Text('Credit Overview',
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
                              label: 'Total Credits',
                              value: '${credits.length}')),
                      Expanded(
                          child: _BannerStat(
                              label: 'Outstanding',
                              value: '${open.length}')),
                      Expanded(
                          child: _BannerStat(
                              label: 'Remaining',
                              value:
                                  '${totalRemaining.toStringAsFixed(0)} ETB')),
                    ],
                  ),
                  if (totalCredit > 0) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: credits.isEmpty
                            ? 0
                            : 1 - (totalRemaining / totalCredit),
                        backgroundColor: Colors.white.withValues(alpha: 0.3),
                        valueColor: const AlwaysStoppedAnimation(Colors.white),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${((1 - totalRemaining / totalCredit) * 100).toStringAsFixed(0)}% of total credits collected',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 20)),

        if (credits.isEmpty)
          const SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.account_balance_wallet_outlined,
                      size: 52, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No credit sales yet',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF374151))),
                  SizedBox(height: 6),
                  Text('Credit sales will appear here',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          )
        else ...[
          // Open credits
          if (open.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: _SectionHeader(
                    label: 'Outstanding (${open.length})',
                    color: const Color(0xFFF59E0B)),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _CreditCard(
                    credit: open[i],
                    onTap: () => _showDetail(context, ref, open[i]),
                  ),
                  childCount: open.length,
                ),
              ),
            ),
          ],

          // Paid credits
          if (closed.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: _SectionHeader(
                    label: 'Fully Paid (${closed.length})',
                    color: const Color(0xFF10B981)),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _CreditCard(
                    credit: closed[i],
                    onTap: () => _showDetail(context, ref, closed[i]),
                  ),
                  childCount: closed.length,
                ),
              ),
            ),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ],
    );
  }

  void _showDetail(BuildContext context, WidgetRef ref, CreditRecord credit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreditDetailSheet(credit: credit, ref: ref),
    );
  }
}

// ── Credit card tile ──────────────────────────────────────────────────────────
class _CreditCard extends StatelessWidget {
  const _CreditCard({required this.credit, required this.onTap});
  final CreditRecord credit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final paid     = credit.isFullyPaid;
    final color    = paid ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    final bgColor  = paid ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: paid
              ? const Color(0xFF10B981).withValues(alpha: 0.3)
              : const Color(0xFFF59E0B).withValues(alpha: 0.3)),
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
                  width: 42, height: 42,
                  decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
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
                      Text(_fmtDate(credit.createdAt),
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${credit.totalAmount.toStringAsFixed(0)} ETB',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF1F2937))),
                    Container(
                      margin: const EdgeInsets.only(top: 3),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(10)),
                      child: Text(
                        paid ? 'Paid' : '${credit.remaining.toStringAsFixed(0)} left',
                        style: TextStyle(
                            fontSize: 11,
                            color: color,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: credit.paidPercent,
                backgroundColor: Colors.grey.shade100,
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 5,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${credit.payments.length} payment${credit.payments.length == 1 ? '' : 's'} made',
                  style:
                      const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                Text(
                  '${(credit.paidPercent * 100).toStringAsFixed(0)}% collected',
                  style: TextStyle(
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Credit Detail Sheet with Add Payment
// ═══════════════════════════════════════════════════════════════════════════
class CreditDetailSheet extends StatefulWidget {
  const CreditDetailSheet({super.key, required this.credit, required this.ref});
  final CreditRecord credit;
  final WidgetRef    ref;

  @override
  State<CreditDetailSheet> createState() => _CreditDetailSheetState();
}

class _CreditDetailSheetState extends State<CreditDetailSheet> {
  late CreditRecord _credit;
  bool _showForm = false;
  final _amtCtrl  = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _saving    = false;
  String? _err;

  @override
  void initState() {
    super.initState();
    _credit = widget.credit;
  }

  @override
  void dispose() {
    _amtCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _addPayment() async {
    final amt = double.tryParse(_amtCtrl.text.trim());
    if (amt == null || amt <= 0) {
      setState(() => _err = 'Enter a valid amount.');
      return;
    }
    setState(() { _saving = true; _err = null; });
    final errMsg = await widget.ref
        .read(cashierCreditProvider.notifier)
        .addPayment(_credit.id, amt, note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim());
    if (!mounted) return;
    if (errMsg != null) {
      setState(() { _saving = false; _err = errMsg; });
    } else {
      // Invalidate all credit and dashboard providers so all screens update in real time!
      widget.ref.invalidate(ownerCreditStatsProvider);
      widget.ref.invalidate(ownerCreditsProvider);
      widget.ref.invalidate(ownerSaleStatsProvider);
      widget.ref.invalidate(saleListProvider);

      // Refresh from provider state
      final updated = widget.ref
          .read(cashierCreditProvider)
          .valueOrNull
          ?.firstWhere((c) => c.id == _credit.id, orElse: () => _credit);
      setState(() {
        _credit    = updated ?? _credit;
        _showForm  = false;
        _saving    = false;
        _amtCtrl.clear();
        _noteCtrl.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final paid  = _credit.isFullyPaid;
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
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
            // Header
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
                        _credit.customer.isNotEmpty
                            ? _credit.customer[0].toUpperCase()
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
                        Text(_credit.customer,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                                color: Color(0xFF1F2937))),
                        Text(_fmtDate(_credit.createdAt),
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      paid ? 'PAID' : 'OUTSTANDING',
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 20),

            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                children: [
                  // ── Amount summary ──────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        _AmountRow(
                            label: 'Total Credit',
                            value: '${_credit.totalAmount.toStringAsFixed(2)} ETB',
                            bold: true),
                        const Divider(height: 16),
                        _AmountRow(
                            label: 'Total Paid',
                            value: '${_credit.totalPaid.toStringAsFixed(2)} ETB',
                            color: const Color(0xFF10B981)),
                        const SizedBox(height: 6),
                        _AmountRow(
                            label: 'Remaining',
                            value: '${_credit.remaining.toStringAsFixed(2)} ETB',
                            color: color,
                            bold: true),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: _credit.paidPercent,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation(color),
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(_credit.paidPercent * 100).toStringAsFixed(0)}% collected',
                          style: TextStyle(
                              fontSize: 12,
                              color: color,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Note ───────────────────────────────────────────────
                  if (_credit.note != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.notes_rounded,
                              color: Colors.blue, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(_credit.note!,
                                  style: const TextStyle(
                                      fontSize: 13, color: Colors.blue))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Payment History ─────────────────────────────────────
                  Row(
                    children: [
                      const Text('Payment History',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF1F2937))),
                      const Spacer(),
                      Text(
                        '${_credit.payments.length} payment${_credit.payments.length == 1 ? '' : 's'}',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (_credit.payments.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('No payments made yet.',
                          style: TextStyle(color: Colors.grey)),
                    )
                  else
                    ...List.generate(_credit.payments.length, (i) {
                      final p = _credit.payments[i];
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
                                Text(
                                  'Payment #${i + 1}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Color(0xFF10B981)),
                                ),
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

                  const SizedBox(height: 16),

                  // ── Add Payment Section ─────────────────────────────────
                  if (!paid) ...[
                    if (_showForm) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: const Color(0xFFF59E0B)
                                  .withValues(alpha: 0.4)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Add Payment',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Color(0xFF92400E))),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _amtCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: InputDecoration(
                                labelText: 'Amount (ETB)',
                                hintText: _credit.remaining
                                    .toStringAsFixed(2),
                                prefixIcon:
                                    const Icon(Icons.payments_outlined),
                                border: const OutlineInputBorder(),
                                helperText:
                                    'Max: ${_credit.remaining.toStringAsFixed(2)} ETB',
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _noteCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Note (optional)',
                                prefixIcon:
                                    Icon(Icons.notes_rounded),
                                border: OutlineInputBorder(),
                              ),
                            ),
                            if (_err != null) ...[
                              const SizedBox(height: 8),
                              Text(_err!,
                                  style: const TextStyle(
                                      color: Colors.red, fontSize: 12)),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => setState(
                                        () => _showForm = false),
                                    child: const Text('Cancel'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed:
                                        _saving ? null : _addPayment,
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFFF59E0B),
                                        foregroundColor: Colors.white),
                                    child: _saving
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white))
                                        : const Text('Save'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              setState(() => _showForm = true),
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text('Add Payment',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF59E0B),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.color});
  final String label;
  final Color  color;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
              width: 4,
              height: 14,
              decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: color)),
        ],
      );
}

class _BannerStat extends StatelessWidget {
  const _BannerStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 10)),
        ],
      );
}

class _AmountRow extends StatelessWidget {
  const _AmountRow(
      {required this.label, required this.value, this.color, this.bold = false});
  final String  label;
  final String  value;
  final Color?  color;
  final bool    bold;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600)),
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
