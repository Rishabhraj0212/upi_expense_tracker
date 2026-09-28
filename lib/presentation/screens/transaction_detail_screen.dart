import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/transaction.dart' as domain;
import '../../domain/models/transaction_type.dart';
import '../../format.dart';
import '../providers/app_providers.dart';
import 'category_selection_sheet.dart';
import 'categories_settings_screen.dart';

class TransactionDetailScreen extends ConsumerWidget {
  const TransactionDetailScreen({super.key, required this.transaction});

  final domain.Transaction transaction;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: const Text('This removes it from your records. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(transactionRepositoryProvider).delete(transaction.id);
    if (context.mounted) Navigator.of(context).pop();
  }

  Future<void> _changeCategory(BuildContext context, WidgetRef ref) async {
    final result = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      builder: (context) => CategorySelectionSheet(selectedCategoryName: transaction.category),
    );

    if (result == '_MANAGE_CATEGORIES_') {
      if (!context.mounted) return;
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CategoriesSettingsScreen()));
      return;
    }

    if (result != transaction.category && (result != null || transaction.category != null)) {
      await ref.read(transactionRepositoryProvider).setCategory(transaction.id, result, transaction.note);
      
      // Save memory rule if a merchant/UPI ID exists
      if (result != null) {
        final merchantKey = transaction.merchantName ?? transaction.upiId;
        if (merchantKey != null && merchantKey.isNotEmpty) {
          await ref.read(categoryRepositoryProvider).saveRule(merchantKey, result);
        }
      }

      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDebit = transaction.type == TransactionType.debit;
    final color = isDebit ? Colors.red : Colors.green;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete',
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                Text(
                  '${isDebit ? '-' : '+'}${Fmt.rupees(transaction.amountPaise)}',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(color: color, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(isDebit ? 'Debit' : 'Credit', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(transaction.displayName, style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Category', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.primary)),
                        const SizedBox(height: 4),
                        Text(
                          transaction.category ?? 'Uncategorized',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontStyle: transaction.category == null ? FontStyle.italic : FontStyle.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => _changeCategory(context, ref),
                    child: const Text('Change'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                _DetailRow(label: 'Date & time', value: Fmt.dayTime(transaction.occurredAt)),
                if (transaction.merchantName != null)
                  _DetailRow(label: 'Merchant', value: transaction.merchantName!),
                if (transaction.upiId != null) _DetailRow(label: 'UPI ID', value: transaction.upiId!),
                if (transaction.bankName != null) _DetailRow(label: 'Bank', value: transaction.bankName!),
                if (transaction.accountHint != null)
                  _DetailRow(label: 'Account', value: transaction.accountHint!),
                if (transaction.referenceId != null)
                  _DetailRow(label: 'Reference ID', value: transaction.referenceId!),
                _DetailRow(label: 'Detected via', value: transaction.sourceList.join(', ')),
                if (transaction.sourceApp != null) _DetailRow(label: 'App', value: transaction.sourceApp!),
                if (transaction.sourceAddress != null)
                  _DetailRow(label: 'SMS sender', value: transaction.sourceAddress!),
                if (transaction.balancePaise != null)
                  _DetailRow(label: 'Balance after', value: Fmt.rupees(transaction.balancePaise!)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Original message', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SelectableText(transaction.rawText, style: const TextStyle(fontFamily: 'monospace')),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
