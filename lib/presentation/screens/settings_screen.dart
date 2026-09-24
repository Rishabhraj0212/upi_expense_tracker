import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/models/sync_settings.dart';
import '../../domain/models/sync_status.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../format.dart';
import '../../sync/transaction_sync_service.dart';
import '../providers/sync_providers.dart';
import 'categories_settings_screen.dart';
import 'google_sheets_setup_screen.dart';

/// Settings -> Google Sheets Sync. Deliberately separate from [SetupScreen],
/// which stays focused on SMS/notification permissions.
///
/// Every value shown here is read from real, persisted state
/// ([SyncSettings] + [TransactionSyncCounts]) — nothing is hard-coded or
/// simulated. Account sign-in/out (Step 6), spreadsheet create/select/verify
/// (Step 7), and manual sync of pending transactions (Step 8) are all real.
/// Auto Sync is not implemented yet — the switch only persists the
/// preference for a future step to act on.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(syncSettingsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.category_outlined),
            title: const Text('Categories'),
            subtitle: const Text('Manage custom expense categories'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CategoriesSettingsScreen()));
            },
          ),
          const Divider(),
          settingsAsync.when(
            data: (settings) => _GoogleSheetsSyncSection(settings: settings),
            loading: () => const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, st) => Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Could not load settings: $e'),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoogleSheetsSyncSection extends ConsumerWidget {
  const _GoogleSheetsSyncSection({required this.settings});

  final SyncSettings settings;

  Future<void> _connect(BuildContext context, WidgetRef ref) async {
    await ref.read(syncSettingsRepositoryProvider).setSyncPreference(SyncPreference.googleSheets);
    if (context.mounted) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GoogleSheetsSetupScreen()));
    }
  }

  Future<void> _continueSetup(BuildContext context) async {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GoogleSheetsSetupScreen()));
  }

  Future<void> _disconnect(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect Google Sheets?'),
        content: const Text(
          'Your local transactions will remain on this device. Disconnecting will stop future synchronization.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Disconnect')),
        ],
      ),
    );
    if (confirmed != true) return;

    // Revoke the actual Google session first (Step 6), then clear local
    // bookkeeping — if this ran the other way around and revocation failed,
    // the app would incorrectly believe it was already disconnected.
    await ref.read(googleAuthGatewayProvider).signOut();

    final repo = ref.read(syncSettingsRepositoryProvider);
    await repo.setGoogleAccount(null);
    await repo.setSpreadsheet(null, null);
    await repo.setConnectionState(GoogleConnectionState.disconnected);
    await repo.setAutoSyncEnabled(false);
    await repo.setSyncPreference(SyncPreference.localOnly);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!settings.isConnected) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Google Sheets Sync', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.circle, size: 12, color: Colors.grey.shade500),
                        const SizedBox(width: 8),
                        Text('Sync is Off', style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('Your expenses are stored only on this device.'),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: settings.syncPreference == SyncPreference.googleSheets
                          ? () => _continueSetup(context)
                          : () => _connect(context, ref),
                      child: Text(
                        settings.syncPreference == SyncPreference.googleSheets
                            ? 'Continue Setup'
                            : 'Connect Google Sheets',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    final countsAsync = ref.watch(transactionSyncCountsProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Google Sheets Sync', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          countsAsync.when(
            data: (counts) => _ConnectedPanel(settings: settings, counts: counts),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Text('Could not load sync counts: $e'),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _disconnect(context, ref),
              child: const Text('Disconnect Google Account'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectedPanel extends ConsumerStatefulWidget {
  const _ConnectedPanel({required this.settings, required this.counts});

  final SyncSettings settings;
  final TransactionSyncCounts counts;

  @override
  ConsumerState<_ConnectedPanel> createState() => _ConnectedPanelState();
}

class _ConnectedPanelState extends ConsumerState<_ConnectedPanel> {
  bool _syncing = false;
  SyncProgress? _progress;

  Future<void> _syncNow() async {
    setState(() {
      _syncing = true;
      _progress = null;
    });
    SyncRunOutcome outcome;
    try {
      outcome = await ref
          .read(transactionSyncServiceProvider)
          .syncPendingTransactions(
            onProgress: (progress) {
              if (mounted) setState(() => _progress = progress);
            },
          );
    } catch (e) {
      outcome = SyncRunAborted('Unexpected error: $e');
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
    if (!mounted) return;
    if (outcome case SyncRunAborted(:final reason)) {
      await _showError(reason);
    }
    // SyncRunCompleted (fully or partially synced): the settings and sync
    // counts streams already reflect the outcome reactively — no extra
    // navigation or state update needed here.
  }

  Future<void> _showError(String message) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sync failed'),
        content: Text('$message\n\nYour local expenses are unaffected.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
        ],
      ),
    );
  }

  String get _statusLabel {
    if (_syncing) return 'Syncing...';
    switch (widget.settings.lastSyncRunState) {
      case SyncRunState.syncing:
        return 'Syncing...';
      case SyncRunState.synced:
        return 'All data synced';
      case SyncRunState.partiallySynced:
        return 'Some transactions are not synced';
      case SyncRunState.syncFailed:
        return 'Sync failed';
      case SyncRunState.idle:
        return widget.counts.pending == 0 && widget.counts.failed == 0 ? 'All data synced' : 'Not yet synced';
    }
  }

  bool get _needsRetry =>
      !_syncing && (widget.counts.failed > 0 || widget.settings.lastSyncRunState == SyncRunState.syncFailed);

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
                Icon(
                  _needsRetry ? Icons.error_outline : Icons.check_circle,
                  color: _needsRetry ? Colors.orange : Colors.green,
                ),
                const SizedBox(width: 8),
                Text(_statusLabel, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const Divider(height: 24),
            _Row('Account', widget.settings.googleAccountEmail ?? '—'),
            _Row('Sheet', widget.settings.spreadsheetName ?? '—'),
            _Row(
              'Last successful sync',
              widget.settings.lastSuccessfulSyncAt == null
                  ? 'Never'
                  : Fmt.dayTime(widget.settings.lastSuccessfulSyncAt!),
            ),
            _Row('Synced', '${widget.counts.synced}'),
            _Row('Pending', '${widget.counts.pending}'),
            _Row('Failed', '${widget.counts.failed}'),
            if (widget.settings.spreadsheetId != null) ...[
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('Open Spreadsheet'),
                  onPressed: () async {
                    final url = Uri.parse(
                      'https://docs.google.com/spreadsheets/d/${widget.settings.spreadsheetId}',
                    );
                    final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
                    if (!launched && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Could not open browser. URL: $url')),
                      );
                    }
                  },
                ),
              ),
            ],
            if (_syncing && _progress != null) ...[
              const SizedBox(height: 8),
              Text(
                '${_progress!.completed} / ${_progress!.total} transactions',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _syncing ? null : _syncNow,
                    child: Text(_needsRetry ? 'Retry Sync' : 'Sync Now'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Auto Sync'),
                      Text(
                        _syncing
                            ? 'Syncing...'
                            : widget.settings.autoSyncEnabled
                                ? 'Automatic sync enabled'
                                : 'Manual sync only',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: widget.settings.autoSyncEnabled,
                  onChanged: (value) => ref.read(syncSettingsRepositoryProvider).setAutoSyncEnabled(value),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
