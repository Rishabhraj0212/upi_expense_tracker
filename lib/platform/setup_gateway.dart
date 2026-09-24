/// Outcome of checking (or requesting) a runtime permission, decoupled from
/// any particular plugin's status enum so the rest of the app doesn't need
/// to depend on one.
enum PermissionRequestStatus {
  granted,
  denied,

  /// The OS won't show the request dialog again; the only way forward is
  /// the app's system settings page.
  permanentlyDenied,
}

class SetupStatus {
  const SetupStatus({
    required this.sms,
    required this.notificationListenerEnabled,
    required this.batteryOptimizationIgnored,
  });

  final PermissionRequestStatus sms;

  /// Whether this app is enabled under Settings > Notification access. This
  /// is a special access grant, not a normal runtime permission, so there is
  /// no "denied vs permanently denied" distinction — just on or off.
  final bool notificationListenerEnabled;

  /// Whether Android is exempting this app from battery optimization.
  /// Recommended, not required: the app still works without it, but headless
  /// background capture (Milestone 8) is more likely to be cut short by
  /// aggressive OEM power management if this is off. Deliberately excluded
  /// from [allGranted], which tracks only what's required for basic function.
  final bool batteryOptimizationIgnored;

  bool get allGranted => sms == PermissionRequestStatus.granted && notificationListenerEnabled;
}

/// Everything the setup screen needs from the platform. Kept as an interface
/// so the screen and its state logic can be unit/widget-tested with a fake,
/// without touching any real platform channel or permission dialog.
abstract class SetupGateway {
  Future<SetupStatus> loadStatus();

  Future<void> requestSmsPermission();

  Future<void> openNotificationListenerSettings();

  Future<void> requestIgnoreBatteryOptimizations();

  Future<void> openSystemAppSettings();
}
