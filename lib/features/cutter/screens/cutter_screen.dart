import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/cutter_provider.dart';
import '../models/cutter_model.dart';

// Purple accent used throughout the cutter feature
const _kPurple   = Color(0xFF8B5CF6);

class CutterScreen extends ConsumerWidget {
  const CutterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cutterListProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.read(cutterListProvider.notifier).load(),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _Header(total: state.cutters.length),
              ),
            ),
            if (state.isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: _kPurple)),
              )
            else if (state.error != null)
              SliverFillRemaining(
                child: _ErrorView(
                  message: state.error!,
                  onRetry: () => ref.read(cutterListProvider.notifier).load(),
                ),
              )
            else if (state.cutters.isEmpty)
              SliverFillRemaining(
                child: _EmptyView(
                  onAdd: () => _openCreateSheet(context, ref),
                ),
              )
            else ...[
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _CutterTable(
                    cutters: state.cutters,
                    onToggleStatus: (id, status) =>
                        ref.read(cutterListProvider.notifier).toggleStatus(id, status),
                    onEdit:          (c) => _openEditSheet(context, ref, c),
                    onResetPassword: (c) => _openResetPasswordSheet(context, ref, c),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateSheet(context, ref),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Add Cutter'),
        backgroundColor: _kPurple,
        foregroundColor: Colors.white,
      ),
    );
  }

  // ── Open sheets ──────────────────────────────────────────────────────────

  void _openCreateSheet(BuildContext context, WidgetRef ref) {
    ref.read(createCutterProvider.notifier).reset();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CreateCutterSheet(),
    );
  }

  void _openEditSheet(BuildContext ctx, WidgetRef ref, CutterModel cutter) {
    final nameCtr  = TextEditingController(text: cutter.name);
    final phoneCtr = TextEditingController(text: cutter.phone);
    String? errorMsg;

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
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
                      color: _kPurple.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit_rounded, color: _kPurple, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Text('Edit Cutter',
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
                    await ref.read(cutterListProvider.notifier).editCutter(cutter.id, name, phone);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('Save Changes',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPurple,
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

  void _openResetPasswordSheet(BuildContext ctx, WidgetRef ref, CutterModel cutter) {
    final pwdCtr     = TextEditingController();
    final confirmCtr = TextEditingController();
    bool obscure     = true;
    String? errorMsg;
    bool isLoading   = false;

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
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
                        Text(cutter.name,
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
                    final err = await ref.read(cutterListProvider.notifier).resetPassword(cutter.id, pwd);
                    if (context.mounted) {
                      if (err != null) {
                        setState(() { isLoading = false; errorMsg = err; });
                      } else {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Password reset successfully'),
                            backgroundColor: _kPurple,
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
          colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
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
            child: const Icon(Icons.content_cut_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Cutters',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(
                  '$total cutter${total == 1 ? '' : 's'} registered',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
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

class _CutterTable extends StatefulWidget {
  const _CutterTable({
    required this.cutters,
    required this.onToggleStatus,
    required this.onEdit,
    required this.onResetPassword,
  });

  final List<CutterModel>                         cutters;
  final void Function(String id, String status)   onToggleStatus;
  final void Function(CutterModel)                onEdit;
  final void Function(CutterModel)                onResetPassword;

  @override
  State<_CutterTable> createState() => _CutterTableState();
}

class _CutterTableState extends State<_CutterTable> {
  final Map<String, bool> _visiblePwd = {};
  final _hScroll = ScrollController();

  @override
  void dispose() {
    _hScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final table = DataTable(
      headingRowColor: WidgetStateProperty.all(_kPurple.withValues(alpha: 0.08)),
      headingTextStyle: const TextStyle(
          fontWeight: FontWeight.w700, color: Color(0xFF5B21B6), fontSize: 13),
      dataRowMinHeight: 58,
      dataRowMaxHeight: 58,
      columnSpacing: 24,
      horizontalMargin: 16,
      dividerThickness: 1,
      columns: const [
        DataColumn(label: SizedBox(width: 28,  child: Text('#'))),
        DataColumn(label: SizedBox(width: 150, child: Text('Name'))),
        DataColumn(label: SizedBox(width: 120, child: Text('Phone'))),
        DataColumn(label: SizedBox(width: 160, child: Text('Password'))),
        DataColumn(label: SizedBox(width: 80,  child: Text('Status'))),
        DataColumn(label: SizedBox(width: 60,  child: Text('Active'))),
        DataColumn(label: SizedBox(width: 100, child: Text('Actions'))),
        DataColumn(label: SizedBox(width: 90,  child: Text('Created'))),
      ],
      rows: [
        for (var i = 0; i < widget.cutters.length; i++)
          _buildRow(i, widget.cutters[i]),
      ],
    );

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag-scrollable table
          Scrollbar(
            controller: _hScroll,
            thumbVisibility: true,
            trackVisibility: true,
            child: ScrollConfiguration(
              // Enable drag-to-scroll on all platforms (including touch + desktop)
              behavior: _DragScrollBehavior(),
              child: SingleChildScrollView(
                controller: _hScroll,
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 900),
                  child: table,
                ),
              ),
            ),
          ),
          // Scroll hint label when table overflows
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.swipe_rounded, size: 14, color: Colors.grey.shade400),
                const SizedBox(width: 4),
                Text(
                  'Swipe left / right to see all columns',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  DataRow _buildRow(int index, CutterModel c) {
    final showPwd = _visiblePwd[c.id] ?? false;
    final pwdText = (c.plainPassword != null && c.plainPassword!.isNotEmpty)
        ? c.plainPassword!
        : '(no password)';

    return DataRow(cells: [
      DataCell(SizedBox(
        width: 28,
        child: Text('${index + 1}', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
      )),
      DataCell(SizedBox(
        width: 150,
        child: Row(children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: _kPurple.withValues(alpha: 0.12),
            child: Text(
              c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
              style: const TextStyle(color: _kPurple, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              c.name,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ]),
      )),
      DataCell(SizedBox(
        width: 120,
        child: Text(c.phone, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
      )),
      DataCell(SizedBox(
        width: 160,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                showPwd ? pwdText : '••••••••',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: Colors.grey.shade800,
                  letterSpacing: showPwd ? 0 : 2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: Icon(showPwd ? Icons.visibility_off : Icons.visibility,
                  size: 18, color: Colors.grey.shade500),
              onPressed: () => setState(() => _visiblePwd[c.id] = !showPwd),
            ),
          ],
        ),
      )),
      DataCell(SizedBox(width: 80, child: _StatusBadge(status: c.status))),
      DataCell(SizedBox(
        width: 60,
        child: Switch(
          value: c.isActive,
          activeThumbColor: _kPurple,
          activeTrackColor: _kPurple.withValues(alpha: 0.4),
          onChanged: (_) => widget.onToggleStatus(c.id, c.status),
        ),
      )),
      DataCell(SizedBox(
        width: 100,
        child: Row(
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
        ),
      )),
      DataCell(SizedBox(
        width: 90,
        child: Text(_fmtDate(c.createdAt),
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
      )),
    ]);
  }

  String _fmtDate(String? iso) {
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

// ── Create cutter sheet ───────────────────────────────────────────────────────

class _CreateCutterSheet extends ConsumerStatefulWidget {
  const _CreateCutterSheet();

  @override
  ConsumerState<_CreateCutterSheet> createState() => _CreateCutterSheetState();
}

class _CreateCutterSheetState extends ConsumerState<_CreateCutterSheet> {
  final _formKey     = GlobalKey<FormState>();
  final _nameCtr     = TextEditingController();
  final _phoneCtr    = TextEditingController();
  final _passwordCtr = TextEditingController();
  final _confirmCtr  = TextEditingController();
  bool _showPwd      = false;
  bool _showConfirm  = false;

  @override
  void dispose() {
    _nameCtr.dispose();
    _phoneCtr.dispose();
    _passwordCtr.dispose();
    _confirmCtr.dispose();
    super.dispose();
  }

  void _onPhoneChanged(String val) {
    String raw = val.replaceAll(RegExp(r'\D'), '');
    if (raw.startsWith('0')) raw = raw.substring(1);
    if (raw.length > 9) raw = raw.substring(0, 9);
    if (raw != val) {
      _phoneCtr.value = TextEditingValue(
        text: raw,
        selection: TextSelection.collapsed(offset: raw.length),
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(createCutterProvider.notifier).create(
      name:     _nameCtr.text.trim(),
      phone:    '0${_phoneCtr.text.trim()}',
      password: _passwordCtr.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final createState = ref.watch(createCutterProvider);

    ref.listen(createCutterProvider, (_, next) {
      if (next.success && context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cutter created successfully'),
            backgroundColor: _kPurple,
          ),
        );
      }
    });

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _kPurple.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.content_cut_rounded, color: _kPurple, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Add New Cutter',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('Fill in the details below',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            if (createState.error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade400, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(createState.error!,
                          style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            Form(
              key: _formKey,
              child: Column(children: [
                _field(
                  controller: _nameCtr,
                  label: 'Full Name',
                  hint: 'e.g. Abebe Kebede',
                  icon: Icons.person_outline,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Name is required';
                    if (v.trim().length < 2) return 'Name must be at least 2 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _phoneCtr,
                  keyboardType: TextInputType.phone,
                  onChanged: _onPhoneChanged,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    hintText: '9xxxxxxxx or 7xxxxxxxx',
                    prefixIcon: const Icon(Icons.phone_outlined, color: _kPurple),
                    prefixText: '0',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _kPurple, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  validator: (v) {
                    final raw = v?.replaceAll(RegExp(r'\D'), '') ?? '';
                    if (raw.length != 9) return 'Enter a 9-digit number (after the 0)';
                    if (raw[0] != '9' && raw[0] != '7') return 'Phone must start with 9 or 7';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _passwordField(
                  controller: _passwordCtr,
                  label: 'Password',
                  show: _showPwd,
                  onToggle: () => setState(() => _showPwd = !_showPwd),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (v.length < 6) return 'Minimum 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _passwordField(
                  controller: _confirmCtr,
                  label: 'Confirm Password',
                  show: _showConfirm,
                  onToggle: () => setState(() => _showConfirm = !_showConfirm),
                  validator: (v) {
                    if (v != _passwordCtr.text) return 'Passwords do not match';
                    return null;
                  },
                ),
              ]),
            ),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: createState.isLoading ? null : () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: createState.isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: createState.isLoading
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Create Cutter',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: _kPurple),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kPurple, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      validator: validator,
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool show,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !show,
      decoration: InputDecoration(
        labelText: label,
        hintText: '••••••••',
        prefixIcon: const Icon(Icons.lock_outline, color: _kPurple),
        suffixIcon: IconButton(
          icon: Icon(show ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey.shade500, size: 20),
          onPressed: onToggle,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kPurple, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      validator: validator,
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
            Icon(Icons.content_cut_rounded, size: 72, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('No cutters yet',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    )),
            const SizedBox(height: 8),
            Text(
              'Tap the button below to add your first cutter.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Add Cutter'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
            Icon(Icons.wifi_off_rounded, size: 60, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
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

// ── Drag scroll behavior — enables mouse/touch drag on horizontal scroll ───────
// By default Flutter desktop only scrolls with the scrollbar or mouse wheel.
// This overrides that so any drag gesture also scrolls horizontally.

class _DragScrollBehavior extends ScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}
