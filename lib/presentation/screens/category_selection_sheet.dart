import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/expense_category.dart';
import '../providers/app_providers.dart';

class CategorySelectionSheet extends ConsumerWidget {
  const CategorySelectionSheet({super.key, required this.selectedCategoryName});

  final String? selectedCategoryName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoryRepositoryProvider).watchAllCategories();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Choose Category', style: Theme.of(context).textTheme.titleLarge),
            ),
            const SizedBox(height: 8),
            StreamBuilder<List<ExpenseCategory>>(
              stream: categoriesAsync,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                  );
                }

                final categories = snapshot.data ?? [];
                
                return Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final cat in categories)
                        RadioListTile<String?>(
                          title: Text(cat.name),
                          value: cat.name,
                          groupValue: selectedCategoryName,
                          onChanged: (val) => Navigator.of(context).pop(val),
                        ),
                      RadioListTile<String?>(
                        title: const Text('Uncategorized', style: TextStyle(fontStyle: FontStyle.italic)),
                        value: null,
                        groupValue: selectedCategoryName,
                        onChanged: (val) => Navigator.of(context).pop(val),
                      ),
                    ],
                  ),
                );
              },
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: TextButton.icon(
                  onPressed: () {
                    // Could navigate to settings or show a dialog here.
                    // For now, we pop with a special signal or let settings handle it.
                    Navigator.of(context).pop('_MANAGE_CATEGORIES_');
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add New Category'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
