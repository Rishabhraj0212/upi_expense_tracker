import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/transaction.dart' as domain;
import '../providers/app_providers.dart';
import '../utils/transaction_totals.dart';
import '../widgets/summary_card.dart';
import '../widgets/transaction_tile.dart';
import 'debug_ingestion_screen.dart';
import 'settings_screen.dart';
import 'setup_screen.dart';
import 'transaction_detail_screen.dart';
import 'transaction_list_screen.dart';

const _recentPreviewCount = 5;

enum _MenuAction { permissions, settings, debug }

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('UPI Expenses'),
        actions: [
          PopupMenuButton<_MenuAction>(
            onSelected: (action) {
              final screen = switch (action) {
                _MenuAction.permissions => const SetupScreen(),
                _MenuAction.settings => const SettingsScreen(),
                _MenuAction.debug => const DebugIngestionScreen(),
              };
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: _MenuAction.permissions, child: Text('Permissions')),
              PopupMenuItem(value: _MenuAction.settings, child: Text('Settings')),
              PopupMenuItem(value: _MenuAction.debug, child: Text('Debug harness')),
            ],
          ),
        ],
      ),
      body: transactionsAsync.when(
        data: (transactions) => _DashboardBody(transactions: transactions),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Could not load transactions: $e')),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.transactions});

  final List<domain.Transaction> transactions;

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) return const _EmptyState();

    final totals = computeTransactionTotals(transactions);
    final recent = transactions.take(_recentPreviewCount).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            SummaryCard(label: 'Total Debit', amountPaise: totals.debitPaise, color: Colors.red),
            const SizedBox(width: 12),
            SummaryCard(label: 'Total Credit', amountPaise: totals.creditPaise, color: Colors.green),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Transactions', style: Theme.of(context).textTheme.titleMedium),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TransactionListScreen()),
              ),
              child: const Text('See all'),
            ),
          ],
        ),
        Card(
          child: Column(
            children: [
              for (final tx in recent)
                TransactionTile(
                  transaction: tx,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => TransactionDetailScreen(transaction: tx)),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.receipt_long, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No transactions yet.\nOnce SMS and notification access are granted, '
              'detected UPI payments will appear here automatically.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SetupScreen()),
              ),
              child: const Text('Check permissions'),
            ),
          ],
        ),
      ),
    );
  }
}
