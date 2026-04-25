import 'package:flutter/material.dart';

import '../../core/auth/app_role.dart';
import '../../features/auth/pages/auth_page.dart';
import '../../routing/app_router.dart';
import '../../services/auth_service.dart';

class ProtectedPage extends StatelessWidget {
  const ProtectedPage({
    super.key,
    required this.child,
    this.allowedRoles = const [],
  });

  final Widget child;
  final List<AppRole> allowedRoles;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AuthService.instance,
      builder: (context, _) {
        final auth = AuthService.instance;

        if (auth.isInitializing) {
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
            onAction: () async {
              await AuthService.instance.logout();
              if (!context.mounted) {
                return;
              }
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRouter.landing,
                (_) => false,
              );
            },
            actionLabel: 'Sign Out',
          );
        }

        if (allowedRoles.isNotEmpty &&
            !allowedRoles.contains(auth.currentUser!.role)) {
          return _ProtectedStateScaffold(
            message:
                'Your account does not have access to this section. Redirecting you to your dashboard.',
            onAction: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRouter.defaultRouteForRole(auth.currentUser!.role),
                (_) => false,
              );
            },
            actionLabel: 'Go To My Dashboard',
          );
        }

        return child;
      },
    );
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
