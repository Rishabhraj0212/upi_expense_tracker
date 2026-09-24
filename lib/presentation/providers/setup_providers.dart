import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../platform/android_setup_gateway.dart';
import '../../platform/setup_gateway.dart';

final setupGatewayProvider = Provider<SetupGateway>((ref) => AndroidSetupGateway());

final setupStatusProvider = AsyncNotifierProvider<SetupStatusNotifier, SetupStatus>(SetupStatusNotifier.new);

class SetupStatusNotifier extends AsyncNotifier<SetupStatus> {
  @override
  Future<SetupStatus> build() => ref.read(setupGatewayProvider).loadStatus();

  /// Re-checks status without a permission prompt — used after the user
  /// comes back from the system settings screen, or taps "refresh" manually.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ref.read(setupGatewayProvider).loadStatus());
  }

  Future<void> requestSms() async {
    await ref.read(setupGatewayProvider).requestSmsPermission();
    await refresh();
  }
}
