import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/parsed_transaction.dart';
import '../../domain/models/raw_event.dart';
import '../../domain/models/transaction_source.dart';
import '../../domain/models/transaction_type.dart';
import '../../format.dart';
import '../providers/app_providers.dart';
import 'category_selection_sheet.dart';

class RecordTransactionScreen extends ConsumerStatefulWidget {
  const RecordTransactionScreen({super.key});

  @override
  ConsumerState<RecordTransactionScreen> createState() => _RecordTransactionScreenState();
}

class _RecordTransactionScreenState extends ConsumerState<RecordTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _merchantController = TextEditingController();
  final _bankController = TextEditingController();
  final _noteController = TextEditingController();
  final _smsTextController = TextEditingController();

  TransactionType _type = TransactionType.debit;
  DateTime _occurredAt = DateTime.now();
  String? _category;
  int? _balancePaise;
  String? _referenceId;
  String? _accountHint;
  String? _upiId;
  bool _saving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    _bankController.dispose();
    _noteController.dispose();
    _smsTextController.dispose();
    super.dispose();
  }

  void _parseSms() {
    final text = _smsTextController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please paste SMS or transaction text first')),
      );
      return;
    }

    final event = RawEvent(
      sourceType: SourceType.sms,
      origin: '',
      text: text,
      receivedAt: DateTime.now(),
    );

    final parsed = ref.read(parserRegistryProvider).parse(event);
    if (parsed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not detect UPI transaction from this text')),
      );
      return;
    }

    setState(() {
      _amountController.text = (parsed.amountPaise / 100).toStringAsFixed(2);
      _type = parsed.type;
      _occurredAt = parsed.occurredAt;
      if (parsed.merchantName != null) {
        _merchantController.text = parsed.merchantName!;
      }
      if (parsed.bankName != null) {
        _bankController.text = parsed.bankName!;
      }
      _upiId = parsed.upiId;
      _accountHint = parsed.accountHint;
      _referenceId = parsed.referenceId;
      _balancePaise = parsed.balancePaise;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Auto-filled ₹${(parsed.amountPaise / 100).toStringAsFixed(2)} (${parsed.type.name})',
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _occurredAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() {
        _occurredAt = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _occurredAt.hour,
          _occurredAt.minute,
          _occurredAt.second,
        );
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _occurredAt.hour, minute: _occurredAt.minute),
    );
    if (picked != null) {
      setState(() {
        _occurredAt = DateTime(
          _occurredAt.year,
          _occurredAt.month,
          _occurredAt.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  Future<void> _pickCategory() async {
    final result = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      builder: (context) => CategorySelectionSheet(selectedCategoryName: _category),
    );

    if (result == '_MANAGE_CATEGORIES_') return;
    setState(() => _category = result);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final amountText = _amountController.text.trim();
    final amountRupees = double.tryParse(amountText);
    if (amountRupees == null || amountRupees <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    final amountPaise = (amountRupees * 100).round();
    final merchantName = _merchantController.text.trim().isEmpty ? null : _merchantController.text.trim();
    final bankName = _bankController.text.trim().isEmpty ? null : _bankController.text.trim();
    final note = _noteController.text.trim().isEmpty ? null : _noteController.text.trim();
    final rawText = _smsTextController.text.trim().isNotEmpty
        ? _smsTextController.text.trim()
        : 'Manual: ${_type == TransactionType.debit ? "Paid" : "Received"} ₹$amountText${merchantName != null ? " to $merchantName" : ""}';

    setState(() => _saving = true);

    try {
      final parsed = ParsedTransaction(
        amountPaise: amountPaise,
        type: _type,
        occurredAt: _occurredAt,
        sourceType: SourceType.manual,
        rawText: rawText,
        merchantName: merchantName,
        upiId: _upiId,
        bankName: bankName,
        accountHint: _accountHint,
        referenceId: _referenceId,
        balancePaise: _balancePaise,
      );

      final id = await ref.read(transactionRepositoryProvider).insert(parsed);
      if (_category != null || note != null) {
        await ref.read(transactionRepositoryProvider).setCategory(id, _category, note);
      }

      if (_category != null && merchantName != null) {
        await ref.read(categoryRepositoryProvider).saveRule(merchantName, _category!);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_type == TransactionType.debit ? "Debit" : "Credit"} of ₹$amountText recorded',
            ),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to record transaction: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDebit = _type == TransactionType.debit;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Transaction'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Transaction Type Selector
            SegmentedButton<TransactionType>(
              segments: const [
                ButtonSegment(
                  value: TransactionType.debit,
                  label: Text('Debit (Expense)'),
                  icon: Icon(Icons.arrow_upward, color: Colors.red),
                ),
                ButtonSegment(
                  value: TransactionType.credit,
                  label: Text('Credit (Income)'),
                  icon: Icon(Icons.arrow_downward, color: Colors.green),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (set) {
                setState(() => _type = set.first);
              },
            ),
            const SizedBox(height: 16),

            // Amount Input
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Amount', style: theme.textTheme.labelMedium),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                      ],
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDebit ? Colors.red.shade700 : Colors.green.shade700,
                      ),
                      decoration: InputDecoration(
                        prefixText: '₹ ',
                        prefixStyle: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDebit ? Colors.red.shade700 : Colors.green.shade700,
                        ),
                        hintText: '0.00',
                        border: const OutlineInputBorder(),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Enter an amount';
                        }
                        final parsed = double.tryParse(val.trim());
                        if (parsed == null || parsed <= 0) {
                          return 'Enter a valid amount';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Payee / Merchant
            TextFormField(
              controller: _merchantController,
              decoration: const InputDecoration(
                labelText: 'Payee / Merchant / Description',
                hintText: 'e.g. Swiggy, Salary, Friend name',
                prefixIcon: Icon(Icons.storefront_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Category Picker Card
            Card(
              child: ListTile(
                leading: Icon(Icons.category_outlined, color: theme.colorScheme.primary),
                title: const Text('Category'),
                subtitle: Text(
                  _category ?? 'Uncategorized',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _category != null ? theme.colorScheme.primary : null,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: _pickCategory,
              ),
            ),
            const SizedBox(height: 12),

            // Date & Time Row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(Fmt.monthYear(_occurredAt)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.access_time, size: 18),
                    label: Text(
                      TimeOfDay(hour: _occurredAt.hour, minute: _occurredAt.minute).format(context),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Bank Name & Note
            TextFormField(
              controller: _bankController,
              decoration: const InputDecoration(
                labelText: 'Bank / Account (optional)',
                hintText: 'e.g. HDFC, BOB, SBI, Cash',
                prefixIcon: Icon(Icons.account_balance_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'Any extra details',
                prefixIcon: Icon(Icons.note_alt_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Expandable SMS Auto-fill helper
            ExpansionTile(
              leading: const Icon(Icons.sms_outlined),
              title: const Text('Auto-fill from SMS / Message text'),
              subtitle: const Text('Paste transaction SMS to fill details automatically'),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      TextField(
                        controller: _smsTextController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Paste SMS text here (e.g. "Dear BOB User: Your account is credited with INR 5.00...")',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _parseSms,
                          icon: const Icon(Icons.auto_awesome),
                          label: const Text('Parse & Auto-fill'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              key: const Key('record_transaction_button'),
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check),
              label: Text(_saving ? 'Recording...' : 'Record Transaction'),
            ),
          ),
        ),
      ),
    );
  }
}
