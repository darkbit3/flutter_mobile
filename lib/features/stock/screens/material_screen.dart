import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/toast/toast_service.dart';
import '../../../core/widgets/app_image_picker.dart';
import '../../../core/widgets/app_loading.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/material_repository.dart';
import '../models/material_model.dart';
import '../providers/material_provider.dart';
import 'material_history_screen.dart';

// ── In-memory base64 cache (shared with AppImageDisplay) ─────────────────────
final Map<String, Uint8List> _b64Cache = {};

Uint8List? _decodeB64(String raw) {
  if (_b64Cache.containsKey(raw)) return _b64Cache[raw];
  try {
    String clean = raw;
    if (raw.startsWith('data:image')) {
      final ci = raw.indexOf(',');
      if (ci != -1) clean = raw.substring(ci + 1);
    }
    final bytes = base64Decode(clean);
    _b64Cache[raw] = bytes;
    return bytes;
  } catch (_) {
    return null;
  }
}

class _ColorEntry {
  _ColorEntry({required this.colorName, required this.color, required this.quantityCtr});
  final String colorName;
  final Color color;
  final TextEditingController quantityCtr;
}

// ── Predefined color palette ──────────────────────────────────────────────────
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

Color _colorForName(String name) {
  try {
    final m = _kSwatches.where((s) => s.name.toLowerCase() == name.toLowerCase());
    if (m.isNotEmpty) return m.first.color;
  } catch (_) {}
  return AppColors.dark;
}

// ═══════════════════════════════════════════════════════════════════════════
// Material Screen
// ═══════════════════════════════════════════════════════════════════════════

class MaterialScreen extends ConsumerStatefulWidget {
  const MaterialScreen({super.key});

  @override
  ConsumerState<MaterialScreen> createState() => _MaterialScreenState();
}

