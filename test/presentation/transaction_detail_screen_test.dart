import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upi_expense_tracker/data/drift_transaction_repository.dart';
import 'package:upi_expense_tracker/domain/models/parsed_transaction.dart';
import 'package:upi_expense_tracker/domain/models/transaction_source.dart';
import 'package:upi_expense_tracker/domain/models/transaction_type.dart';
import 'package:upi_expense_tracker/presentation/screens/transaction_detail_screen.dart';

import 'test_harness.dart';

void main() {
  testWidgets('shows the transaction fields', (tester) async {
    final db = newInMemoryTestDatabase();
    addTearDown(db.close);
    final repo = DriftTransactionRepository(db);
    final id = await repo.insert(ParsedTransaction(
      amountPaise: 25000,
      type: TransactionType.debit,
      occurredAt: DateTime(2026, 1, 15, 10, 30),
      sourceType: SourceType.sms,
      rawText: 'Rs.250.00 debited from A/c XX1234 to Tea Stall Ref No 302615478321 -HDFC Bank',
      merchantName: 'Tea Stall',
      bankName: 'HDFC Bank',
      accountHint: 'XX1234',
      referenceId: '302615478321',
      sourceAddress: 'HDFCBK',
    ));
    final tx = (await repo.getById(id))!;

    await pumpDriftScreen(tester, db, TransactionDetailScreen(transaction: tx));

    expect(find.text('-₹250'), findsOneWidget);
    expect(find.text('Debit'), findsOneWidget);
    expect(find.text('Tea Stall'), findsWidgets);
    expect(find.text('HDFC Bank'), findsOneWidget);
    expect(find.text('XX1234'), findsOneWidget);
    expect(find.text('302615478321'), findsOneWidget);
    expect(find.text('HDFCBK'), findsOneWidget);
    expect(find.textContaining('Rs.250.00 debited'), findsOneWidget);

    await disposeAndFlushDriftTimer(tester);
  });

  testWidgets('deleting asks for confirmation, then removes the row and pops back', (tester) async {
    final db = newInMemoryTestDatabase();
    addTearDown(db.close);
    final repo = DriftTransactionRepository(db);
    final id = await repo.insert(ParsedTransaction(
      amountPaise: 10000,
      type: TransactionType.debit,
      occurredAt: DateTime(2026, 1, 15),
      sourceType: SourceType.sms,
      rawText: 'raw',
      merchantName: 'Tea Stall',
    ));
    final tx = (await repo.getById(id))!;

    // Host the detail screen behind a "home" route so a real pop is observable.
    final navigatorKey = GlobalKey<NavigatorState>();
    await pumpDriftScreen(
      tester,
      db,
      Navigator(
        key: navigatorKey,
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => navigatorKey.currentState!.push(
                  MaterialPageRoute(builder: (_) => TransactionDetailScreen(transaction: tx)),
                ),
                child: const Text('Open detail'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open detail'));
    await tester.pumpAndSettle();
    expect(find.byType(TransactionDetailScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(find.text('Delete transaction?'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.byType(TransactionDetailScreen), findsNothing);
    expect(find.text('Open detail'), findsOneWidget);
    expect(await repo.getById(id), isNull);

    await disposeAndFlushDriftTimer(tester);
  });

  testWidgets('canceling the delete dialog keeps the transaction', (tester) async {
    final db = newInMemoryTestDatabase();
    addTearDown(db.close);
    final repo = DriftTransactionRepository(db);
    final id = await repo.insert(ParsedTransaction(
      amountPaise: 10000,
      type: TransactionType.debit,
      occurredAt: DateTime(2026, 1, 15),
      sourceType: SourceType.sms,
      rawText: 'raw',
      merchantName: 'Tea Stall',
    ));
    final tx = (await repo.getById(id))!;

    await pumpDriftScreen(tester, db, TransactionDetailScreen(transaction: tx));

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.byType(TransactionDetailScreen), findsOneWidget);
    expect(await repo.getById(id), isNotNull);

    await disposeAndFlushDriftTimer(tester);
  });
}
