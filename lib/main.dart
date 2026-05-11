import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/platform_settings/providers/platform_settings_provider.dart';
import 'routing/app_navigator.dart';
import 'routing/app_router.dart';
import 'services/auth_service.dart';
import 'services/platform_settings_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.instance.initialize();
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
    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      title: platformName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRouter.authGate,
      onGenerateRoute: AppRouter.onGenerateRoute,
      builder: (context, child) => PlatformInactivityLogout(
        child: child ?? const SizedBox.shrink(),
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
    ref.listen(platformSettingsProvider, (_, __) => _resetTimer());
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
    await AuthService.instance.logout();
    rootNavigatorKey.currentState?.pushNamedAndRemoveUntil(
      AppRouter.authGate,
      (_) => false,
    );
    final context = rootNavigatorKey.currentContext;
    if (context != null) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }
}
