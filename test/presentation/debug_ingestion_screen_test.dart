import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upi_expense_tracker/data/local/app_database.dart';
import 'package:upi_expense_tracker/presentation/providers/app_providers.dart';
import 'package:upi_expense_tracker/presentation/screens/debug_ingestion_screen.dart';

/// Exercises the real widget tree (no mocked ingestion pipeline) with an
/// in-memory database swapped in for the on-disk one, since path_provider
/// has no platform implementation under `flutter test`.
///
/// Two test-harness quirks handled here, neither of which is an app bug:
///  - The screen's content is taller than the default 800x600 test surface,
///    so anything below the fold would otherwise be treated as offstage —
///    fixed with a tall virtual viewport.
///  - Drift's watched-stream cancellation (which happens when ProviderScope
///    disposes at teardown) schedules a real zero-duration Timer. flutter_test
///    asserts no timers are left pending when a test ends, so we dispose the
///    tree ourselves and pump once more to let that timer fire first.
Future<void> _pumpHarness(WidgetTester tester, AppDatabase db) async {
  tester.view.physicalSize = const Size(1080, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(ProviderScope(
    overrides: [appDatabaseProvider.overrideWithValue(db)],
    child: const MaterialApp(home: DebugIngestionScreen()),
  ));
  await tester.pumpAndSettle();
}

/// Must be called at the very end of each test body (not via addTearDown —
/// flutter_test's pending-timers check runs before addTearDown callbacks are
/// awaited). See the class-level doc comment above for why this is needed.
Future<void> _disposeAndFlushDriftTimer(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 10));
}

Future<void> _submitAndSettle(WidgetTester tester) async {
  // FilledButton.icon(...) returns a private subclass, and find.byType
  // (which widgetWithText relies on) matches exact runtimeType — so we find
  // the button by tapping its label text instead.
  await tester.tap(find.text('Run through pipeline'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('loading the HDFC sample and submitting inserts and displays a transaction', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await _pumpHarness(tester, db);

    expect(find.text('No transactions yet.'), findsOneWidget);

    await tester.tap(find.widgetWithText(ActionChip, 'HDFC debit'));
    await tester.pumpAndSettle();

    await _submitAndSettle(tester);

    expect(find.textContaining('Inserted new transaction'), findsOneWidget);
    expect(find.text('No transactions yet.'), findsNothing);
    expect(find.text('merchant@ybl'), findsOneWidget);

    await _disposeAndFlushDriftTimer(tester);
  });

  testWidgets('submitting an OTP sample shows it was ignored and adds no transaction', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await _pumpHarness(tester, db);

    await tester.tap(find.widgetWithText(ActionChip, 'OTP (should be ignored)'));
    await tester.pumpAndSettle();

    await _submitAndSettle(tester);

    expect(find.textContaining('Ignored'), findsOneWidget);
    expect(find.text('No transactions yet.'), findsOneWidget);

    await _disposeAndFlushDriftTimer(tester);
  });

  testWidgets('the same payment via SMS then a matching notification merges into one row', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await _pumpHarness(tester, db);

    // First: the SBI SMS sample.
    await tester.tap(find.widgetWithText(ActionChip, 'SBI debit (quirky format)'));
    await tester.pumpAndSettle();
    await _submitAndSettle(tester);
    expect(find.textContaining('Inserted new transaction'), findsOneWidget);

    // Then: switch to a notification carrying the *same reference id* as the
    // SBI SMS above, so dedup matches on reference id rather than timing
    // (the SBI SMS's parsed date and "now" won't be within the merge window).
    await tester.tap(find.text('Notification'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Notification package name'),
      'net.one97.paytm',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Raw message text'),
      'Payment successful | ₹300 paid to Tea Stall Ref No 302615478321',
    );
    await tester.pumpAndSettle();
    await _submitAndSettle(tester);

    expect(find.textContaining('Merged into existing transaction'), findsOneWidget);

    await _disposeAndFlushDriftTimer(tester);
  });
}
