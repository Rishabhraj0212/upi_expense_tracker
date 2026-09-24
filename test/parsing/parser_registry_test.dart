import 'package:flutter_test/flutter_test.dart';
import 'package:upi_expense_tracker/domain/models/raw_event.dart';
import 'package:upi_expense_tracker/domain/models/transaction_source.dart';
import 'package:upi_expense_tracker/domain/models/transaction_type.dart';
import 'package:upi_expense_tracker/parsing/parser_registry.dart';

void main() {
  final registry = ParserRegistry();
  final now = DateTime(2026, 1, 15, 10, 30);

  test('routes an SBI SMS through the SBI-specific parser, not the generic one', () {
    final event = RawEvent(
      sourceType: SourceType.sms,
      origin: 'SBIINB',
      text: 'Dear UPI user A/C X1234 debited by 500.0 on date 12Jan24 trf to '
          'merchant@ybl Refno 302615478321 -SBI',
      receivedAt: now,
    );

    final result = registry.parse(event);

    expect(result, isNotNull);
    expect(result!.bankName, 'State Bank of India');
    expect(result.amountPaise, 50000);
    expect(result.occurredAt, DateTime(2024, 1, 12));
  });

  test('routes a non-SBI SMS through the generic parser', () {
    final event = RawEvent(
      sourceType: SourceType.sms,
      origin: 'HDFCBK',
      text: 'Rs.500.00 debited from A/c XX1234 on 15-01-24 to merchant@ybl '
          'UPI Ref No 302615478321 -HDFC Bank',
      receivedAt: now,
    );

    final result = registry.parse(event);

    expect(result, isNotNull);
    expect(result!.bankName, 'HDFC Bank');
  });

  test('routes a notification through the notification parser', () {
    final event = RawEvent(
      sourceType: SourceType.notification,
      origin: 'com.phonepe.app',
      text: 'Payment successful | ₹250 paid to Tea Stall',
      receivedAt: now,
    );

    final result = registry.parse(event);

    expect(result, isNotNull);
    expect(result!.sourceApp, 'PhonePe');
    expect(result.type, TransactionType.debit);
  });

  test('falls through to the generic SMS parser when an SBI sender sends a non-SBI-shaped message', () {
    // Some banking aggregator senders route through an "SBI"-like id but use
    // the generic template; the registry should still recover the transaction.
    final event = RawEvent(
      sourceType: SourceType.sms,
      origin: 'SBICRD',
      text: 'Rs.750.00 debited from A/c XX9999 on 15-01-24 to shop@sbi UPI '
          'Ref No 888877776666',
      receivedAt: now,
    );

    final result = registry.parse(event);

    expect(result, isNotNull);
    expect(result!.amountPaise, 75000);
  });

  test('returns null for an unrecognized message', () {
    final event = RawEvent(
      sourceType: SourceType.sms,
      origin: 'HDFCBK',
      text: 'Your OTP for login is 123456. Do not share it with anyone.',
      receivedAt: now,
    );

    expect(registry.parse(event), isNull);
  });

  test('a custom parser list can be injected for testing/extension', () {
    final emptyRegistry = ParserRegistry(parsers: []);
    final event = RawEvent(
      sourceType: SourceType.sms,
      origin: 'HDFCBK',
      text: 'Rs.500.00 debited from A/c XX1234 to merchant@ybl',
      receivedAt: now,
    );

    expect(emptyRegistry.parse(event), isNull);
  });
}
