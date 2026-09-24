import 'month_names.dart';

/// Best-effort date/time extraction from bank SMS text. Indian bank SMS
/// always use day-first dates, so "05-01-24" is 5 Jan, never 1 May.
class DateExtractors {
  DateExtractors._();

  static final RegExp _numericDateRx = RegExp(r'\b(\d{1,2})[-/](\d{1,2})[-/](\d{2,4})\b|\b(\d{4}):(\d{1,2}):(\d{1,2})\b');

  static final RegExp _namedMonthDateRx = RegExp(
    r'\b(\d{1,2})[-\s](jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*[-\s](\d{2,4})\b',
    caseSensitive: false,
  );

  // Negative lookbehind (?<![:\d]) stops the regex grabbing MM:DD from
  // inside a YYYY:MM:DD date like "2026:09:24 01:23:23" — without it,
  // the scanner picks up "09:24" (month:day) instead of "01:23:23" (time).
  static final RegExp _timeRx = RegExp(
    r'(?<![:\d])(\d{1,2}):(\d{2})(?::(\d{2}))?\s*(am|pm)?\b',
    caseSensitive: false,
  );

  /// Extracts a date+time from [text], falling back to [fallback] (usually
  /// the moment the SMS/notification was received) for whatever it can't find.
  static DateTime extractDateTime(String text, DateTime fallback) {
    final date = _extractDate(text) ?? DateTime(fallback.year, fallback.month, fallback.day);

    final tm = _timeRx.firstMatch(text);
    if (tm == null) {
      return DateTime(date.year, date.month, date.day, fallback.hour, fallback.minute, fallback.second);
    }

    var hour = int.parse(tm.group(1)!);
    final minute = int.parse(tm.group(2)!);
    final second = tm.group(3) != null ? int.parse(tm.group(3)!) : 0;
    final ampm = tm.group(4)?.toLowerCase();
    if (ampm == 'pm' && hour < 12) hour += 12;
    if (ampm == 'am' && hour == 12) hour = 0;
    if (hour > 23) return DateTime(date.year, date.month, date.day, fallback.hour, fallback.minute, fallback.second);

    return DateTime(date.year, date.month, date.day, hour, minute, second);
  }

  static DateTime? _extractDate(String text) {
    final named = _namedMonthDateRx.firstMatch(text);
    if (named != null) {
      final day = int.parse(named.group(1)!);
      final month = monthAbbreviations[named.group(2)!.toLowerCase()]!;
      final year = _normalizeYear(int.parse(named.group(3)!));
      if (_isValidDay(day, month, year)) return DateTime(year, month, day);
    }

    final numeric = _numericDateRx.firstMatch(text);
    if (numeric != null) {
      // Two alternations: DD-MM-YYYY (groups 1,2,3) or YYYY:MM:DD (groups 4,5,6).
      final int day, month, year;
      if (numeric.group(1) != null) {
        // Standard DD/MM/YYYY or DD-MM-YYYY
        day = int.parse(numeric.group(1)!);
        month = int.parse(numeric.group(2)!);
        year = _normalizeYear(int.parse(numeric.group(3)!));
      } else {
        // YYYY:MM:DD format (e.g. Bank of Baroda: 2026:09:24)
        year = int.parse(numeric.group(4)!);
        month = int.parse(numeric.group(5)!);
        day = int.parse(numeric.group(6)!);
      }
      if (month >= 1 && month <= 12 && _isValidDay(day, month, year)) return DateTime(year, month, day);
    }

    return null;
  }

  static int _normalizeYear(int year) => year < 100 ? year + 2000 : year;

  static bool _isValidDay(int day, int month, int year) {
    if (day < 1) return false;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    return day <= daysInMonth;
  }
}
