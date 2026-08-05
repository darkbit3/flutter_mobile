import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/toast/toast_service.dart';
import '../../../core/widgets/app_image_picker.dart';
import '../../../core/widgets/app_loading.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/material_repository.dart';
import '../providers/material_provider.dart';
import 'material_history_screen.dart';

class _ColorEntry {
  _ColorEntry({required this.colorName, required this.quantityCtr});
  final String colorName;
  final TextEditingController quantityCtr;
}

/// Dedicated Material Screen for Resellers and Manufacturers
class MaterialScreen extends ConsumerStatefulWidget {
  const MaterialScreen({super.key});

  @override
  ConsumerState<MaterialScreen> createState() => _MaterialScreenState();
}

class _MaterialScreenState extends ConsumerState<MaterialScreen> {
  String _searchQuery = '';
  String _selectedFilter =
      'All'; // 'All' | 'Meter' | 'Piece' | 'Kilogram' | 'Low Stock'

  void _openAddMaterialSheet() {
    final nameCtr = TextEditingController();
    final imageCtr = TextEditingController();
    final costPriceCtr = TextEditingController();
    final sellPriceCtr = TextEditingController();
    final mainQtyCtr = TextEditingController();
    String unit = 'Meter'; // 'Meter' | 'Piece' | 'Kilogram'

    List<_ColorEntry> colorEntries = [];
    final newColorNameCtr = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (_, setSheetState) {
          final unitSuffix = unit == 'Meter'
              ? 'm'
              : unit == 'Kilogram'
                  ? 'kg'
                  : 'pcs';

          double totalQtyFromColors = 0;
          for (final entry in colorEntries) {
            totalQtyFromColors +=
                double.tryParse(entry.quantityCtr.text.trim()) ?? 0;
          }

          final manualQty = double.tryParse(mainQtyCtr.text.trim()) ?? 0;
          final finalQty =
              colorEntries.isNotEmpty ? totalQtyFromColors : manualQty;

          final costPrice = double.tryParse(costPriceCtr.text.trim()) ?? 0;
          final sellPrice = double.tryParse(sellPriceCtr.text.trim()) ?? 0;
          final totalCost = finalQty * costPrice;
          final totalSales = finalQty * sellPrice;
          final totalProfit = totalSales - totalCost;

          return Container(
            padding: EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Icon(Icons.inventory_2_rounded,
                          color: AppColors.gold, size: 24),
                      SizedBox(width: 10),
                      Text(
                        'Add New Material',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: AppColors.dark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // ── Image / Photo Picker ─────────────────────────────────
                  AppImagePickerBox(
                    base64Image: imageCtr.text.isNotEmpty ? imageCtr.text : null,
                    onImagePicked: (b64) => setSheetState(() => imageCtr.text = b64),
                    onImageRemoved: () => setSheetState(() => imageCtr.text = ''),
                  ),
                  const SizedBox(height: 14),

                  // ── Material Name ─────────────────────────────────────────
                  TextField(
                    controller: nameCtr,
                    decoration: const InputDecoration(
                      labelText: 'Material Name',
                      hintText: 'e.g. Silk Fabric, Threads, Metal Parts',
                      prefixIcon: Icon(Icons.label_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── 3 Unit Selector (Meter, Piece, Kilogram) ──────────────
                  const Text('Measurement Unit',
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMid)),
                  const SizedBox(height: 6),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'Meter',
                        label: Text('Meter (m)'),
                        icon: Icon(Icons.straighten_rounded, size: 14),
                      ),
                      ButtonSegment(
                        value: 'Piece',
                        label: Text('Piece (pcs)'),
                        icon: Icon(Icons.grid_view_rounded, size: 14),
                      ),
                      ButtonSegment(
                        value: 'Kilogram',
                        label: Text('Kilo (kg)'),
                        icon: Icon(Icons.scale_rounded, size: 14),
                      ),
                    ],
                    selected: {unit},
                    onSelectionChanged: (set) {
                      setSheetState(() => unit = set.first);
                    },
                  ),
                  const SizedBox(height: 16),

                  // ── Color Variants Section ────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Color Content & Quantities ($unitSuffix)',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.dark,
                        ),
                      ),
                      Text(
                        'Total: $finalQty $unitSuffix',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.gold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (colorEntries.isNotEmpty) ...[
                    ...colorEntries.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.dark.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  e.colorName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: e.quantityCtr,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  onChanged: (_) => setSheetState(() {}),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    labelText: 'Quantity ($unitSuffix)',
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded,
                                    color: Colors.red, size: 20),
                                onPressed: () {
                                  setSheetState(() {
                                    e.quantityCtr.dispose();
                                    colorEntries.remove(e);
                                  });
                                },
                              ),
                            ],
                          ),
                        )),
                    const SizedBox(height: 8),
                  ] else ...[
                    TextField(
                      controller: mainQtyCtr,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      onChanged: (_) => setSheetState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Total Quantity ($unitSuffix)',
                        hintText: 'Enter weight / quantity',
                        prefixIcon: const Icon(Icons.numbers_rounded),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Add Color Entry Row
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: newColorNameCtr,
                          decoration: const InputDecoration(
                            isDense: true,
                            hintText: 'Add color variant (e.g. Red, Blue)',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () {
                          final cName = newColorNameCtr.text.trim();
                          if (cName.isNotEmpty) {
                            setSheetState(() {
                              colorEntries.add(_ColorEntry(
                                colorName: cName,
                                quantityCtr: TextEditingController(text: '0'),
                              ));
                              newColorNameCtr.clear();
                            });
                          }
                        },
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Color'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Prices ───────────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: costPriceCtr,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          onChanged: (_) => setSheetState(() {}),
                          decoration: const InputDecoration(
                            labelText: 'Cost Price',
                            hintText: 'Initial price',
                            prefixText: 'ETB ',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: sellPriceCtr,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          onChanged: (_) => setSheetState(() {}),
                          decoration: const InputDecoration(
                            labelText: 'Sell Price',
                            hintText: 'Selling price',
                            prefixText: 'ETB ',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Summary Box ──────────────────────────────────────────
                  if (finalQty > 0 && (costPrice > 0 || sellPrice > 0))
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Cost Value:',
                                  style: TextStyle(fontSize: 12)),
                              Text('${totalCost.toStringAsFixed(2)} ETB',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Selling Value:',
                                  style: TextStyle(fontSize: 12)),
                              Text('${totalSales.toStringAsFixed(2)} ETB',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.dark)),
                            ],
                          ),
                          const Divider(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Est. Profit Margin:',
                                  style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold)),
                              Text(
                                '${totalProfit.toStringAsFixed(2)} ETB',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: totalProfit >= 0
                                      ? Colors.green.shade700
                                      : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.dark,
                        foregroundColor: AppColors.cream,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () async {
                        final name = nameCtr.text.trim();
                        final img = imageCtr.text.trim();

                        if (name.isEmpty || finalQty <= 0 || sellPrice <= 0) {
                          ref.read(toastServiceProvider).warning(
                              'Please enter material name, quantity, and selling price');
                          return;
                        }

                        final colorPayload = colorEntries
                            .map((e) => {
                                  'colorName': e.colorName,
                                  'quantity': double.tryParse(
                                          e.quantityCtr.text.trim()) ??
                                      0,
                                })
                            .toList();

                        Navigator.pop(ctx);
                        try {
                          await ref
                              .read(materialRepositoryProvider)
                              .createMaterial(
                                name: name,
                                quantity: finalQty,
                                unit: unit,
                                unitPrice: sellPrice,
                                initialPrice:
                                    costPrice > 0 ? costPrice : null,
                                imageUrl: img.isNotEmpty ? img : null,
                                colors: colorPayload.isNotEmpty
                                    ? colorPayload
                                    : null,
                              );
                          ref.invalidate(materialsProvider);
                          ref
                              .read(toastServiceProvider)
                              .success('Material added successfully!');
                        } catch (e) {
                          ref
                              .read(toastServiceProvider)
                              .error('Failed to add material');
                        }
                      },
                      child: const Text('Save Material',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final materialsAsync = ref.watch(materialsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Materials & Inventory'),
        actions: [
          // ── Stock Movement History Button ────────────────────────────────
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Stock History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const MaterialHistoryScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(materialsProvider),
          ),
        ],
      ),
      floatingActionButton: (user?.isReseller ?? false) ||
              (user?.isManufacturer ?? false)
          ? FloatingActionButton.extended(
              onPressed: _openAddMaterialSheet,
              backgroundColor: AppColors.dark,
              foregroundColor: AppColors.cream,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Material'),
            )
          : null,
      body: Column(
        children: [
          // ── Low Stock Alert Banner ───────────────────────────────────────
          materialsAsync.maybeWhen(
            data: (items) {
              final lowStockItems = items.where((i) => i.isLowStock).toList();
              if (lowStockItems.isEmpty) return const SizedBox.shrink();
              return Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: Colors.amber.shade100,
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Colors.amber, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Stock Alert: ${lowStockItems.length} item(s) running low on stock!',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),

          // ── Search & Filter Bar ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  onChanged: (v) => setState(() => _searchQuery = v.trim()),
                  decoration: InputDecoration(
                    hintText: 'Search material by name...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                    fillColor: Colors.white,
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children:
                        ['All', 'Meter', 'Piece', 'Kilogram', 'Low Stock']
                            .map((cat) {
                      final selected = _selectedFilter == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(cat == 'Kilogram' ? 'Kilo (kg)' : cat),
                          selected: selected,
                          selectedColor: AppColors.gold.withValues(alpha: 0.2),
                          checkmarkColor: AppColors.gold,
                          onSelected: (_) =>
                              setState(() => _selectedFilter = cat),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // ── List View ──────────────────────────────────────────────────
          Expanded(
            child: materialsAsync.when(
              loading: () => const AppLoadingIndicator(
                  message: 'Loading materials...'),
              error: (err, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        size: 40, color: Colors.red),
                    const SizedBox(height: 8),
                    Text('Failed to load materials: $err'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => ref.invalidate(materialsProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (items) {
                final filtered = items.where((item) {
                  final matchesSearch = item.name
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase());
                  if (!matchesSearch) return false;

                  if (_selectedFilter == 'Meter') return item.isMeter;
                  if (_selectedFilter == 'Piece') return item.isPiece;
                  if (_selectedFilter == 'Kilogram') return item.isKilo;
                  if (_selectedFilter == 'Low Stock') return item.isLowStock;
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text(
                      'No materials found.',
                      style: TextStyle(color: AppColors.textMid),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, idx) {
                    final item = filtered[idx];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Thumbnail or Icon
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: item.isLowStock
                                        ? Colors.red.withValues(alpha: 0.12)
                                        : AppColors.gold.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: AppImageDisplay(
                                      imageUrl: item.imageUrl,
                                      fit: BoxFit.cover,
                                      placeholderIcon: item.isMeter
                                          ? Icons.straighten_rounded
                                          : item.isKilo
                                              ? Icons.scale_rounded
                                              : Icons.grid_view_rounded,
                                      iconColor: item.isLowStock
                                          ? Colors.red
                                          : AppColors.gold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Title & Subtitle
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Qty: ${item.quantity} ${item.unitLabel}  •  Sell: ${item.sellingPrice} ETB/${item.unitLabel}',
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          color: AppColors.textMid,
                                        ),
                                      ),
                                      if (item.initialPrice != null)
                                        Text(
                                          'Cost: ${item.initialPrice} ETB/${item.unitLabel}',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),

                                // Total Value & Badge
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${item.totalValue.toStringAsFixed(2)} ETB',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: AppColors.dark,
                                      ),
                                    ),
                                    if (item.isLowStock) ...[
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.red
                                              .withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'Low Stock Alert',
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),

                            // Color Variants Chips
                            if (item.colors.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              const Divider(height: 1),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: item.colors.map((c) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.dark
                                          .withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: AppColors.border),
                                    ),
                                    child: Text(
                                      '${c.colorName}: ${c.quantity} ${item.unitLabel}',
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.dark,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
