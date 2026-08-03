import 'package:intl/intl.dart';

class AppDateUtils {
  static final _formatter = DateFormat('dd-MM-yyyy');

  static String today() => _formatter.format(DateTime.now());

  static String format(DateTime date) => _formatter.format(date);

  static DateTime? parse(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      return _formatter.parse(dateStr);
    } catch (_) {
      return null;
    }
  }

  static bool isToday(String dateStr) => dateStr == today();

  static bool isSameMonth(String dateStr) {
    final parsed = parse(dateStr);
    if (parsed == null) return false;
    final now = DateTime.now();
    return parsed.month == now.month && parsed.year == now.year;
  }

  static String daysFromNow(int days) {
    return _formatter.format(DateTime.now().add(Duration(days: days)));
  }

  static int daysBetween(String from, String to) {
    final f = parse(from);
    final t = parse(to);
    if (f == null || t == null) return 0;
    return t.difference(f).inDays;
  }
}
