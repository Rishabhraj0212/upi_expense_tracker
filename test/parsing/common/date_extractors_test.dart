import 'package:flutter_test/flutter_test.dart';
import 'package:upi_expense_tracker/parsing/common/date_extractors.dart';

void main() {
  final fallback = DateTime(2026, 9, 29, 12, 0, 0);

  group('DateExtractors', () {
    test('extracts YYYY-MM-DD date and time correctly', () {
      const text = 'Dear BOB UPI User: Your account is credited with INR 5.00 on 2026-09-28 08:14:23 AM by UPI Ref No 627114110535; AvlBal: Rs11651.87 - BOB';
      final dt = DateExtractors.extractDateTime(text, fallback);
      expect(dt.year, 2026);
      expect(dt.month, 9);
      expect(dt.day, 28);
      expect(dt.hour, 8);
      expect(dt.minute, 14);
      expect(dt.second, 23);
    });

    test('extracts YYYY:MM:DD date correctly', () {
      const text = 'debited Rs.100 on 2026:09:24 14:30:00';
      final dt = DateExtractors.extractDateTime(text, fallback);
      expect(dt.year, 2026);
      expect(dt.month, 9);
      expect(dt.day, 24);
      expect(dt.hour, 14);
      expect(dt.minute, 30);
    });

    test('extracts DD-MM-YYYY date correctly', () {
      const text = 'debited Rs.100 on 28-09-2026 10:15 am';
      final dt = DateExtractors.extractDateTime(text, fallback);
      expect(dt.year, 2026);
      expect(dt.month, 9);
      expect(dt.day, 28);
      expect(dt.hour, 10);
      expect(dt.minute, 15);
    });
  });
}
