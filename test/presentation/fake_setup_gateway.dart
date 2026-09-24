import 'package:upi_expense_tracker/platform/setup_gateway.dart';

/// Configurable fake so setup-flow tests never touch a real platform channel
/// or trigger a real permission dialog.
class FakeSetupGateway implements SetupGateway {
  PermissionRequestStatus smsStatus = PermissionRequestStatus.denied;
  bool notificationListenerEnabled = false;
  bool batteryOptimizationIgnored = false;

  int requestSmsCalls = 0;
  int openNotificationSettingsCalls = 0;
  int requestIgnoreBatteryOptimizationsCalls = 0;
  int openAppSettingsCalls = 0;

  /// Simulates the user granting SMS access when the OS dialog is shown.
  bool grantSmsOnRequest = true;

  @override
  Future<SetupStatus> loadStatus() async => SetupStatus(
        sms: smsStatus,
        notificationListenerEnabled: notificationListenerEnabled,
        batteryOptimizationIgnored: batteryOptimizationIgnored,
      );

  @override
  Future<void> requestSmsPermission() async {
    requestSmsCalls++;
    if (grantSmsOnRequest) smsStatus = PermissionRequestStatus.granted;
  }

  @override
  Future<void> openNotificationListenerSettings() async {
    openNotificationSettingsCalls++;
  }

  @override
  Future<void> requestIgnoreBatteryOptimizations() async {
    requestIgnoreBatteryOptimizationsCalls++;
  }

  @override
  Future<void> openSystemAppSettings() async {
    openAppSettingsCalls++;
  }
}
