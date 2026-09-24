import 'package:flutter_test/flutter_test.dart';
import 'package:upi_expense_tracker/domain/models/transaction_source.dart';
import 'package:upi_expense_tracker/platform/native_bridge.dart';

void main() {
  test('converts a well-formed SMS payload into a RawEvent', () {
    final event = smsRawEventFromPayload({
      'origin': 'HDFCBK',
      'text': 'Rs.500.00 debited from A/c XX1234 to merchant@ybl',
      'receivedAt': 1768000000000,
    });

    expect(event.sourceType, SourceType.sms);
    expect(event.origin, 'HDFCBK');
    expect(event.text, 'Rs.500.00 debited from A/c XX1234 to merchant@ybl');
    expect(event.receivedAt, DateTime.fromMillisecondsSinceEpoch(1768000000000));
  });

  test('falls back to empty strings for missing origin/text rather than throwing', () {
    final event = smsRawEventFromPayload({'receivedAt': 1768000000000});

    expect(event.origin, '');
    expect(event.text, '');
  });

  test('falls back to DateTime.now() when receivedAt is missing', () {
    final before = DateTime.now();
    final event = smsRawEventFromPayload({'origin': 'HDFCBK', 'text': 'hi'});
    final after = DateTime.now();

    expect(event.receivedAt.isBefore(before.subtract(const Duration(seconds: 1))), isFalse);
    expect(event.receivedAt.isAfter(after.add(const Duration(seconds: 1))), isFalse);
  });

  test('accepts a platform-channel-style Map<Object?, Object?> as well as Map<String, dynamic>', () {
    final Map<Object?, Object?> platformStyle = {
      'origin': 'SBIINB',
      'text': 'debited by 100',
      'receivedAt': 1700000000000,
    };

    final event = smsRawEventFromPayload(platformStyle);

    expect(event.origin, 'SBIINB');
  });

  test('combines title and text into "title | text" for a well-formed notification payload', () {
    final event = notificationRawEventFromPayload({
      'packageName': 'com.google.android.apps.nbu.paisa.user',
      'title': 'Payment successful',
      'text': '₹250 paid to Tea Stall',
      'receivedAt': 1768000000000,
    });

    expect(event.sourceType, SourceType.notification);
    expect(event.origin, 'com.google.android.apps.nbu.paisa.user');
    expect(event.text, 'Payment successful | ₹250 paid to Tea Stall');
    expect(event.receivedAt, DateTime.fromMillisecondsSinceEpoch(1768000000000));
  });

  test('does not leave a stray separator when only the title or only the text is present', () {
    final titleOnly = notificationRawEventFromPayload({
      'packageName': 'com.phonepe.app',
      'title': 'Payment successful',
      'text': '',
      'receivedAt': 1768000000000,
    });
    final textOnly = notificationRawEventFromPayload({
      'packageName': 'com.phonepe.app',
      'title': '',
      'text': '₹250 paid to Tea Stall',
      'receivedAt': 1768000000000,
    });

    expect(titleOnly.text, 'Payment successful');
    expect(textOnly.text, '₹250 paid to Tea Stall');
  });

  test('notification payload falls back gracefully when fields are missing', () {
    final event = notificationRawEventFromPayload({});

    expect(event.origin, '');
    expect(event.text, '');
  });

  test('headless dispatch routes an sms-kind payload through smsRawEventFromPayload', () {
    final event = headlessRawEventFromArguments({
      'kind': 'sms',
      'origin': 'HDFCBK',
      'text': 'Rs.500.00 debited from A/c XX1234 to merchant@ybl',
      'receivedAt': 1768000000000,
    });

    expect(event, isNotNull);
    expect(event!.sourceType, SourceType.sms);
    expect(event.origin, 'HDFCBK');
  });

  test('headless dispatch routes a notification-kind payload through notificationRawEventFromPayload', () {
    final event = headlessRawEventFromArguments({
      'kind': 'notification',
      'packageName': 'com.phonepe.app',
      'title': 'Payment successful',
      'text': '₹250 paid to Tea Stall',
      'receivedAt': 1768000000000,
    });

    expect(event, isNotNull);
    expect(event!.sourceType, SourceType.notification);
    expect(event.text, 'Payment successful | ₹250 paid to Tea Stall');
  });

  test('headless dispatch returns null for an unrecognized or missing kind', () {
    expect(headlessRawEventFromArguments({'kind': 'unknown'}), isNull);
    expect(headlessRawEventFromArguments({'origin': 'HDFCBK'}), isNull);
  });
}
