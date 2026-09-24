String? validateEmail(String? value) {
  final v = (value ?? '').trim();
  if (v.isEmpty) return 'Email is required';
  final ok = RegExp(r'^[\w\.\-+]+@[\w\-]+(\.[\w\-]+)+$').hasMatch(v);
  return ok ? null : 'Enter a valid email address';
}

String? validatePassword(String? value) {
  final v = value ?? '';
  if (v.isEmpty) return 'Password is required';
  if (v.length < 6) return 'Password must be at least 6 characters';
  return null;
}

String? validateName(String? value) {
  final v = (value ?? '').trim();
  if (v.isEmpty) return 'Full name is required';
  if (v.split(' ').length < 1 || v.length < 3) return 'Enter a valid full name';
  return null;
}

String? validateAge(String? value) {
  final v = int.tryParse(value ?? '');
  if (v == null || v < 1 || v > 120) return 'Enter a valid age';
  return null;
}

String? validateMobile(String? value) {
  final v = (value ?? '').trim();
  if (v.isEmpty) return 'Mobile number is required';
  if (v.length < 10) return 'Enter a valid 10-digit mobile number';
  return null;
}

String? validateRequired(String? value, {String label = 'This field'}) {
  if ((value ?? '').trim().isEmpty) return '$label is required';
  return null;
}