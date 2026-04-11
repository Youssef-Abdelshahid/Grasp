import 'package:flutter/material.dart';
import '../features/auth/pages/landing_page.dart';
import '../features/auth/pages/auth_page.dart';
import '../layout/main_layout.dart';
import '../layout/student_layout.dart';
import '../layout/admin_layout.dart';

class AppRouter {
  AppRouter._();

  static const landing = '/';
  static const auth = '/auth';
  static const dashboard = '/dashboard';
  static const courses = '/courses';
  static const studentDashboard = '/student/dashboard';
  static const studentCourses = '/student/courses';
  static const adminDashboard = '/admin/dashboard';
  static const adminUsers = '/admin/users';
  static const adminPermissions = '/admin/permissions';
  static const adminAiControls = '/admin/ai-controls';
  static const adminUploadLimits = '/admin/upload-limits';
  static const adminPlatform = '/admin/platform';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case landing:
        return _fade(const LandingPage());
      case auth:
        return _fade(const AuthPage());
      case dashboard:
        return _fade(const MainLayout(initialIndex: 0));
      case courses:
        return _fade(const MainLayout(initialIndex: 1));
      case studentDashboard:
        return _fade(const StudentLayout(initialIndex: 0));
      case studentCourses:
        return _fade(const StudentLayout(initialIndex: 1));
      case adminDashboard:
        return _fade(const AdminLayout(initialIndex: 0));
      case adminUsers:
        return _fade(const AdminLayout(initialIndex: 1));
      case adminPermissions:
        return _fade(const AdminLayout(initialIndex: 2));
      case adminAiControls:
        return _fade(const AdminLayout(initialIndex: 3));
      case adminUploadLimits:
        return _fade(const AdminLayout(initialIndex: 4));
      case adminPlatform:
        return _fade(const AdminLayout(initialIndex: 5));
      default:
        return _fade(const LandingPage());
    }
  }

  static PageRouteBuilder _fade(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, animation, _, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 200),
    );
  }
}
