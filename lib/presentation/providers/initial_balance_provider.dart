import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden in ProviderScope');
});

class InitialBalanceNotifier extends Notifier<int> {
  static const _key = 'initial_balance_paise';

  @override
  int build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getInt(_key) ?? 0;
  }

  Future<void> setBalance(int amountPaise) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setInt(_key, amountPaise);
    state = amountPaise;
  }
}

final initialBalanceProvider = NotifierProvider<InitialBalanceNotifier, int>(
  InitialBalanceNotifier.new,
);
