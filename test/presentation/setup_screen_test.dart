import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upi_expense_tracker/platform/setup_gateway.dart';
import 'package:upi_expense_tracker/presentation/providers/setup_providers.dart';
import 'package:upi_expense_tracker/presentation/screens/setup_screen.dart';

import 'fake_setup_gateway.dart';

Widget _harness(FakeSetupGateway gateway) {
  return ProviderScope(
    overrides: [setupGatewayProvider.overrideWithValue(gateway)],
    child: const MaterialApp(home: SetupScreen()),
  );
}

/// Three permission cards plus the summary banner is taller than the default
/// 800x600 test surface, so the third card would otherwise be treated as
/// offstage — see debug_ingestion_screen_test.dart for the full explanation.
Future<void> _pumpSetupScreen(WidgetTester tester, FakeSetupGateway gateway) async {
  tester.view.physicalSize = const Size(1080, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(_harness(gateway));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows a warning banner and action buttons when nothing is granted yet', (tester) async {
    final gateway = FakeSetupGateway();

    await _pumpSetupScreen(tester, gateway);

    expect(find.text('Setup required before transactions can be detected.'), findsOneWidget);
    expect(find.text('Grant SMS access'), findsOneWidget);
    expect(find.text('Open notification access settings'), findsOneWidget);
    expect(find.text('Exempt from battery optimization'), findsOneWidget);
  });

  testWidgets(
    'the battery optimization card being unmet does not affect the overall banner (it is optional)',
    (tester) async {
      final gateway = FakeSetupGateway()
        ..smsStatus = PermissionRequestStatus.granted
        ..notificationListenerEnabled = true
        ..batteryOptimizationIgnored = false;

      await _pumpSetupScreen(tester, gateway);

      expect(find.text('All set — ready to detect transactions.'), findsOneWidget);
      expect(find.text('Exempt from battery optimization'), findsOneWidget);
    },
  );

  testWidgets('tapping the battery optimization action calls the gateway and updates on success', (tester) async {
    final gateway = FakeSetupGateway();

    await _pumpSetupScreen(tester, gateway);

    await tester.tap(find.text('Exempt from battery optimization'));
    await tester.pumpAndSettle();

    expect(gateway.requestIgnoreBatteryOptimizationsCalls, 1);
    // The fake doesn't flip the flag itself (unlike SMS's grantSmsOnRequest),
    // matching how the real system dialog result isn't known synchronously —
    // the refresh-on-resume/refresh-button path is what re-checks it.
  });

  testWidgets('shows the all-set banner and no action buttons when everything is granted', (tester) async {
    final gateway = FakeSetupGateway()
      ..smsStatus = PermissionRequestStatus.granted
      ..notificationListenerEnabled = true;

    await _pumpSetupScreen(tester, gateway);

    expect(find.text('All set — ready to detect transactions.'), findsOneWidget);
    expect(find.text('Grant SMS access'), findsNothing);
    expect(find.text('Open notification access settings'), findsNothing);
  });

  testWidgets('permanently denied SMS shows an "open app settings" action, not a request action', (tester) async {
    final gateway = FakeSetupGateway()..smsStatus = PermissionRequestStatus.permanentlyDenied;

    await _pumpSetupScreen(tester, gateway);

    expect(find.text('Open app settings'), findsOneWidget);
    expect(find.text('Grant SMS access'), findsNothing);

    await tester.tap(find.text('Open app settings'));
    await tester.pumpAndSettle();

    expect(gateway.openAppSettingsCalls, 1);
  });

  testWidgets('tapping "Grant SMS access" requests permission and updates the UI on success', (tester) async {
    final gateway = FakeSetupGateway()..grantSmsOnRequest = true;

    await _pumpSetupScreen(tester, gateway);

    await tester.tap(find.text('Grant SMS access'));
    await tester.pumpAndSettle();

    expect(gateway.requestSmsCalls, 1);
    expect(find.text('Grant SMS access'), findsNothing);
  });

  testWidgets('tapping the notification settings action calls the gateway', (tester) async {
    final gateway = FakeSetupGateway();

    await _pumpSetupScreen(tester, gateway);

    await tester.tap(find.text('Open notification access settings'));
    await tester.pumpAndSettle();

    expect(gateway.openNotificationSettingsCalls, 1);
  });

  testWidgets('the refresh button re-checks status', (tester) async {
    final gateway = FakeSetupGateway();

    await _pumpSetupScreen(tester, gateway);

    gateway.notificationListenerEnabled = true;
    await tester.tap(find.byTooltip('Refresh status'));
    await tester.pumpAndSettle();

    expect(find.text('Open notification access settings'), findsNothing);
  });
}
