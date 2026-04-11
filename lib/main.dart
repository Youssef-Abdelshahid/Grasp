import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'routing/app_router.dart';

void main() {
  runApp(const GraspApp());
}

class GraspApp extends StatelessWidget {
  const GraspApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Grasp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRouter.landing,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
