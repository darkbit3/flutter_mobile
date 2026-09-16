String normalizeEthiopianPhone(String raw) {
  final digits = raw.replaceAll(RegExp(r'\D+'), '');
  var local = digits;
  if (local.startsWith('251')) local = local.substring(3);
  if (local.startsWith('0')) local = local.substring(1);
  return '251$local';
}

bool isValidEthiopianPhone(String raw) {
  return RegExp(r'^251[97]\d{8}$').hasMatch(normalizeEthiopianPhone(raw));
}