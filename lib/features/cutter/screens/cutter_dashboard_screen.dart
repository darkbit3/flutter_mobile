import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_image_picker.dart';
import '../../auth/providers/auth_provider.dart';
import '../../stock/models/material_model.dart';
import '../../stock/providers/material_provider.dart';

const _kPurple = Color(0xFF8B5CF6);
const _kPurpleBg = Color(0xFFF3F0FF);

class CutterDashboardScreen extends ConsumerStatefulWidget {
  const CutterDashboardScreen({super.key});

  @override
  ConsumerState<CutterDashboardScreen> createState() =>
      _CutterDashboardScreenState();
}

class _CutterDashboardScreenState
    extends ConsumerState<CutterDashboardScreen> {
  final _searchCtr = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All'; // 'All' | 'Meter' | 'Piece' | 'Kilogram'

  @override
  void dispose() {
    _searchCtr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final materialsAsync = ref.watch(materialsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(materialsProvider);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── 1. Top Header Banner ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: _CutterHeader(user: user),
            ),

            // ── 2. Materials Async Content ───────────────────────────────────
            materialsAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: _kPurple),
                ),
              ),
              error: (err, stack) => SliverFillRemaining(
                child: _CutterErrorView(
                  error: err.toString(),
                  onRetry: () => ref.invalidate(materialsProvider),
                ),
              ),
              data: (materials) {
                final user = ref.watch(authProvider).user;
                final threshold = user?.alertThresholdPercentage ?? 20.0;
                
                final filtered = materials.where((m) {
                  final matchesSearch = m.name
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase());
                  final matchesFilter = _selectedFilter == 'All' ||
                      m.unit.toLowerCase() == _selectedFilter.toLowerCase() ||
                      (_selectedFilter == 'Kilogram' &&
                          (m.unit == 'Kilo' || m.unit == 'kg'));
                  return matchesSearch && matchesFilter;
                }).toList();

                final lowStockCount = materials.where((m) => m.isLowStockWithThreshold(threshold)).length;
                final totalQty = materials.fold<double>(
                    0, (sum, m) => sum + m.quantity);

                return SliverMainAxisGroup(
                  slivers: [
                    // ── Stat Summary Cards ───────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                title: 'Total Stock Items',
                                value: '${materials.length}',
                                icon: Icons.inventory_2_rounded,
                                color: _kPurple,
                                bg: _kPurpleBg,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                title: 'Low Stock Alerts',
                                value: '$lowStockCount',
                                icon: Icons.warning_amber_rounded,
                                color: lowStockCount > 0
                                    ? Colors.orange.shade700
                                    : Colors.green.shade700,
                                bg: lowStockCount > 0
                                    ? Colors.orange.shade50
                                    : Colors.green.shade50,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                title: 'Total Qty',
                                value: totalQty.toStringAsFixed(0),
                                icon: Icons.straighten_rounded,
                                color: Colors.blue.shade700,
                                bg: Colors.blue.shade50,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Cutting Calculator Quick Bar ─────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: _CuttingCalculatorBanner(materials: materials),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 16)),

                    // ── Search & Filter Controls ─────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          children: [
                            TextField(
                              controller: _searchCtr,
                              onChanged: (val) {
                                setState(() {
                                  _searchQuery = val.trim();
                                });
                              },
                              decoration: InputDecoration(
                                hintText: 'Search materials by name...',
                                prefixIcon: const Icon(Icons.search_rounded,
                                    color: _kPurple),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear_rounded),
                                        onPressed: () {
                                          _searchCtr.clear();
                                          setState(() {
                                            _searchQuery = '';
                                          });
                                        },
                                      )
                                    : null,
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: Colors.grey.shade200),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      const BorderSide(color: _kPurple, width: 1.5),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Filter Chips
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: ['All', 'Meter', 'Piece', 'Kilogram']
                                    .map((filter) {
                                  final isSel = _selectedFilter == filter;
                                  return Padding(
                                    padding:
                                        const EdgeInsets.only(right: 8.0),
                                    child: ChoiceChip(
                                      label: Text(filter),
                                      selected: isSel,
                                      selectedColor: _kPurple,
                                      backgroundColor: Colors.white,
                                      labelStyle: TextStyle(
                                        color: isSel
                                            ? Colors.white
                                            : AppColors.textMid,
                                        fontWeight: isSel
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        fontSize: 13,
                                      ),
                                      side: BorderSide(
                                        color: isSel
                                            ? _kPurple
                                            : Colors.grey.shade300,
                                      ),
                                      onSelected: (selected) {
                                        if (selected) {
                                          setState(() {
                                            _selectedFilter = filter;
                                          });
                                        }
                                      },
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 12)),

                    // ── Materials List ───────────────────────────────────────
                    if (filtered.isEmpty)
                      SliverToBoxAdapter(
                        child: Container(
                          margin: const EdgeInsets.all(32),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.content_cut_rounded,
                                  size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              Text(
                                _searchQuery.isEmpty
                                    ? 'No Materials Available'
                                    : 'No matching materials found',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppColors.dark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _searchQuery.isEmpty
                                    ? 'No stock has been added by your manufacturer yet.'
                                    : 'Try adjusting your search or filter options.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final mat = filtered[index];
                              return _CutterMaterialCard(material: mat);
                            },
                            childCount: filtered.length,
                          ),
                        ),
                      ),

                    const SliverToBoxAdapter(child: SizedBox(height: 80)),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header Banner ─────────────────────────────────────────────────────────────
class _CutterHeader extends StatelessWidget {
  const _CutterHeader({required this.user});
  final dynamic user;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const CircleAvatar(
                    radius: 22,
                    backgroundColor: _kPurpleBg,
                    child: Icon(Icons.content_cut_rounded,
                        color: _kPurple, size: 24),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, ${user?.name ?? 'Cutter'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Cutter Workstation • ${user?.phone ?? ''}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_rounded,
                          size: 14, color: Colors.greenAccent),
                      SizedBox(width: 4),
                      Text(
                        'Active',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stat Card ─────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.bg,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Cutting Calculator Quick Banner ──────────────────────────────────────────
class _CuttingCalculatorBanner extends StatelessWidget {
  const _CuttingCalculatorBanner({required this.materials});
  final List<MaterialItem> materials;

  void _openCalculator(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CuttingCalculatorSheet(materials: materials),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_kPurpleBg, Colors.purple.shade50],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kPurple.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _kPurple,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.calculate_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cutting Calculator',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.dark,
                  ),
                ),
                Text(
                  'Quickly calculate piece cuts & remaining roll stock',
                  style: TextStyle(fontSize: 11, color: AppColors.textMid),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _openCalculator(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPurple,
              foregroundColor: Colors.white,
              elevation: 0,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Open Tool', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

// ── Interactive Cutting Calculator Sheet ──────────────────────────────────────
class _CuttingCalculatorSheet extends StatefulWidget {
  const _CuttingCalculatorSheet({required this.materials});
  final List<MaterialItem> materials;

  @override
  State<_CuttingCalculatorSheet> createState() =>
      _CuttingCalculatorSheetState();
}

class _CuttingCalculatorSheetState extends State<_CuttingCalculatorSheet> {
  MaterialItem? _selectedMaterial;
  final _stockCtr = TextEditingController();
  final _cutSizeCtr = TextEditingController();

  double _totalPieces = 0;
  double _remainingWaste = 0;

  void _calculate() {
    final stock = double.tryParse(_stockCtr.text) ?? 0;
    final cutSize = double.tryParse(_cutSizeCtr.text) ?? 0;

    if (stock <= 0 || cutSize <= 0) {
      setState(() {
        _totalPieces = 0;
        _remainingWaste = 0;
      });
      return;
    }

    final pieces = (stock / cutSize).floorToDouble();
    final remaining = stock - (pieces * cutSize);

    setState(() {
      _totalPieces = pieces;
      _remainingWaste = remaining;
    });
  }

  @override
  void dispose() {
    _stockCtr.dispose();
    _cutSizeCtr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                Icon(Icons.calculate_rounded, color: _kPurple, size: 24),
                SizedBox(width: 10),
                Text(
                  'Cut & Piece Calculator',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.dark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Material Dropdown
            DropdownButtonFormField<MaterialItem>(
              initialValue: _selectedMaterial,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Select Material (Optional)',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              items: widget.materials.map((m) {
                return DropdownMenuItem(
                  value: m,
                  child: Text('${m.name} (${m.quantity} ${m.unitLabel})'),
                );
              }).toList(),
              onChanged: (mat) {
                setState(() {
                  _selectedMaterial = mat;
                  if (mat != null) {
                    _stockCtr.text = mat.quantity.toStringAsFixed(1);
                    _calculate();
                  }
                });
              },
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _stockCtr,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => _calculate(),
                    decoration: InputDecoration(
                      labelText: 'Total Stock Length',
                      hintText: 'e.g. 100',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _cutSizeCtr,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => _calculate(),
                    decoration: InputDecoration(
                      labelText: 'Piece Cut Size',
                      hintText: 'e.g. 2.5',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Result Display Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _kPurpleBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _kPurple.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Cut Pieces Yield:',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${_totalPieces.toInt()} pcs',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _kPurple,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Remaining Offcut / Waste:',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${_remainingWaste.toStringAsFixed(2)} ${_selectedMaterial?.unitLabel ?? "units"}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Close Calculator',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Cutter Material Card ──────────────────────────────────────────────────────
class _CutterMaterialCard extends StatelessWidget {
  const _CutterMaterialCard({required this.material});
  final MaterialItem material;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: material.isLowStock
              ? Colors.orange.shade300
              : Colors.grey.shade200,
          width: material.isLowStock ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail Image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 56,
                height: 56,
                child: AppImageDisplay(
                  imageUrl: material.imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          material.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.dark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (material.isLowStock)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.orange.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber_rounded,
                                  size: 12, color: Colors.orange.shade800),
                              const SizedBox(width: 3),
                              Text(
                                'LOW STOCK',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade900,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  Row(
                    children: [
                      Text(
                        'Available: ',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        '${material.quantity} ${material.unitLabel}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _kPurple,
                        ),
                      ),
                    ],
                  ),

                  // Color Variants
                  if (material.colors.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: material.colors.map((c) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: _kPurpleBg,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: _kPurple.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            '${c.colorName}: ${c.quantity} ${material.unitLabel}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _kPurple,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
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

// ── Error View ────────────────────────────────────────────────────────────────
class _CutterErrorView extends StatelessWidget {
  const _CutterErrorView({required this.error, required this.onRetry});
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            const Text(
              'Failed to load materials',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              error,
              style: const TextStyle(fontSize: 12, color: AppColors.textMid),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPurple,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
