import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/transaction.dart' as domain;
import '../../format.dart';
import '../providers/app_providers.dart';
import '../providers/initial_balance_provider.dart';
import '../utils/transaction_totals.dart';
import '../widgets/summary_card.dart';
import '../widgets/transaction_tile.dart';
import 'ai_assistant_screen.dart';
import 'debug_ingestion_screen.dart';
import 'record_transaction_screen.dart';
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
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Record Transaction',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RecordTransactionScreen()),
            ),
          ),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const RecordTransactionScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Record Transaction'),
      ),
    );
  }
}

class _DashboardBody extends ConsumerStatefulWidget {
  const _DashboardBody({required this.transactions});

  final List<domain.Transaction> transactions;

  @override
  ConsumerState<_DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends ConsumerState<_DashboardBody> {
  bool _filterThisMonth = true;

  @override
  Widget build(BuildContext context) {
    if (widget.transactions.isEmpty) return const _EmptyState();

    final now = DateTime.now();
    final displayedTransactions = _filterThisMonth
        ? widget.transactions
            .where((tx) =>
                tx.occurredAt.year == now.year && tx.occurredAt.month == now.month)
            .toList()
        : widget.transactions;

    final totals = computeTransactionTotals(displayedTransactions);
    final recent = displayedTransactions.take(_recentPreviewCount).toList();

    // transactions are sorted by occurredAt DESC — the first one with
    // a non-null balancePaise is the most recent known bank balance.
    final latestBalanceTx = widget.transactions.cast<domain.Transaction?>().firstWhere(
          (tx) => tx!.balancePaise != null,
          orElse: () => null,
        );

    final initialBalance = ref.watch(initialBalanceProvider);
    // Calculated balance is only accurate for all-time transactions
    final allTimeTotals = _filterThisMonth ? computeTransactionTotals(widget.transactions) : totals;
    final calculatedBalancePaise = initialBalance + allTimeTotals.creditPaise - allTimeTotals.debitPaise;

    final currentMonthLabel = Fmt.monthYear(now);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _filterThisMonth ? 'Overview ($currentMonthLabel)' : 'Overview (All Time)',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            Row(
              children: [
                ChoiceChip(
                  label: Text(currentMonthLabel),
                  selected: _filterThisMonth,
                  onSelected: (val) {
                    if (val) setState(() => _filterThisMonth = true);
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('All Time'),
                  selected: !_filterThisMonth,
                  onSelected: (val) {
                    if (val) setState(() => _filterThisMonth = false);
                  },
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            SummaryCard(
              label: _filterThisMonth ? 'Debit ($currentMonthLabel)' : 'Total Debit',
              amountPaise: totals.debitPaise,
              color: Colors.red,
            ),
            const SizedBox(width: 12),
            SummaryCard(
              label: _filterThisMonth ? 'Credit ($currentMonthLabel)' : 'Total Credit',
              amountPaise: totals.creditPaise,
              color: Colors.green,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
          child: InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AiAssistantScreen()),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.blue),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('AI Expense Assistant', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text('Ask questions about your expenses', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _BalanceCard(balanceTx: latestBalanceTx, calculatedBalancePaise: calculatedBalancePaise),
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
              if (recent.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Center(
                    child: Text(
                      _filterThisMonth
                          ? 'No transactions for $currentMonthLabel'
                          : 'No transactions yet',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                ),
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
        // Extra space at bottom so FAB doesn't obscure content
        const SizedBox(height: 72),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balanceTx, required this.calculatedBalancePaise});

  final domain.Transaction? balanceTx;
  final int calculatedBalancePaise;

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
                    Text('Account Balance (SMS)', style: theme.textTheme.labelLarge),
                    const SizedBox(height: 2),
                    Text(
                      'No balance info found in SMS yet',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                    const SizedBox(height: 6),
                    Text('Calculated: ${Fmt.rupees(calculatedBalancePaise)}', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade800)),
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
                  Text('Account Balance (SMS)', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 2),
                  Text(
                    '$bankLabel$acctHint • ${Fmt.dayTime(tx.occurredAt)}',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text('Calculated: ${Fmt.rupees(calculatedBalancePaise)}', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade800)),
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
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RecordTransactionScreen()),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Record a transaction'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
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
