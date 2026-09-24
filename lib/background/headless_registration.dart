import 'dart:ui';

import 'package:flutter/services.dart';

import 'headless_entrypoint.dart';

const _platformChannel = MethodChannel('upi_tracker/platform');

/// Computes a stable handle for [backgroundMain] and hands it to Kotlin to
/// persist (in native SharedPreferences, not a Flutter plugin — see
/// HeadlessEngineManager.saveCallbackHandle). Kotlin needs this to know which
/// Dart entrypoint to run later, potentially in a process where the app
/// never got a chance to start normally.
///
/// Call once at app startup. Safe to call every launch — it's cheap and
/// idempotent (the handle for a given function never changes).
Future<void> registerHeadlessCallbackHandle() async {
  final handle = PluginUtilities.getCallbackHandle(backgroundMain);
  if (handle == null) return;
  await _platformChannel.invokeMethod('registerHeadlessCallbackHandle', {
    'handle': handle.toRawHandle(),
  });
}
