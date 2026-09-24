import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/transaction.dart' as domain;
import '../../domain/repositories/transaction_repository.dart';
import 'app_providers.dart';

final transactionFilterProvider = StateProvider.autoDispose<TransactionFilter>((ref) => TransactionFilter.none);

/// Separate from [transactionsStreamProvider] (which the dashboard uses for
/// its always-unfiltered totals) so filtering the list screen never affects
/// what the dashboard shows.
final filteredTransactionsProvider = StreamProvider.autoDispose<List<domain.Transaction>>((ref) {
  final filter = ref.watch(transactionFilterProvider);
  return ref.watch(transactionRepositoryProvider).watchAll(filter: filter);
});
