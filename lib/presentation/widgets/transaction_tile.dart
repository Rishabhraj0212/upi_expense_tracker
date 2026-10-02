import 'package:flutter/material.dart';

import '../../domain/models/transaction.dart' as domain;
import '../../domain/models/transaction_type.dart';
import '../../format.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.transaction, this.onTap});

  final domain.Transaction transaction;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDebit = transaction.type == TransactionType.debit;
    final color = isDebit ? Colors.red : Colors.green;
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(isDebit ? Icons.arrow_upward : Icons.arrow_downward, color: color),
      ),
      title: Text(transaction.displayName, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${transaction.sourceList.join(' + ')} • ${Fmt.dayTime(transaction.occurredAt)}'),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  transaction.category ?? 'Uncategorized',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontStyle: transaction.category == null ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ),
              if (transaction.note != null && transaction.note!.isNotEmpty) ...[
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '• ${transaction.note!}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
      trailing: Text(
        '${isDebit ? '-' : '+'}${Fmt.rupees(transaction.amountPaise)}',
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
