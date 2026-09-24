import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/expense_category.dart';
import '../providers/app_providers.dart';

class CategoriesSettingsScreen extends ConsumerWidget {
  const CategoriesSettingsScreen({super.key});

  Future<void> _addCategory(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Category'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Category Name',
              hintText: 'e.g. Subscriptions',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Please enter a name';
              if (value.trim().toLowerCase() == 'uncategorized') return 'Reserved name';
              return null;
            },
            onFieldSubmitted: (_) {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop(controller.text.trim());
              }
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop(controller.text.trim());
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && context.mounted) {
      try {
        await ref.read(categoryRepositoryProvider).addCustomCategory(result);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
        }
      }
    }
  }

  Future<void> _editCategory(BuildContext context, WidgetRef ref, ExpenseCategory category) async {
    if (category.isDefault) return;

    final controller = TextEditingController(text: category.name);
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Category'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Category Name'),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Please enter a name';
              if (value.trim().toLowerCase() == 'uncategorized') return 'Reserved name';
              return null;
            },
            onFieldSubmitted: (_) {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop(controller.text.trim());
              }
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop(controller.text.trim());
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && result != category.name && context.mounted) {
      try {
        await ref.read(categoryRepositoryProvider).updateCustomCategory(category.id, result);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
        }
      }
    }
  }

  Future<void> _deleteCategory(BuildContext context, WidgetRef ref, ExpenseCategory category) async {
    if (category.isDefault) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category?'),
        content: Text('Are you sure you want to delete "${category.name}"?\n\n'
            'If any transactions are currently using this category, you must re-assign them to a different category first.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        await ref.read(categoryRepositoryProvider).deleteCustomCategory(category.id);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red, duration: const Duration(seconds: 4)));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoryRepositoryProvider).watchAllCategories();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addCategory(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Category'),
      ),
      body: StreamBuilder<List<ExpenseCategory>>(
        stream: categoriesAsync,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          
          final categories = snapshot.data ?? [];
          final defaultCats = categories.where((c) => c.isDefault).toList();
          final customCats = categories.where((c) => !c.isDefault).toList();

          return ListView(
            children: [
              if (customCats.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text('Custom categories', style: Theme.of(context).textTheme.titleSmall),
                ),
                for (final cat in customCats)
                  ListTile(
                    title: Text(cat.name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          onPressed: () => _editCategory(context, ref, cat),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          onPressed: () => _deleteCategory(context, ref, cat),
                        ),
                      ],
                    ),
                  ),
                const Divider(),
              ],
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text('Built-in categories', style: Theme.of(context).textTheme.titleSmall),
              ),
              for (final cat in defaultCats)
                ListTile(
                  title: Text(cat.name),
                ),
              const SizedBox(height: 80), // Padding for FAB
            ],
          );
        },
      ),
    );
  }
}
