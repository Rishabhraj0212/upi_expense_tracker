import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upi_expense_tracker/data/drift_category_repository.dart';
import 'package:upi_expense_tracker/data/drift_transaction_repository.dart';
import 'package:upi_expense_tracker/data/local/app_database.dart';
import 'package:upi_expense_tracker/domain/models/parsed_transaction.dart';
import 'package:upi_expense_tracker/domain/models/sync_status.dart';
import 'package:upi_expense_tracker/domain/models/transaction_source.dart';
import 'package:upi_expense_tracker/domain/models/transaction_type.dart';

void main() {
  late AppDatabase db;
  late DriftCategoryRepository categoryRepo;
  late DriftTransactionRepository transactionRepo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    categoryRepo = DriftCategoryRepository(db);
    transactionRepo = DriftTransactionRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('adds and retrieves a custom category', () async {
    final cat = await categoryRepo.addCustomCategory('Custom 1');
    expect(cat.name, 'Custom 1');
    expect(cat.isDefault, isFalse);

    final all = await categoryRepo.getAllCategories();
    expect(all.map((c) => c.name), contains('Custom 1'));
  });

  test('prevents duplicate category names', () async {
    await categoryRepo.addCustomCategory('Custom 1');
    expect(() => categoryRepo.addCustomCategory('custom 1'), throwsA(isA<StateError>()));
    expect(() => categoryRepo.addCustomCategory('  Custom 1  '), throwsA(isA<StateError>()));
  });

  test('updateCustomCategory updates name and modifies transactions', () async {
    final cat = await categoryRepo.addCustomCategory('OldName');
    
    // Insert a transaction with this category
    final id1 = await transactionRepo.insert(ParsedTransaction(
      amountPaise: 100,
      type: TransactionType.debit,
      occurredAt: DateTime.now(),
      sourceType: SourceType.sms,
      rawText: 'text1',
    ));
    await transactionRepo.setCategory(id1, 'OldName', null);

    // markSynced so we can see it flip back to pending
    await transactionRepo.markSynced(id1, syncedAt: DateTime.now());
    var tx = await transactionRepo.getById(id1);
    expect(tx!.syncStatus, TransactionSyncStatus.synced);
    expect(tx.category, 'OldName');

    // Rename the category
    await categoryRepo.updateCustomCategory(cat.id, 'NewName');

    final updatedCat = (await categoryRepo.getAllCategories()).firstWhere((c) => c.id == cat.id);
    expect(updatedCat.name, 'NewName');

    // Transaction should be updated and marked pending
    tx = await transactionRepo.getById(id1);
    expect(tx!.category, 'NewName');
    expect(tx.syncStatus, TransactionSyncStatus.pending);
  });

  test('deleteCustomCategory throws if in use', () async {
    final cat = await categoryRepo.addCustomCategory('UsedCat');
    final id1 = await transactionRepo.insert(ParsedTransaction(
      amountPaise: 100,
      type: TransactionType.debit,
      occurredAt: DateTime.now(),
      sourceType: SourceType.sms,
      rawText: 'text1',
    ));
    await transactionRepo.setCategory(id1, 'UsedCat', null);

    expect(() => categoryRepo.deleteCustomCategory(cat.id), throwsA(isA<StateError>()));
  });

  test('deleteCustomCategory succeeds if not in use', () async {
    final cat = await categoryRepo.addCustomCategory('UnusedCat');
    await categoryRepo.deleteCustomCategory(cat.id);
    
    final all = await categoryRepo.getAllCategories();
    expect(all.map((c) => c.name), isNot(contains('UnusedCat')));
  });
}
