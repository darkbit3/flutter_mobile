class SaleItemModel {
  const SaleItemModel({
    required this.id,
    required this.saleId,
    required this.material,
    required this.quantity,
    required this.unitPrice,
    required this.total,
  });

  final String id;
  final String saleId;
  final String material;
  final double quantity;
  final double unitPrice;
  final double total;

  factory SaleItemModel.fromJson(Map<String, dynamic> j) => SaleItemModel(
        id:        j['id'] as String? ?? '',
        saleId:    j['sale_id'] as String? ?? '',
        material:  j['material'] as String? ?? '',
        quantity:  (j['quantity'] as num?)?.toDouble() ?? 0.0,
        unitPrice: (j['unit_price'] as num?)?.toDouble() ?? 0.0,
        total:     (j['total'] as num?)?.toDouble() ?? 0.0,
      );
}

class SaleModel {
  const SaleModel({
    required this.id,
    required this.cashierId,
    required this.ownerId,
    required this.paymentType,
    required this.totalAmount,
    required this.items,
    required this.createdAt,
    this.customer,
    this.cashierName,
    this.note,
  });

  final String          id;
  final String          cashierId;
  final String          ownerId;
  final String          paymentType;
  final double          totalAmount;
  final List<SaleItemModel> items;
  final String          createdAt;
  final String?         customer;
  final String?         cashierName;
  final String?         note;

  bool get isCash   => paymentType == 'Cash';
  bool get isCredit => paymentType == 'Credit';

  factory SaleModel.fromJson(Map<String, dynamic> j) => SaleModel(
        id:          j['id'] as String? ?? '',
        cashierId:   j['cashier_id'] as String? ?? '',
        ownerId:     j['owner_id'] as String? ?? '',
        paymentType: j['payment_type'] as String? ?? 'Cash',
        totalAmount: (j['total_amount'] as num?)?.toDouble() ?? 0.0,
        createdAt:   j['created_at'] as String? ?? '',
        customer:    j['customer'] as String?,
        cashierName: j['cashier_name'] as String?,
        note:        j['note'] as String?,
        items: (j['items'] as List<dynamic>? ?? [])
            .map((i) => SaleItemModel.fromJson(i as Map<String, dynamic>))
            .toList(),
      );
}

class SaleStats {
  const SaleStats({
    required this.totalSales,
    required this.totalRevenue,
    required this.totalCredit,
    required this.totalCash,
  });
  final int    totalSales;
  final double totalRevenue;
  final double totalCredit;
  final double totalCash;

  factory SaleStats.fromJson(Map<String, dynamic> j) => SaleStats(
        totalSales:   (j['total_sales'] as num?)?.toInt() ?? 0,
        totalRevenue: (j['total_revenue'] as num?)?.toDouble() ?? 0.0,
        totalCredit:  (j['total_credit'] as num?)?.toDouble() ?? 0.0,
        totalCash:    (j['total_cash'] as num?)?.toDouble() ?? 0.0,
      );

  factory SaleStats.empty() =>
      const SaleStats(totalSales: 0, totalRevenue: 0, totalCredit: 0, totalCash: 0);
}
