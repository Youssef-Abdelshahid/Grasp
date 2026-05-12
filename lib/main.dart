import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import 'core/local_db/app_local_database.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_providers.dart';
import 'features/platform_settings/providers/platform_settings_provider.dart';
import 'features/settings/providers/user_settings_provider.dart';
import 'features/theme/providers/theme_mode_provider.dart';
import 'models/user_settings_model.dart';
import 'routing/app_navigator.dart';
import 'routing/app_router.dart';
import 'services/auth_service.dart';
import 'services/platform_settings_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.instance.initialize();
  if (!kIsWeb) {
    await AppLocalDatabase.instance.database;
  }
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: AppColors.surface,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );
  runApp(const ProviderScope(child: GraspApp()));
}

class GraspApp extends ConsumerWidget {
  const GraspApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final platformName = ref
        .watch(platformSettingsProvider)
        .valueOrDefaults
        .platformName;
    final themeMode =
        ref.watch(themeModeProvider).valueOrNull ?? ThemeMode.light;
    final isDark = themeMode == ThemeMode.dark;
    AppColors.setDarkMode(isDark);
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: AppColors.surface,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarDividerColor: AppColors.background,
      ),
    );
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser != null && currentUser.role.value != 'admin') {
      ref.listen(
        userSettingsProvider,
        (previous, next) {
          final settings = next.valueOrNull?.settings;
          final themeModeValue = switch (settings) {
            StudentSettings() => settings.themeMode,
            InstructorSettings() => settings.themeMode,
            _ => null,
          };
          if (themeModeValue != null) {
            ref.read(themeModeProvider.notifier).syncFromBackend(themeModeValue);
          }
        },
      );
    }
    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      title: platformName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      initialRoute: AppRouter.authGate,
      onGenerateRoute: AppRouter.onGenerateRoute,
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: AppColors.surface,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
          systemNavigationBarColor: AppColors.background,
          systemNavigationBarIconBrightness:
              isDark ? Brightness.light : Brightness.dark,
          systemNavigationBarDividerColor: AppColors.background,
        ),
        child: ColoredBox(
          color: AppColors.surface,
          child: PlatformInactivityLogout(
            child: SafeArea(
              left: false,
              right: false,
              bottom: false,
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }
}

class PlatformInactivityLogout extends ConsumerStatefulWidget {
  const PlatformInactivityLogout({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PlatformInactivityLogout> createState() =>
      _PlatformInactivityLogoutState();
}

class _PlatformInactivityLogoutState
    extends ConsumerState<PlatformInactivityLogout> {
  Timer? _timer;
  Timer? _sessionCheckTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resetTimer());
    _sessionCheckTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _checkSessionInvalidation(refresh: true),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sessionCheckTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(platformSettingsProvider, (previous, next) {
      if (previous?.valueOrNull != next.valueOrNull) {
        _resetTimer();
      }
    });
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _resetTimer(),
      onPointerMove: (_) => _resetTimer(),
      onPointerSignal: (_) => _resetTimer(),
      child: widget.child,
    );
  }

  void _resetTimer() {
    _timer?.cancel();
    final settings = ref.read(platformSettingsProvider).valueOrNull;
    if (settings == null ||
        !settings.autoLogoutInactiveUsers ||
        !AuthService.instance.isAuthenticated) {
      return;
    }
    _timer = Timer(Duration(minutes: settings.timeoutDurationMinutes), () async {
      if (!mounted || !AuthService.instance.isAuthenticated) return;
      await _logoutWithMessage('You were signed out after being inactive.');
    });
  }

  Future<void> _checkSessionInvalidation({bool refresh = false}) async {
    if (!AuthService.instance.isAuthenticated) return;
    if (refresh) {
      await ref.read(platformSettingsProvider.notifier).refresh();
    }
    final settings = ref.read(platformSettingsProvider).valueOrNull;
    final session = AuthService.instance.session;
    if (settings == null || session == null) return;
    final invalidated = PlatformSettingsService.instance.sessionWasInvalidated(
      accessToken: session.accessToken,
      invalidatedAt: settings.platformSessionInvalidatedAt,
    );
    if (invalidated) {
      await _logoutWithMessage(PlatformSettingsService.forceLogoutMessage);
    }
  }

  Future<void> _logoutWithMessage(String message) async {
    final navigator = rootNavigatorKey.currentState;
    final currentContext = rootNavigatorKey.currentContext;
    final messenger = currentContext == null
        ? null
        : ScaffoldMessenger.maybeOf(currentContext);
    await AuthService.instance.logout();
    if (!mounted) return;
    navigator?.pushNamedAndRemoveUntil(AppRouter.authGate, (_) => false);
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }
}
