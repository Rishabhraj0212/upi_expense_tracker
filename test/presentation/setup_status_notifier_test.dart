import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upi_expense_tracker/platform/setup_gateway.dart';
import 'package:upi_expense_tracker/presentation/providers/setup_providers.dart';

import 'fake_setup_gateway.dart';

void main() {
  late FakeSetupGateway gateway;
  late ProviderContainer container;

  setUp(() {
    gateway = FakeSetupGateway();
    container = ProviderContainer(overrides: [setupGatewayProvider.overrideWithValue(gateway)]);
    addTearDown(container.dispose);
  });

  test('build loads the initial status from the gateway', () async {
    gateway.smsStatus = PermissionRequestStatus.denied;
    gateway.notificationListenerEnabled = false;

    final status = await container.read(setupStatusProvider.future);

    expect(status.sms, PermissionRequestStatus.denied);
    expect(status.notificationListenerEnabled, isFalse);
  });

  test('requestSms asks the gateway then refreshes state to reflect the new status', () async {
    await container.read(setupStatusProvider.future);
    gateway.grantSmsOnRequest = true;

    await container.read(setupStatusProvider.notifier).requestSms();

    expect(gateway.requestSmsCalls, 1);
    final status = container.read(setupStatusProvider).requireValue;
    expect(status.sms, PermissionRequestStatus.granted);
  });

  test('refresh re-reads status without requesting anything', () async {
    await container.read(setupStatusProvider.future);
    gateway.notificationListenerEnabled = true;

    await container.read(setupStatusProvider.notifier).refresh();

    expect(gateway.requestSmsCalls, 0);
    expect(container.read(setupStatusProvider).requireValue.notificationListenerEnabled, isTrue);
  });
}
