import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/sale_provider.dart';
import '../../stock/models/material_model.dart';
import '../../stock/providers/material_provider.dart';
import '../../stock/data/material_repository.dart';
import '../../cashier/providers/credit_provider.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Internal sale item row — holds selected material + qty entered
// ═══════════════════════════════════════════════════════════════════════════
class _SaleItem {
  _SaleItem() : quantityCtrl = TextEditingController(text: '1');

  MaterialItem? selectedMaterial;
  final TextEditingController quantityCtrl;

  void dispose() => quantityCtrl.dispose();

  bool get isValid =>
      selectedMaterial != null &&
      (double.tryParse(quantityCtrl.text) ?? 0) > 0;

  double get subtotal {
    final q = double.tryParse(quantityCtrl.text) ?? 0;
    return q * (selectedMaterial?.unitPrice ?? 0);
  }

  Map<String, dynamic> toMap() => {
        'materialId': selectedMaterial!.id,
        'material':   selectedMaterial!.name,
        'quantity':   double.parse(quantityCtrl.text),
        'unitPrice':  selectedMaterial!.unitPrice,
      };
}

// ═══════════════════════════════════════════════════════════════════════════
// NewSaleSheet
// ═══════════════════════════════════════════════════════════════════════════
class NewSaleSheet extends ConsumerStatefulWidget {
  const NewSaleSheet({super.key});

  @override
  ConsumerState<NewSaleSheet> createState() => _NewSaleSheetState();
}

class _NewSaleSheetState extends ConsumerState<NewSaleSheet> {
  final _customerCtrl = TextEditingController();
  final _noteCtrl     = TextEditingController();
  final _items        = <_SaleItem>[_SaleItem()];
  String  _paymentType = 'Cash';
  String? _error;
  bool    _loading     = false;

