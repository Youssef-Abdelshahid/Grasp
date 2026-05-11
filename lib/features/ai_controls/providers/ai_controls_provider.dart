import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/service_providers.dart';
import '../../../models/ai_controls_model.dart';

final aiControlsProvider =
    AsyncNotifierProvider<AiControlsNotifier, AiControlsConfig>(
      AiControlsNotifier.new,
    );

class AiControlsNotifier extends AsyncNotifier<AiControlsConfig> {
  @override
  Future<AiControlsConfig> build() {
    return ref.watch(aiControlsServiceProvider).getEffectiveConfig();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(aiControlsServiceProvider).getEffectiveConfig(),
    );
  }
}

final adminAiControlsProvider =
    AsyncNotifierProvider<AdminAiControlsNotifier, AiControlsConfig>(
      AdminAiControlsNotifier.new,
    );

class AdminAiControlsNotifier extends AsyncNotifier<AiControlsConfig> {
  @override
  Future<AiControlsConfig> build() {
    return ref.watch(aiControlsServiceProvider).getAdminConfig();
  }

  Future<AiControlsConfig> save(AiControlsConfig config) async {
    state = const AsyncLoading();
    try {
      final saved = await ref.read(aiControlsServiceProvider).updateAdminConfig(
            config,
          );
      state = AsyncData(saved);
      ref.invalidate(aiControlsProvider);
      ref.invalidate(aiUsageStatsProvider);
      return saved;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<AiControlsConfig> reset() async {
    state = const AsyncLoading();
    try {
      final saved = await ref.read(aiControlsServiceProvider).resetAdminConfig();
      state = AsyncData(saved);
      ref.invalidate(aiControlsProvider);
      ref.invalidate(aiUsageStatsProvider);
      return saved;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}

final aiUsageStatsProvider = FutureProvider<AiUsageStats>((ref) {
  return ref.watch(aiControlsServiceProvider).getUsageStats();
});

extension AiControlsAsyncSelectors on AsyncValue<AiControlsConfig> {
  AiControlsConfig get valueOrDefaults =>
      valueOrNull ?? AiControlsConfig.defaults();
}
