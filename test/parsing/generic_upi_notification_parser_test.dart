import 'package:flutter_test/flutter_test.dart';
import 'package:upi_expense_tracker/domain/models/raw_event.dart';
import 'package:upi_expense_tracker/domain/models/transaction_source.dart';
import 'package:upi_expense_tracker/domain/models/transaction_type.dart';
import 'package:upi_expense_tracker/parsing/notification/generic_upi_notification_parser.dart';

void main() {
  final parser = GenericUpiNotificationParser();
  final now = DateTime(2026, 1, 15, 18, 45);

  RawEvent notif(String text, {String origin = 'com.google.android.apps.nbu.paisa.user'}) =>
      RawEvent(sourceType: SourceType.notification, origin: origin, text: text, receivedAt: now);

  test('canHandle requires a known UPI app package', () {
    expect(parser.canHandle(notif('paid')), isTrue);
    expect(parser.canHandle(notif('paid', origin: 'com.some.random.app')), isFalse);
  });

  test('parses a Google Pay payment-successful notification as a debit', () {
    final event = notif('Payment successful | ₹250 paid to Tea Stall using HDFC Bank');

    final result = parser.tryParse(event);

    expect(result, isNotNull);
    expect(result!.amountPaise, 25000);
    expect(result.type, TransactionType.debit);
    expect(result.merchantName, 'Tea Stall');
    expect(result.sourceApp, 'Google Pay');
    expect(result.occurredAt, now);
  });

  test('parses a PhonePe received notification as a credit', () {
    final event = notif(
      'Money received | You received ₹1500 from John Doe',
      origin: 'com.phonepe.app',
    );

    final result = parser.tryParse(event);

    expect(result, isNotNull);
    expect(result!.amountPaise, 150000);
    expect(result.type, TransactionType.credit);
    expect(result.merchantName, 'John Doe');
    expect(result.sourceApp, 'PhonePe');
  });

  test('extracts a reference id when the notification text includes one, without corrupting the name', () {
    final event = notif('Payment successful | ₹250 paid to Tea Stall Ref No 302615478321');

    final result = parser.tryParse(event);

    expect(result!.referenceId, '302615478321');
    expect(result.merchantName, 'Tea Stall');
  });

  test('captures the VPA when the notification shows one instead of a name', () {
    final event = notif('Payment successful | ₹99 paid to shop@icici using ICICI Bank');

    final result = parser.tryParse(event);

    expect(result!.upiId, 'shop@icici');
  });

  test('rejects a payment request (nothing has been paid yet)', () {
    final event = notif('Payment request | Rahul requested ₹500 from you');
    expect(parser.tryParse(event), isNull);
  });

  test('rejects a failed payment notification', () {
    final event = notif('Payment failed | Your payment of ₹300 to merchant@ybl could not be completed');
    expect(parser.tryParse(event), isNull);
  });

  test('rejects a promotional/reward notification', () {
    final event = notif('Scratch card unlocked! | You could win up to ₹1000 cashback');
    expect(parser.tryParse(event), isNull);
  });

  test('ignores notifications from apps outside the known UPI app list', () {
    final event = notif('₹100 paid to someone', origin: 'com.whatsapp');
    expect(parser.canHandle(event), isFalse);
  });
}
