import '../../domain/models/transaction.dart' as domain;
import '../../domain/models/transaction_type.dart';

typedef TransactionTotals = ({int debitPaise, int creditPaise});

/// Pure and unit-testable: sums debit and credit amounts separately.
TransactionTotals computeTransactionTotals(List<domain.Transaction> transactions) {
  var debit = 0;
  var credit = 0;
  for (final t in transactions) {
    if (t.type == TransactionType.debit) {
      debit += t.amountPaise;
    } else {
      credit += t.amountPaise;
    }
  }
  return (debitPaise: debit, creditPaise: credit);
}
