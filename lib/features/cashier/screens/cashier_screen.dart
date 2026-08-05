import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/cashier_provider.dart';
import '../models/cashier_model.dart';
import 'create_cashier_sheet.dart';

class CashierScreen extends ConsumerWidget {
  const CashierScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cashierListProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.read(cashierListProvider.notifier).load(),
        child: CustomScrollView(
          slivers: [
            // ── Header ─────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _Header(total: state.cashiers.length),
              ),
            ),

            // ── Loading ─────────────────────────────────────────────────────
            if (state.isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )

            // ── Error ───────────────────────────────────────────────────────
            else if (state.error != null)
              SliverFillRemaining(
                child: _ErrorView(
                  message: state.error!,
                  onRetry: () =>
                      ref.read(cashierListProvider.notifier).load(),
                ),
              )

            // ── Empty ────────────────────────────────────────────────────────
            else if (state.cashiers.isEmpty)
              SliverFillRemaining(
                child: _EmptyView(
                  onAdd: () => _openCreateSheet(context, ref),
                ),
              )

            // ── Table ────────────────────────────────────────────────────────
            else ...[
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _CashierTable(
                    cashiers: state.cashiers,
                    onToggleStatus: (id, currentStatus) {
                      ref
                          .read(cashierListProvider.notifier)
                          .toggleStatus(id, currentStatus);
                    },
                    onEdit: (cashier) => _openEditSheet(context, ref, cashier),
                    onResetPassword: (cashier) => _openResetPasswordSheet(context, ref, cashier),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ],
        ),
      ),

      // ── FAB ────────────────────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateSheet(context, ref),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Add Cashier'),
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
      ),
    );
  }

  void _openCreateSheet(BuildContext context, WidgetRef ref) {
    ref.read(createCashierProvider.notifier).reset();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CreateCashierSheet(),
    );
  }

  void _openEditSheet(BuildContext context, WidgetRef ref, CashierModel cashier) {
    final nameCtr  = TextEditingController(text: cashier.name);
    final phoneCtr = TextEditingController(text: cashier.phone);
    String? errorMsg;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: EdgeInsets.only(
            top: 24, left: 20, right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit_rounded, color: Color(0xFF3B82F6), size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Text('Edit Cashier',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop()),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameCtr,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: phoneCtr,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              if (errorMsg != null) ...[
                const SizedBox(height: 10),
                Text(errorMsg!, style: const TextStyle(color: Colors.red, fontSize: 13)),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final name  = nameCtr.text.trim();
                    final phone = phoneCtr.text.trim();
                    if (name.isEmpty || phone.isEmpty) {
                      setState(() => errorMsg = 'Name and phone are required');
                      return;
                    }
                    await ref.read(cashierListProvider.notifier)
                        .editCashier(cashier.id, name, phone);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('Save Changes',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openResetPasswordSheet(BuildContext context, WidgetRef ref, CashierModel cashier) {
    final pwdCtr     = TextEditingController();
    final confirmCtr = TextEditingController();
    bool obscure     = true;
    String? errorMsg;
    bool isLoading   = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: EdgeInsets.only(
            top: 24, left: 20, right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_reset_rounded, color: Color(0xFFF59E0B), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Reset Password',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(cashier.name,
                            style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop()),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: pwdCtr,
                obscureText: obscure,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => obscure = !obscure),
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: confirmCtr,
                obscureText: obscure,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              if (errorMsg != null) ...[
                const SizedBox(height: 10),
                Text(errorMsg!, style: const TextStyle(color: Colors.red, fontSize: 13)),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : () async {
                    final pwd     = pwdCtr.text.trim();
                    final confirm = confirmCtr.text.trim();
                    if (pwd.length < 6) {
                      setState(() => errorMsg = 'Password must be at least 6 characters');
                      return;
                    }
                    if (pwd != confirm) {
                      setState(() => errorMsg = 'Passwords do not match');
                      return;
                    }
                    setState(() { isLoading = true; errorMsg = null; });
                    final err = await ref.read(cashierListProvider.notifier)
                        .resetPassword(cashier.id, pwd);
                    if (context.mounted) {
                      if (err != null) {
                        setState(() { isLoading = false; errorMsg = err; });
                      } else {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Password reset successfully'),
                            backgroundColor: Color(0xFF10B981),
                          ),
                        );
                      }
                    }
                  },
                  icon: isLoading
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.lock_reset_rounded),
                  label: const Text('Reset Password',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.total});
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.point_of_sale_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cashiers',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$total cashier${total == 1 ? '' : 's'} registered',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Table ─────────────────────────────────────────────────────────────────────

class _CashierTable extends StatefulWidget {
  const _CashierTable({
    required this.cashiers,
    required this.onToggleStatus,
    required this.onEdit,
    required this.onResetPassword,
  });
  final List<CashierModel> cashiers;
  final void Function(String id, String currentStatus) onToggleStatus;
  final void Function(CashierModel cashier) onEdit;
  final void Function(CashierModel cashier) onResetPassword;

  @override
  State<_CashierTable> createState() => _CashierTableState();
}

class _CashierTableState extends State<_CashierTable> {
  final Map<String, bool> _visiblePwd = {};

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            const Color(0xFF10B981).withValues(alpha: 0.08),
          ),
          headingTextStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF065F46),
            fontSize: 13,
          ),
          dataRowMinHeight: 56,
          dataRowMaxHeight: 56,
          columnSpacing: 20,
          columns: const [
            DataColumn(label: Text('#')),
            DataColumn(label: Text('Name')),
            DataColumn(label: Text('Phone')),
            DataColumn(label: Text('Password')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Active')),
            DataColumn(label: Text('Actions')),
            DataColumn(label: Text('Created')),
          ],
          rows: [
            for (var i = 0; i < widget.cashiers.length; i++)
              _buildRow(i, widget.cashiers[i]),
          ],
        ),
      ),
    );
  }

  DataRow _buildRow(int index, CashierModel c) {
    final showPwd = _visiblePwd[c.id] ?? false;
    final pwdText = (c.plainPassword != null && c.plainPassword!.isNotEmpty)
        ? c.plainPassword!
        : '(no password)';

    return DataRow(
      cells: [
        DataCell(Text(
          '${index + 1}',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        )),
        DataCell(Row(
          children: [
            CircleAvatar(
              radius: 15,
              backgroundColor:
                  const Color(0xFF10B981).withValues(alpha: 0.12),
              child: Text(
                c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Color(0xFF059669),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              c.name,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ],
        )),
        DataCell(Text(c.phone,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13))),
        DataCell(Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              showPwd ? pwdText : '••••••••',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: Colors.grey.shade800,
                letterSpacing: showPwd ? 0 : 2,
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: Icon(
                showPwd ? Icons.visibility_off : Icons.visibility,
                size: 18,
                color: Colors.grey.shade500,
              ),
              onPressed: () {
                setState(() {
                  _visiblePwd[c.id] = !showPwd;
                });
              },
            ),
          ],
        )),
        DataCell(_StatusBadge(status: c.status)),
        DataCell(Switch(
          value: c.isActive,
          activeThumbColor: const Color(0xFF10B981),
          activeTrackColor: const Color(0xFF10B981).withValues(alpha: 0.4),
          onChanged: (_) => widget.onToggleStatus(c.id, c.status),
        )),
        DataCell(Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Edit',
              icon: const Icon(Icons.edit_rounded, size: 18, color: Color(0xFF3B82F6)),
              onPressed: () => widget.onEdit(c),
            ),
            IconButton(
              tooltip: 'Reset Password',
              icon: const Icon(Icons.lock_reset_rounded, size: 18, color: Color(0xFFF59E0B)),
              onPressed: () => widget.onResetPassword(c),
            ),
          ],
        )),
        DataCell(Text(
          _formatDate(c.createdAt),
          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
        )),
      ],
    );
  }

  String _formatDate(String? iso) {
    if (iso == null) return '—';
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}

// ── Status badge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final isActive = status == 'Active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.withValues(alpha: 0.12)
            : Colors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color:      isActive ? Colors.green.shade700 : Colors.orange.shade700,
          fontWeight: FontWeight.w600,
          fontSize:   12,
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline_rounded,
                size: 72, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No cashiers yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the button below to add your first cashier.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Add Cashier'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error state ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String       message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded,
                size: 60, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
