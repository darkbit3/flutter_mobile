class CreditPayment {
  const CreditPayment({
    required this.id,
    required this.creditId,
    required this.amount,
    required this.paidAt,
    this.note,
  });

  final String  id;
  final String  creditId;
  final double  amount;
  final String  paidAt;
  final String? note;

  factory CreditPayment.fromJson(Map<String, dynamic> j) => CreditPayment(
        id:       j['id']        as String? ?? '',
        creditId: j['credit_id'] as String? ?? '',
        amount:   (j['amount']   as num?)?.toDouble() ?? 0.0,
        paidAt:   j['paid_at']   as String? ?? '',
        note:     j['note']      as String?,
      );
}

class CreditRecord {
  const CreditRecord({
    required this.id,
    required this.saleId,
    required this.cashierId,
    required this.ownerId,
    required this.customer,
    required this.totalAmount,
    required this.totalPaid,
    required this.createdAt,
    required this.payments,
    this.cashierName,
    this.note,
  });

  final String  id;
  final String  saleId;
  final String  cashierId;
  final String  ownerId;
  final String  customer;
  final double  totalAmount;
  final double  totalPaid;
  final String  createdAt;
  final List<CreditPayment> payments;
  final String? cashierName;
  final String? note;

  double get remaining    => (totalAmount - totalPaid).clamp(0.0, double.infinity);
  bool   get isFullyPaid  => remaining <= 0.01;
  double get paidPercent  => totalAmount > 0 ? (totalPaid / totalAmount).clamp(0.0, 1.0) : 0.0;

  factory CreditRecord.fromJson(Map<String, dynamic> j) => CreditRecord(
        id:           j['id']           as String? ?? '',
        saleId:       j['sale_id']      as String? ?? '',
        cashierId:    j['cashier_id']   as String? ?? '',
        ownerId:      j['owner_id']     as String? ?? '',
        customer:     j['customer']     as String? ?? 'Unknown',
        totalAmount:  (j['total_amount'] as num?)?.toDouble() ?? 0.0,
        totalPaid:    (j['total_paid']   as num?)?.toDouble() ?? 0.0,
        createdAt:    j['created_at']   as String? ?? '',
        cashierName:  j['cashier_name'] as String?,
        note:         j['note']         as String?,
        payments: (j['payments'] as List<dynamic>? ?? [])
            .map((p) => CreditPayment.fromJson(p as Map<String, dynamic>))
            .toList(),
      );
}

class CreditStats {
  const CreditStats({
    required this.totalCredits,
    required this.totalAmount,
    required this.totalPaid,
    required this.totalRemaining,
  });

  final int    totalCredits;
  final double totalAmount;
  final double totalPaid;
  final double totalRemaining;

  factory CreditStats.fromJson(Map<String, dynamic> j) => CreditStats(
        totalCredits:   (j['total_credits']   as num?)?.toInt()    ?? 0,
        totalAmount:    (j['total_amount']     as num?)?.toDouble() ?? 0.0,
        totalPaid:      (j['total_paid']       as num?)?.toDouble() ?? 0.0,
        totalRemaining: (j['total_remaining']  as num?)?.toDouble() ?? 0.0,
      );
}
