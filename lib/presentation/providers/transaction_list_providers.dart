import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/transaction.dart' as domain;
import '../../domain/repositories/transaction_repository.dart';
import '../utils/transaction_totals.dart';
import 'app_providers.dart';

final transactionFilterProvider = StateProvider.autoDispose<TransactionFilter>((ref) => TransactionFilter.none);

/// Represents the selected month for filtering in the transaction list screen.
/// `null` means "All Months / All Time".
/// When set to a [DateTime] (e.g. `DateTime(2026, 9)`), only transactions
/// occurring in that month are returned.
final selectedMonthProvider = StateProvider.autoDispose<DateTime?>((ref) => null);

/// List of distinct months that have transactions, sorted descending (newest first).
/// Always includes the current month so users can select it even if empty.
final availableMonthsProvider = Provider.autoDispose<List<DateTime>>((ref) {
  final allTxAsync = ref.watch(transactionsStreamProvider);
  final monthsSet = <String, DateTime>{};

  // Always include current month
  final now = DateTime.now();
  final currentMonth = DateTime(now.year, now.month);
  monthsSet['${currentMonth.year}-${currentMonth.month}'] = currentMonth;

  allTxAsync.whenData((transactions) {
    for (final tx in transactions) {
      final m = DateTime(tx.occurredAt.year, tx.occurredAt.month);
      monthsSet['${m.year}-${m.month}'] = m;
    }
  });

  final list = monthsSet.values.toList()..sort((a, b) => b.compareTo(a));
  return list;
});

/// Streams transactions matching both the active [transactionFilterProvider]
/// (type, category, search text) and the [selectedMonthProvider] (month-wise).
final filteredTransactionsProvider = StreamProvider.autoDispose<List<domain.Transaction>>((ref) {
  final baseFilter = ref.watch(transactionFilterProvider);
  final selectedMonth = ref.watch(selectedMonthProvider);

  TransactionFilter effectiveFilter = baseFilter;
  if (selectedMonth != null) {
    final start = DateTime(selectedMonth.year, selectedMonth.month, 1, 0, 0, 0);
    final end = DateTime(selectedMonth.year, selectedMonth.month + 1, 0, 23, 59, 59, 999);
    effectiveFilter = baseFilter.copyWith(from: start, to: end);
  }

  return ref.watch(transactionRepositoryProvider).watchAll(filter: effectiveFilter);
});

/// Computes totals (debit, credit, net balance) for the currently filtered transactions.
final filteredTotalsProvider = Provider.autoDispose<TransactionTotals>((ref) {
  final txAsync = ref.watch(filteredTransactionsProvider);
  return txAsync.maybeWhen(
    data: (txs) => computeTransactionTotals(txs),
    orElse: () => (debitPaise: 0, creditPaise: 0, netBalancePaise: 0),
  );
});
