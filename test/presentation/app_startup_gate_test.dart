import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upi_expense_tracker/data/drift_sync_settings_repository.dart';
import 'package:upi_expense_tracker/domain/models/sync_status.dart';
import 'package:upi_expense_tracker/presentation/providers/sync_providers.dart';
import 'package:upi_expense_tracker/presentation/screens/app_startup_gate.dart';
import 'package:upi_expense_tracker/presentation/screens/dashboard_screen.dart';
import 'package:upi_expense_tracker/presentation/screens/first_launch_sync_choice_screen.dart';
import 'package:upi_expense_tracker/presentation/screens/google_sheets_setup_screen.dart';

import '../sync/fake_google_auth_gateway.dart';
import 'test_harness.dart';

/// This gate can land on GoogleSheetsSetupScreen, which calls
/// GoogleAuthGateway.currentAccountEmail() in initState — always override it
/// so no test touches the real (platform-channel-backed) implementation.
List<Override> _fakeAuthOverride() => [googleAuthGatewayProvider.overrideWithValue(FakeGoogleAuthGateway())];

void main() {
  testWidgets('a fresh (NOT_CONFIGURED) database shows the first-launch choice, not the dashboard', (tester) async {
    final db = newInMemoryTestDatabase();
    addTearDown(db.close);

    await pumpDriftScreen(tester, db, const AppStartupGate(), extraOverrides: _fakeAuthOverride());

    expect(find.byType(FirstLaunchSyncChoiceScreen), findsOneWidget);
    expect(find.byType(DashboardScreen), findsNothing);

    await disposeAndFlushDriftTimer(tester);
  });

  testWidgets('a database already migrated to LOCAL_ONLY goes straight to the dashboard', (tester) async {
    final db = newInMemoryTestDatabase();
    addTearDown(db.close);
    await DriftSyncSettingsRepository(db).setSyncPreference(SyncPreference.localOnly);

    await pumpDriftScreen(tester, db, const AppStartupGate(), extraOverrides: _fakeAuthOverride());

    expect(find.byType(DashboardScreen), findsOneWidget);
    expect(find.byType(FirstLaunchSyncChoiceScreen), findsNothing);

    await disposeAndFlushDriftTimer(tester);
  });

  testWidgets(
    'GOOGLE_SHEETS but not yet connected goes to the setup flow, never the dashboard — '
    'never claim connected/synced before it is real',
    (tester) async {
      final db = newInMemoryTestDatabase();
      addTearDown(db.close);
      await DriftSyncSettingsRepository(db).setSyncPreference(SyncPreference.googleSheets);

      await pumpDriftScreen(tester, db, const AppStartupGate(), extraOverrides: _fakeAuthOverride());

      expect(find.byType(GoogleSheetsSetupScreen), findsOneWidget);
      expect(find.byType(DashboardScreen), findsNothing);
      expect(find.byType(FirstLaunchSyncChoiceScreen), findsNothing);

      await disposeAndFlushDriftTimer(tester);
    },
  );

  testWidgets('GOOGLE_SHEETS and actually connected goes straight to the dashboard', (tester) async {
    final db = newInMemoryTestDatabase();
    addTearDown(db.close);
    final repo = DriftSyncSettingsRepository(db);
    await repo.setSyncPreference(SyncPreference.googleSheets);
    await repo.setConnectionState(GoogleConnectionState.connected);

    await pumpDriftScreen(tester, db, const AppStartupGate(), extraOverrides: _fakeAuthOverride());

    expect(find.byType(DashboardScreen), findsOneWidget);
    expect(find.byType(GoogleSheetsSetupScreen), findsNothing);

    await disposeAndFlushDriftTimer(tester);
  });

  testWidgets('choosing "Not Now" reactively swaps to the dashboard with no manual navigation', (tester) async {
    final db = newInMemoryTestDatabase();
    addTearDown(db.close);

    await pumpDriftScreen(tester, db, const AppStartupGate(), extraOverrides: _fakeAuthOverride());
    expect(find.byType(FirstLaunchSyncChoiceScreen), findsOneWidget);

    await tester.tap(find.text('Not Now'));
    await tester.pumpAndSettle();

    expect(find.byType(DashboardScreen), findsOneWidget);
    expect(find.byType(FirstLaunchSyncChoiceScreen), findsNothing);

    final settings = await DriftSyncSettingsRepository(db).getSettings();
    expect(settings.syncPreference, SyncPreference.localOnly);

    await disposeAndFlushDriftTimer(tester);
  });

  testWidgets(
    'choosing "Yes, Sync with Google Sheets" reactively swaps to the setup flow, not the dashboard',
    (tester) async {
      final db = newInMemoryTestDatabase();
      addTearDown(db.close);

      await pumpDriftScreen(tester, db, const AppStartupGate(), extraOverrides: _fakeAuthOverride());

      await tester.tap(find.text('Yes, Sync with Google Sheets'));
      await tester.pumpAndSettle();

      expect(find.byType(GoogleSheetsSetupScreen), findsOneWidget);
      expect(
        find.byType(DashboardScreen),
        findsNothing,
        reason: 'must not reach the dashboard until Google Sheets setup actually completes',
      );

      final settings = await DriftSyncSettingsRepository(db).getSettings();
      expect(settings.syncPreference, SyncPreference.googleSheets);
      expect(
        settings.connectionState,
        GoogleConnectionState.disconnected,
        reason: 'choosing to sync only records intent — no auth has happened at this milestone',
      );

      await disposeAndFlushDriftTimer(tester);
    },
  );

  testWidgets('"Skip for now" on the setup screen falls back to local-only and reaches the dashboard', (tester) async {
    final db = newInMemoryTestDatabase();
    addTearDown(db.close);

    await pumpDriftScreen(tester, db, const AppStartupGate(), extraOverrides: _fakeAuthOverride());
    await tester.tap(find.text('Yes, Sync with Google Sheets'));
    await tester.pumpAndSettle();
    expect(find.byType(GoogleSheetsSetupScreen), findsOneWidget);

    await tester.tap(find.text('Skip for now — keep my data local'));
    await tester.pumpAndSettle();

    expect(find.byType(DashboardScreen), findsOneWidget);

    final settings = await DriftSyncSettingsRepository(db).getSettings();
    expect(settings.syncPreference, SyncPreference.localOnly);

    await disposeAndFlushDriftTimer(tester);
  });

  testWidgets('re-launching against a database that already has a choice never shows the prompt again', (tester) async {
    final db = newInMemoryTestDatabase();
    addTearDown(db.close);

    // First "launch": make the choice.
    await pumpDriftScreen(tester, db, const AppStartupGate(), extraOverrides: _fakeAuthOverride());
    await tester.tap(find.text('Not Now'));
    await tester.pumpAndSettle();
    await disposeAndFlushDriftTimer(tester);

    // Second "launch" against the same (now-configured) database.
    await pumpDriftScreen(tester, db, const AppStartupGate(), extraOverrides: _fakeAuthOverride());

    expect(find.byType(DashboardScreen), findsOneWidget);
    expect(find.byType(FirstLaunchSyncChoiceScreen), findsNothing);

    await disposeAndFlushDriftTimer(tester);
  });
}
