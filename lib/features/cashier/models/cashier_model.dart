class CashierModel {
  const CashierModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.status,
    this.plainPassword,
    this.createdAt,
  });

  final String  id;
  final String  name;
  final String  phone;
  final String  status;         // 'Active' | 'Inactive'
  final String? plainPassword;
  final String? createdAt;      // ISO date string

  bool get isActive => status == 'Active';

  factory CashierModel.fromJson(Map<String, dynamic> json) {
    return CashierModel(
      id:            json['id'].toString(),
      name:          json['name']           as String,
      phone:         json['phone']          as String,
      status:        json['status']         as String? ?? 'Active',
      plainPassword: json['plain_password'] as String?,
      createdAt:     (json['created_at'] ?? json['createdAt']) as String?,
    );
  }
}
