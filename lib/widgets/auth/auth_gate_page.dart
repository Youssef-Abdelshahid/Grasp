import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/pages/landing_page.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../routing/app_router.dart';
import 'logout_flow.dart';

class AuthGatePage extends ConsumerWidget {
  const AuthGatePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authValue = ref.watch(authControllerProvider);
    final auth = authValue.valueOrNull;
    if (authValue.isLoading || auth == null || auth.isInitializing) {
      return const _LoadingScaffold(message: 'Preparing your workspace...');
    }

    if (!auth.isSupabaseConfigured) {
      return const _LoadingScaffold(
        message:
            'Supabase is not configured yet. Add your project keys to .env to continue.',
      );
    }

    if (!auth.isAuthenticated || auth.currentUser == null) {
      return const LandingPage();
    }

    if (!auth.currentUser!.isActive) {
      return _InactiveAccountScaffold(status: auth.currentUser!.accountStatus);
    }

    final route = AppRouter.defaultRouteForRole(auth.currentUser!.role);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushNamedAndRemoveUntil(context, route, (_) => false);
    });
    return const _LoadingScaffold(message: 'Restoring your session...');
  }
}

class _InactiveAccountScaffold extends ConsumerWidget {
  const _InactiveAccountScaffold({required this.status});

  final String status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_rounded, size: 40),
                const SizedBox(height: 16),
                Text(
                  'Your account is $status. Contact an administrator to restore access.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => logoutAndReturnToAuthGate(context, ref),
                  child: const Text('Sign Out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
