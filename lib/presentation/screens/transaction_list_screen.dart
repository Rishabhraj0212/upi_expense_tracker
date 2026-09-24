import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/transaction_list_providers.dart';
import '../widgets/filter_bar.dart';
import '../widgets/transaction_tile.dart';
import 'transaction_detail_screen.dart';

class TransactionListScreen extends ConsumerWidget {
  const TransactionListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(filteredTransactionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      body: Column(
        children: [
          const FilterBar(),
          const Divider(height: 1),
          Expanded(
            child: transactionsAsync.when(
              data: (transactions) => transactions.isEmpty
                  ? const Center(child: Text('No transactions match this filter.'))
                  : ListView.builder(
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        final tx = transactions[index];
                        return TransactionTile(
                          transaction: tx,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => TransactionDetailScreen(transaction: tx)),
                          ),
                        );
                      },
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Could not load transactions: $e')),
            ),
          ),
        ],
      ),
    );
  }
}
