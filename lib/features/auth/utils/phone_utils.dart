String normalizeEthiopianPhone(String raw) {
  final digits = raw.replaceAll(RegExp(r'\D+'), '');
  if (digits.startsWith('251')) return digits;
  return '251$digits';
}

bool isValidEthiopianPhone(String raw) {
  return RegExp(r'^251[97]\d{8}$').hasMatch(normalizeEthiopianPhone(raw));
}