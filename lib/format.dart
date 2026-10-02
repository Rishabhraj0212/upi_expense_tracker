const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const _fullMonths = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December'
];

class Fmt {
  /// 125050 -> "₹1,250.50" (Indian digit grouping, paise hidden when zero).
  static String rupees(int paise) {
    final whole = (paise ~/ 100).toString();
    var grouped = whole;
    if (whole.length > 3) {
      final tail = whole.substring(whole.length - 3);
      var head = whole.substring(0, whole.length - 3);
      final parts = <String>[];
      while (head.length > 2) {
        parts.insert(0, head.substring(head.length - 2));
        head = head.substring(0, head.length - 2);
      }
      if (head.isNotEmpty) parts.insert(0, head);
      grouped = '${parts.join(',')},$tail';
    }
    final frac = paise % 100;
    return frac == 0 ? '₹$grouped' : '₹$grouped.${frac.toString().padLeft(2, '0')}';
  }

  static String monthYear(DateTime d) => '${_months[d.month - 1]} ${d.year}';
  static String fullMonthYear(DateTime d) => '${_fullMonths[d.month - 1]} ${d.year}';

  static String dayTime(DateTime d) {
    final local = d.toLocal();
    final h = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final m = local.minute.toString().padLeft(2, '0');
    return '${local.day} ${_months[local.month - 1]}, $h:$m ${local.hour < 12 ? 'am' : 'pm'}';
  }
}
