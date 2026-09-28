import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/transaction.dart' as domain;
import '../../format.dart';
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

    // transactions are sorted by occurredAt DESC — the first one with
    // a non-null balancePaise is the most recent known bank balance.
    final latestBalanceTx = transactions.cast<domain.Transaction?>().firstWhere(
          (tx) => tx!.balancePaise != null,
          orElse: () => null,
        );

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
        const SizedBox(height: 12),
        _BalanceCard(balanceTx: latestBalanceTx),
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

/// Full-width card showing the latest known account balance extracted from
/// an SMS. Displays bank name, amount, and when the balance was last seen.
class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balanceTx});

  final domain.Transaction? balanceTx;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (balanceTx == null) {
      return Card(
        color: Colors.grey.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.account_balance_wallet, color: Colors.grey.shade400),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Account Balance', style: theme.textTheme.labelLarge),
                    const SizedBox(height: 2),
                    Text(
                      'No balance info found in SMS yet',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Text('—', style: theme.textTheme.headlineSmall?.copyWith(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    final tx = balanceTx!;
    final bankLabel = tx.bankName ?? 'Bank';
    final acctHint = tx.accountHint != null ? ' (${tx.accountHint})' : '';

    return Card(
      color: Colors.blue.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Row(
          children: [
            Icon(Icons.account_balance_wallet, color: Colors.blue.shade600),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Account Balance', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 2),
                  Text(
                    '$bankLabel$acctHint • ${Fmt.dayTime(tx.occurredAt)}',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text(
              Fmt.rupees(tx.balancePaise!),
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.blue.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
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
