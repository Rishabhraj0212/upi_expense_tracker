import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upi_expense_tracker/data/drift_transaction_repository.dart';
import 'package:upi_expense_tracker/domain/models/transaction_type.dart';
import 'package:upi_expense_tracker/presentation/screens/dashboard_screen.dart';
import 'package:upi_expense_tracker/presentation/screens/record_transaction_screen.dart';
import 'package:upi_expense_tracker/presentation/screens/transaction_list_screen.dart';

import 'test_harness.dart';

void main() {
  testWidgets('records a manual transaction and it appears in database', (tester) async {
    final db = newInMemoryTestDatabase();
    addTearDown(db.close);
    final repo = DriftTransactionRepository(db);

    await pumpDriftScreen(tester, db, const RecordTransactionScreen());

    // Enter amount
    await tester.enterText(find.byType(TextFormField).first, '250.50');
    // Enter merchant
    await tester.enterText(find.widgetWithText(TextFormField, 'Payee / Merchant / Description'), 'Supermarket');

    // Tap record
    await tester.tap(find.byKey(const Key('record_transaction_button')));
    await tester.pumpAndSettle();

    // Verify stored in DB
    final all = await repo.getAll();
    expect(all.length, 1);
    expect(all.first.amountPaise, 25050);
    expect(all.first.type, TransactionType.debit);
    expect(all.first.merchantName, 'Supermarket');

    await disposeAndFlushDriftTimer(tester);
  });

  testWidgets('auto-fills transaction details from pasted SMS text', (tester) async {
    final db = newInMemoryTestDatabase();
    addTearDown(db.close);

    await pumpDriftScreen(tester, db, const RecordTransactionScreen());

    // Expand SMS helper
    await tester.tap(find.text('Auto-fill from SMS / Message text'));
    await tester.pumpAndSettle();

    // Paste SMS
    const sms = 'Dear BOB UPI User: Your account is credited with INR 5.00 on 2026-09-28 08:14:23 AM by UPI Ref No 627114110535; AvlBal: Rs11651.87 - BOB';
    await tester.enterText(find.byType(TextField).last, sms);

    // Tap Parse & Auto-fill
    await tester.tap(find.text('Parse & Auto-fill'));
    await tester.pumpAndSettle();

    // Amount should be filled
    expect(find.text('5.00'), findsOneWidget);

    await disposeAndFlushDriftTimer(tester);
  });

  testWidgets('recorded transaction immediately shows in Recent Transactions and Transaction List', (tester) async {
    final db = newInMemoryTestDatabase();
    addTearDown(db.close);

    // 1. Show Dashboard
    await pumpDriftScreen(tester, db, const DashboardScreen());

    // Tap Floating Action Button to record
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.byType(RecordTransactionScreen), findsOneWidget);

    // Enter amount and merchant
    await tester.enterText(find.byType(TextFormField).first, '120.00');
    await tester.enterText(find.widgetWithText(TextFormField, 'Payee / Merchant / Description'), 'Coffee Shop');

    // Save
    await tester.tap(find.byKey(const Key('record_transaction_button')));
    await tester.pumpAndSettle();

    // Should return to Dashboard and show in Recent Transactions!
    expect(find.byType(DashboardScreen), findsOneWidget);
    expect(find.text('Coffee Shop'), findsOneWidget);
    expect(find.text('₹120'), findsOneWidget);

    // Navigate to Transaction List
    await tester.tap(find.text('See all'));
    await tester.pumpAndSettle();

    // Should appear in Transaction List Screen too!
    expect(find.byType(TransactionListScreen), findsOneWidget);
    expect(find.text('Coffee Shop'), findsOneWidget);

    await disposeAndFlushDriftTimer(tester);
  });
}
