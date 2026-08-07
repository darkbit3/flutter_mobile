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
  _ColorEntry({required this.colorName, required this.color, required this.quantityCtr});
  final String colorName;
  final Color color;
  final TextEditingController quantityCtr;
}

// ── Predefined color palette ─────────────────────────────────────────────────
const List<_SwatchDef> _kSwatches = [
  _SwatchDef('Red',       Color(0xFFE53935)),
  _SwatchDef('Pink',      Color(0xFFE91E63)),
  _SwatchDef('Purple',    Color(0xFF9C27B0)),
  _SwatchDef('Navy',      Color(0xFF1A237E)),
  _SwatchDef('Blue',      Color(0xFF1E88E5)),
  _SwatchDef('Sky',       Color(0xFF29B6F6)),
  _SwatchDef('Teal',      Color(0xFF009688)),
  _SwatchDef('Green',     Color(0xFF43A047)),
  _SwatchDef('Lime',      Color(0xFF8BC34A)),
  _SwatchDef('Yellow',    Color(0xFFFFD600)),
  _SwatchDef('Orange',    Color(0xFFFB8C00)),
  _SwatchDef('Brown',     Color(0xFF6D4C41)),
  _SwatchDef('Beige',     Color(0xFFD7CCC8)),
  _SwatchDef('White',     Color(0xFFF5F5F5)),
  _SwatchDef('Silver',    Color(0xFFBDBDBD)),
  _SwatchDef('Grey',      Color(0xFF757575)),
  _SwatchDef('Charcoal',  Color(0xFF37474F)),
  _SwatchDef('Black',     Color(0xFF212121)),
  _SwatchDef('Gold',      Color(0xFFC8A96E)),
  _SwatchDef('Cream',     Color(0xFFF5EDE0)),
];