  @override
  void dispose() {
    _customerCtrl.dispose();
    _noteCtrl.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  double get _grandTotal => _items.fold(0, (s, i) => s + i.subtotal);

  void _addItem() => setState(() => _items.add(_SaleItem()));

  void _removeItem(int i) {
    if (_items.length == 1) return;
    setState(() {
      _items[i].dispose();
      _items.removeAt(i);
    });
  }

  // ── Pick a material from the stock list ──────────────────────────────────
  Future<void> _pickMaterial(int index, List<MaterialItem> stock) async {
    if (stock.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No materials in stock yet. Ask your owner to add some.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final result = await showModalBottomSheet<MaterialItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MaterialPickerSheet(stock: stock),
    );

    if (result != null) {
      setState(() {
        _items[index].selectedMaterial = result;
      });
    }
  }

  Future<void> _submit() async {
    final invalid = _items.any((i) => !i.isValid);
    if (invalid) {
      setState(() => _error = 'Select a material and enter a valid quantity for all items.');
      return;
    }
    setState(() { _loading = true; _error = null; });

    final err = await ref.read(saleListProvider.notifier).recordSale(
      customer:    _customerCtrl.text.trim().isEmpty ? null : _customerCtrl.text.trim(),
      paymentType: _paymentType,
      note:        _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      items:       _items.map((i) => i.toMap()).toList(),
    );

    if (!mounted) return;
    if (err != null) {
      setState(() { _loading = false; _error = err; });
    } else {
      ref.invalidate(ownerMaterialsProvider);
      ref.invalidate(materialsProvider);
      ref.invalidate(cashierCreditProvider);
      ref.invalidate(ownerCreditsProvider);
      ref.invalidate(ownerCreditStatsProvider);

      // Fetch fresh stock to check low stock items
      final freshStock = await ref.read(materialRepositoryProvider).fetchOwnerMaterials();
      final lowStockList = freshStock.where((m) => m.isLowStock).toList();

      if (!mounted) return;
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Sale recorded successfully!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );

      // If any items are at 20% or less, show low stock alert modal
      if (lowStockList.isNotEmpty && mounted) {
        showDialog(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 28),
                const SizedBox(width: 10),
                const Text('Low Stock Alert!',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'The following material(s) are down to 20% or less of initial stock:',
                  style: TextStyle(fontSize: 13, color: Color(0xFF374151)),
                ),
                const SizedBox(height: 12),
                ...lowStockList.map((m) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            m.isMeter
                                ? Icons.straighten_rounded
                                : Icons.widgets_rounded,
                            color: Colors.red.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  m.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.red.shade900,
                                  ),
                                ),
                                Text(
                                  'Only ${m.quantity.toStringAsFixed(m.isMeter ? 1 : 0)} ${m.unitLabel} left (${m.remainingPercentage.toStringAsFixed(0)}%)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('OK, Got It'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final stockAsync = ref.watch(ownerMaterialsProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.93,
      minChildSize:     0.5,
      maxChildSize:     0.98,
      builder: (ctx, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF9FAFB),
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
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add_shopping_cart_rounded,
                        color: Color(0xFF10B981), size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Text('New Sale',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937))),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Body
            Expanded(
              child: stockAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Color(0xFF10B981)),
                ),
                error: (e, _) => _buildForm(ctx, ctrl, []),
                data:  (stock) => _buildForm(ctx, ctrl, stock),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(
      BuildContext ctx, ScrollController ctrl, List<MaterialItem> stock) {
    return ListView(
      controller: ctrl,
      padding: const EdgeInsets.all(16),
      children: [
        // ── Customer & Payment ───────────────────────────────────────────
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _FieldLabel(text: 'Customer (optional)'),
              const SizedBox(height: 8),
              TextField(
                controller: _customerCtrl,
                decoration: const InputDecoration(
                  hintText: 'Customer name or phone',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 14),
              const _FieldLabel(text: 'Payment Type'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _PayTypeButton(
                      label: 'Cash',
                      icon: Icons.payments_rounded,
                      selected: _paymentType == 'Cash',
                      color: const Color(0xFF10B981),
                      onTap: () => setState(() => _paymentType = 'Cash'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PayTypeButton(
                      label: 'Credit',
                      icon: Icons.account_balance_wallet_rounded,
                      selected: _paymentType == 'Credit',
                      color: const Color(0xFFF59E0B),
                      onTap: () => setState(() => _paymentType = 'Credit'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── Items ────────────────────────────────────────────────────────
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const _FieldLabel(text: 'Items'),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _addItem,
                    icon: const Icon(Icons.add_circle_outline, size: 16),
                    label: const Text('Add item'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF10B981),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Stock warning if empty
              if (stock.isEmpty)
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: Colors.orange.shade700, size: 18),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'No materials in stock. The owner needs to add stock first.',
                          style: TextStyle(fontSize: 12, color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                ),

              // Item rows
              ...List.generate(
                _items.length,
                (i) => _SaleItemRow(
                  key: ValueKey(i),
                  item: _items[i],
                  onPickMaterial: () => _pickMaterial(i, stock),
                  onRemove: _items.length > 1 ? () => _removeItem(i) : null,
                  onChanged: () => setState(() {}),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── Note ─────────────────────────────────────────────────────────
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _FieldLabel(text: 'Note (optional)'),
              const SizedBox(height: 8),
              TextField(
                controller: _noteCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Any note about this sale…',
                  prefixIcon: Icon(Icons.notes_rounded),
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── Grand Total card ─────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF059669)],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Grand Total',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(
                    '${_items.length} item${_items.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                        color: Colors.white60, fontSize: 11),
                  ),
                ],
              ),
              Text(
                '${_grandTotal.toStringAsFixed(2)} ETB',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: Colors.white),
              ),
            ],
          ),
        ),

        if (_error != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Text(_error!,
                style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
          ),
        ],
        const SizedBox(height: 18),

        // ── Submit ───────────────────────────────────────────────────────
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: _loading ? null : _submit,
            icon: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.check_circle_rounded),
            label: const Text('Record Sale',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(height: 28),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Material Picker Bottom Sheet
// ═══════════════════════════════════════════════════════════════════════════
class _MaterialPickerSheet extends StatefulWidget {
  const _MaterialPickerSheet({required this.stock});
  final List<MaterialItem> stock;

  @override
  State<_MaterialPickerSheet> createState() => _MaterialPickerSheetState();
}

class _MaterialPickerSheetState extends State<_MaterialPickerSheet> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.stock
        .where((m) =>
            m.name.toLowerCase().contains(_search.toLowerCase()))
        .toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Row(
              children: [
                const Icon(Icons.inventory_2_rounded,
                    color: Color(0xFF10B981), size: 22),
                const SizedBox(width: 10),
                const Text('Select Material',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937))),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),

          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              autofocus: true,
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Search materials…',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),

          const Divider(height: 1),

          // List
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text('No materials found',
                        style: TextStyle(color: Colors.grey)),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 70),
                    itemBuilder: (_, i) {
                      final mat = filtered[i];
                      final isMeter = mat.isMeter;
                      final color = isMeter
                          ? const Color(0xFF6366F1)
                          : const Color(0xFF10B981);
                      final bg = isMeter
                          ? const Color(0xFFEEF2FF)
                          : const Color(0xFFECFDF5);

                      return ListTile(
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isMeter
                                ? Icons.straighten_rounded
                                : Icons.widgets_rounded,
                            color: color,
                            size: 22,
                          ),
                        ),
                        title: Text(
                          mat.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937)),
                        ),
                      subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: bg,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    '${mat.quantity.toStringAsFixed(mat.quantity == mat.quantity.truncateToDouble() ? 0 : 2)} ${mat.unitLabel} left',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: mat.isLowStock ? Colors.red : color),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${mat.unitPrice.toStringAsFixed(2)} ETB/${mat.unitLabel}',
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: mat.remainingPercentage / 100,
                                minHeight: 4,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  mat.remainingPercentage <= 20
                                      ? Colors.red
                                      : mat.remainingPercentage <= 50
                                          ? Colors.orange
                                          : color,
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right,
                            color: Colors.grey),
                        onTap: () => Navigator.of(context).pop(mat),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Sale Item Row — shows selected material chip + quantity field + subtotal
