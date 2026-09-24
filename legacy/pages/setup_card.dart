import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../native_bridge.dart';

/// Lists the permissions payment detection needs, with a button to grant each one.
class SetupCard extends StatelessWidget {
  const SetupCard({super.key, required this.status, required this.onChanged});

  final SetupStatus status;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.secondaryContainer,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text('Finish setup to detect payments', style: theme.textTheme.titleMedium),
            ),
            _row(
              done: status.listener,
              title: 'Notification access',
              subtitle: 'Reads Paytm / super.money payment notifications',
              onGrant: () async {
                await NativeBridge.openNotificationListenerSettings();
              },
            ),
            _row(
              done: status.sms,
              title: 'SMS access',
              subtitle: 'Reads Bank of Baroda debit messages',
              onGrant: () async {
                final r = await Permission.sms.request();
                if (r.isPermanentlyDenied) await NativeBridge.openAppSettings();
                onChanged();
              },
            ),
            _row(
              done: status.notifications,
              title: 'Show notifications',
              subtitle: 'For the "what was this for?" prompt',
              onGrant: () async {
                final r = await Permission.notification.request();
                if (r.isPermanentlyDenied) await NativeBridge.openAppSettings();
                onChanged();
              },
            ),
            _row(
              done: status.overlay,
              title: 'Display over other apps (optional)',
              subtitle: 'Pops the prompt up directly instead of only as a notification',
              onGrant: () async {
                await Permission.systemAlertWindow.request();
                onChanged();
              },
            ),
            if (!status.listener || !status.sms)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                child: Text(
                  'Installed outside the Play Store and the toggle is greyed out? Open App info, '
                  'tap ⋮ and choose "Allow restricted settings", then try again.',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: TextButton(onPressed: NativeBridge.openAppSettings, child: const Text('Open App info')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row({
    required bool done,
    required String title,
    required String subtitle,
    required Future<void> Function() onGrant,
  }) {
    return ListTile(
      dense: true,
      leading: Icon(done ? Icons.check_circle : Icons.radio_button_unchecked),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: done ? null : FilledButton.tonal(onPressed: onGrant, child: const Text('Grant')),
    );
  }
}
