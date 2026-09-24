import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upi_expense_tracker/data/local/app_database.dart';
import 'package:upi_expense_tracker/presentation/providers/app_providers.dart';

AppDatabase newInMemoryTestDatabase() => AppDatabase.forTesting(NativeDatabase.memory());

/// Any screen that watches a Drift-backed stream provider needs this same
/// pair of workarounds under `flutter_test` (see debug_ingestion_screen_test
/// for the full root-cause explanation):
///  - a tall virtual viewport, so content below the default 600px fold isn't
///    treated as offstage;
///  - disposing the tree and pumping once more at the very end of the test
///    (via [disposeAndFlushDriftTimer], not addTearDown) so Drift's watched-
///    stream-cancellation Timer fires before flutter_test's "no pending
///    timers" check runs.
Future<void> pumpDriftScreen(
  WidgetTester tester,
  AppDatabase db,
  Widget child, {
  List<Override> extraOverrides = const [],
}) async {
  tester.view.physicalSize = const Size(1080, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(ProviderScope(
    overrides: [appDatabaseProvider.overrideWithValue(db), ...extraOverrides],
    child: MaterialApp(home: child),
  ));
  await tester.pumpAndSettle();
}

/// Must be called at the very end of each test body — see [pumpDriftScreen].
Future<void> disposeAndFlushDriftTimer(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 10));
}
