import 'package:flutter_test/flutter_test.dart';
import 'package:upi_expense_tracker/platform/setup_gateway.dart';

const _batteryIgnored = true;

void main() {
  test('allGranted requires both sms granted and notification listener enabled', () {
    expect(
      const SetupStatus(
        sms: PermissionRequestStatus.granted,
        notificationListenerEnabled: true,
        batteryOptimizationIgnored: _batteryIgnored,
      ).allGranted,
      isTrue,
    );
    expect(
      const SetupStatus(
        sms: PermissionRequestStatus.granted,
        notificationListenerEnabled: false,
        batteryOptimizationIgnored: _batteryIgnored,
      ).allGranted,
      isFalse,
    );
    expect(
      const SetupStatus(
        sms: PermissionRequestStatus.denied,
        notificationListenerEnabled: true,
        batteryOptimizationIgnored: _batteryIgnored,
      ).allGranted,
      isFalse,
    );
    expect(
      const SetupStatus(
        sms: PermissionRequestStatus.permanentlyDenied,
        notificationListenerEnabled: true,
        batteryOptimizationIgnored: _batteryIgnored,
      ).allGranted,
      isFalse,
    );
  });

  test('allGranted ignores battery optimization status either way', () {
    expect(
      const SetupStatus(
        sms: PermissionRequestStatus.granted,
        notificationListenerEnabled: true,
        batteryOptimizationIgnored: false,
      ).allGranted,
      isTrue,
      reason: 'battery optimization exemption is recommended, not required',
    );
  });
}
