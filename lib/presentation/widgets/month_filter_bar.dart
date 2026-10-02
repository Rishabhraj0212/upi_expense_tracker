import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../format.dart';
import '../providers/transaction_list_providers.dart';

class MonthFilterBar extends ConsumerWidget {
  const MonthFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final availableMonths = ref.watch(availableMonthsProvider);
    final totals = ref.watch(filteredTotalsProvider);
    final theme = Theme.of(context);

    int? currentIndex;
    if (selectedMonth != null) {
      for (int i = 0; i < availableMonths.length; i++) {
        if (availableMonths[i].year == selectedMonth.year &&
            availableMonths[i].month == selectedMonth.month) {
          currentIndex = i;
          break;
        }
      }
    }

    final idx = currentIndex;
    final hasPrevious = idx == null
        ? availableMonths.isNotEmpty
        : idx < availableMonths.length - 1;
    final hasNext = idx != null && idx > 0;

    void selectPrevious() {
      if (idx == null) {
        if (availableMonths.isNotEmpty) {
          ref.read(selectedMonthProvider.notifier).state = availableMonths.first;
        }
      } else if (idx < availableMonths.length - 1) {
        ref.read(selectedMonthProvider.notifier).state = availableMonths[idx + 1];
      }
    }

    void selectNext() {
      if (idx != null && idx > 0) {
        ref.read(selectedMonthProvider.notifier).state = availableMonths[idx - 1];
      }
    }

    void showMonthPickerSheet() {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => _MonthPickerSheet(
          selectedMonth: selectedMonth,
          availableMonths: availableMonths,
          onSelect: (month) {
            ref.read(selectedMonthProvider.notifier).state = month;
            Navigator.of(ctx).pop();
          },
        ),
      );
    }

    return Container(
      color: theme.colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Previous month',
                onPressed: hasPrevious ? selectPrevious : null,
              ),
              Expanded(
                child: InkWell(
                  onTap: showMonthPickerSheet,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_month,
                          size: 18,
                          color: selectedMonth != null
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            selectedMonth != null
                                ? Fmt.fullMonthYear(selectedMonth)
                                : 'All Months',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: selectedMonth != null
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_drop_down,
                          color: selectedMonth != null
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Next month',
                onPressed: hasNext ? selectNext : null,
              ),
              if (selectedMonth != null)
                TextButton(
                  onPressed: () => ref.read(selectedMonthProvider.notifier).state = null,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text('All Time'),
                )
              else
                TextButton(
                  onPressed: () {
                    final now = DateTime.now();
                    ref.read(selectedMonthProvider.notifier).state = DateTime(now.year, now.month);
                  },
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text('This Month'),
                ),
            ],
          ),
          if (selectedMonth != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _MonthlyStatItem(
                    label: 'Debit',
                    amount: totals.debitPaise,
                    color: Colors.red.shade700,
                  ),
                  Container(
                    height: 20,
                    width: 1,
                    color: theme.colorScheme.outlineVariant,
                  ),
                  _MonthlyStatItem(
                    label: 'Credit',
                    amount: totals.creditPaise,
                    color: Colors.green.shade700,
                  ),
                  Container(
                    height: 20,
                    width: 1,
                    color: theme.colorScheme.outlineVariant,
                  ),
                  _MonthlyStatItem(
                    label: 'Net',
                    amount: totals.netBalancePaise,
                    color: totals.netBalancePaise >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MonthPickerSheet extends StatelessWidget {
  const _MonthPickerSheet({
    required this.selectedMonth,
    required this.availableMonths,
    required this.onSelect,
  });

  final DateTime? selectedMonth;
  final List<DateTime> availableMonths;
  final void Function(DateTime? month) onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Select Month', style: theme.textTheme.titleLarge),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.all_inclusive),
              title: const Text('All Months (All Time)'),
              selected: selectedMonth == null,
              trailing: selectedMonth == null ? Icon(Icons.check, color: theme.colorScheme.primary) : null,
              onTap: () => onSelect(null),
            ),
            const Divider(),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: availableMonths.length,
                itemBuilder: (context, index) {
                  final month = availableMonths[index];
                  final isSelected = selectedMonth != null &&
                      selectedMonth!.year == month.year &&
                      selectedMonth!.month == month.month;
                  final isCurrentMonth = month.year == now.year && month.month == now.month;

                  return ListTile(
                    leading: const Icon(Icons.calendar_today_outlined),
                    title: Text(Fmt.fullMonthYear(month)),
                    subtitle: isCurrentMonth ? const Text('Current Month') : null,
                    selected: isSelected,
                    trailing: isSelected ? Icon(Icons.check, color: theme.colorScheme.primary) : null,
                    onTap: () => onSelect(month),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedMonth ?? now,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                      initialDatePickerMode: DatePickerMode.year,
                    );
                    if (picked != null) {
                      onSelect(DateTime(picked.year, picked.month));
                    }
                  },
                  icon: const Icon(Icons.edit_calendar),
                  label: const Text('Choose other month/year...'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthlyStatItem extends StatelessWidget {
  const _MonthlyStatItem({
    required this.label,
    required this.amount,
    required this.color,
  });

  final String label;
  final int amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 2),
        Text(
          Fmt.rupees(amount.abs()),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
      ],
    );
  }
}
