import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../platform/setup_gateway.dart';
import '../providers/setup_providers.dart';

/// Explains and requests the two things Phase 1 needs — SMS access (a normal
/// runtime permission) and Notification access (a special-access grant with
/// no in-app request dialog, only a system settings toggle) — plus one
/// recommended-but-not-required extra: exempting the app from battery
/// optimization, which makes headless background capture (Milestone 8) less
/// likely to be cut short by aggressive OEM power management. Denial is
/// handled gracefully — every unmet requirement gets a clear next step
/// rather than a dead end.
class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The user grants notification access (and settles a permanently-denied
    // SMS permission) from outside the app; re-check as soon as they're back.
    if (state == AppLifecycleState.resumed) {
      ref.read(setupStatusProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(setupStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Permissions & Setup'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh status',
            onPressed: () => ref.read(setupStatusProvider.notifier).refresh(),
          ),
        ],
      ),
      body: statusAsync.when(
        data: (status) => _SetupBody(status: status),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Could not check permission status: $e')),
      ),
    );
  }
}

class _SetupBody extends ConsumerWidget {
  const _SetupBody({required this.status});

  final SetupStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gateway = ref.read(setupGatewayProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SummaryBanner(allGranted: status.allGranted),
        const SizedBox(height: 16),
        _PermissionCard(
          icon: Icons.sms,
          title: 'SMS Access',
          explanation: 'Needed to detect incoming bank and UPI SMS in real time, as they arrive.',
          granted: status.sms == PermissionRequestStatus.granted,
          actionLabel: switch (status.sms) {
            PermissionRequestStatus.granted => null,
            PermissionRequestStatus.denied => 'Grant SMS access',
            PermissionRequestStatus.permanentlyDenied => 'Open app settings',
          },
          onAction: switch (status.sms) {
            PermissionRequestStatus.granted => null,
            PermissionRequestStatus.denied => () => ref.read(setupStatusProvider.notifier).requestSms(),
            PermissionRequestStatus.permanentlyDenied => () => gateway.openSystemAppSettings(),
          },
        ),
        const SizedBox(height: 12),
        _PermissionCard(
          icon: Icons.notifications_active,
          title: 'Notification Access',
          explanation: 'Needed to read payment notifications from apps like Google Pay, PhonePe, and Paytm. '
              'This is a special access you grant from Android settings, not a normal permission popup.',
          granted: status.notificationListenerEnabled,
          actionLabel: status.notificationListenerEnabled ? null : 'Open notification access settings',
          onAction: status.notificationListenerEnabled ? null : () => gateway.openNotificationListenerSettings(),
        ),
        const SizedBox(height: 12),
        _PermissionCard(
          icon: Icons.battery_charging_full,
          title: 'Background Reliability',
          explanation: 'Recommended, not required: exempting this app from battery optimization makes it less '
              'likely that a payment is missed while the app is fully closed, on phones with aggressive '
              'battery management.',
          granted: status.batteryOptimizationIgnored,
          optional: true,
          actionLabel: status.batteryOptimizationIgnored ? null : 'Exempt from battery optimization',
          onAction: status.batteryOptimizationIgnored ? null : () => gateway.requestIgnoreBatteryOptimizations(),
        ),
      ],
    );
  }
}

class _SummaryBanner extends StatelessWidget {
  const _SummaryBanner({required this.allGranted});

  final bool allGranted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: allGranted ? scheme.primaryContainer : scheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(allGranted ? Icons.check_circle : Icons.warning_amber_rounded),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              allGranted
                  ? 'All set — ready to detect transactions.'
                  : 'Setup required before transactions can be detected.',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({
    required this.icon,
    required this.title,
    required this.explanation,
    required this.granted,
    required this.actionLabel,
    required this.onAction,
    this.optional = false,
  });

  final IconData icon;
  final String title;
  final String explanation;
  final bool granted;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// True for something merely recommended (e.g. battery optimization
  /// exemption): "not granted" is shown as a neutral prompt, not a red X.
  final bool optional;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 12),
                Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
                Icon(
                  granted ? Icons.check_circle : (optional ? Icons.info_outline : Icons.cancel),
                  color: granted ? Colors.green : (optional ? Colors.amber.shade700 : Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(explanation, style: Theme.of(context).textTheme.bodyMedium),
            if (actionLabel != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(onPressed: onAction, child: Text(actionLabel!)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
