import 'package:flutter_test/flutter_test.dart';
import 'package:upi_expense_tracker/parsing/common/text_normalizer.dart';

void main() {
  test('collapses \\r\\n line breaks into a single space', () {
    expect(normalizeMessageText('Rs.500.00 debited\r\nfrom A/c XX1234'), 'Rs.500.00 debited from A/c XX1234');
  });

  test('collapses a bare \\r (old-style line ending) into a single space', () {
    expect(normalizeMessageText('Rs.500.00 debited\rfrom A/c XX1234'), 'Rs.500.00 debited from A/c XX1234');
  });

  test('collapses runs of repeated whitespace', () {
    expect(normalizeMessageText('Rs.500.00   debited     from A/c'), 'Rs.500.00 debited from A/c');
  });

  test('trims leading and trailing whitespace', () {
    expect(normalizeMessageText('  Rs.500.00 debited  \n'), 'Rs.500.00 debited');
  });
}
