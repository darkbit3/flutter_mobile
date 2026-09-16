class PaymentAccount {
  const PaymentAccount({
    required this.id,
    required this.bank,
    required this.accountName,
    required this.accountNumber,
  });

  final String id;
  final String bank;
  final String accountName;
  final String accountNumber;

  factory PaymentAccount.fromJson(Map<String, dynamic> json) {
    return PaymentAccount(
      id: (json['id'] ?? '').toString(),
      bank: (json['bank'] ?? '').toString(),
      accountName: (json['accountName'] ?? '').toString(),
      accountNumber: (json['accountNumber'] ?? '').toString(),
    );
  }
}

class PaymentInfo {
  const PaymentInfo({
    required this.telegramUsername,
    required this.accounts,
  });

  final String telegramUsername;
  final List<PaymentAccount> accounts;

  String get cleanTelegramUsername => telegramUsername.replaceAll('@', '').trim();

  factory PaymentInfo.fromJson(Map<String, dynamic> json) {
    final rawAccounts = json['accounts'] as List<dynamic>? ?? [];
    return PaymentInfo(
      telegramUsername: (json['telegramUsername'] ?? '@shmeta_admin').toString(),
      accounts: rawAccounts
          .map((a) => PaymentAccount.fromJson(a as Map<String, dynamic>))
          .toList(),
    );
  }
}

class RegistrationStatusData {
  const RegistrationStatusData({
    required this.status,
    this.id,
    this.plan,
    this.fee,
    this.rejectionReason,
    this.createdAt,
  });

  final String status;
  final String? id;
  final String? plan;
  final double? fee;
  final String? rejectionReason;
  final String? createdAt;

  bool get isApproved => status.toLowerCase() == 'approved';
  bool get isRejected => status.toLowerCase() == 'rejected';
  bool get isPending => status.toLowerCase() == 'pending';

  factory RegistrationStatusData.fromJson(Map<String, dynamic> json) {
    return RegistrationStatusData(
      status: (json['status'] ?? 'None').toString(),
      id: json['id']?.toString(),
      plan: json['plan']?.toString(),
      fee: (json['fee'] as num?)?.toDouble(),
      rejectionReason: json['rejectionReason']?.toString(),
      createdAt: json['createdAt']?.toString(),
    );
  }
}
