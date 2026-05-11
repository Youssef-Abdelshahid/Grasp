import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/service_providers.dart';
import '../../../models/upload_limits_model.dart';

final uploadLimitsProvider =
    AsyncNotifierProvider<UploadLimitsNotifier, UploadLimitsConfig>(
      UploadLimitsNotifier.new,
    );

class UploadLimitsNotifier extends AsyncNotifier<UploadLimitsConfig> {
  @override
  Future<UploadLimitsConfig> build() {
    return ref.watch(uploadLimitsServiceProvider).getEffectiveConfig();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(uploadLimitsServiceProvider).getEffectiveConfig(),
    );
  }
}

final adminUploadLimitsProvider =
    AsyncNotifierProvider<AdminUploadLimitsNotifier, UploadLimitsConfig>(
      AdminUploadLimitsNotifier.new,
    );

class AdminUploadLimitsNotifier extends AsyncNotifier<UploadLimitsConfig> {
  @override
  Future<UploadLimitsConfig> build() {
    return ref.watch(uploadLimitsServiceProvider).getAdminConfig();
  }

  Future<UploadLimitsConfig> save(UploadLimitsConfig config) async {
    state = const AsyncLoading();
    try {
      final saved = await ref
          .read(uploadLimitsServiceProvider)
          .updateAdminConfig(config);
      state = AsyncData(saved);
      ref.invalidate(uploadLimitsProvider);
      ref.invalidate(uploadStorageOverviewProvider);
      return saved;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<UploadLimitsConfig> reset() async {
    state = const AsyncLoading();
    try {
      final saved = await ref.read(uploadLimitsServiceProvider).resetAdminConfig();
      state = AsyncData(saved);
      ref.invalidate(uploadLimitsProvider);
      ref.invalidate(uploadStorageOverviewProvider);
      return saved;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}

final uploadStorageOverviewProvider = FutureProvider<UploadStorageOverview>(
  (ref) => ref.watch(uploadLimitsServiceProvider).getStorageOverview(),
);

extension UploadLimitsAsyncSelectors on AsyncValue<UploadLimitsConfig> {
  UploadLimitsConfig get valueOrDefaults =>
      valueOrNull ?? UploadLimitsConfig.defaults();
}
