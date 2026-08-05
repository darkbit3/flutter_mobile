import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../models/material_model.dart';

final materialHistoryProvider =
    Provider.autoDispose<List<MaterialHistoryLog>>((ref) {
  // Sample stock movement history timeline
  final now = DateTime.now();
  return [
    MaterialHistoryLog(
      id: 'h1',
      materialName: 'Silk Fabric',
      action: 'Restocked',
      quantity: 50.0,
      unitLabel: 'm',
      note: 'Added new batch from supplier',
      dateStr: '${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute}',
    ),
    MaterialHistoryLog(
      id: 'h2',
      materialName: 'Cotton Thread',
      action: 'Added',
      quantity: 25.0,
      unitLabel: 'kg',
      note: 'Initial stock entry',
      dateStr: '${now.day}/${now.month}/${now.year} 10:30',
    ),
    MaterialHistoryLog(
      id: 'h3',
      materialName: 'Metal Buttons',
      action: 'Deducted',
      quantity: 100.0,
      unitLabel: 'pcs',
      note: 'Used for Sale #104',
      dateStr: '${now.day}/${now.month}/${now.year} 09:15',
    ),
  ];
});

class MaterialHistoryScreen extends ConsumerWidget {
  const MaterialHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyList = ref.watch(materialHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Stock Movement History'),
      ),
      body: historyList.isEmpty
          ? const Center(
              child: Text(
                'No stock history logs yet.',
                style: TextStyle(color: AppColors.textMid),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: historyList.length,
              itemBuilder: (context, idx) {
                final item = historyList[idx];
                final isRestock = item.action == 'Restocked' || item.action == 'Added';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: isRestock
                          ? Colors.green.withValues(alpha: 0.15)
                          : Colors.orange.withValues(alpha: 0.15),
                      child: Icon(
                        isRestock
                            ? Icons.add_circle_outline_rounded
                            : Icons.remove_circle_outline_rounded,
                        color: isRestock ? Colors.green : Colors.orange,
                      ),
                    ),
                    title: Text(
                      item.materialName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Text(
                      '${item.action}: ${item.quantity} ${item.unitLabel} • ${item.note}\n${item.dateStr}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMid),
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }
}
