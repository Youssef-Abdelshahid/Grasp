import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/service_providers.dart';
import '../../../models/permissions_model.dart';

final permissionsProvider =
    AsyncNotifierProvider<PermissionsNotifier, AppPermissions>(
      PermissionsNotifier.new,
    );

final publicRegistrationPermissionsProvider =
    FutureProvider<({bool student, bool instructor})>((ref) {
  return ref
      .watch(permissionsServiceProvider)
      .getPublicRegistrationPermissions();
});

class PermissionsNotifier extends AsyncNotifier<AppPermissions> {
  @override
  Future<AppPermissions> build() {
    return ref.watch(permissionsServiceProvider).getPermissions();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(permissionsServiceProvider).getPermissions(),
    );
  }
}

final adminPermissionsProvider =
    AsyncNotifierProvider<AdminPermissionsNotifier, AppPermissions>(
      AdminPermissionsNotifier.new,
    );

class AdminPermissionsNotifier extends AsyncNotifier<AppPermissions> {
  @override
  Future<AppPermissions> build() {
    return ref.watch(permissionsServiceProvider).getAdminPermissions();
  }

  Future<AppPermissions> save(AppPermissions permissions) async {
    state = const AsyncLoading();
    try {
      final saved = await ref
          .read(permissionsServiceProvider)
          .updateAdminPermissions(permissions);
      state = AsyncData(saved);
      ref.invalidate(permissionsProvider);
      ref.invalidate(publicRegistrationPermissionsProvider);
      return saved;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<AppPermissions> reset() async {
    state = const AsyncLoading();
    try {
      final saved = await ref
          .read(permissionsServiceProvider)
          .resetAdminPermissions();
      state = AsyncData(saved);
      ref.invalidate(permissionsProvider);
      ref.invalidate(publicRegistrationPermissionsProvider);
      return saved;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}

extension PermissionAsyncSelectors on AsyncValue<AppPermissions> {
  AppPermissions get valueOrDefaults => valueOrNull ?? AppPermissions.defaults();
}
