import 'package:flutter_test/flutter_test.dart';
import 'package:upi_expense_tracker/format.dart';

void main() {
  test('rupees uses Indian grouping and hides zero paise', () {
    expect(Fmt.rupees(25000), '₹250');
    expect(Fmt.rupees(125050), '₹1,250.50');
    expect(Fmt.rupees(12500000), '₹1,25,000');
    expect(Fmt.rupees(5), '₹0.05');
  });
}
