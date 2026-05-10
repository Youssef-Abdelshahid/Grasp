import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/providers/auth_providers.dart';
import '../../routing/app_navigator.dart';
import '../../routing/app_router.dart';

Future<void> logoutAndReturnToAuthGate(
  BuildContext context,
  WidgetRef ref,
) async {
  final navigator =
      rootNavigatorKey.currentState ??
      Navigator.of(context, rootNavigator: true);

  await ref.read(authControllerProvider.notifier).logout();

  if (navigator.mounted) {
    navigator.pushNamedAndRemoveUntil(AppRouter.authGate, (_) => false);
  }
}
