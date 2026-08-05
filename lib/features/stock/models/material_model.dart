class MaterialColorVariant {
  const MaterialColorVariant({
    required this.colorName,
    required this.quantity,
  });

  final String colorName;
  final double quantity;

  Map<String, dynamic> toJson() => {
        'colorName': colorName,
        'quantity': quantity,
      };

  factory MaterialColorVariant.fromJson(Map<String, dynamic> json) {
    return MaterialColorVariant(
      colorName: (json['colorName'] ?? json['color'] ?? 'Default') as String,
      quantity: (json['quantity'] as num? ?? 0).toDouble(),
    );
  }
}

class MaterialItem {
  const MaterialItem({
    required this.id,
    required this.userId,
    required this.name,
    required this.quantity,
    required this.initialQuantity,
    required this.unit,
    required this.unitPrice,
    this.initialPrice,
    this.imageUrl,
    this.colors = const [],
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String name;
  final double quantity;
  final double initialQuantity;
  final String unit; // 'Meter' | 'Piece' | 'Kilogram'
  final double unitPrice; // Selling Price per unit
  final double? initialPrice; // Purchase / Cost Price per unit
  final String? imageUrl;
  final List<MaterialColorVariant> colors;
  final String createdAt;

  double get sellingPrice => unitPrice;
  double get costPrice => initialPrice ?? unitPrice;
  double get totalValue => quantity * sellingPrice;
  double get totalCostValue => quantity * costPrice;
  double get profitMargin => sellingPrice - costPrice;

  bool get isMeter => unit == 'Meter';
  bool get isPiece => unit == 'Piece';
  bool get isKilo => unit == 'Kilogram' || unit == 'Kilo' || unit == 'kg';

  String get unitLabel {
    if (isMeter) return 'm';
    if (isKilo) return 'kg';
    return 'pcs';
  }

  bool get isLowStock =>
      initialQuantity > 0
          ? (quantity / initialQuantity) <= 0.20
          : quantity <= 5;

  double get remainingPercentage =>
      initialQuantity > 0
          ? ((quantity / initialQuantity) * 100).clamp(0.0, 100.0)
          : 100.0;

  factory MaterialItem.fromJson(Map<String, dynamic> json) {
    final qty = (json['quantity'] as num).toDouble();
    final initQty = json['initial_quantity'] != null
        ? (json['initial_quantity'] as num).toDouble()
        : qty;

    List<MaterialColorVariant> parsedColors = [];
    if (json['colors'] != null && json['colors'] is List) {
      parsedColors = (json['colors'] as List)
          .map((c) => MaterialColorVariant.fromJson(c as Map<String, dynamic>))
          .toList();
    }

    return MaterialItem(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      quantity: qty,
      initialQuantity: initQty > 0 ? initQty : qty,
      unit: json['unit'] as String,
      unitPrice: (json['unit_price'] as num).toDouble(),
      initialPrice: json['initial_price'] != null
          ? (json['initial_price'] as num).toDouble()
          : null,
      imageUrl: json['image_url'] as String?,
      colors: parsedColors,
      createdAt: json['created_at'] as String,
    );
  }
}

class MaterialHistoryLog {
  const MaterialHistoryLog({
    required this.id,
    required this.materialName,
    required this.action, // 'Restocked' | 'Added' | 'Deducted'
    required this.quantity,
    required this.unitLabel,
    required this.note,
    required this.dateStr,
  });

  final String id;
  final String materialName;
  final String action;
  final double quantity;
  final String unitLabel;
  final String note;
  final String dateStr;
}
