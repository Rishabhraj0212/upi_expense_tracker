import 'package:flutter_test/flutter_test.dart';
import 'package:upi_expense_tracker/data/drift_transaction_repository.dart';
import 'package:upi_expense_tracker/domain/models/parsed_transaction.dart';
import 'package:upi_expense_tracker/domain/models/transaction_source.dart';
import 'package:upi_expense_tracker/domain/models/transaction_type.dart';
import 'package:upi_expense_tracker/presentation/providers/setup_providers.dart';
import 'package:upi_expense_tracker/presentation/screens/dashboard_screen.dart';
import 'package:upi_expense_tracker/presentation/screens/setup_screen.dart';
import 'package:upi_expense_tracker/presentation/screens/transaction_detail_screen.dart';
import 'package:upi_expense_tracker/presentation/screens/transaction_list_screen.dart';

import 'fake_setup_gateway.dart';
import 'test_harness.dart';

ParsedTransaction _parsed({
  required int amountPaise,
  required TransactionType type,
  required DateTime occurredAt,
  String? merchantName,
}) {
  return ParsedTransaction(
    amountPaise: amountPaise,
    type: type,
    occurredAt: occurredAt,
    sourceType: SourceType.sms,
    rawText: 'raw text for $merchantName',
    merchantName: merchantName,
  );
}

void main() {
  testWidgets('shows the empty state and can navigate to Setup from it', (tester) async {
    final db = newInMemoryTestDatabase();
    addTearDown(db.close);

    await pumpDriftScreen(
      tester,
      db,
      const DashboardScreen(),
      extraOverrides: [setupGatewayProvider.overrideWithValue(FakeSetupGateway())],
    );

    expect(find.textContaining('No transactions yet'), findsOneWidget);

    await tester.tap(find.text('Check permissions'));
    await tester.pumpAndSettle();

    expect(find.byType(SetupScreen), findsOneWidget);

    await disposeAndFlushDriftTimer(tester);
  });

  testWidgets('shows correct totals and a recent transaction preview for current month by default', (tester) async {
    final db = newInMemoryTestDatabase();
    addTearDown(db.close);
    final repo = DriftTransactionRepository(db);
    final now = DateTime.now();
    await repo.insert(_parsed(
      amountPaise: 10000,
      type: TransactionType.debit,
      occurredAt: DateTime(now.year, now.month, 1),
      merchantName: 'Tea Stall',
    ));
    await repo.insert(_parsed(
      amountPaise: 5000,
      type: TransactionType.debit,
      occurredAt: DateTime(now.year, now.month, 2),
      merchantName: 'Coffee Shop',
    ));
    await repo.insert(_parsed(
      amountPaise: 20000,
      type: TransactionType.credit,
      occurredAt: DateTime(now.year, now.month, 3),
      merchantName: 'Employer',
    ));

    await pumpDriftScreen(tester, db, const DashboardScreen());

    expect(find.text('₹150'), findsOneWidget); // total debit: 100 + 50
    expect(find.text('₹200'), findsOneWidget); // total credit
    expect(find.text('Tea Stall'), findsOneWidget);
    expect(find.text('Coffee Shop'), findsOneWidget);
    expect(find.text('Employer'), findsOneWidget);

    await disposeAndFlushDriftTimer(tester);
  });

  testWidgets('defaults to current month and toggles to all time', (tester) async {
    final db = newInMemoryTestDatabase();
    addTearDown(db.close);
    final repo = DriftTransactionRepository(db);
    final now = DateTime.now();

    // Previous year transaction
    await repo.insert(_parsed(
      amountPaise: 50000,
      type: TransactionType.debit,
      occurredAt: DateTime(now.year - 1, 1, 1),
      merchantName: 'Old Laptop',
    ));

    // Current month transaction
    await repo.insert(_parsed(
      amountPaise: 10000,
      type: TransactionType.debit,
      occurredAt: DateTime(now.year, now.month, 1),
      merchantName: 'Tea Stall',
    ));

    await pumpDriftScreen(tester, db, const DashboardScreen());

    // By default, only current month is shown (₹100, not ₹600)
    expect(find.text('₹100'), findsOneWidget);
    expect(find.text('Tea Stall'), findsOneWidget);
    expect(find.text('Old Laptop'), findsNothing);

    // Switch to All Time
    await tester.tap(find.text('All Time'));
    await tester.pumpAndSettle();

    expect(find.text('₹600'), findsOneWidget);
    expect(find.text('Old Laptop'), findsOneWidget);

    await disposeAndFlushDriftTimer(tester);
  });

  testWidgets('"See all" navigates to the transaction list screen', (tester) async {
    final db = newInMemoryTestDatabase();
    addTearDown(db.close);
    final repo = DriftTransactionRepository(db);
    final now = DateTime.now();
    await repo.insert(_parsed(
      amountPaise: 10000,
      type: TransactionType.debit,
      occurredAt: DateTime(now.year, now.month, 1),
      merchantName: 'Tea Stall',
    ));

    await pumpDriftScreen(tester, db, const DashboardScreen());

    await tester.tap(find.text('See all'));
    await tester.pumpAndSettle();

    expect(find.byType(TransactionListScreen), findsOneWidget);

    await disposeAndFlushDriftTimer(tester);
  });

  testWidgets('tapping a recent transaction opens its detail screen', (tester) async {
    final db = newInMemoryTestDatabase();
    addTearDown(db.close);
    final repo = DriftTransactionRepository(db);
    final now = DateTime.now();
    await repo.insert(_parsed(
      amountPaise: 10000,
      type: TransactionType.debit,
      occurredAt: DateTime(now.year, now.month, 1),
      merchantName: 'Tea Stall',
    ));

    await pumpDriftScreen(tester, db, const DashboardScreen());

    await tester.tap(find.text('Tea Stall'));
    await tester.pumpAndSettle();

    expect(find.byType(TransactionDetailScreen), findsOneWidget);

    await disposeAndFlushDriftTimer(tester);
  });
}
