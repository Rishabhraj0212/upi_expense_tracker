import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'background/headless_registration.dart';
import 'presentation/providers/app_providers.dart';
import 'presentation/providers/sync_providers.dart';
import 'presentation/screens/app_startup_gate.dart';

void main() {
  // registerHeadlessCallbackHandle uses a MethodChannel, which needs the
  // binding initialized first — runApp() would do this too, but only after
  // it runs, and the call below is fire-and-forget before that point.
  WidgetsFlutterBinding.ensureInitialized();
  registerHeadlessCallbackHandle();
  runApp(const ProviderScope(child: UpiExpenseApp()));
}

class UpiExpenseApp extends ConsumerWidget {
  const UpiExpenseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Reading these once at startup opens the native event subscriptions for
    // the lifetime of the app; nothing in the UI needs their values.
    ref.watch(smsIngestionControllerProvider);
    ref.watch(notificationIngestionControllerProvider);
    // Activate auto-sync listener for the lifetime of the app.
    ref.watch(autoSyncControllerProvider);

    ThemeData theme(Brightness b) => ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal, brightness: b),
          useMaterial3: true,
        );
    return MaterialApp(
      title: 'UPI Expenses',
      theme: theme(Brightness.light),
      darkTheme: theme(Brightness.dark),
      home: const AppStartupGate(),
    );
  }
}
