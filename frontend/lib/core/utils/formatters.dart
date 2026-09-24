import 'package:intl/intl.dart';

import '../constants/app_constants.dart';

String formatMoney(num value) => '${AppConstants.currency}${NumberFormat('#,##0.00', 'en_IN').format(value)}';

String formatTime(DateTime time) {
  final local = time.toLocal();
  return DateFormat('hh:mm a').format(local);
}

String formatDate(DateTime date) => DateFormat('EEE, d MMM yyyy').format(date);

String formatShortDate(DateTime date) => DateFormat('dd MMM yyyy').format(date);

String formatDuration(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return h > 0 ? '${h}h ${m}m' : '${m}m';
}

String capitalize(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1);
}

String two(int n) => n.toString().padLeft(2, '0');