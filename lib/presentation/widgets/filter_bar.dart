import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/transaction_type.dart';
import '../providers/transaction_list_providers.dart';
import '../screens/category_selection_sheet.dart';

class FilterBar extends ConsumerWidget {
  const FilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(transactionFilterProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              _TypeChip(
                label: 'All',
                selected: filter.type == null,
                onSelected: () => ref.read(transactionFilterProvider.notifier).state =
                    filter.copyWith(clearType: true),
              ),
              const SizedBox(width: 8),
              _TypeChip(
                label: 'Debit',
                selected: filter.type == TransactionType.debit,
                onSelected: () => ref.read(transactionFilterProvider.notifier).state =
                    filter.copyWith(type: TransactionType.debit),
              ),
              const SizedBox(width: 8),
              _TypeChip(
                label: 'Credit',
                selected: filter.type == TransactionType.credit,
                onSelected: () => ref.read(transactionFilterProvider.notifier).state =
                    filter.copyWith(type: TransactionType.credit),
              ),
              const Spacer(),
              ActionChip(
                avatar: const Icon(Icons.filter_list, size: 16),
                label: Text(filter.category != null ? filter.category! : 'Category'),
                onPressed: () async {
                  final result = await showModalBottomSheet<String?>(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) => CategorySelectionSheet(selectedCategoryName: filter.category),
                  );
                  // We ignore _MANAGE_CATEGORIES_ here since this is just filtering.
                  if (result == '_MANAGE_CATEGORIES_') return;
                  
                  ref.read(transactionFilterProvider.notifier).state = filter.copyWith(
                    category: result ?? 'Uncategorized',
                  );
                },
              ),
              if (filter.category != null)
                IconButton(
                  icon: const Icon(Icons.clear, size: 16),
                  onPressed: () => ref.read(transactionFilterProvider.notifier).state =
                      filter.copyWith(clearCategory: true),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(
              hintText: 'Search merchant, UPI ID, or message text',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              isDense: true,
              suffixIcon: (filter.searchText ?? '').isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => ref.read(transactionFilterProvider.notifier).state =
                          filter.copyWith(clearSearchText: true),
                    ),
            ),
            onChanged: (value) => ref.read(transactionFilterProvider.notifier).state =
                filter.copyWith(searchText: value, clearSearchText: value.isEmpty),
          ),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.label, required this.selected, required this.onSelected});

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(label: Text(label), selected: selected, onSelected: (_) => onSelected());
  }
}
