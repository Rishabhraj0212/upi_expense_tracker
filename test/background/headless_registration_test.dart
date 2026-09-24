import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upi_expense_tracker/background/headless_registration.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('registers a non-null callback handle with Kotlin over the platform channel', () async {
    const channel = MethodChannel('upi_tracker/platform');
    final calls = <MethodCall>[];

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (call) async {
        calls.add(call);
        return null;
      },
    );
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    await registerHeadlessCallbackHandle();

    expect(calls, hasLength(1));
    expect(calls.single.method, 'registerHeadlessCallbackHandle');
    final handle = calls.single.arguments['handle'];
    expect(handle, isA<int>());
  });
}
