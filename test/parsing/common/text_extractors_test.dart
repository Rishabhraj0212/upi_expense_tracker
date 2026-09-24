import 'package:flutter_test/flutter_test.dart';
import 'package:upi_expense_tracker/parsing/common/text_extractors.dart';

void main() {
  group('extractAmountPaise', () {
    test('picks the transaction amount over a spaced-out "Avl Bal" mention', () {
      final result = TextExtractors.extractAmountPaise('Rs.250.00 debited. Avl Bal Rs.48,750.00');
      expect(result, 25000);
    });

    test('excludes a concatenated "AvlBal:" mention (no space) even when it comes before the real amount', () {
      // Real bank SMS sometimes write this run-together, e.g. Bank of
      // Baroda's "AvlBal:Rs12817.87(...)". A \b-terminated regex doesn't
      // match "avl" here at all, because "Bal" immediately follows with no
      // word-boundary between them — so this amount would previously have
      // been wrongly accepted as the transaction amount instead of the
      // actual one that follows.
      final text = 'AvlBal:Rs12817.87 as of last night. Now Rs.10.00 has been debited.';

      final result = TextExtractors.extractAmountPaise(text);

      expect(result, 1000);
    });

    test('still excludes the ordinary spaced "Avl Bal" / "Available Balance" forms', () {
      expect(
        TextExtractors.extractAmountPaise('Available Balance Rs.9,999.00. Rs.100 debited.'),
        10000,
      );
    });
  });
}
