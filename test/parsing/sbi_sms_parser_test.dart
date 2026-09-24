import 'package:flutter_test/flutter_test.dart';
import 'package:upi_expense_tracker/domain/models/raw_event.dart';
import 'package:upi_expense_tracker/domain/models/transaction_source.dart';
import 'package:upi_expense_tracker/domain/models/transaction_type.dart';
import 'package:upi_expense_tracker/parsing/sms/sbi_sms_parser.dart';

void main() {
  final parser = SbiSmsParser();
  final now = DateTime(2026, 1, 15, 10, 30);

  RawEvent sms(String text, {String origin = 'SBIINB'}) =>
      RawEvent(sourceType: SourceType.sms, origin: origin, text: text, receivedAt: now);

  test('canHandle only accepts SMS from an SBI-like sender', () {
    expect(parser.canHandle(sms('debited by 100', origin: 'SBIINB')), isTrue);
    expect(parser.canHandle(sms('debited by 100', origin: 'JD-SBIUPI')), isTrue);
    expect(parser.canHandle(sms('debited by 100', origin: 'HDFCBK')), isFalse);
  });

  test('parses the no-separator SBI debit format', () {
    final event = sms(
      'Dear UPI user A/C X1234 debited by 500.0 on date 12Jan24 trf to '
      'merchant@ybl Refno 302615478321.If not u? call 1800111109 -SBI',
    );

    final result = parser.tryParse(event);

    expect(result, isNotNull);
    expect(result!.amountPaise, 50000);
    expect(result.type, TransactionType.debit);
    expect(result.upiId, 'merchant@ybl');
    expect(result.bankName, 'State Bank of India');
    expect(result.accountHint, 'X1234');
    expect(result.referenceId, '302615478321');
    expect(result.occurredAt, DateTime(2024, 1, 12));
  });

  test('parses an SBI credit', () {
    final event = sms(
      'Dear UPI user A/C X1234 credited by 2500.0 on date 05Feb24 trf to '
      'payer@oksbi Refno 111122223333 -SBI',
    );

    final result = parser.tryParse(event);

    expect(result, isNotNull);
    expect(result!.amountPaise, 250000);
    expect(result.type, TransactionType.credit);
    expect(result.occurredAt, DateTime(2024, 2, 5));
  });

  test('extracts a plain merchant name when no VPA is present', () {
    final event = sms(
      'Dear UPI user A/C X1234 debited by 300.0 on date 12Jan24 trf to Tea '
      'Stall Refno 444455556666 -SBI',
    );

    final result = parser.tryParse(event);

    expect(result!.merchantName, 'Tea Stall');
  });

  test('falls back to receivedAt when the odd date format is missing', () {
    final event = sms('Dear UPI user A/C X1234 debited by 100.0 trf to shop@ybl Refno 777788889999 -SBI');

    final result = parser.tryParse(event);

    expect(result!.occurredAt, now);
  });

  test('returns null for a non-transactional SBI message', () {
    final event = sms('Dear Customer, your SBI net banking password was changed successfully.');
    expect(parser.tryParse(event), isNull);
  });
}
