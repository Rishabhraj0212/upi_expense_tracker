import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/sync_settings.dart';
import '../../domain/models/sync_status.dart';
import '../providers/sync_providers.dart';
import 'dashboard_screen.dart';
import 'first_launch_sync_choice_screen.dart';
import 'google_sheets_setup_screen.dart';

/// Decides, reactively, which top-level screen to show. Reactive on purpose:
/// every screen this gate can show only ever *writes* to SyncSettings — this
/// widget picks that change up on its own, with no manual navigation call
/// anywhere in the flow it controls.
///
///  - NOT_CONFIGURED            -> the one-time first-launch choice
///  - GOOGLE_SHEETS, not yet connected -> the setup flow (Connect Account ->
///    Create/Select Sheet -> Verify -> Initial Sync). Deliberately shown
///    every launch until connection actually succeeds — this app must never
///    claim "connected" before it's real (Step 6+ implements the actual
///    connection; until then this screen is reachable but inert).
///  - LOCAL_ONLY, or GOOGLE_SHEETS once connected -> the dashboard
class AppStartupGate extends ConsumerWidget {
  const AppStartupGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(syncSettingsStreamProvider);

    return settingsAsync.when(
      data: (settings) => _screenFor(settings),
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, st) => Scaffold(body: Center(child: Text('Could not load app settings: $e'))),
    );
  }

  Widget _screenFor(SyncSettings settings) {
    switch (settings.syncPreference) {
      case SyncPreference.notConfigured:
        return const FirstLaunchSyncChoiceScreen();
      case SyncPreference.localOnly:
        return const DashboardScreen();
      case SyncPreference.googleSheets:
        return settings.isConnected ? const DashboardScreen() : const GoogleSheetsSetupScreen();
    }
  }
}
