import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/app_role.dart';
import '../../features/auth/pages/auth_page.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../routing/app_router.dart';
import 'logout_flow.dart';

class ProtectedPage extends ConsumerWidget {
  const ProtectedPage({
    super.key,
    required this.child,
    this.allowedRoles = const [],
  });

  final Widget child;
  final List<AppRole> allowedRoles;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authValue = ref.watch(authControllerProvider);
    final auth = authValue.valueOrNull;

    if (authValue.isLoading || auth == null || auth.isInitializing) {
      return const _ProtectedStateScaffold(
        message: 'Checking your access...',
        showSpinner: true,
      );
    }

    if (!auth.isAuthenticated || auth.currentUser == null) {
      return const AuthPage();
    }

    if (!auth.currentUser!.isActive) {
      return _ProtectedStateScaffold(
        message:
            'Your account is ${auth.currentUser!.accountStatus}. Contact an administrator to restore access.',
        onAction: () => logoutAndReturnToAuthGate(context, ref),
        actionLabel: 'Sign Out',
      );
    }

    if (allowedRoles.isNotEmpty &&
        !allowedRoles.contains(auth.currentUser!.role)) {
      final route = AppRouter.defaultRouteForRole(auth.currentUser!.role);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, route, (_) => false);
      });
      return const _ProtectedStateScaffold(
        message: 'Redirecting you to your dashboard...',
        showSpinner: true,
      );
    }

    return child;
  }
}

class _ProtectedStateScaffold extends StatelessWidget {
  const _ProtectedStateScaffold({
    required this.message,
    this.showSpinner = false,
    this.onAction,
    this.actionLabel,
  });

  final String message;
  final bool showSpinner;
  final VoidCallback? onAction;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showSpinner) ...[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                ],
                Text(message, textAlign: TextAlign.center),
                if (onAction != null && actionLabel != null) ...[
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: onAction,
                    child: Text(actionLabel!),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