// ═══════════════════════════════════════════════════════════════════════════
class _SaleItemRow extends StatelessWidget {
  const _SaleItemRow({
    super.key,
    required this.item,
    required this.onPickMaterial,
    required this.onChanged,
    this.onRemove,
  });

  final _SaleItem      item;
  final VoidCallback   onPickMaterial;
  final VoidCallback   onChanged;
  final VoidCallback?  onRemove;

  @override
  Widget build(BuildContext context) {
    final mat      = item.selectedMaterial;
    final isMeter  = mat?.isMeter ?? true;
    final accent   = isMeter ? const Color(0xFF6366F1) : const Color(0xFF10B981);
    final qty      = double.tryParse(item.quantityCtrl.text) ?? 0;
    final subtotal = qty * (mat?.unitPrice ?? 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Material selector ──────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onPickMaterial,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: mat != null
                          ? accent.withValues(alpha: 0.08)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: mat != null
                              ? accent.withValues(alpha: 0.4)
                              : Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          mat != null
                              ? (isMeter
                                  ? Icons.straighten_rounded
                                  : Icons.widgets_rounded)
                              : Icons.add_box_outlined,
                          size: 18,
                          color: mat != null ? accent : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            mat?.name ?? 'Tap to select material',
                            style: TextStyle(
                              fontWeight: mat != null
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: mat != null
                                  ? const Color(0xFF1F2937)
                                  : Colors.grey,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(Icons.arrow_drop_down,
                            color: mat != null ? accent : Colors.grey,
                            size: 20),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Remove button
              GestureDetector(
                onTap: onRemove,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: onRemove != null
                        ? Colors.red.shade50
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.remove_circle_outline,
                    size: 18,
                    color: onRemove != null
                        ? Colors.red.shade400
                        : Colors.grey.shade300,
                  ),
                ),
              ),
            ],
          ),

          if (mat != null) ...[
            const SizedBox(height: 10),
            // ── Price info + qty input ─────────────────────────────────
            Row(
              children: [
                // Unit price chip
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${mat.unitPrice.toStringAsFixed(2)} ETB/${mat.unitLabel}',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: accent),
                  ),
                ),
                const SizedBox(width: 8),
                // Available stock chip
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'In stock: ${mat.isMeter ? '${mat.quantity.toStringAsFixed(1)} m' : '${mat.quantity.toStringAsFixed(0)} pcs'}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Qty input + subtotal
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: item.quantityCtrl,
                    onChanged: (_) => onChanged(),
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration: InputDecoration(
                      labelText: isMeter ? 'Meters' : 'Pieces',
                      suffixText: mat.unitLabel,
                      prefixIcon: Icon(
                        isMeter
                            ? Icons.straighten_rounded
                            : Icons.widgets_rounded,
                        size: 18,
                      ),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Subtotal
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color:
                            const Color(0xFF10B981).withValues(alpha: 0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Subtotal',
                          style: TextStyle(
                              fontSize: 10, color: Colors.grey)),
                      Text(
                        '${subtotal.toStringAsFixed(0)} ETB',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Shared small widgets
// ═══════════════════════════════════════════════════════════════════════════
class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: child,
      );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Color(0xFF374151)),
      );
}

class _PayTypeButton extends StatelessWidget {
  const _PayTypeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String     label;
  final IconData   icon;
  final bool       selected;
  final Color      color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? color : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: selected ? color : Colors.grey.shade200, width: 1.5),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: selected ? Colors.white : Colors.grey, size: 20),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                      color: selected ? Colors.white : Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ],
          ),
        ),
      );
}
