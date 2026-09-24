import 'dart:async';

import 'package:flutter/material.dart';

import '../expense.dart';
import '../format.dart';
import '../native_bridge.dart';
import 'captures_page.dart';
import 'setup_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  List<Expense> _all = const [];
  List<String> _categories = const [];
  SetupStatus? _setup;
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
    _startPolling();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _poll?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refresh();
      _startPolling();
    } else {
      _poll?.cancel();
    }
  }

  // Payments are saved by native code, possibly while this screen is open (e.g. after tapping a
  // category on the notification), so re-read while the app is in the foreground.
  void _startPolling() {
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 3), (_) => _refresh());
  }

  Future<void> _refresh() async {
    try {
      final results = await Future.wait([
        NativeBridge.listExpenses(),
        NativeBridge.categories(),
        SetupStatus.load(),
      ]);
      if (!mounted) return;
      setState(() {
        _all = results[0] as List<Expense>;
        _categories = results[1] as List<String>;
        _setup = results[2] as SetupStatus;
      });
    } catch (e) {
      debugPrint('refresh failed: $e');
    }
  }

  List<Expense> get _inMonth => [
        for (final e in _all)
          if (e.createdAt.year == _month.year && e.createdAt.month == _month.month) e,
      ];

  void _shiftMonth(int delta) => setState(() => _month = DateTime(_month.year, _month.month + delta));

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _month.year == now.year && _month.month == now.month;
  }

  @override
  Widget build(BuildContext context) {
    final expenses = _inMonth;
    final total = expenses.fold<int>(0, (sum, e) => sum + e.amountPaise);
    final pending = expenses.where((e) => e.isPending).length;
    final byCategory = <String, int>{};
    for (final e in expenses) {
      if (e.category != null) byCategory[e.category!] = (byCategory[e.category!] ?? 0) + e.amountPaise;
    }
    final sorted = byCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(
        title: const Text('UPI Expenses'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'simulate') {
                await NativeBridge.simulatePayment();
                _refresh();
              } else {
                await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const CapturesPage()));
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'simulate', child: Text('Simulate a payment')),
              PopupMenuItem(value: 'captures', child: Text('Captured messages')),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          children: [
            if (_setup != null && !_setup!.requiredOk) SetupCard(status: _setup!, onChanged: _refresh),
            _monthHeader(total, pending),
            for (final entry in sorted) _categoryBar(entry.key, entry.value, total),
            const Divider(height: 24),
            if (expenses.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No payments this month yet.\nPay with Paytm or super.money and they show up here.',
                  textAlign: TextAlign.center,
                ),
              ),
            for (final e in expenses) _tile(e),
          ],
        ),
      ),
    );
  }

  Widget _monthHeader(int total, int pending) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _shiftMonth(-1)),
              Text(Fmt.monthYear(_month), style: theme.textTheme.titleMedium),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _isCurrentMonth ? null : () => _shiftMonth(1),
              ),
            ],
          ),
          Text(Fmt.rupees(total), style: theme.textTheme.displaySmall),
          if (pending > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '$pending payment${pending == 1 ? '' : 's'} need a category',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }

  Widget _categoryBar(String category, int paise, int total) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text(category), Text(Fmt.rupees(paise))],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(value: total == 0 ? 0 : paise / total, minHeight: 6),
        ],
      ),
    );
  }

  Widget _tile(Expense e) {
    final theme = Theme.of(context);
    final subtitle = [
      e.category ?? 'Tap to categorise',
      if (e.note != null) e.note!,
      Fmt.dayTime(e.createdAt),
    ].join(' · ');
    return Dismissible(
      key: ValueKey(e.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: theme.colorScheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_outline),
      ),
      confirmDismiss: (_) async =>
          await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Delete this payment?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
              ],
            ),
          ) ??
          false,
      onDismissed: (_) async {
        await NativeBridge.deleteExpense(e.id);
        _refresh();
      },
      child: ListTile(
        title: Text(e.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          subtitle,
          style: e.isPending ? TextStyle(color: theme.colorScheme.error) : null,
        ),
        trailing: Text(Fmt.rupees(e.amountPaise), style: theme.textTheme.titleMedium),
        onTap: () => _edit(e),
      ),
    );
  }

  Future<void> _edit(Expense e) async {
    var selected = e.category;
    final note = TextEditingController(text: e.note);
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + MediaQuery.of(ctx).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${Fmt.rupees(e.amountPaise)} · ${e.title}', style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  for (final c in _categories)
                    ChoiceChip(
                      label: Text(c),
                      selected: selected == c,
                      onSelected: (_) => setSheet(() => selected = c),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: note,
                decoration: const InputDecoration(labelText: 'Note (optional)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: selected == null ? null : () => Navigator.pop(ctx, true),
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    final noteText = note.text;
    note.dispose();
    if (saved == true && selected != null) {
      await NativeBridge.setCategory(e.id, selected!, noteText);
      _refresh();
    }
  }
}
