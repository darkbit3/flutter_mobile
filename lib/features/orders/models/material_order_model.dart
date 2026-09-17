class MaterialOrder {
  const MaterialOrder({
    required this.id,
    required this.materialName,
    required this.quantity,
    required this.status,
    required this.createdAt,
    this.materialId,
    this.requesterName,
    this.note,
  });

  final String id;
  final String? materialId;
  final String materialName;
  final double quantity;
  final String status;
  final String createdAt;
  final String? requesterName;
  final String? note;

  factory MaterialOrder.fromJson(Map<String, dynamic> json) => MaterialOrder(
        id: json['id']?.toString() ?? '',
        materialId: json['material_id']?.toString(),
        materialName: json['material_name']?.toString() ?? 'Material',
        quantity: _number(json['quantity']),
        status: json['status']?.toString() ?? 'Pending',
        createdAt: json['created_at']?.toString() ?? '',
        requesterName: json['requester_name']?.toString(),
        note: json['note']?.toString(),
      );

  static double _number(dynamic value) => value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '') ?? 0;
}
