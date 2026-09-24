import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/raw_event.dart';
import '../../domain/models/transaction_source.dart';
import '../../format.dart';
import '../../ingestion/ingestion_result.dart';
import '../providers/app_providers.dart';
import '../widgets/transaction_tile.dart';
import 'setup_screen.dart';

/// Milestone 4 debug harness: feed a raw SMS/notification string through the
/// real parse -> dedup -> store pipeline and watch the result. Kept around
/// after Milestone 9 introduced the real dashboard/list/detail UI, since it's
/// still useful for exercising the parser without a real SMS/notification —
/// reachable from the dashboard's app bar rather than being the app's home.
class DebugIngestionScreen extends ConsumerStatefulWidget {
  const DebugIngestionScreen({super.key});

  @override
  ConsumerState<DebugIngestionScreen> createState() => _DebugIngestionScreenState();
}

class _Sample {
  const _Sample(this.label, this.sourceType, this.origin, this.text);
  final String label;
  final SourceType sourceType;
  final String origin;
  final String text;
}

const _samples = [
  _Sample(
    'HDFC debit',
    SourceType.sms,
    'HDFCBK',
    'Rs.500.00 debited from A/c XX1234 on 15-01-26 to VPA merchant@ybl '
        '(UPI Ref No 302615478321). Not you? Call 18002586161 -HDFC Bank',
  ),
  _Sample(
    'HDFC credit',
    SourceType.sms,
    'HDFCBK',
    'Rs.15,000.00 credited to your A/c XX1234 on 20-01-26 from VPA '
        'employer@okaxis (UPI Ref No 400011122233). -HDFC Bank',
  ),
  _Sample(
    'SBI debit (quirky format)',
    SourceType.sms,
    'SBIINB',
    'Dear UPI user A/C X1234 debited by 300.0 on date 15Jan26 trf to Tea '
        'Stall Refno 302615478321.If not u? call 1800111109 -SBI',
  ),
  _Sample(
    'Google Pay notification',
    SourceType.notification,
    'com.google.android.apps.nbu.paisa.user',
    'Payment successful | ₹250 paid to Tea Stall using HDFC Bank',
  ),
  _Sample(
    'PhonePe received',
    SourceType.notification,
    'com.phonepe.app',
    'Money received | You received ₹1500 from John Doe',
  ),
  _Sample(
    'OTP (should be ignored)',
    SourceType.sms,
    'HDFCBK',
    '123456 is your OTP for a transaction of Rs.5000 at Amazon. Do not share it.',
  ),
];

class _DebugIngestionScreenState extends ConsumerState<DebugIngestionScreen> {
  SourceType _sourceType = SourceType.sms;
  final _originController = TextEditingController(text: 'HDFCBK');
  final _textController = TextEditingController();
  String? _resultSummary;
  bool _resultWasError = false;
  bool _submitting = false;

  @override
  void dispose() {
    _originController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _loadSample(_Sample sample) {
    setState(() {
      _sourceType = sample.sourceType;
      _originController.text = sample.origin;
      _textController.text = sample.text;
    });
  }

  Future<void> _submit() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() => _submitting = true);
    try {
      final event = RawEvent(
        sourceType: _sourceType,
        origin: _originController.text.trim(),
        text: text,
        receivedAt: DateTime.now(),
      );
      final result = await ref.read(ingestionServiceProvider).process(event);
      ref.invalidate(capturesProvider);
      setState(() {
        _resultWasError = result.outcome == IngestionOutcome.ignored;
        _resultSummary = switch (result.outcome) {
          IngestionOutcome.ignored => 'Ignored — not a recognizable transaction.',
          IngestionOutcome.inserted =>
            'Inserted new transaction #${result.transactionId}: '
                '${Fmt.rupees(result.parsed!.amountPaise)} (${result.parsed!.type.name}).',
          IngestionOutcome.merged =>
            'Merged into existing transaction #${result.transactionId} '
                '(duplicate via ${result.parsed!.sourceType.name}).',
        };
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('UPI Expenses — debug harness'),
        actions: [
          IconButton(
            icon: const Icon(Icons.security),
            tooltip: 'Permissions & Setup',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SetupScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Simulate a captured event', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final s in _samples) ActionChip(label: Text(s.label), onPressed: () => _loadSample(s))],
          ),
          const SizedBox(height: 12),
          SegmentedButton<SourceType>(
            segments: const [
              ButtonSegment(value: SourceType.sms, label: Text('SMS'), icon: Icon(Icons.sms)),
              ButtonSegment(
                  value: SourceType.notification, label: Text('Notification'), icon: Icon(Icons.notifications)),
            ],
            selected: {_sourceType},
            onSelectionChanged: (s) => setState(() => _sourceType = s.first),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _originController,
            decoration: InputDecoration(
              labelText: _sourceType == SourceType.sms ? 'SMS sender id' : 'Notification package name',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _textController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Raw message text',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _submitting ? null : _submit,
            icon: const Icon(Icons.send),
            label: const Text('Run through pipeline'),
          ),
          if (_resultSummary != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _resultWasError
                    ? Theme.of(context).colorScheme.errorContainer
                    : Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_resultSummary!),
            ),
          ],
          const Divider(height: 32),
          Text('Stored transactions', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          transactionsAsync.when(
            data: (transactions) => transactions.isEmpty
                ? const Padding(padding: EdgeInsets.all(8), child: Text('No transactions yet.'))
                : Column(children: [for (final t in transactions) TransactionTile(transaction: t)]),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Text('Error loading transactions: $e'),
          ),
          const Divider(height: 32),
          Text('Recent captures (diagnostic log)', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Consumer(
            builder: (context, ref, _) {
              final capturesAsync = ref.watch(capturesProvider);
              return capturesAsync.when(
                data: (captures) => captures.isEmpty
                    ? const Padding(padding: EdgeInsets.all(8), child: Text('No captures yet.'))
                    : Column(
                        children: [
                          for (final c in captures)
                            ListTile(
                              dense: true,
                              leading: Icon(c.sourceType == 'sms' ? Icons.sms : Icons.notifications, size: 18),
                              title: Text(c.text, maxLines: 1, overflow: TextOverflow.ellipsis),
                              subtitle: Text('${c.origin ?? '?'} • ${c.result}'),
                            ),
                        ],
                      ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Text('Error loading captures: $e'),
              );
            },
          ),
        ],
      ),
    );
  }
}
