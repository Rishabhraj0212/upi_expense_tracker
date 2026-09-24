import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

import 'setup_gateway.dart';

class AndroidSetupGateway implements SetupGateway {
  static const _channel = MethodChannel('upi_tracker/platform');

  @override
  Future<SetupStatus> loadStatus() async {
    final smsStatus = await ph.Permission.sms.status;
    final listenerEnabled = await _channel.invokeMethod<bool>('isNotificationListenerEnabled') ?? false;
    final batteryIgnored = await _channel.invokeMethod<bool>('isIgnoringBatteryOptimizations') ?? false;
    return SetupStatus(
      sms: _mapStatus(smsStatus),
      notificationListenerEnabled: listenerEnabled,
      batteryOptimizationIgnored: batteryIgnored,
    );
  }

  @override
  Future<void> requestSmsPermission() async {
    await ph.Permission.sms.request();
  }

  @override
  Future<void> openNotificationListenerSettings() =>
      _channel.invokeMethod('openNotificationListenerSettings');

  @override
  Future<void> requestIgnoreBatteryOptimizations() =>
      _channel.invokeMethod('requestIgnoreBatteryOptimizations');

  @override
  Future<void> openSystemAppSettings() => ph.openAppSettings();

  PermissionRequestStatus _mapStatus(ph.PermissionStatus status) {
    if (status.isGranted || status.isLimited || status.isProvisional) return PermissionRequestStatus.granted;
    if (status.isPermanentlyDenied || status.isRestricted) return PermissionRequestStatus.permanentlyDenied;
    return PermissionRequestStatus.denied;
  }
}
