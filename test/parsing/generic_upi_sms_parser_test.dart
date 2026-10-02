import 'package:flutter_test/flutter_test.dart';
import 'package:upi_expense_tracker/domain/models/raw_event.dart';
import 'package:upi_expense_tracker/domain/models/transaction_source.dart';
import 'package:upi_expense_tracker/domain/models/transaction_type.dart';
import 'package:upi_expense_tracker/parsing/sms/generic_upi_sms_parser.dart';

void main() {
  final parser = GenericUpiSmsParser();
  final now = DateTime(2026, 1, 15, 10, 30);

  RawEvent sms(String text, {String origin = 'HDFCBK'}) =>
      RawEvent(sourceType: SourceType.sms, origin: origin, text: text, receivedAt: now);

  test('canHandle only accepts sms events', () {
    expect(parser.canHandle(sms('anything')), isTrue);
    expect(
      parser.canHandle(RawEvent(
        sourceType: SourceType.notification,
        origin: 'x',
        text: 'debited',
        receivedAt: now,
      )),
      isFalse,
    );
  });

  test('parses a standard HDFC UPI debit', () {
    final event = sms(
      'Dear Customer, Rs.500.00 debited from A/c XX1234 on 15-01-24 to VPA '
      'merchant@ybl (UPI Ref No 302615478321). Not you? Call 18002586161 -HDFC Bank',
    );

    final result = parser.tryParse(event);

    expect(result, isNotNull);
    expect(result!.amountPaise, 50000);
    expect(result.type, TransactionType.debit);
    expect(result.upiId, 'merchant@ybl');
    expect(result.bankName, 'HDFC Bank');
    expect(result.accountHint, 'XX1234');
    expect(result.referenceId, '302615478321');
    // The SMS has a date but no time-of-day; extractDateTime keeps the
    // received time-of-day rather than defaulting to a misleading midnight.
    expect(result.occurredAt, DateTime(2024, 1, 15, 10, 30));
  });

  test('parses a standard credit and captures the payer VPA', () {
    final event = sms(
      'Rs.15,000.00 credited to your A/c XX1234 on 20-01-24 from VPA '
      'employer@okaxis (UPI Ref No 400011122233). -HDFC Bank',
    );

    final result = parser.tryParse(event);

    expect(result, isNotNull);
    expect(result!.amountPaise, 1500000);
    expect(result.type, TransactionType.credit);
    expect(result.upiId, 'employer@okaxis');
    expect(result.referenceId, '400011122233');
  });

  test('excludes the available-balance amount, keeping the transaction amount', () {
    final event = sms(
      'Rs.250.00 debited from A/c XX1234 on 15-01-24 to merchant@ybl UPI Ref '
      'No 111122223333. Avl Bal Rs.48,750.00 -HDFC Bank',
    );

    final result = parser.tryParse(event);

    expect(result!.amountPaise, 25000);
  });

  test('extracts a merchant name when no VPA is present', () {
    final event = sms(
      'Rs.1200.00 debited from A/c XX1234 on 15-01-24 towards Big Bazaar '
      'Ref No 555566667777 -HDFC Bank',
    );

    final result = parser.tryParse(event);

    expect(result, isNotNull);
    expect(result!.merchantName, 'Big Bazaar');
    expect(result.upiId, isNull);
  });

  test('does not produce a truncated name when VPA text breaks the name regex', () {
    final event = sms(
      'Rs.15000.00 credited to your A/c XX1234 on 20-01-24 from VPA '
      'employer@okaxis (UPI Ref No 400011122233). -HDFC Bank',
    );

    final result = parser.tryParse(event);

    // The payer-name regex can't cross the '@', so it must not leak a
    // truncated "employer"-style fragment into merchantName.
    expect(result!.merchantName, isNull);
  });

  test('rejects an OTP message even though it mentions an amount', () {
    final event = sms('123456 is your OTP for a transaction of Rs.5000 at Amazon. Do not share it.');
    expect(parser.tryParse(event), isNull);
  });

  test('rejects a card-blocked / promotional style message', () {
    final event = sms('Get cashback up to Rs.500 on your next UPI payment! Offer valid till 31-Jan.');
    expect(parser.tryParse(event), isNull);
  });

  test('rejects a future EMI-due reminder, not a completed transaction', () {
    final event = sms('Your EMI of Rs.2500.00 is due on 25-01-24. Please ensure sufficient balance.');
    expect(parser.tryParse(event), isNull);
  });

  test('rejects a failed payment attempt', () {
    final event = sms('Your UPI payment of Rs.500 to merchant@ybl has failed. Please retry.');
    expect(parser.tryParse(event), isNull);
  });

  test('returns null when there is no debit/credit keyword at all', () {
    final event = sms('Your account statement for January is now available. Download the app to view.');
    expect(parser.tryParse(event), isNull);
  });

  test('returns null when amount cannot be found', () {
    final event = sms('Your account was debited towards UPI payment to merchant@ybl Ref No 123456789012.');
    expect(parser.tryParse(event), isNull);
  });

  test('captures a non-UPI card/account debit too (broadened per spec)', () {
    final event = sms(
      'Your HDFC Bank A/c XX1234 has been debited with Rs.2500.00 on 15-01-24 '
      'towards purchase at AMAZON. Avl Bal Rs 47500.00',
    );

    final result = parser.tryParse(event);

    expect(result, isNotNull);
    expect(result!.amountPaise, 250000);
    expect(result.upiId, isNull);
  });

  test('parses a real Bank of Baroda debit phrased as "Dr. from A/c X and Cr. to VPA Y"', () {
    // Real message reported by a user testing on-device: this used to be
    // silently dropped, because both "Dr." and "Cr." appear in the text —
    // the old check treated any message with both words as ambiguous,
    // without noticing "Cr." here describes the payee's side, not the
    // user's own account.
    final event = sms(
      'Rs.10.00 Dr. from A/C XXXXXX0011 and Cr. to paytm.s3klfey@pty. '
      'Ref:216339664246. AvlBal:Rs12817.87(2026:09:23 09:01:53). '
      'Not you? Call 18005700/5000-BOB',
      origin: 'BOB',
    );

    final result = parser.tryParse(event);

    expect(result, isNotNull);
    expect(result!.type, TransactionType.debit);
    expect(result.amountPaise, 1000);
    expect(result.upiId, 'paytm.s3klfey@pty');
    expect(result.referenceId, '216339664246');
    expect(result.accountHint, 'XXXXXX0011');
    expect(result.bankName, 'Bank of Baroda');
  });

  test('a message where your account is both debited and credited is genuinely ambiguous', () {
    final event = sms(
      'Your A/c XX1234 was debited by Rs.500 and your A/c XX1234 was credited by Rs.500 due to a reversal.',
    );

    expect(parser.tryParse(event), isNull);
  });

  test('parses correctly when the SMS uses \\r\\n line breaks instead of \\n', () {
    final event = sms(
      'Dear Customer,\r\nRs.500.00 debited from A/c XX1234 on 15-01-24 to merchant@ybl\r\n'
      'UPI Ref No 302615478321 -HDFC Bank',
    );

    final result = parser.tryParse(event);

    expect(result, isNotNull);
    expect(result!.amountPaise, 50000);
    expect(result.referenceId, '302615478321');
  });

  test('infers bank name from sender id', () {
    final event = sms(
      'Rs.100.00 debited from A/c XX9999 to shop@icici Ref No 999988887777 on 15-01-24',
      origin: 'AD-ICICIB-S',
    );

    expect(parser.tryParse(event)!.bankName, 'ICICI Bank');
  });

  test('extracts note/remark from SMS with explicit Remark or Note prefix', () {
    final event = sms(
      'Rs.200.00 debited from A/c XX1234 to tea@upi Ref No 123456789012. Remark: Evening tea',
    );

    final result = parser.tryParse(event);

    expect(result, isNotNull);
    expect(result!.note, 'Evening tea');
  });

  test('extracts purpose from SMS with for <purpose>', () {
    final event = sms(
      'Rs.1200.00 debited from A/c XX1234 on 15-01-24 to Ramesh for Room Rent Ref: 555566667777',
    );

    final result = parser.tryParse(event);

    expect(result, isNotNull);
    expect(result!.merchantName, 'Ramesh');
    expect(result.note, 'Room Rent');
  });
}
