import 'user_model.dart';

class RegistrationPlan {
  const RegistrationPlan({
    required this.key,
    required this.months,
    required this.label,
    required this.fee,
    required this.enabled,
  });

  final String key;
  final int months;
  final String label;
  final double fee;
  final bool enabled;

  bool get isFree => fee == 0;

  factory RegistrationPlan.fromJson(Map<String, dynamic> json) {
    return RegistrationPlan(
      key: json['key'] as String,
      months: (json['months'] as num?)?.toInt() ?? 1,
      label: json['label'] as String? ?? 'Registration plan',
      fee: (json['fee'] as num?)?.toDouble() ?? 0,
      enabled: json['enabled'] as bool? ?? true,
    );
  }
}

class RegistrationResult {
  const RegistrationResult({
    required this.user,
    required this.plan,
    required this.registrationFree,
  });

  final UserModel user;
  final RegistrationPlan plan;
  final bool registrationFree;
}