class _MaterialScreenState extends ConsumerState<MaterialScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'All';

  void _openAddMaterialSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddMaterialSheet(
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

  void _openDetailSheet(MaterialItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _MaterialDetailSheet(item: item),
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
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Stock History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MaterialHistoryScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(materialsProvider),
          ),
        ],
      ),
      floatingActionButton: (user?.isReseller ?? false) || (user?.isManufacturer ?? false)
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
          // Low Stock Banner
          materialsAsync.maybeWhen(
            data: (items) {
              final lowStock = items.where((i) => i.isLowStock).toList();
              if (lowStock.isEmpty) return const SizedBox.shrink();
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: Colors.amber.shade100,
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Stock Alert: ${lowStock.length} item(s) running low on stock!',
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

          // Search & Filter
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
                    children: ['All', 'Meter', 'Piece', 'Kilogram', 'Low Stock'].map((cat) {
                      final selected = _selectedFilter == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(cat == 'Kilogram' ? 'Kilo (kg)' : cat),
                          selected: selected,
                          selectedColor: AppColors.gold.withValues(alpha: 0.2),
                          checkmarkColor: AppColors.gold,
                          onSelected: (_) => setState(() => _selectedFilter = cat),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: materialsAsync.when(
              loading: () => const AppLoadingIndicator(message: 'Loading materials...'),
              error: (err, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 40, color: Colors.red),
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
                final user = ref.watch(authProvider).user;
                final threshold = user?.alertThresholdPercentage ?? 20.0;
                
                final filtered = items.where((item) {
                  final matchesSearch = item.name.toLowerCase().contains(_searchQuery.toLowerCase());
                  if (!matchesSearch) return false;
                  if (_selectedFilter == 'Meter') return item.isMeter;
                  if (_selectedFilter == 'Piece') return item.isPiece;
                  if (_selectedFilter == 'Kilogram') return item.isKilo;
                  if (_selectedFilter == 'Low Stock') return item.isLowStockWithThreshold(threshold);
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('No materials found.', style: TextStyle(color: AppColors.textMid)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, idx) {
                    final item = filtered[idx];
                    return _MaterialCard(
                      item: item,
                      onTap: () => _openDetailSheet(item),
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
// Material Card
// ═══════════════════════════════════════════════════════════════════════════

class _MaterialCard extends StatelessWidget {
  const _MaterialCard({required this.item, required this.onTap});
  final MaterialItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: item.isLowStock ? Colors.red.shade200 : AppColors.border,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image thumbnail (first image or icon)
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: item.isLowStock
                          ? Colors.red.withValues(alpha: 0.12)
                          : AppColors.gold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _ImageThumb(
                        imageUrl: item.imageUrl,
                        icon: item.isMeter
                            ? Icons.straighten_rounded
                            : item.isKilo
                                ? Icons.scale_rounded
                                : Icons.grid_view_rounded,
                        iconColor: item.isLowStock ? Colors.red : AppColors.gold,
                      ),
                    ),
                  ),

                  // Multiple images indicator badge
                  if (item.images.length > 1)
                    Align(
                      alignment: Alignment.topLeft,
                      child: Transform.translate(
                        offset: const Offset(-8, -4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.dark,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '+${item.images.length - 1}',
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(width: 12),

                  // Title & details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textMid),
                          ],
                        ),
                        const SizedBox(height: 4),
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
                          style: const TextStyle(fontSize: 11.5, color: AppColors.textMid),
                        ),
                      ],
                    ),
                  ),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${item.totalValue.toStringAsFixed(2)} ETB',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.dark),
                      ),
                      if (item.isLowStock) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Low Stock',
                            style: TextStyle(fontSize: 10.5, color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),

              // Color Variants
              if (item.colors.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: item.colors.map((c) {
                    final cc = _colorForName(c.colorName);
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: cc.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: cc.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 12, height: 12,
                            decoration: BoxDecoration(
                              color: cc,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black.withValues(alpha: 0.1), width: 0.8),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${c.colorName}: ${c.quantity.toStringAsFixed(c.quantity == c.quantity.truncateToDouble() ? 0 : 1)} ${item.unitLabel}',
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.dark),
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
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Material Detail Sheet — full detail with image slider
// ═══════════════════════════════════════════════════════════════════════════

class _MaterialDetailSheet extends ConsumerStatefulWidget {
  const _MaterialDetailSheet({required this.item});
  final MaterialItem item;

  @override
  ConsumerState<_MaterialDetailSheet> createState() => _MaterialDetailSheetState();
}

class _MaterialDetailSheetState extends ConsumerState<_MaterialDetailSheet> {
  int _currentImageIndex = 0;
  late final PageController _pageCtrl;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final hasImages = item.images.isNotEmpty;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Column(
        children: [
          // Handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 4),

          // Image Slider
          if (hasImages) ...[
            SizedBox(
              height: 220,
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _pageCtrl,
                    itemCount: item.images.length,
                    onPageChanged: (i) => setState(() => _currentImageIndex = i),
                    itemBuilder: (_, i) => _FullImage(imageUrl: item.images[i]),
                  ),
                  // Gradient overlay at bottom
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.black.withValues(alpha: 0.5), Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                  // Dots
                  if (item.images.length > 1)
                    Positioned(
                      bottom: 10, left: 0, right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(item.images.length, (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: i == _currentImageIndex ? 18 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: i == _currentImageIndex ? AppColors.gold : Colors.white.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        )),
                      ),
                    ),
                  // Arrow left
                  if (item.images.length > 1 && _currentImageIndex > 0)
                    Positioned(
                      left: 8, top: 0, bottom: 0,
                      child: Center(
                        child: GestureDetector(
                          onTap: () => _pageCtrl.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.35), shape: BoxShape.circle),
                            child: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ),
                  // Arrow right
                  if (item.images.length > 1 && _currentImageIndex < item.images.length - 1)
                    Positioned(
                      right: 8, top: 0, bottom: 0,
                      child: Center(
                        child: GestureDetector(
                          onTap: () => _pageCtrl.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.35), shape: BoxShape.circle),
                            child: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ),
                  // Image count badge
                  if (item.images.length > 1)
                    Positioned(
                      top: 10, right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_currentImageIndex + 1} / ${item.images.length}',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ] else ...[
            Container(
              height: 120,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Icon(
                  item.isMeter ? Icons.straighten_rounded : item.isKilo ? Icons.scale_rounded : Icons.grid_view_rounded,
                  size: 48, color: AppColors.gold.withValues(alpha: 0.5),
                ),
              ),
            ),
          ],

          // Scrollable Details
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + Low Stock badge + Edit button
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.dark),
                        ),
                      ),
                      if (item.isLowStock)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '⚠ Low Stock',
                            style: TextStyle(color: Colors.red, fontSize: 11.5, fontWeight: FontWeight.bold),
                          ),
                        ),
                      const SizedBox(width: 8),
                      // Edit button
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (ctx) => EditMaterialSheet(
                              item: item,
                              notifier: ref.read(materialNotifierProvider.notifier),
                              onUpdated: () {
                                ref.invalidate(materialsProvider);
                                ref.read(toastServiceProvider).success('Material updated!');
                              },
                              onError: () {
                                ref.read(toastServiceProvider).error('Failed to update material');
                              },
                              onValidationError: (msg) {
                                ref.read(toastServiceProvider).warning(msg);
                              },
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                          ),
                          child: const Icon(Icons.edit_rounded, size: 18, color: AppColors.gold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Added ${item.createdAt.split('T').first}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMid),
                  ),
                  const SizedBox(height: 16),

                  // Stock progress
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Stock: ${item.quantity.toStringAsFixed(1)} / ${item.initialQuantity.toStringAsFixed(1)} ${item.unitLabel}',
                                  style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600,
                                    color: item.isLowStock ? Colors.red : AppColors.dark,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: item.isLowStock
                                        ? Colors.red.withValues(alpha: 0.1)
                                        : AppColors.gold.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${item.remainingPercentage.toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      fontSize: 12, fontWeight: FontWeight.bold,
                                      color: item.isLowStock ? Colors.red : AppColors.gold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: item.remainingPercentage / 100,
                                minHeight: 8,
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
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Price info cards
                  Row(
                    children: [
                      Expanded(child: _DetailCard(
                        label: 'Sell Price',
                        value: '${item.sellingPrice.toStringAsFixed(2)} ETB',
                        icon: Icons.sell_rounded,
                        color: Colors.green.shade600,
                      )),
                      const SizedBox(width: 10),
                      if (item.initialPrice != null)
                        Expanded(child: _DetailCard(
                          label: 'Cost Price',
                          value: '${item.initialPrice!.toStringAsFixed(2)} ETB',
                          icon: Icons.shopping_bag_rounded,
                          color: Colors.blue.shade600,
                        )),
                      const SizedBox(width: 10),
                      Expanded(child: _DetailCard(
                        label: 'Total Value',
                        value: '${item.totalValue.toStringAsFixed(2)} ETB',
                        icon: Icons.account_balance_wallet_rounded,
                        color: AppColors.gold,
                      )),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Unit badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              item.isMeter ? Icons.straighten_rounded : item.isKilo ? Icons.scale_rounded : Icons.grid_view_rounded,
                              size: 14, color: AppColors.gold,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              item.isMeter ? 'Meter (m)' : item.isKilo ? 'Kilogram (kg)' : 'Piece (pcs)',
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.gold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Color Variants
                  if (item.colors.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text(
                      'Color Variants',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.dark),
                    ),
                    const SizedBox(height: 10),
                    ...item.colors.map((c) {
                      final cc = _colorForName(c.colorName);
                      final pct = item.quantity > 0 ? (c.quantity / item.quantity * 100).clamp(0.0, 100.0) : 0.0;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: cc.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: cc.withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 28, height: 28,
                              decoration: BoxDecoration(
                                color: cc,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.black.withValues(alpha: 0.12), width: 1.2),
                                boxShadow: [BoxShadow(color: cc.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2))],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        c.colorName,
                                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.dark),
                                      ),
                                      Text(
                                        '${c.quantity.toStringAsFixed(c.quantity == c.quantity.truncateToDouble() ? 0 : 1)} ${item.unitLabel}',
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: cc),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: pct / 100,
                                      minHeight: 4,
                                      backgroundColor: Colors.grey.shade200,
                                      valueColor: AlwaysStoppedAnimation<Color>(cc),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],

                  // Image thumbnails strip (tap to jump)
                  if (item.images.length > 1) ...[
                    const SizedBox(height: 20),
                    const Text(
                      'All Photos',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.dark),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 72,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: item.images.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final selected = i == _currentImageIndex;
                          return GestureDetector(
                            onTap: () {
                              _pageCtrl.animateToPage(i, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 72, height: 72,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: selected ? AppColors.gold : AppColors.border,
                                  width: selected ? 2.5 : 1,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: _FullImage(imageUrl: item.images[i]),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Add Material Sheet
// ═══════════════════════════════════════════════════════════════════════════

class AddMaterialSheet extends StatefulWidget {
  const AddMaterialSheet({
    super.key,
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
  State<AddMaterialSheet> createState() => _AddMaterialSheetState();
}

class _AddMaterialSheetState extends State<AddMaterialSheet> {
  final _nameCtr        = TextEditingController();
  final _costPriceCtr   = TextEditingController();
  final _sellPriceCtr   = TextEditingController();
  final _mainQtyCtr     = TextEditingController();
  final _customColorCtr = TextEditingController();

  String _unit = 'Meter';
  final List<String> _images = []; // Multiple base64 images
  final List<_ColorEntry> _colorEntries = [];

  @override
  void dispose() {
    _nameCtr.dispose();
    _costPriceCtr.dispose();
    _sellPriceCtr.dispose();
    _mainQtyCtr.dispose();
    _customColorCtr.dispose();
    for (final e in _colorEntries) { e.quantityCtr.dispose(); }
    super.dispose();
  }

  String get _unitSuffix => _unit == 'Meter' ? 'm' : _unit == 'Kilogram' ? 'kg' : 'pcs';
  double get _totalQtyFromColors => _colorEntries.fold(0.0, (sum, e) => sum + (double.tryParse(e.quantityCtr.text.trim()) ?? 0));
  double get _manualQty => double.tryParse(_mainQtyCtr.text.trim()) ?? 0;
  double get _finalQty  => _colorEntries.isNotEmpty ? _totalQtyFromColors : _manualQty;
  double get _costPrice => double.tryParse(_costPriceCtr.text.trim()) ?? 0;
  double get _sellPrice => double.tryParse(_sellPriceCtr.text.trim()) ?? 0;

  Future<void> _addImage() async {
    if (_images.length >= 6) {
      widget.onValidationError('Maximum 6 photos allowed');
      return;
    }
    final source = await _showImageSourceDialog();
    if (source == null) return;
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, maxWidth: 800, maxHeight: 800, imageQuality: 75);
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        final b64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        _b64Cache[b64] = bytes;
        setState(() => _images.add(b64));
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add Material Photo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _SourceButton(
                  icon: Icons.camera_alt_rounded,
                  label: 'Camera',
                  onTap: () => Navigator.pop(ctx, ImageSource.camera),
                ),
                _SourceButton(
                  icon: Icons.photo_library_rounded,
                  label: 'Gallery',
                  onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameCtr.text.trim();
    if (name.isEmpty || _finalQty <= 0 || _sellPrice <= 0) {
      widget.onValidationError('Please enter material name, quantity, and selling price');
      return;
    }

    final colorPayload = _colorEntries.map((e) => {
      'colorName': e.colorName,
      'colorHex': '#${e.color.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
      'quantity': double.tryParse(e.quantityCtr.text.trim()) ?? 0.0,
    }).toList();

    Navigator.pop(context);

    try {
      await widget.materialRepo.createMaterial(
        name:         name,
        quantity:     _finalQty,
        unit:         _unit,
        unitPrice:    _sellPrice,
        initialPrice: _costPrice > 0 ? _costPrice : null,
        images:       _images.isNotEmpty ? List.from(_images) : null,
        colors:       colorPayload.isNotEmpty ? colorPayload : null,
      );
      widget.onCreated();
    } catch (_) {
      widget.onError();
    }
  }

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
                        color: picked, shape: BoxShape.circle,
                        border: Border.all(color: Colors.black.withValues(alpha: 0.15)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final n = nameCtr.text.trim();
                if (n.isNotEmpty) {
                  setState(() => _colorEntries.add(_ColorEntry(
                    colorName: n,
                    color: picked,
                    quantityCtr: TextEditingController(text: '0'),
                  )));
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
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),

            const Row(
              children: [
                Icon(Icons.inventory_2_rounded, color: AppColors.gold, size: 24),
                SizedBox(width: 10),
                Text('Add New Material',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: AppColors.dark)),
              ],
            ),
            const SizedBox(height: 18),

            // ── Multi-Image Section ─────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Material Photos',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.dark)),
                Text('${_images.length}/6',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMid)),
              ],
            ),
            const SizedBox(height: 8),

            // Image grid
            if (_images.isNotEmpty) ...[
              SizedBox(
                height: 90,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _images.length + (_images.length < 6 ? 1 : 0),
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    if (i == _images.length) {
                      // Add more button
                      return GestureDetector(
                        onTap: _addImage,
                        child: Container(
                          width: 90, height: 90,
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.gold.withValues(alpha: 0.4), style: BorderStyle.solid),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_rounded, color: AppColors.gold, size: 24),
                              SizedBox(height: 4),
                              Text('Add', style: TextStyle(fontSize: 11, color: AppColors.gold, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      );
                    }
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: 90, height: 90,
                            child: _FullImage(imageUrl: _images[i]),
                          ),
                        ),
                        Positioned(
                          top: 4, right: 4,
                          child: GestureDetector(
                            onTap: () => setState(() => _images.removeAt(i)),
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ] else ...[
              GestureDetector(
                onTap: _addImage,
                child: Container(
                  width: double.infinity,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.gold.withValues(alpha: 0.4), width: 1.5),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_rounded, size: 28, color: AppColors.gold),
                      SizedBox(height: 6),
                      Text('Add Photos (up to 6)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.dark)),
                      Text('Tap to select from Gallery or Camera',
                          style: TextStyle(fontSize: 11, color: AppColors.textMid)),
                    ],
                  ),
                ),
              ),
            ],
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
                ButtonSegment(value: 'Meter',    label: Text('Meter (m)'),   icon: Icon(Icons.straighten_rounded, size: 14)),
                ButtonSegment(value: 'Piece',    label: Text('Piece (pcs)'), icon: Icon(Icons.grid_view_rounded,  size: 14)),
                ButtonSegment(value: 'Kilogram', label: Text('Kilo (kg)'),   icon: Icon(Icons.scale_rounded,      size: 14)),
              ],
              selected: {_unit},
              onSelectionChanged: (s) => setState(() => _unit = s.first),
            ),
            const SizedBox(height: 16),

            // ── Color section ──────────────────────────────────────────────
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

            // Selected color rows with quantity inputs
            if (_colorEntries.isNotEmpty) ...[
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                      child: Row(
                        children: [
                          const Icon(Icons.palette_rounded, size: 15, color: AppColors.textMid),
                          const SizedBox(width: 6),
                          Text(
                            '${_colorEntries.length} color${_colorEntries.length == 1 ? '' : 's'} selected — enter quantity for each',
                            style: const TextStyle(fontSize: 11.5, color: AppColors.textMid, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // Each color row
                    ..._colorEntries.asMap().entries.map((entry) {
                      final i = entry.key;
                      final e = entry.value;
                      final isLast = i == _colorEntries.length - 1;
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Row(
                              children: [
                                // Color circle
                                Container(
                                  width: 36, height: 36,
                                  decoration: BoxDecoration(
                                    color: e.color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.black.withValues(alpha: 0.12),
                                      width: 1.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: e.color.withValues(alpha: 0.3),
                                        blurRadius: 5,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                // Color name
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    e.colorName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13.5,
                                      color: AppColors.dark,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Quantity input
                                Expanded(
                                  flex: 3,
                                  child: TextField(
                                    controller: e.quantityCtr,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    textAlign: TextAlign.center,
                                    onChanged: (_) => setState(() {}),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.dark,
                                    ),
                                    decoration: InputDecoration(
                                      isDense: false,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                      labelText: _unitSuffix,
                                      labelStyle: const TextStyle(fontSize: 12),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(color: e.color.withValues(alpha: 0.5), width: 1.5),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(color: e.color, width: 2),
                                      ),
                                      filled: true,
                                      fillColor: e.color.withValues(alpha: 0.06),
                                      // Stepper buttons
                                      prefixIcon: GestureDetector(
                                        onTap: () {
                                          final v = double.tryParse(e.quantityCtr.text) ?? 0;
                                          if (v > 0) {
                                            e.quantityCtr.text = (v - 1).toStringAsFixed(v % 1 == 0 ? 0 : 1);
                                            setState(() {});
                                          }
                                        },
                                        child: Icon(Icons.remove_rounded, size: 18, color: e.color),
                                      ),
                                      suffixIcon: GestureDetector(
                                        onTap: () {
                                          final v = double.tryParse(e.quantityCtr.text) ?? 0;
                                          e.quantityCtr.text = (v + 1).toStringAsFixed(v % 1 == 0 ? 0 : 1);
                                          setState(() {});
                                        },
                                        child: Icon(Icons.add_rounded, size: 18, color: e.color),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                // Remove button
                                GestureDetector(
                                  onTap: () => setState(() {
                                    e.quantityCtr.dispose();
                                    _colorEntries.remove(e);
                                  }),
                                  child: Container(
                                    width: 32, height: 32,
                                    decoration: BoxDecoration(
                                      color: Colors.red.withValues(alpha: 0.08),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close_rounded, size: 16, color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!isLast) const Divider(height: 1, indent: 12, endIndent: 12),
                        ],
                      );
                    }),
                    // Total row
                    if (_colorEntries.isNotEmpty) ...[
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'Total: ${_totalQtyFromColors.toStringAsFixed(_totalQtyFromColors == _totalQtyFromColors.truncateToDouble() ? 0 : 2)} $_unitSuffix',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.gold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ] else ...[
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

            // ── Add Color Variant ────────────────────────────────────────
            const Text('Add Color Variant',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.dark)),
            const SizedBox(height: 4),
            const Text(
              'Tap a color to select · tap again to deselect',
              style: TextStyle(fontSize: 11, color: AppColors.textLight),
            ),
            const SizedBox(height: 10),

            // Color swatches — single-select per swatch name
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._kSwatches.map((swatch) {
                  final isSelected = _colorEntries.any(
                    (e) => e.colorName.toLowerCase() == swatch.name.toLowerCase(),
                  );
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          // Deselect: remove this color entry
                          final idx = _colorEntries.indexWhere(
                            (e) => e.colorName.toLowerCase() == swatch.name.toLowerCase(),
                          );
                          if (idx != -1) {
                            _colorEntries[idx].quantityCtr.dispose();
                            _colorEntries.removeAt(idx);
                          }
                        } else {
                          // Select: add new entry
                          _colorEntries.add(_ColorEntry(
                            colorName: swatch.name,
                            color: swatch.color,
                            quantityCtr: TextEditingController(text: '0'),
                          ));
                        }
                      });
                    },
                    child: Tooltip(
                      message: swatch.name,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: swatch.color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? AppColors.gold : Colors.black.withValues(alpha: 0.12),
                            width: isSelected ? 3 : 1.2,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: swatch.color.withValues(alpha: 0.5),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                        child: isSelected
                            ? Icon(
                                Icons.check_rounded,
                                size: 18,
                                color: ThemeData.estimateBrightnessForColor(swatch.color) == Brightness.light
                                    ? AppColors.dark
                                    : Colors.white,
                              )
                            : null,
                      ),
                    ),
                  );
                }),
                // Rainbow "custom color" button
                GestureDetector(
                  onTap: _openCustomColorDialog,
                  child: Tooltip(
                    message: 'Pick custom color',
                    child: ClipOval(
                      child: Container(
                        width: 40, height: 40,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SweepGradient(colors: [
                            Color(0xFFE53935), Color(0xFFFFD600),
                            Color(0xFF43A047), Color(0xFF1E88E5),
                            Color(0xFF9C27B0), Color(0xFFE53935),
                          ]),
                        ),
                        child: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Selected colors label strip (shows selected colors at a glance)
            if (_colorEntries.isNotEmpty) ...[
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _colorEntries.map((e) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: e.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: e.color.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10, height: 10,
                        decoration: BoxDecoration(
                          color: e.color,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(e.colorName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.dark)),
                    ],
                  ),
                )).toList(),
              ),
              const SizedBox(height: 12),
            ],


            // Prices
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

            // Summary box
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

            // Save button
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

// ═══════════════════════════════════════════════════════════════════════════
// Edit Material Sheet
// ═══════════════════════════════════════════════════════════════════════════

class EditMaterialSheet extends StatefulWidget {
  const EditMaterialSheet({
    super.key,
    required this.item,
    required this.onUpdated,
    required this.onError,
    required this.onValidationError,
    required this.notifier,
  });

  final MaterialItem item;
  final VoidCallback onUpdated;
  final VoidCallback onError;
  final ValueChanged<String> onValidationError;
  final MaterialNotifier notifier;

  @override
  State<EditMaterialSheet> createState() => _EditMaterialSheetState();
}

class _EditMaterialSheetState extends State<EditMaterialSheet> {
  late final TextEditingController _nameCtr;
  late final TextEditingController _costPriceCtr;
  late final TextEditingController _sellPriceCtr;
  late final TextEditingController _customColorCtr;
  late String _unit;
  late List<String> _images;
  late List<_ColorEntry> _colorEntries;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameCtr      = TextEditingController(text: item.name);
    _costPriceCtr = TextEditingController(text: item.initialPrice != null ? item.initialPrice!.toStringAsFixed(2) : '');
    _sellPriceCtr = TextEditingController(text: item.unitPrice.toStringAsFixed(2));
    _customColorCtr = TextEditingController();
    _unit   = item.unit;
    _images = List<String>.from(item.images);
    _colorEntries = item.colors.map((c) => _ColorEntry(
      colorName: c.colorName,
      color: _colorForName(c.colorName),
      quantityCtr: TextEditingController(text: c.quantity.toStringAsFixed(c.quantity == c.quantity.truncateToDouble() ? 0 : 1)),
    )).toList();
  }

  @override
  void dispose() {
    _nameCtr.dispose();
    _costPriceCtr.dispose();
    _sellPriceCtr.dispose();
    _customColorCtr.dispose();
    for (final e in _colorEntries) { e.quantityCtr.dispose(); }
    super.dispose();
  }

  String get _unitSuffix => _unit == 'Meter' ? 'm' : _unit == 'Kilogram' ? 'kg' : 'pcs';
  double get _totalQtyFromColors => _colorEntries.fold(0.0, (sum, e) => sum + (double.tryParse(e.quantityCtr.text.trim()) ?? 0));
  double get _costPrice => double.tryParse(_costPriceCtr.text.trim()) ?? 0;
  double get _sellPrice => double.tryParse(_sellPriceCtr.text.trim()) ?? 0;

  Future<void> _addImage() async {
    if (_images.length >= 6) {
      widget.onValidationError('Maximum 6 photos allowed');
      return;
    }
    final source = await _showImageSourceDialog();
    if (source == null) return;
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, maxWidth: 800, maxHeight: 800, imageQuality: 75);
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        final b64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        _b64Cache[b64] = bytes;
        setState(() => _images.add(b64));
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add Photo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _SourceButton(icon: Icons.camera_alt_rounded, label: 'Camera',  onTap: () => Navigator.pop(ctx, ImageSource.camera)),
                _SourceButton(icon: Icons.photo_library_rounded, label: 'Gallery', onTap: () => Navigator.pop(ctx, ImageSource.gallery)),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

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
                  decoration: const InputDecoration(labelText: 'Color Name', hintText: 'e.g. Burgundy, Mustard'),
                ),
                const SizedBox(height: 16),
                const Text('Pick a color:', style: TextStyle(fontSize: 12, color: AppColors.textMid)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: _kSwatches.map((s) {
                    final sel = picked == s.color;
                    return GestureDetector(
                      onTap: () => setDlg(() => picked = s.color),
                      child: Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: s.color, shape: BoxShape.circle,
                          border: Border.all(
                            color: sel ? AppColors.gold : Colors.black.withValues(alpha: 0.1),
                            width: sel ? 2.5 : 1,
                          ),
                        ),
                        child: sel ? Icon(Icons.check_rounded, size: 14,
                          color: ThemeData.estimateBrightnessForColor(s.color) == Brightness.light ? AppColors.dark : Colors.white) : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final n = nameCtr.text.trim();
                if (n.isNotEmpty) {
                  setState(() => _colorEntries.add(_ColorEntry(
                    colorName: n, color: picked,
                    quantityCtr: TextEditingController(text: '0'),
                  )));
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

  Future<void> _save() async {
    final name = _nameCtr.text.trim();
    if (name.isEmpty || _sellPrice <= 0) {
      widget.onValidationError('Please enter material name and selling price');
      return;
    }
    setState(() => _saving = true);

    final colorPayload = _colorEntries.map((e) => {
      'colorName': e.colorName,
      'colorHex': '#${e.color.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
      'quantity': double.tryParse(e.quantityCtr.text.trim()) ?? 0.0,
    }).toList();

    Navigator.pop(context);

    try {
      await widget.notifier.update(
        id:           widget.item.id,
        name:         name,
        unit:         _unit,
        unitPrice:    _sellPrice,
        initialPrice: _costPrice > 0 ? _costPrice : null,
        images:       _images,
        colors:       colorPayload.isNotEmpty ? colorPayload : [],
      );
      widget.onUpdated();
    } catch (_) {
      widget.onError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalCost  = widget.item.quantity * _costPrice;
    final totalSales = widget.item.quantity * _sellPrice;
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
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                const Icon(Icons.edit_rounded, color: AppColors.gold, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Edit "${widget.item.name}"',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.dark),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline_rounded, size: 13, color: Colors.amber.shade700),
                  const SizedBox(width: 5),
                  Text(
                    'Quantity is managed by sales/restocking — edit prices & details here',
                    style: TextStyle(fontSize: 11, color: Colors.amber.shade800),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ── Images ──────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Photos', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.dark)),
                Text('${_images.length}/6', style: const TextStyle(fontSize: 12, color: AppColors.textMid)),
              ],
            ),
            const SizedBox(height: 8),
            if (_images.isNotEmpty) ...[
              SizedBox(
                height: 90,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _images.length + (_images.length < 6 ? 1 : 0),
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    if (i == _images.length) {
                      return GestureDetector(
                        onTap: _addImage,
                        child: Container(
                          width: 90, height: 90,
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_rounded, color: AppColors.gold, size: 24),
                              SizedBox(height: 4),
                              Text('Add', style: TextStyle(fontSize: 11, color: AppColors.gold, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      );
                    }
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(width: 90, height: 90, child: _FullImage(imageUrl: _images[i])),
                        ),
                        Positioned(
                          top: 4, right: 4,
                          child: GestureDetector(
                            onTap: () => setState(() => _images.removeAt(i)),
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), shape: BoxShape.circle),
                              child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ] else ...[
              GestureDetector(
                onTap: _addImage,
                child: Container(
                  width: double.infinity, height: 90,
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.gold.withValues(alpha: 0.4), width: 1.5),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_rounded, size: 28, color: AppColors.gold),
                      SizedBox(height: 6),
                      Text('Add Photos (up to 6)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.dark)),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),

            // ── Name ────────────────────────────────────────────────────
            TextField(
              controller: _nameCtr,
              decoration: const InputDecoration(
                labelText: 'Material Name',
                prefixIcon: Icon(Icons.label_outline_rounded),
              ),
            ),
            const SizedBox(height: 14),

            // ── Unit selector ────────────────────────────────────────────
            const Text('Measurement Unit',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textMid)),
            const SizedBox(height: 6),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Meter',    label: Text('Meter (m)'),   icon: Icon(Icons.straighten_rounded, size: 14)),
                ButtonSegment(value: 'Piece',    label: Text('Piece (pcs)'), icon: Icon(Icons.grid_view_rounded,  size: 14)),
                ButtonSegment(value: 'Kilogram', label: Text('Kilo (kg)'),   icon: Icon(Icons.scale_rounded,      size: 14)),
              ],
              selected: {_unit},
              onSelectionChanged: (s) => setState(() => _unit = s.first),
            ),
            const SizedBox(height: 16),

            // ── Color variants ───────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Color Variants ($_unitSuffix)',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.dark)),
                Text('Total: ${_totalQtyFromColors.toStringAsFixed(2)} $_unitSuffix',
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.gold)),
              ],
            ),
            const SizedBox(height: 8),

            if (_colorEntries.isNotEmpty) ...[
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                      child: Row(
                        children: [
                          const Icon(Icons.palette_rounded, size: 15, color: AppColors.textMid),
                          const SizedBox(width: 6),
                          Text(
                            '${_colorEntries.length} color${_colorEntries.length == 1 ? '' : 's'} — adjust quantities',
                            style: const TextStyle(fontSize: 11.5, color: AppColors.textMid, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    ..._colorEntries.asMap().entries.map((entry) {
                      final i = entry.key;
                      final e = entry.value;
                      final isLast = i == _colorEntries.length - 1;
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Row(
                              children: [
                                Container(
                                  width: 36, height: 36,
                                  decoration: BoxDecoration(
                                    color: e.color, shape: BoxShape.circle,
                                    border: Border.all(color: Colors.black.withValues(alpha: 0.12), width: 1.2),
                                    boxShadow: [BoxShadow(color: e.color.withValues(alpha: 0.3), blurRadius: 5, offset: const Offset(0, 2))],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 2,
                                  child: Text(e.colorName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.dark)),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 3,
                                  child: TextField(
                                    controller: e.quantityCtr,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    textAlign: TextAlign.center,
                                    onChanged: (_) => setState(() {}),
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.dark),
                                    decoration: InputDecoration(
                                      isDense: false,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                      labelText: _unitSuffix,
                                      labelStyle: const TextStyle(fontSize: 12),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(color: e.color.withValues(alpha: 0.5), width: 1.5),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(color: e.color, width: 2),
                                      ),
                                      filled: true,
                                      fillColor: e.color.withValues(alpha: 0.06),
                                      prefixIcon: GestureDetector(
                                        onTap: () {
                                          final v = double.tryParse(e.quantityCtr.text) ?? 0;
                                          if (v > 0) { e.quantityCtr.text = (v - 1).toStringAsFixed(0); setState(() {}); }
                                        },
                                        child: Icon(Icons.remove_rounded, size: 18, color: e.color),
                                      ),
                                      suffixIcon: GestureDetector(
                                        onTap: () {
                                          final v = double.tryParse(e.quantityCtr.text) ?? 0;
                                          e.quantityCtr.text = (v + 1).toStringAsFixed(0);
                                          setState(() {});
                                        },
                                        child: Icon(Icons.add_rounded, size: 18, color: e.color),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: () => setState(() {
                                    e.quantityCtr.dispose();
                                    _colorEntries.remove(e);
                                  }),
                                  child: Container(
                                    width: 32, height: 32,
                                    decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.08), shape: BoxShape.circle),
                                    child: const Icon(Icons.close_rounded, size: 16, color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!isLast) const Divider(height: 1, indent: 12, endIndent: 12),
                        ],
                      );
                    }),
                    if (_colorEntries.isNotEmpty) ...[
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'Total: ${_totalQtyFromColors.toStringAsFixed(_totalQtyFromColors == _totalQtyFromColors.truncateToDouble() ? 0 : 2)} $_unitSuffix',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.gold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],

            // ── Add Color swatch ─────────────────────────────────────────
            const Text('Add / Remove Color Variants',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.dark)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: [
                ..._kSwatches.map((swatch) {
                  final isSelected = _colorEntries.any(
                    (e) => e.colorName.toLowerCase() == swatch.name.toLowerCase(),
                  );
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          final idx = _colorEntries.indexWhere(
                            (e) => e.colorName.toLowerCase() == swatch.name.toLowerCase(),
                          );
                          if (idx != -1) { _colorEntries[idx].quantityCtr.dispose(); _colorEntries.removeAt(idx); }
                        } else {
                          _colorEntries.add(_ColorEntry(
                            colorName: swatch.name, color: swatch.color,
                            quantityCtr: TextEditingController(text: '0'),
                          ));
                        }
                      });
                    },
                    child: Tooltip(
                      message: swatch.name,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: swatch.color, shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? AppColors.gold : Colors.black.withValues(alpha: 0.12),
                            width: isSelected ? 3 : 1.2,
                          ),
                          boxShadow: isSelected
                              ? [BoxShadow(color: swatch.color.withValues(alpha: 0.5), blurRadius: 6, spreadRadius: 1)]
                              : null,
                        ),
                        child: isSelected
                            ? Icon(Icons.check_rounded, size: 18,
                                color: ThemeData.estimateBrightnessForColor(swatch.color) == Brightness.light
                                    ? AppColors.dark : Colors.white)
                            : null,
                      ),
                    ),
                  );
                }),
                GestureDetector(
                  onTap: _openCustomColorDialog,
                  child: Tooltip(
                    message: 'Custom color',
                    child: ClipOval(
                      child: Container(
                        width: 40, height: 40,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SweepGradient(colors: [
                            Color(0xFFE53935), Color(0xFFFFD600),
                            Color(0xFF43A047), Color(0xFF1E88E5),
                            Color(0xFF9C27B0), Color(0xFFE53935),
                          ]),
                        ),
                        child: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Prices ───────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _costPriceCtr,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Cost Price', hintText: 'Purchase price', prefixText: 'ETB ',
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
                      labelText: 'Sell Price *', hintText: 'Selling price', prefixText: 'ETB ',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Summary
            if (widget.item.quantity > 0 && (_costPrice > 0 || _sellPrice > 0))
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    _SummaryRow('Current Stock:', '${widget.item.quantity.toStringAsFixed(2)} ${widget.item.unitLabel}'),
                    const SizedBox(height: 4),
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

            // Save button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.dark,
                  foregroundColor: AppColors.cream,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.save_rounded, size: 20),
                label: Text(_saving ? 'Saving...' : 'Save Changes',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helper Widgets ──────────────────────────────────────────────────────────

class _ImageThumb extends StatelessWidget {
  const _ImageThumb({required this.imageUrl, required this.icon, required this.iconColor});
  final String? imageUrl;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return Icon(icon, color: iconColor, size: 24);
    }
    return AppImageDisplay(imageUrl: imageUrl, fit: BoxFit.cover, placeholderIcon: icon, iconColor: iconColor);
  }
}

class _FullImage extends StatelessWidget {
  const _FullImage({required this.imageUrl});
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.startsWith('data:image') || (!imageUrl.startsWith('http://') && !imageUrl.startsWith('https://'))) {
      final bytes = _decodeB64(imageUrl);
      if (bytes != null) {
        return Image.memory(bytes, fit: BoxFit.cover, width: double.infinity, height: double.infinity, gaplessPlayback: true);
      }
      return const ColoredBox(color: Color(0xFFF5EDE0), child: Center(child: Icon(Icons.broken_image_rounded, color: AppColors.gold)));
    }
    return Image.network(imageUrl, fit: BoxFit.cover, width: double.infinity, height: double.infinity, gaplessPlayback: true);
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.label, required this.value, required this.icon, required this.color});
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10.5, color: color.withValues(alpha: 0.8))),
          Text(value, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class _SourceButton extends StatelessWidget {
  const _SourceButton({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.gold.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: AppColors.gold),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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
        Text(value, style: TextStyle(fontSize: 12, fontWeight: bold ? FontWeight.bold : FontWeight.w600)),
      ],
    );
  }
}
