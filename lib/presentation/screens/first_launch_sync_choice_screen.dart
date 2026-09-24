import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/sync_status.dart';
import '../providers/sync_providers.dart';

/// Shown exactly once, when [SyncPreference] is still [SyncPreference.notConfigured].
/// Neither button does any Google/network work here — this milestone only
/// records the user's choice; [AppStartupGate] reacts to that write and
/// swaps to the dashboard on its own, so there's no manual navigation here.
class FirstLaunchSyncChoiceScreen extends ConsumerStatefulWidget {
  const FirstLaunchSyncChoiceScreen({super.key});

  @override
  ConsumerState<FirstLaunchSyncChoiceScreen> createState() => _FirstLaunchSyncChoiceScreenState();
}

class _FirstLaunchSyncChoiceScreenState extends ConsumerState<FirstLaunchSyncChoiceScreen> {
  bool _submitting = false;

  Future<void> _choose(SyncPreference preference) async {
    setState(() => _submitting = true);
    try {
      await ref.read(syncSettingsRepositoryProvider).setSyncPreference(preference);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.table_chart_outlined, size: 64, color: Colors.teal),
                const SizedBox(height: 24),
                Text(
                  'Sync your expenses with Google Sheets?',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Your expenses are always stored locally on this device. '
                  'Google Sheets sync is optional and can be enabled later.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: _submitting ? null : () => _choose(SyncPreference.googleSheets),
                  child: const Text('Yes, Sync with Google Sheets'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _submitting ? null : () => _choose(SyncPreference.localOnly),
                  child: const Text('Not Now'),
                ),
                if (_submitting) ...[
                  const SizedBox(height: 20),
                  const Center(child: CircularProgressIndicator()),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
