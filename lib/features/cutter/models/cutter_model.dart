class CutterModel {
  const CutterModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.status,
    this.createdAt,
  });

  final String  id;
  final String  name;
  final String  phone;
  final String  status;
  final String? createdAt;

  bool get isActive => status == 'Active';

  factory CutterModel.fromJson(Map<String, dynamic> json) {
    return CutterModel(
      id:            json['id'].toString(),
      name:          json['name']           as String,
      phone:         json['phone']          as String,
      status:        json['status']         as String? ?? 'Active',
      createdAt:     (json['created_at'] ?? json['createdAt']) as String?,
    );
  }
}
