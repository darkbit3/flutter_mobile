import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_image_picker.dart';
import '../../auth/providers/auth_provider.dart';
import '../../sales/data/sale_repository.dart';
import '../../sales/models/sale_model.dart';
import '../providers/material_provider.dart';
import '../models/material_model.dart';

// ── Owner sales (for "Sales by Cashiers" section) ────────────────────────────
final ownerSalesProvider = FutureProvider.autoDispose<List<SaleModel>>((ref) async {
  return ref.watch(saleRepositoryProvider).getOwnerSales();
});

// ═══════════════════════════════════════════════════════════════════════════
// StockScreen
// ═══════════════════════════════════════════════════════════════════════════
class StockScreen extends ConsumerStatefulWidget {
  const StockScreen({super.key});

  @override
  ConsumerState<StockScreen> createState() => _StockScreenState();
}

class _ColorEntry {
  _ColorEntry({required this.colorName, required this.quantityCtr});
  final String colorName;
  final TextEditingController quantityCtr;
}

class _StockScreenState extends ConsumerState<StockScreen> {
  // ── Add Material Sheet ───────────────────────────────────────────────────
  void _openCreateMaterialSheet() {
    final nameCtr      = TextEditingController();
    final imageCtr     = TextEditingController();
    final costPriceCtr = TextEditingController();
    final sellPriceCtr = TextEditingController();
    final mainQtyCtr   = TextEditingController();
    String selectedUnit = 'Meter';

    List<_ColorEntry> colorEntries = [];
    final newColorNameCtr = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (_, setSheetState) {
          final unitSuffix = selectedUnit == 'Meter'
              ? 'm'
              : selectedUnit == 'Kilogram'
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
              top: 24,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
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
                  // ── Sheet header ──────────────────────────────────────────
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add_box_rounded,
                            color: AppColors.gold, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Add Stock Material',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.dark,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(ctx).pop(),
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
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Material Name',
                      hintText: 'e.g. Silk Fabric, Buttons, Leather',
                      prefixIcon: const Icon(Icons.category_outlined),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── 3 Unit selector: Meter | Piece | Kilogram ──────────────
                  const Text(
                    'Unit',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMid,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: ['Meter', 'Piece', 'Kilogram'].map((u) {
                      final isSelected = selectedUnit == u;
                      final uLabel = u == 'Meter'
                          ? 'Meter (m)'
                          : u == 'Piece'
                              ? 'Piece (pcs)'
                              : 'Kilo (kg)';
                      final uIcon = u == 'Meter'
                          ? Icons.straighten_rounded
                          : u == 'Piece'
                              ? Icons.widgets_rounded
                              : Icons.scale_rounded;

                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setSheetState(() => selectedUnit = u),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.gold
                                  : AppColors.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.gold
                                    : AppColors.border,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  uIcon,
                                  color: isSelected
                                      ? AppColors.dark
                                      : AppColors.textMid,
                                  size: 20,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  uLabel,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11.5,
                                    color: isSelected
                                        ? AppColors.dark
                                        : AppColors.textMid,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
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
                        hintText: 'Enter total quantity / weight',
                        prefixIcon: const Icon(Icons.numbers_rounded),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
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
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'Add color variant (e.g. Red, Blue)',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
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

                  // ── Price inputs (Cost Price vs Sell Price) ──────────────
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: costPriceCtr,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          onChanged: (_) => setSheetState(() {}),
                          decoration: InputDecoration(
                            labelText: 'Cost Price',
                            hintText: 'Initial cost',
                            prefixText: 'ETB ',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
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
                          decoration: InputDecoration(
                            labelText: 'Sell Price',
                            hintText: 'Selling price',
                            prefixText: 'ETB ',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
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
                  const SizedBox(height: 22),

                  // ── Submit button ─────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final name = nameCtr.text.trim();
                        final img  = imageCtr.text.trim();

                        if (name.isEmpty || finalQty <= 0 || sellPrice <= 0) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Please enter material name, quantity > 0, and sell price > 0.'),
                            ),
                          );
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

                        Navigator.of(ctx).pop();
                        try {
                          await ref
                              .read(materialNotifierProvider.notifier)
                              .create(
                                name:         name,
                                quantity:     finalQty,
                                unit:         selectedUnit,
                                unitPrice:    sellPrice,
                                initialPrice: costPrice > 0 ? costPrice : null,
                                imageUrl:     img.isNotEmpty ? img : null,
                                colors:       colorPayload.isNotEmpty
                                    ? colorPayload
                                    : null,
                              );
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('✅ "$name" added to stock.'),
                                backgroundColor: const Color(0xFF10B981),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text(
                        'Add to Stock',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: AppColors.dark,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
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

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final user          = ref.watch(authProvider).user;
    final materialsAsync = ref.watch(materialNotifierProvider);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header banner ────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.dark,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.dark.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.4)),
                    ),
                    child: const Icon(Icons.inventory_2_rounded,
                        color: AppColors.gold, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Stock & Materials',
                          style: TextStyle(
                            color: AppColors.cream,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${user?.role ?? "User"} — ${user?.name ?? ""}',
                          style: TextStyle(
                            color: AppColors.cream.withValues(alpha: 0.65),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Summary chips ────────────────────────────────────────────────
            materialsAsync.when(
              loading: () => const SizedBox.shrink(),
              error:   (_, __) => const SizedBox.shrink(),
              data: (materials) {
                final totalMeters = materials
                    .where((m) => m.isMeter)
                    .fold(0.0, (s, m) => s + m.quantity);
                final totalPieces = materials
                    .where((m) => m.isPiece)
                    .fold(0.0, (s, m) => s + m.quantity);
                final totalValue  = materials.fold(
                    0.0, (s, m) => s + m.totalValue);

                final lowStockItems = materials.where((m) => m.isLowStock).toList();

                if (materials.isEmpty) return const SizedBox.shrink();

                return Column(
                  children: [
                    Row(
                      children: [
                        _SummaryChip(
                          icon: Icons.straighten_rounded,
                          label: 'Total Meters',
                          value:
                              '${totalMeters.toStringAsFixed(totalMeters == totalMeters.truncateToDouble() ? 0 : 1)} m',
                          color: const Color(0xFF6366F1),
                        ),
                        const SizedBox(width: 10),
                        _SummaryChip(
                          icon: Icons.widgets_rounded,
                          label: 'Total Pieces',
                          value: '${totalPieces.toStringAsFixed(0)} pcs',
                          color: const Color(0xFF10B981),
                        ),
                        const SizedBox(width: 10),
                        _SummaryChip(
                          icon: Icons.payments_outlined,
                          label: 'Stock Value',
                          value: '${totalValue.toStringAsFixed(0)} ETB',
                          color: AppColors.gold,
                        ),
                      ],
                    ),
                    if (lowStockItems.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.red.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.warning_amber_rounded,
                                    color: Colors.red.shade700, size: 22),
                                const SizedBox(width: 8),
                                Text(
                                  'Low Stock Alert (≤ 20% remaining)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.red.shade800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'The following ${lowStockItems.length} item(s) are running critically low:',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.red.shade900),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: lowStockItems.map((m) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: Colors.red.shade200),
                                  ),
                                  child: Text(
                                    '⚠️ ${m.name}: ${m.quantity.toStringAsFixed(m.isMeter ? 1 : 0)} ${m.unitLabel} (${m.remainingPercentage.toStringAsFixed(0)}%)',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red.shade700,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),

            // ── Action Bar ───────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                materialsAsync.when(
                  loading: () => const Text('Materials Inventory',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.dark)),
                  error: (_, __) => const Text('Materials Inventory',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.dark)),
                  data: (m) => Text(
                    'Materials Inventory (${m.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.dark,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _openCreateMaterialSheet,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Material'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.dark,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Material List ─────────────────────────────────────────────────
            materialsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                    child: CircularProgressIndicator(color: AppColors.gold)),
              ),
              error: (err, _) => _EmptyCard(
                icon: Icons.error_outline,
                message: 'Could not load materials: $err',
              ),
              data: (materials) {
                if (materials.isEmpty) {
                  return const _EmptyCard(
                    icon: Icons.inventory_outlined,
                    message: 'No stock materials added yet',
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: materials.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) =>
                      _MaterialTile(material: materials[i], ref: ref),
                );
              },
            ),

            const SizedBox(height: 28),

            // ── Sales by Cashiers Section ─────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.point_of_sale_rounded,
                      color: Color(0xFF10B981), size: 18),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Sales by Cashiers',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.dark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            ref.watch(ownerSalesProvider).when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                    child: CircularProgressIndicator(color: AppColors.gold)),
              ),
              error: (_, __) => const _EmptyCard(
                icon: Icons.info_outline,
                message: 'No cashier sales recorded yet.',
              ),
              data: (sales) {
                if (sales.isEmpty) {
                  return const _EmptyCard(
                    icon: Icons.sell_outlined,
                    message: 'No sales recorded by cashiers yet',
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sales.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _SaleTile(sale: sales[i]),
                );
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Helper widgets
// ═══════════════════════════════════════════════════════════════════════════

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String   label;
  final String   value;
  final Color    color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: AppColors.textLight),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.icon, required this.message});
  final IconData icon;
  final String   message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: AppColors.textLight),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 14,
                color: AppColors.textMid,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _MaterialTile extends StatelessWidget {
  const _MaterialTile({required this.material, required this.ref});
  final MaterialItem material;
  final WidgetRef    ref;

  @override
  Widget build(BuildContext context) {
    final isMeter = material.isMeter;
    final color   = isMeter ? const Color(0xFF6366F1) : const Color(0xFF10B981);
    final bg      = isMeter ? const Color(0xFFEEF2FF) : const Color(0xFFECFDF5);

    final qtyLabel = isMeter
        ? '${material.quantity.toStringAsFixed(material.quantity == material.quantity.truncateToDouble() ? 0 : 2)} m'
        : material.isKilo
            ? '${material.quantity.toStringAsFixed(1)} kg'
            : '${material.quantity.toStringAsFixed(0)} pcs';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: AppImageDisplay(
                      imageUrl: material.imageUrl,
                      fit: BoxFit.cover,
                      placeholderIcon: isMeter
                          ? Icons.straighten_rounded
                          : material.isKilo
                              ? Icons.scale_rounded
                              : Icons.widgets_rounded,
                      iconColor: color,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Title & Subtitle details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        material.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.dark),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: material.isLowStock
                              ? Colors.red.shade50
                              : bg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$qtyLabel total',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: material.isLowStock
                                ? Colors.red.shade700
                                : color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Total Value & Delete Button
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${material.totalValue.toStringAsFixed(0)} ETB',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.dark,
                        fontSize: 14,
                      ),
                    ),
                    const Text(
                      'total value',
                      style: TextStyle(
                          fontSize: 10, color: AppColors.textLight),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          size: 18, color: Colors.red),
                      onPressed: () => _confirmDelete(context),
                    ),
                  ],
                ),
              ],
            ),

            // Color Variant Chips
            if (material.colors.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: material.colors.map((c) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.dark.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      '${c.colorName}: ${c.quantity} ${material.unitLabel}',
                      style: const TextStyle(
                        fontSize: 11,
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
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Material'),
        content: Text(
            'Delete "${material.name}" from stock? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await ref
                  .read(materialNotifierProvider.notifier)
                  .delete(material.id);
            },
            child: const Text('Delete',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _SaleTile extends StatelessWidget {
  const _SaleTile({required this.sale});
  final SaleModel sale;

  @override
  Widget build(BuildContext context) {
    final isCash = sale.isCash;
    final color  = isCash ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    final bg     = isCash ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: bg, borderRadius: BorderRadius.circular(8)),
                child: Icon(
                  isCash
                      ? Icons.sell_rounded
                      : Icons.account_balance_wallet_rounded,
                  size: 16,
                  color: color,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          sale.cashierName != null
                              ? 'Cashier: ${sale.cashierName}'
                              : 'Cashier Sale',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.dark),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                              color: bg,
                              borderRadius: BorderRadius.circular(6)),
                          child: Text(
                            sale.paymentType,
                            style: TextStyle(
                                fontSize: 10,
                                color: color,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      _fmtDate(sale.createdAt),
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textLight),
                    ),
                  ],
                ),
              ),
              Text(
                '${sale.totalAmount.toStringAsFixed(0)} ETB',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: color,
                ),
              ),
            ],
          ),
          if (sale.items.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: sale.items
                  .map((item) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          '${item.material} × ${item.quantity.toStringAsFixed(item.quantity == item.quantity.truncateToDouble() ? 0 : 1)}',
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.dark,
                              fontWeight: FontWeight.w500),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

String _fmtDate(String iso) {
  const months = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  try {
    final dt = DateTime.parse(iso);
    return '${dt.day} ${months[dt.month]} ${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  } catch (_) {
    return iso;
  }
}
