import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

import '../../format.dart';
import '../../ingestion/historical_sms_scanner.dart';
import '../../platform/sms_inbox_reader.dart';
import '../providers/app_providers.dart';
import '../providers/sync_providers.dart';

/// "Find Missed Transactions" — scans the Android SMS inbox for bank SMS
/// that the real-time listener may have missed (e.g. before the app was
/// installed, or while permissions were temporarily off).
///
/// First scan: previous 90 days. Subsequent scans: from
/// `lastSmsRescanAt - 48 hours` until now. The 48-hour overlap is
/// intentional so late-arriving or temporarily missed messages are
/// rechecked.
class SmsRescanScreen extends ConsumerStatefulWidget {
  const SmsRescanScreen({super.key});

  @override
  ConsumerState<SmsRescanScreen> createState() => _SmsRescanScreenState();
}

enum _ScanPeriod {
  smart('Smart (Since last scan)'),
  yesterday('Yesterday'),
  last7Days('Last 7 days'),
  last30Days('Last 30 days'),
  allTime('All time (May take a while)');

  const _ScanPeriod(this.label);
  final String label;
}

class _SmsRescanScreenState extends ConsumerState<SmsRescanScreen> {
  static const _firstScanDays = 90;
  static const _overlapHours = 48;

  bool _scanning = false;
  ScanProgress? _progress;
  ScanResult? _result;
  String? _error;
  bool _permissionDenied = false;
  _ScanPeriod _selectedPeriod = _ScanPeriod.smart;

  Future<void> _startScan() async {
    // 1. Check READ_SMS permission
    var status = await ph.Permission.sms.status;
    if (!status.isGranted) {
      status = await ph.Permission.sms.request();
    }
    if (!status.isGranted) {
      setState(() => _permissionDenied = true);
      return;
    }
    setState(() {
      _permissionDenied = false;
      _scanning = true;
      _progress = null;
      _result = null;
      _error = null;
    });

    try {
      // 2. Determine scan window
      final settings = await ref.read(syncSettingsRepositoryProvider).getSettings();
      final now = DateTime.now();

      DateTime since;
      switch (_selectedPeriod) {
        case _ScanPeriod.smart:
          if (settings.lastSmsRescanAt == null) {
            since = now.subtract(const Duration(days: _firstScanDays));
          } else {
            since = settings.lastSmsRescanAt!.subtract(const Duration(hours: _overlapHours));
          }
          break;
        case _ScanPeriod.yesterday:
          since = now.subtract(const Duration(days: 1));
          break;
        case _ScanPeriod.last7Days:
          since = now.subtract(const Duration(days: 7));
          break;
        case _ScanPeriod.last30Days:
          since = now.subtract(const Duration(days: 30));
          break;
        case _ScanPeriod.allTime:
          since = DateTime(2000); // Scan everything possible
          break;
      }

      // 3. Run the scan
      final scanner = HistoricalSmsScanner(
        smsInboxReader: SmsInboxReader(),
        ingestionService: ref.read(ingestionServiceProvider),
      );

      final result = await scanner.scan(
        since: since,
        until: now,
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
      );

      // 4. Persist the rescan timestamp (only if smart scan was used, otherwise
      // we might mess up the smart scan overlap window)
      if (_selectedPeriod == _ScanPeriod.smart) {
        await ref.read(syncSettingsRepositoryProvider).setLastSmsRescanAt(now);
      }

      if (mounted) setState(() => _result = result);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Find Missed Transactions')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.search, color: theme.colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Scan Previous SMS',
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Scan previous bank SMS messages for transactions that may '
                    'not have been captured.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _LastScanInfo(),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<_ScanPeriod>(
                    value: _selectedPeriod,
                    decoration: const InputDecoration(
                      labelText: 'Time Period',
                      border: OutlineInputBorder(),
                    ),
                    items: _ScanPeriod.values.map((p) => DropdownMenuItem(
                      value: p,
                      child: Text(p.label),
                    )).toList(),
                    onChanged: _scanning ? null : (value) {
                      if (value != null) setState(() => _selectedPeriod = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _scanning ? null : _startScan,
                      icon: _scanning
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.sms_outlined),
                      label: Text(_scanning ? 'Scanning...' : 'Scan Previous SMS'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_permissionDenied) ...[
            const SizedBox(height: 16),
            Card(
              color: theme.colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: theme.colorScheme.onErrorContainer),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'SMS permission is required to scan previous messages.',
                            style: TextStyle(color: theme.colorScheme.onErrorContainer),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => ph.openAppSettings(),
                      child: const Text('Grant SMS Permission'),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (_scanning && _progress != null) ...[
            const SizedBox(height: 16),
            _ProgressCard(progress: _progress!),
          ],
          if (_result != null && !_scanning) ...[
            const SizedBox(height: 16),
            _ResultCard(result: _result!),
          ],
          if (_error != null && !_scanning) ...[
            const SizedBox(height: 16),
            Card(
              color: theme.colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Scan failed',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(color: theme.colorScheme.onErrorContainer)),
                    const SizedBox(height: 8),
                    Text(_error!,
                        style: TextStyle(color: theme.colorScheme.onErrorContainer)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LastScanInfo extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(syncSettingsStreamProvider);
    return settingsAsync.when(
      data: (settings) {
        if (settings.lastSmsRescanAt == null) {
          return Text(
            'Never scanned before. First scan checks the last 90 days.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          );
        }
        return Text(
          'Last scanned: ${Fmt.dayTime(settings.lastSmsRescanAt!)}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.progress});
  final ScanProgress progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fraction = progress.totalMessages > 0
        ? progress.processedMessages / progress.totalMessages
        : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Scanning SMS...', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: fraction),
            const SizedBox(height: 8),
            Text(
              '${progress.processedMessages} / ${progress.totalMessages} messages',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            _StatRow('Transactions found', '${progress.transactionsFound}'),
            _StatRow('New transactions', '${progress.newTransactions}'),
            _StatRow('Already existing', '${progress.duplicates}'),
            if (progress.failed > 0)
              _StatRow('Failed', '${progress.failed}'),
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});
  final ScanResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasNew = result.newTransactions > 0;

    return Card(
      color: hasNew
          ? Colors.green.withValues(alpha: 0.1)
          : theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hasNew ? Icons.check_circle : Icons.check_circle_outline,
                  color: hasNew ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text('Scan Complete', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            _StatRow('SMS checked', '${result.totalMessages}'),
            _StatRow('Transactions found', '${result.transactionsFound}'),
            _StatRow('New transactions', '${result.newTransactions}'),
            _StatRow('Duplicates ignored', '${result.duplicates}'),
            if (result.failed > 0)
              _StatRow('Failed/invalid', '${result.failed}'),
            const SizedBox(height: 8),
            if (!hasNew)
              Text(
                "You're up to date. No missed transactions were found.",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            if (hasNew)
              Text(
                '${result.newTransactions} missed transaction${result.newTransactions == 1 ? '' : 's'} '
                'recovered and added to your records.',
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.green.shade700),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          )),
        ],
      ),
    );
  }
}
