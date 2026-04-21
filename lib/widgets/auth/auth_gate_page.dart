import 'package:flutter/material.dart';

import '../../features/auth/pages/landing_page.dart';
import '../../routing/app_router.dart';
import '../../services/auth_service.dart';

class AuthGatePage extends StatelessWidget {
  const AuthGatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AuthService.instance,
      builder: (context, _) {
        final auth = AuthService.instance;
        if (auth.isInitializing) {
          return const _LoadingScaffold(
            message: 'Preparing your workspace...',
          );
        }

        if (!auth.isSupabaseConfigured) {
          return const _LoadingScaffold(
            message: 'Supabase is not configured yet. Add your project keys to .env to continue.',
          );
        }

        if (!auth.isAuthenticated || auth.currentUser == null) {
          return const LandingPage();
        }

        final route = AppRouter.defaultRouteForRole(auth.currentUser!.role);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushNamedAndRemoveUntil(context, route, (_) => false);
        });
        return const _LoadingScaffold(message: 'Restoring your session...');
      },
    );
  }
}

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold({
    required this.message,
  });

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
              Text(
                message,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
