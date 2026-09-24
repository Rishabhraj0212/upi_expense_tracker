import 'package:flutter/material.dart';

import '../expense.dart';
import '../format.dart';
import '../native_bridge.dart';

/// Raw notifications / SMS the app looked at, and whether each one was recognised as a payment.
/// Use it to see why a payment was missed, then tune the parser to the real wording.
class CapturesPage extends StatefulWidget {
  const CapturesPage({super.key});

  @override
  State<CapturesPage> createState() => _CapturesPageState();
}

class _CapturesPageState extends State<CapturesPage> {
  List<Capture>? _items;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await NativeBridge.captures();
    if (mounted) setState(() => _items = items);
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Captured messages'),
        actions: [
          IconButton(
            tooltip: 'Clear',
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () async {
              await NativeBridge.clearCaptures();
              _load();
            },
          ),
          IconButton(tooltip: 'Refresh', icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: items == null
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Nothing captured yet. Once Paytm / super.money notifications or bank SMS '
                      'arrive, they are listed here.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final c = items[i];
                    final parsed = c.result.startsWith('parsed');
                    return ListTile(
                      isThreeLine: true,
                      leading: Icon(
                        c.source == 'sms' ? Icons.sms_outlined : Icons.notifications_outlined,
                        color: parsed ? Colors.green : null,
                      ),
                      title: Text(c.text, maxLines: 4, overflow: TextOverflow.ellipsis),
                      subtitle: Text('${c.origin ?? c.source} · ${Fmt.dayTime(c.ts)} · ${c.result}'),
                      onLongPress: () => showDialog<void>(
                        context: context,
                        builder: (_) => AlertDialog(content: SelectableText(c.text)),
                      ),
                    );
                  },
                ),
    );
  }
}
