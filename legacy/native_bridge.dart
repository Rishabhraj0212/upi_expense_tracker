import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import 'expense.dart';

/// Thin wrapper over the Kotlin side, which owns the database and the payment detection.
class NativeBridge {
  static const _ch = MethodChannel('upi_tracker/native');

  static Future<List<Expense>> listExpenses() async {
    final rows = await _ch.invokeListMethod<Map>('listExpenses', {'limit': 1000});
    return [for (final r in rows ?? const <Map>[]) Expense.fromMap(r)];
  }

  static Future<List<String>> categories() async =>
      (await _ch.invokeListMethod<String>('categories')) ?? const [];

  static Future<void> setCategory(int id, String category, String? note) =>
      _ch.invokeMethod('setCategory', {'id': id, 'category': category, 'note': note});

  static Future<void> deleteExpense(int id) => _ch.invokeMethod('deleteExpense', {'id': id});

  static Future<List<Capture>> captures() async {
    final rows = await _ch.invokeListMethod<Map>('captures', {'limit': 200});
    return [for (final r in rows ?? const <Map>[]) Capture.fromMap(r)];
  }

  static Future<void> clearCaptures() => _ch.invokeMethod('clearCaptures');

  static Future<void> simulatePayment() => _ch.invokeMethod('simulatePayment');

  static Future<void> openNotificationListenerSettings() =>
      _ch.invokeMethod('openNotificationListenerSettings');

  static Future<void> openAppSettings() => _ch.invokeMethod('openAppSettings');
}

class SetupStatus {
  const SetupStatus({
    required this.listener,
    required this.sms,
    required this.notifications,
    required this.overlay,
  });

  final bool listener;
  final bool sms;
  final bool notifications;
  final bool overlay;

  bool get requiredOk => listener && sms && notifications;

  static Future<SetupStatus> load() async {
    const ch = MethodChannel('upi_tracker/native');
    final listener = await ch.invokeMethod<bool>('isNotificationListenerEnabled') ?? false;
    return SetupStatus(
      listener: listener,
      sms: await Permission.sms.isGranted,
      notifications: await Permission.notification.isGranted,
      overlay: await Permission.systemAlertWindow.isGranted,
    );
  }
}
