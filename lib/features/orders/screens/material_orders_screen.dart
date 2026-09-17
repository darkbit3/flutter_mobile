import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../stock/data/material_repository.dart';
import '../../stock/models/material_model.dart';
import '../../stock/providers/material_provider.dart';
import '../models/material_order_model.dart';
import '../providers/material_order_provider.dart';

class MaterialOrdersScreen extends ConsumerWidget {
  const MaterialOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final ownerView = user != null && !user.isCashier;
    final canManage = user?.isMainUser == true;
    final orders = ref.watch(materialOrdersProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(ownerView ? 'Material Orders' : 'My Orders'),
        backgroundColor: ownerView ? const Color(0xFF8B5CF6) : const Color(0xFF10B981),
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: () => ref.invalidate(materialOrdersProvider), icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      floatingActionButton: user?.isCashier == true
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateOrder(context, ref),
              icon: const Icon(Icons.add_shopping_cart_rounded),
              label: const Text('Request Material'),
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
            )
          : null,
      body: orders.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (items) => items.isEmpty
            ? const Center(child: Text('No material orders yet'))
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(materialOrdersProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, index) => _OrderCard(order: items[index], ownerView: ownerView, canManage: canManage, onStatus: (status) async {
                    await ref.read(materialRepositoryProvider).updateMaterialOrderStatus(items[index].id, status);
                    ref.invalidate(materialOrdersProvider);
                  }),
                ),
              ),
      ),
    );
  }

  void _showCreateOrder(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _CreateOrderSheet(),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.ownerView, required this.canManage, required this.onStatus});
  final MaterialOrder order;
  final bool ownerView;
  final bool canManage;
  final Future<void> Function(String) onStatus;

  @override
  Widget build(BuildContext context) {
    final color = order.status == 'Pending' ? Colors.orange : order.status == 'Rejected' ? Colors.red : Colors.green;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.inventory_2_rounded, color: Color(0xFF8B5CF6)),
          const SizedBox(width: 10),
          Expanded(child: Text(order.materialName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
          Text(order.status, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 8),
        Text('Requested quantity: ${order.quantity.toStringAsFixed(2)}'),
        if (ownerView && order.requesterName != null) Text('Requested by: ${order.requesterName}'),
        if (order.note != null && order.note!.isNotEmpty) Text('Note: ${order.note}'),
        if (canManage && order.status != 'Fulfilled' && order.status != 'Rejected') ...[
          const SizedBox(height: 10),
          Wrap(spacing: 8, children: [
            OutlinedButton(onPressed: () => onStatus('Approved'), child: const Text('Approve')),
            OutlinedButton(onPressed: () => onStatus('Fulfilled'), child: const Text('Fulfilled')),
            TextButton(onPressed: () => onStatus('Rejected'), child: const Text('Reject')),
          ]),
        ],
      ]),
    );
  }
}

class _CreateOrderSheet extends ConsumerStatefulWidget {
  const _CreateOrderSheet();
  @override
  ConsumerState<_CreateOrderSheet> createState() => _CreateOrderSheetState();
}

class _CreateOrderSheetState extends ConsumerState<_CreateOrderSheet> {
  MaterialItem? _material;
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _noteController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final quantity = double.tryParse(_quantityController.text);
    final name = (_material?.name ?? _nameController.text).trim();
    if (name.isEmpty || quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter material and quantity.')));
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(materialRepositoryProvider).createMaterialOrder(
        materialId: _material?.id,
        materialName: name,
        quantity: quantity,
        note: _noteController.text,
      );
      ref.invalidate(materialOrdersProvider);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final materials = ref.watch(ownerMaterialsProvider).valueOrNull ?? const <MaterialItem>[];
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.viewInsetsOf(context).bottom + 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Request Material', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        DropdownButtonFormField<MaterialItem>(
          initialValue: _material,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Select existing material', border: OutlineInputBorder()),
          items: materials.map((item) => DropdownMenuItem(value: item, child: Text('${item.name} (${item.quantity} remaining)'))).toList(),
          onChanged: (value) => setState(() { _material = value; if (value != null) _nameController.text = value.name; }),
        ),
        const SizedBox(height: 10),
        TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Material name', border: OutlineInputBorder())),
        const SizedBox(height: 10),
        TextField(controller: _quantityController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Quantity needed', border: OutlineInputBorder())),
        const SizedBox(height: 10),
        TextField(controller: _noteController, decoration: const InputDecoration(labelText: 'Note (optional)', border: OutlineInputBorder())),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _saving ? null : _submit, child: _saving ? const CircularProgressIndicator() : const Text('Send Request'))),
      ]),
    );
  }
}
