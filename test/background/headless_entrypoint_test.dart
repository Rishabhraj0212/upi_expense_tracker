import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upi_expense_tracker/background/headless_entrypoint.dart';
import 'package:upi_expense_tracker/data/drift_transaction_repository.dart';
import 'package:upi_expense_tracker/data/drift_category_repository.dart';
import 'package:upi_expense_tracker/data/local/app_database.dart';

/// Simulates Kotlin sending a MethodCall into a channel Dart has registered
/// a handler for, and returns the decoded reply.
Future<Object?> _simulateIncomingCall(MethodChannel channel, MethodCall call) async {
  const codec = StandardMethodCodec();
  final data = codec.encodeMethodCall(call);
  final completer = Completer<ByteData?>();
  await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
    channel.name,
    data,
    (reply) => completer.complete(reply),
  );
  final reply = await completer.future;
  return reply == null ? null : codec.decodeEnvelope(reply);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('wires the channel so an incoming "ingest" call reaches the real pipeline', () async {
    const channel = MethodChannel('test_headless_channel');
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final readyCalls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (call) async {
        readyCalls.add(call);
        return null;
      },
    );
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    runBackgroundIngestion(
      channel: channel, 
      buildRepository: () => DriftTransactionRepository(db),
      buildCategoryRepository: () => DriftCategoryRepository(db),
    );

    expect(readyCalls.map((c) => c.method), contains('ready'));

    await _simulateIncomingCall(
      channel,
      const MethodCall('ingest', {
        'kind': 'sms',
        'origin': 'HDFCBK',
        'text': 'Rs.500.00 debited from A/c XX1234 to merchant@ybl UPI Ref No 302615478321',
        'receivedAt': 1768000000000,
      }),
    );

    final repo = DriftTransactionRepository(db);
    final all = await repo.getAll();
    expect(all, hasLength(1));
    expect(all.single.amountPaise, 50000);
  });

  test('an unrecognized method is a no-op, not an error', () async {
    const channel = MethodChannel('test_headless_channel_2');
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (call) async => null,
    );
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    runBackgroundIngestion(
      channel: channel, 
      buildRepository: () => DriftTransactionRepository(db),
      buildCategoryRepository: () => DriftCategoryRepository(db),
    );

    await _simulateIncomingCall(channel, const MethodCall('somethingElse', {}));

    final repo = DriftTransactionRepository(db);
    expect(await repo.getAll(), isEmpty);
  });
}