class _SwatchDef {
  const _SwatchDef(this.name, this.color);
  final String name;
  final Color color;
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddMaterialSheet(
        onCreated: () {
          ref.invalidate(materialsProvider);
          ref.read(toastServiceProvider).success('Material added successfully!');
        },
        onError: () {
          ref.read(toastServiceProvider).error('Failed to add material');
        },
        onValidationError: (msg) {
          ref.read(toastServiceProvider).warning(msg);
        },
        materialRepo: ref.read(materialRepositoryProvider),
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
                                      const SizedBox(height: 4),
                                      // ── Remaining / Total ──────────────
                                      Row(
                                        children: [
                                          Text(
                                            '${item.quantity.toStringAsFixed(item.quantity == item.quantity.truncateToDouble() ? 0 : 2)} / ${item.initialQuantity.toStringAsFixed(item.initialQuantity == item.initialQuantity.truncateToDouble() ? 0 : 2)} ${item.unitLabel}',
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w600,
                                              color: item.isLowStock ? Colors.red : AppColors.textMid,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: item.isLowStock
                                                  ? Colors.red.withValues(alpha: 0.1)
                                                  : AppColors.gold.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '${item.remainingPercentage.toStringAsFixed(0)}%',
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.bold,
                                                color: item.isLowStock ? Colors.red : AppColors.gold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 5),
                                      // ── Progress bar ───────────────────
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: item.remainingPercentage / 100,
                                          minHeight: 5,
                                          backgroundColor: Colors.grey.shade200,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            item.remainingPercentage <= 20
                                                ? Colors.red
                                                : item.remainingPercentage <= 50
                                                    ? Colors.orange
                                                    : AppColors.gold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'Sell: ${item.sellingPrice.toStringAsFixed(2)} ETB/${item.unitLabel}',
                                        style: const TextStyle(
                                          fontSize: 11.5,
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
                                runSpacing: 6,
                                children: item.colors.map((c) {
                                  // Parse hex color if available, fallback to dark
                                  Color circleColor = AppColors.dark;
                                  try {
                                    if (c.colorName.isNotEmpty) {
                                      final match = _kSwatches.where((s) =>
                                          s.name.toLowerCase() == c.colorName.toLowerCase());
                                      if (match.isNotEmpty) circleColor = match.first.color;
                                    }
                                  } catch (_) {}

                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: circleColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: circleColor.withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 14,
                                          height: 14,
                                          decoration: BoxDecoration(
                                            color: circleColor,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.black.withValues(alpha: 0.1),
                                              width: 0.8,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          '${c.colorName}: ${c.quantity} ${item.unitLabel}',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color: ThemeData.estimateBrightnessForColor(circleColor) == Brightness.light
                                                ? AppColors.dark
                                                : AppColors.dark,
                                          ),
                                        ),
                                      ],
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

// ═══════════════════════════════════════════════════════════════════════════
// Add Material Sheet — proper StatefulWidget so all state is clean
// ═══════════════════════════════════════════════════════════════════════════

class _AddMaterialSheet extends StatefulWidget {
  const _AddMaterialSheet({
    required this.onCreated,
    required this.onError,
    required this.onValidationError,
    required this.materialRepo,
  });

  final VoidCallback onCreated;
  final VoidCallback onError;
  final ValueChanged<String> onValidationError;
  final MaterialRepository materialRepo;

  @override
  State<_AddMaterialSheet> createState() => _AddMaterialSheetState();
}

class _AddMaterialSheetState extends State<_AddMaterialSheet> {
  final _nameCtr      = TextEditingController();
  final _costPriceCtr = TextEditingController();
  final _sellPriceCtr = TextEditingController();
  final _mainQtyCtr   = TextEditingController();

  String _unit = 'Meter';
  String _imageBase64 = '';
  final List<_ColorEntry> _colorEntries = [];

  @override
  void dispose() {
    _nameCtr.dispose();
    _costPriceCtr.dispose();
    _sellPriceCtr.dispose();
    _mainQtyCtr.dispose();
    for (final e in _colorEntries) {
      e.quantityCtr.dispose();
    }
    super.dispose();
  }

  // ── Derived values ───────────────────────────────────────────────────────
  String get _unitSuffix => _unit == 'Meter' ? 'm' : _unit == 'Kilogram' ? 'kg' : 'pcs';

  double get _totalQtyFromColors => _colorEntries.fold(
      0.0, (sum, e) => sum + (double.tryParse(e.quantityCtr.text.trim()) ?? 0));

  double get _manualQty => double.tryParse(_mainQtyCtr.text.trim()) ?? 0;
  double get _finalQty  => _colorEntries.isNotEmpty ? _totalQtyFromColors : _manualQty;
  double get _costPrice => double.tryParse(_costPriceCtr.text.trim()) ?? 0;
  double get _sellPrice => double.tryParse(_sellPriceCtr.text.trim()) ?? 0;

  // ── Save ─────────────────────────────────────────────────────────────────
  Future<void> _save() async {
    final name = _nameCtr.text.trim();
    if (name.isEmpty || _finalQty <= 0 || _sellPrice <= 0) {
      widget.onValidationError('Please enter material name, quantity, and selling price');
      return;
    }

    final colorPayload = _colorEntries.map((e) => {
      'colorName': e.colorName,
      'colorHex':  '#${e.color.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
      'quantity':  double.tryParse(e.quantityCtr.text.trim()) ?? 0.0,
    }).toList();

    Navigator.pop(context);

    try {
      await widget.materialRepo.createMaterial(
        name:         name,
        quantity:     _finalQty,
        unit:         _unit,
        unitPrice:    _sellPrice,
        initialPrice: _costPrice > 0 ? _costPrice : null,
        imageUrl:     _imageBase64.isNotEmpty ? _imageBase64 : null,
        colors:       colorPayload.isNotEmpty ? colorPayload : null,
      );
      widget.onCreated();
    } catch (_) {
      widget.onError();
    }
  }

  // ── Custom color dialog ──────────────────────────────────────────────────
  void _openCustomColorDialog() {
    final nameCtr = TextEditingController();
    Color picked = const Color(0xFF9E9E9E);

    showDialog(
      context: context,
      builder: (dCtx) => StatefulBuilder(
        builder: (_, setDlg) => AlertDialog(
          title: const Text('Custom Color'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtr,
                  decoration: const InputDecoration(
                    labelText: 'Color Name',
                    hintText: 'e.g. Burgundy, Mustard',
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Pick a color:', style: TextStyle(fontSize: 12, color: AppColors.textMid)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _kSwatches.map((s) {
                    final sel = picked == s.color;
                    return GestureDetector(
                      onTap: () => setDlg(() => picked = s.color),
                      child: Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: s.color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: sel ? AppColors.gold : Colors.black.withValues(alpha: 0.1),
                            width: sel ? 2.5 : 1,
                          ),
                        ),
                        child: sel
                            ? Icon(Icons.check_rounded, size: 14,
                                color: ThemeData.estimateBrightnessForColor(s.color) == Brightness.light
                                    ? AppColors.dark : Colors.white)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Selected:', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 8),
                    Container(
                      width: 26, height: 26,
                      decoration: BoxDecoration(
                        color: picked,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black.withValues(alpha: 0.15)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dCtx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final n = nameCtr.text.trim();
                if (n.isNotEmpty) {
                  setState(() {
                    _colorEntries.add(_ColorEntry(
                      colorName: n,
                      color: picked,
                      quantityCtr: TextEditingController(text: '0'),
                    ));
                  });
                  Navigator.pop(dCtx);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final totalCost   = _finalQty * _costPrice;
    final totalSales  = _finalQty * _sellPrice;
    final totalProfit = totalSales - totalCost;

    return Container(
      padding: EdgeInsets.only(
        top: 20, left: 20, right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            const Row(
              children: [
                Icon(Icons.inventory_2_rounded, color: AppColors.gold, size: 24),
                SizedBox(width: 10),
                Text('Add New Material',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: AppColors.dark)),
              ],
            ),
            const SizedBox(height: 18),

            // ── Image picker ───────────────────────────────────────────────
            AppImagePickerBox(
              base64Image: _imageBase64.isNotEmpty ? _imageBase64 : null,
              onImagePicked:  (b64) => setState(() => _imageBase64 = b64),
              onImageRemoved: ()    => setState(() => _imageBase64 = ''),
            ),
            const SizedBox(height: 14),

            // ── Name ───────────────────────────────────────────────────────
            TextField(
              controller: _nameCtr,
              decoration: const InputDecoration(
                labelText: 'Material Name',
                hintText: 'e.g. Silk Fabric, Threads, Metal Parts',
                prefixIcon: Icon(Icons.label_outline_rounded),
              ),
            ),
            const SizedBox(height: 14),

            // ── Unit selector ──────────────────────────────────────────────
            const Text('Measurement Unit',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textMid)),
            const SizedBox(height: 6),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Meter',    label: Text('Meter (m)'),   icon: Icon(Icons.straighten_rounded,  size: 14)),
                ButtonSegment(value: 'Piece',    label: Text('Piece (pcs)'), icon: Icon(Icons.grid_view_rounded,   size: 14)),
                ButtonSegment(value: 'Kilogram', label: Text('Kilo (kg)'),   icon: Icon(Icons.scale_rounded,       size: 14)),
              ],
              selected: {_unit},
              onSelectionChanged: (s) => setState(() => _unit = s.first),
            ),
            const SizedBox(height: 16),

            // ── Color section header ───────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Color Variants & Quantities ($_unitSuffix)',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.dark)),
                Text('Total: ${_finalQty.toStringAsFixed(2)} $_unitSuffix',
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.gold)),
              ],
            ),
            const SizedBox(height: 8),

            // ── Selected color rows ────────────────────────────────────────
            if (_colorEntries.isNotEmpty) ...[
              ..._colorEntries.map((e) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      // Colored circle
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: e.color,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black.withValues(alpha: 0.15), width: 1.5),
                          boxShadow: [BoxShadow(color: e.color.withValues(alpha: 0.35), blurRadius: 4, offset: const Offset(0, 2))],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Color name badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: e.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: e.color.withValues(alpha: 0.35)),
                        ),
                        child: Text(
                          e.colorName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                            color: ThemeData.estimateBrightnessForColor(e.color) == Brightness.light
                                ? AppColors.dark : Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: e.quantityCtr,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(isDense: true, labelText: 'Qty ($_unitSuffix)'),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                        onPressed: () => setState(() {
                          e.quantityCtr.dispose();
                          _colorEntries.remove(e);
                        }),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 4),
            ] else ...[
              // No colors → manual qty
              TextField(
                controller: _mainQtyCtr,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Total Quantity ($_unitSuffix)',
                  hintText: 'Enter weight / quantity',
                  prefixIcon: const Icon(Icons.numbers_rounded),
                ),
              ),
              const SizedBox(height: 10),
            ],

            // ── Swatch palette label ───────────────────────────────────────
            const Text('Add Color Variant',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMid)),
            const SizedBox(height: 8),

            // ── Swatch grid ────────────────────────────────────────────────
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._kSwatches.map((swatch) {
                  final added = _colorEntries.any((e) => e.colorName == swatch.name);
                  return GestureDetector(
                    onTap: added
                        ? null
                        : () => setState(() {
                              _colorEntries.add(_ColorEntry(
                                colorName: swatch.name,
                                color: swatch.color,
                                quantityCtr: TextEditingController(text: '0'),
                              ));
                            }),
                    child: Tooltip(
                      message: swatch.name,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: swatch.color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: added ? AppColors.gold : Colors.black.withValues(alpha: 0.12),
                                width: added ? 2.5 : 1.2,
                              ),
                            ),
                          ),
                          if (added)
                            Icon(Icons.check_rounded, size: 16,
                                color: ThemeData.estimateBrightnessForColor(swatch.color) == Brightness.light
                                    ? AppColors.dark : Colors.white),
                        ],
                      ),
                    ),
                  );
                }),

                // Rainbow "custom" button
                GestureDetector(
                  onTap: _openCustomColorDialog,
                  child: Tooltip(
                    message: 'Custom color',
                    child: ClipOval(
                      child: Container(
                        width: 36, height: 36,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SweepGradient(
                            colors: [
                              Color(0xFFE53935), Color(0xFFFFD600),
                              Color(0xFF43A047), Color(0xFF1E88E5),
                              Color(0xFF9C27B0), Color(0xFFE53935),
                            ],
                          ),
                        ),
                        child: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Prices ─────────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _costPriceCtr,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Cost Price', hintText: 'Initial price', prefixText: 'ETB ',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _sellPriceCtr,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Sell Price', hintText: 'Selling price', prefixText: 'ETB ',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Summary box ────────────────────────────────────────────────
            if (_finalQty > 0 && (_costPrice > 0 || _sellPrice > 0))
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    _SummaryRow('Total Cost Value:',    '${totalCost.toStringAsFixed(2)} ETB',   bold: false),
                    const SizedBox(height: 4),
                    _SummaryRow('Total Selling Value:', '${totalSales.toStringAsFixed(2)} ETB',  bold: true),
                    const Divider(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Est. Profit Margin:', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                        Text(
                          '${totalProfit.toStringAsFixed(2)} ETB',
                          style: TextStyle(
                            fontSize: 13.5, fontWeight: FontWeight.bold,
                            color: totalProfit >= 0 ? Colors.green.shade700 : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // ── Save button ────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.dark,
                  foregroundColor: AppColors.cream,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _save,
                child: const Text('Save Material', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value, {this.bold = false});
  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        Text(value,  style: TextStyle(fontSize: 12, fontWeight: bold ? FontWeight.bold : FontWeight.w600)),
      ],
    );
  }
}
