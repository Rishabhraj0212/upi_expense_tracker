import 'package:drift/drift.dart';
import '../../domain/models/expense_category.dart';
import '../../domain/models/sync_status.dart';
import '../../domain/repositories/category_repository.dart';
import 'local/app_database.dart';

class DriftCategoryRepository implements CategoryRepository {
  DriftCategoryRepository(this._db);

  final AppDatabase _db;

  ExpenseCategory _toDomain(ExpenseCategoryRow row) {
    return ExpenseCategory(
      id: row.id,
      name: row.name,
      isDefault: row.isDefault,
    );
  }

  @override
  Stream<List<ExpenseCategory>> watchAllCategories() {
    return (_db.select(_db.expenseCategories)
          ..orderBy([
            (t) => OrderingTerm(expression: t.isDefault, mode: OrderingMode.desc),
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.asc),
          ]))
        .watch()
        .map((rows) => rows.map(_toDomain).toList());
  }

  @override
  Future<List<ExpenseCategory>> getAllCategories() async {
    final rows = await (_db.select(_db.expenseCategories)
          ..orderBy([
            (t) => OrderingTerm(expression: t.isDefault, mode: OrderingMode.desc),
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.asc),
          ]))
        .get();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<ExpenseCategory> addCustomCategory(String name) async {
    final normalized = name.trim().toLowerCase();
    
    // Check if it already exists
    final existing = await (_db.select(_db.expenseCategories)..where((t) => t.normalizedName.equals(normalized))).getSingleOrNull();
    if (existing != null) {
      throw StateError('A category with this name already exists.');
    }

    final now = DateTime.now();
    final id = await _db.into(_db.expenseCategories).insert(
          ExpenseCategoriesCompanion.insert(
            name: name.trim(),
            normalizedName: normalized,
            isDefault: const Value(false),
            createdAt: now,
            updatedAt: now,
          ),
        );

    final row = await (_db.select(_db.expenseCategories)..where((t) => t.id.equals(id))).getSingle();
    return _toDomain(row);
  }

  @override
  Future<void> updateCustomCategory(int id, String newName) async {
    return _db.transaction(() async {
      final category = await (_db.select(_db.expenseCategories)..where((t) => t.id.equals(id))).getSingle();
      if (category.isDefault) {
        throw StateError('Cannot rename a built-in category.');
      }
      
      final normalized = newName.trim().toLowerCase();
      if (normalized != category.normalizedName) {
        final existing = await (_db.select(_db.expenseCategories)..where((t) => t.normalizedName.equals(normalized))).getSingleOrNull();
        if (existing != null) {
          throw StateError('A category with this name already exists.');
        }
      }

      final oldName = category.name;
      
      // Update category
      await (_db.update(_db.expenseCategories)..where((t) => t.id.equals(id))).write(
        ExpenseCategoriesCompanion(
          name: Value(newName.trim()),
          normalizedName: Value(normalized),
          updatedAt: Value(DateTime.now()),
        ),
      );
      
      // Also update all transactions using the old name
      if (oldName != newName.trim()) {
        final txsToUpdate = await (_db.select(_db.transactions)..where((t) => t.category.equals(oldName))).get();
        for (final tx in txsToUpdate) {
           await (_db.update(_db.transactions)..where((t) => t.id.equals(tx.id))).write(
             TransactionsCompanion(
               category: Value(newName.trim()),
               updatedAt: Value(DateTime.now()),
               syncStatus: const Value(TransactionSyncStatus.pending),
             ),
           );
        }
      }
    });
  }

  @override
  Future<void> deleteCustomCategory(int id) async {
    final category = await (_db.select(_db.expenseCategories)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (category == null) return;
    if (category.isDefault) {
      throw StateError('Cannot delete a built-in category.');
    }
    
    // Check if in use
    final countExp = _db.transactions.id.count();
    final query = _db.selectOnly(_db.transactions)
      ..addColumns([countExp])
      ..where(_db.transactions.category.equals(category.name));
    final count = await query.map((row) => row.read(countExp)).getSingle();
    
    if (count != null && count > 0) {
      throw StateError('Cannot delete this category because it is used by $count transaction(s). Reassign them first.');
    }
    
    await (_db.delete(_db.expenseCategories)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<void> saveRule(String merchantKey, String category) async {
    final now = DateTime.now();
    await _db.into(_db.categoryRules).insert(
      CategoryRulesCompanion.insert(
        merchantKey: merchantKey.trim().toLowerCase(),
        category: category.trim(),
        createdAt: now,
        updatedAt: now,
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  @override
  Future<String?> getCategoryForMerchant(String merchantKey) async {
    final rule = await (_db.select(_db.categoryRules)
          ..where((t) => t.merchantKey.equals(merchantKey.trim().toLowerCase())))
        .getSingleOrNull();
    return rule?.category;
  }
}
