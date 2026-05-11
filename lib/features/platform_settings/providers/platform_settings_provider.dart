import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/service_providers.dart';
import '../../../models/platform_settings_model.dart';

final platformSettingsProvider =
    AsyncNotifierProvider<PlatformSettingsNotifier, PlatformSettingsConfig>(
  PlatformSettingsNotifier.new,
);

class PlatformSettingsNotifier extends AsyncNotifier<PlatformSettingsConfig> {
  @override
  Future<PlatformSettingsConfig> build() {
    return ref.watch(platformSettingsServiceProvider).getEffectiveSettings();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(platformSettingsServiceProvider).getEffectiveSettings(),
    );
  }
}

final publicPlatformSettingsProvider =
    FutureProvider<PlatformSettingsConfig>((ref) {
  return ref.watch(platformSettingsServiceProvider).getPublicSettings();
});

final adminPlatformSettingsProvider = AsyncNotifierProvider<
    AdminPlatformSettingsNotifier, PlatformSettingsConfig>(
  AdminPlatformSettingsNotifier.new,
);

class AdminPlatformSettingsNotifier
    extends AsyncNotifier<PlatformSettingsConfig> {
  @override
  Future<PlatformSettingsConfig> build() {
    return ref.watch(platformSettingsServiceProvider).getAdminSettings();
  }

  Future<PlatformSettingsConfig> save(PlatformSettingsConfig settings) async {
    state = const AsyncLoading();
    try {
      final saved = await ref
          .read(platformSettingsServiceProvider)
          .updateAdminSettings(settings);
      state = AsyncData(saved);
      ref.invalidate(platformSettingsProvider);
      ref.invalidate(publicPlatformSettingsProvider);
      return saved;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<PlatformSettingsConfig> reset() async {
    state = const AsyncLoading();
    try {
      final saved =
          await ref.read(platformSettingsServiceProvider).resetAdminSettings();
      state = AsyncData(saved);
      ref.invalidate(platformSettingsProvider);
      ref.invalidate(publicPlatformSettingsProvider);
      return saved;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> forceLogoutAllUsers() async {
    await ref.read(platformSettingsServiceProvider).forceLogoutAllUsers();
    ref.invalidate(platformSettingsProvider);
    ref.invalidate(publicPlatformSettingsProvider);
  }
}

extension PlatformSettingsAsyncSelectors on AsyncValue<PlatformSettingsConfig> {
  PlatformSettingsConfig get valueOrDefaults =>
      valueOrNull ?? PlatformSettingsConfig.defaults();
}
