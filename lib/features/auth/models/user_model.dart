class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    required this.status,
    this.ownerId,
  });

  final String  id;
  final String  name;
  final String  phone;
  final String  role;     // 'Manufacturer' | 'Reseller' | 'Cashier' | 'Cutter'
  final String  status;   // 'Active' | 'Inactive'
  final String? ownerId;  // set for Cashier / Cutter — points to their owner user

  bool get isReseller     => role == 'Reseller';
  bool get isManufacturer => role == 'Manufacturer';
  bool get isCashier      => role == 'Cashier';
  bool get isCutter       => role == 'Cutter';

  /// True for Manufacturer / Reseller (main user accounts)
  bool get isMainUser => isManufacturer || isReseller;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id:      json['id']       as String,
      name:    json['name']     as String,
      phone:   json['phone']    as String,
      role:    json['role']     as String,
      status:  json['status']   as String,
      ownerId: json['owner_id'] as String?,
    );
  }
}
