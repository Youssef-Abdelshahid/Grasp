import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/app_role.dart';
import '../../../core/providers/service_providers.dart';
import '../../../models/user_model.dart';

class AuthSnapshot {
  const AuthSnapshot({
    required this.isInitializing,
    required this.isAuthenticated,
    required this.isSupabaseConfigured,
    this.currentUser,
    this.lastError,
  });

  final bool isInitializing;
  final bool isAuthenticated;
  final bool isSupabaseConfigured;
  final UserModel? currentUser;
  final String? lastError;

  bool get hasActiveUser => isAuthenticated && currentUser?.isActive == true;
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthSnapshot>(AuthController.new);

final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(
    authControllerProvider.select((value) => value.valueOrNull?.currentUser),
  );
});

final currentRoleProvider = Provider<AppRole?>((ref) {
  return ref.watch(currentUserProvider)?.role;
});

class AuthController extends AsyncNotifier<AuthSnapshot> {
  @override
  Future<AuthSnapshot> build() async {
    final service = ref.watch(authServiceProvider);
    void syncFromService() {
      state = AsyncData(_snapshotFromService());
    }

    service.addListener(syncFromService);
    ref.onDispose(() => service.removeListener(syncFromService));

    return _snapshotFromService();
  }

  Future<void> login({required String email, required String password}) async {
    final previous = state.valueOrNull;
    state = AsyncData(
      AuthSnapshot(
        isInitializing: true,
        isAuthenticated: previous?.isAuthenticated ?? false,
        isSupabaseConfigured: previous?.isSupabaseConfigured ?? true,
        currentUser: previous?.currentUser,
        lastError: null,
      ),
    );
    final service = ref.read(authServiceProvider);
    try {
      await service.login(email: email, password: password);
    } finally {
      state = AsyncData(_snapshotFromService());
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    required AppRole role,
  }) async {
    final previous = state.valueOrNull;
    state = AsyncData(
      AuthSnapshot(
        isInitializing: true,
        isAuthenticated: previous?.isAuthenticated ?? false,
        isSupabaseConfigured: previous?.isSupabaseConfigured ?? true,
        currentUser: previous?.currentUser,
        lastError: null,
      ),
    );
    final service = ref.read(authServiceProvider);
    try {
      await service.register(
        email: email,
        password: password,
        fullName: fullName,
        role: role,
      );
    } finally {
      state = AsyncData(_snapshotFromService());
    }
  }

  Future<void> logout() async {
    await ref.read(authServiceProvider).logout();
    state = AsyncData(_snapshotFromService());
    ref.invalidate(currentUserProvider);
    ref.invalidate(currentRoleProvider);
  }

  Future<void> reloadProfile() async {
    await ref.read(authServiceProvider).reloadProfile();
    state = AsyncData(_snapshotFromService());
  }

  AuthSnapshot _snapshotFromService() {
    final service = ref.read(authServiceProvider);
    return AuthSnapshot(
      isInitializing: service.isInitializing,
      isAuthenticated: service.isAuthenticated,
      isSupabaseConfigured: service.isSupabaseConfigured,
      currentUser: service.currentUser,
      lastError: service.lastError,
    );
  }
}
