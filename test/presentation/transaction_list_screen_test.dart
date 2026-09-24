import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upi_expense_tracker/data/drift_transaction_repository.dart';
import 'package:upi_expense_tracker/data/local/app_database.dart';
import 'package:upi_expense_tracker/domain/models/parsed_transaction.dart';
import 'package:upi_expense_tracker/domain/models/transaction_source.dart';
import 'package:upi_expense_tracker/domain/models/transaction_type.dart';
import 'package:upi_expense_tracker/presentation/screens/transaction_detail_screen.dart';
import 'package:upi_expense_tracker/presentation/screens/transaction_list_screen.dart';

import 'test_harness.dart';

ParsedTransaction _parsed({
  required int amountPaise,
  required TransactionType type,
  required DateTime occurredAt,
  String? merchantName,
  String? upiId,
}) {
  return ParsedTransaction(
    amountPaise: amountPaise,
    type: type,
    occurredAt: occurredAt,
    sourceType: SourceType.sms,
    rawText: 'raw text for $merchantName$upiId',
    merchantName: merchantName,
    upiId: upiId,
  );
}

Future<DriftTransactionRepository> _seed(AppDatabase db) async {
  final repo = DriftTransactionRepository(db);
  await repo.insert(_parsed(
    amountPaise: 10000,
    type: TransactionType.debit,
    occurredAt: DateTime(2026, 1, 1),
    merchantName: 'Tea Stall',
    upiId: 'teastall@ybl',
  ));
  await repo.insert(_parsed(
    amountPaise: 20000,
    type: TransactionType.credit,
    occurredAt: DateTime(2026, 1, 2),
    merchantName: 'Employer',
    upiId: 'employer@okaxis',
  ));
  return repo;
}

void main() {
  testWidgets('shows every transaction by default', (tester) async {
    final db = newInMemoryTestDatabase();
    addTearDown(db.close);
    await _seed(db);

    await pumpDriftScreen(tester, db, const TransactionListScreen());

    expect(find.text('Tea Stall'), findsOneWidget);
    expect(find.text('Employer'), findsOneWidget);

    await disposeAndFlushDriftTimer(tester);
  });

  testWidgets('the Debit chip narrows the list to debits only', (tester) async {
    final db = newInMemoryTestDatabase();
    addTearDown(db.close);
    await _seed(db);

    await pumpDriftScreen(tester, db, const TransactionListScreen());

    await tester.tap(find.text('Debit'));
    await tester.pumpAndSettle();

    expect(find.text('Tea Stall'), findsOneWidget);
    expect(find.text('Employer'), findsNothing);

    await disposeAndFlushDriftTimer(tester);
  });

  testWidgets('the Credit chip narrows the list to credits only', (tester) async {
    final db = newInMemoryTestDatabase();
    addTearDown(db.close);
    await _seed(db);

    await pumpDriftScreen(tester, db, const TransactionListScreen());

    await tester.tap(find.text('Credit'));
    await tester.pumpAndSettle();

    expect(find.text('Employer'), findsOneWidget);
    expect(find.text('Tea Stall'), findsNothing);

    await disposeAndFlushDriftTimer(tester);
  });

  testWidgets('search text narrows the list by merchant/UPI id/raw text', (tester) async {
    final db = newInMemoryTestDatabase();
    addTearDown(db.close);
    await _seed(db);

    await pumpDriftScreen(tester, db, const TransactionListScreen());

    await tester.enterText(find.byType(TextField), 'employer');
    await tester.pumpAndSettle();

    expect(find.text('Employer'), findsOneWidget);
    expect(find.text('Tea Stall'), findsNothing);

    await disposeAndFlushDriftTimer(tester);
  });

  testWidgets('shows a message when no transaction matches the filter', (tester) async {
    final db = newInMemoryTestDatabase();
    addTearDown(db.close);
    await _seed(db);

    await pumpDriftScreen(tester, db, const TransactionListScreen());

    await tester.enterText(find.byType(TextField), 'nonexistent merchant');
    await tester.pumpAndSettle();

    expect(find.text('No transactions match this filter.'), findsOneWidget);

    await disposeAndFlushDriftTimer(tester);
  });

  testWidgets('tapping a tile opens its detail screen', (tester) async {
    final db = newInMemoryTestDatabase();
    addTearDown(db.close);
    await _seed(db);

    await pumpDriftScreen(tester, db, const TransactionListScreen());

    await tester.tap(find.text('Tea Stall'));
    await tester.pumpAndSettle();

    expect(find.byType(TransactionDetailScreen), findsOneWidget);

    await disposeAndFlushDriftTimer(tester);
  });
}
