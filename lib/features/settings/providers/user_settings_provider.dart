import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/service_providers.dart';
import '../../auth/providers/auth_providers.dart';
import '../../../models/user_settings_model.dart';

final userSettingsProvider =
    AsyncNotifierProvider<UserSettingsNotifier, UserSettingsEnvelope>(
      UserSettingsNotifier.new,
    );

class UserSettingsNotifier extends AsyncNotifier<UserSettingsEnvelope> {
  @override
  Future<UserSettingsEnvelope> build() {
    ref.watch(currentUserProvider.select((user) => user?.id));
    return ref.watch(userSettingsServiceProvider).getCurrentSettings();
  }

  Future<void> save(UserSettings settings) async {
    state = await AsyncValue.guard(
      () =>
          ref.read(userSettingsServiceProvider).updateCurrentSettings(settings),
    );
  }

  Future<void> reset() async {
    state = await AsyncValue.guard(
      () => ref.read(userSettingsServiceProvider).resetCurrentSettings(),
    );
  }
}
