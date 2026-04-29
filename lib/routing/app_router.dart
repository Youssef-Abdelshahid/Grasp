import 'package:flutter/material.dart';

import '../core/auth/app_role.dart';
import '../features/auth/pages/landing_page.dart';
import '../features/auth/pages/auth_page.dart';
import '../layout/main_layout.dart';
import '../layout/student_layout.dart';
import '../layout/admin_layout.dart';
import '../widgets/auth/auth_gate_page.dart';
import '../widgets/auth/protected_page.dart';

class AppRouter {
  AppRouter._();

  static const authGate = '/auth-gate';
  static const landing = '/';
  static const auth = '/auth';
  static const dashboard = '/dashboard';
  static const courses = '/courses';
  static const studentDashboard = '/student/dashboard';
  static const studentCourses = '/student/courses';
  static const adminDashboard = '/admin/dashboard';
  static const adminUsers = '/admin/users';
  static const adminCourses = '/admin/courses';
  static const adminMaterials = '/admin/materials';
  static const adminQuizzes = '/admin/quizzes';
  static const adminAssignments = '/admin/assignments';
  static const adminFlashcards = '/admin/flashcards';
  static const adminAnnouncements = '/admin/announcements';
  static const adminPermissions = '/admin/permissions';
  static const adminAiControls = '/admin/ai-controls';
  static const adminUploadLimits = '/admin/upload-limits';
  static const adminPlatform = '/admin/platform';

  static String defaultRouteForRole(AppRole role) {
    switch (role) {
      case AppRole.student:
        return studentDashboard;
      case AppRole.instructor:
        return dashboard;
      case AppRole.admin:
        return adminDashboard;
    }
  }

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case authGate:
        return _fade(const AuthGatePage());
      case landing:
        return _fade(const LandingPage());
      case auth:
        return _fade(const AuthPage());
      case dashboard:
        return _fade(
          const ProtectedPage(
            allowedRoles: [AppRole.instructor],
            child: MainLayout(initialIndex: 0),
          ),
        );
      case courses:
        return _fade(
          const ProtectedPage(
            allowedRoles: [AppRole.instructor],
            child: MainLayout(initialIndex: 1),
          ),
        );
      case studentDashboard:
        return _fade(
          const ProtectedPage(
            allowedRoles: [AppRole.student],
            child: StudentLayout(initialIndex: 0),
          ),
        );
      case studentCourses:
        return _fade(
          const ProtectedPage(
            allowedRoles: [AppRole.student],
            child: StudentLayout(initialIndex: 1),
          ),
        );
      case adminDashboard:
        return _fade(
          const ProtectedPage(
            allowedRoles: [AppRole.admin],
            child: AdminLayout(initialIndex: 0),
          ),
        );
      case adminUsers:
        return _fade(
          const ProtectedPage(
            allowedRoles: [AppRole.admin],
            child: AdminLayout(initialIndex: 1),
          ),
        );
      case adminCourses:
        return _fade(
          const ProtectedPage(
            allowedRoles: [AppRole.admin],
            child: AdminLayout(initialIndex: 2),
          ),
        );
      case adminMaterials:
        return _fade(
          const ProtectedPage(
            allowedRoles: [AppRole.admin],
            child: AdminLayout(initialIndex: 3),
          ),
        );
      case adminQuizzes:
        return _fade(
          const ProtectedPage(
            allowedRoles: [AppRole.admin],
            child: AdminLayout(initialIndex: 4),
          ),
        );
      case adminAssignments:
        return _fade(
          const ProtectedPage(
            allowedRoles: [AppRole.admin],
            child: AdminLayout(initialIndex: 5),
          ),
        );
      case adminAnnouncements:
        return _fade(
          const ProtectedPage(
            allowedRoles: [AppRole.admin],
            child: AdminLayout(initialIndex: 7),
          ),
        );
      case adminFlashcards:
        return _fade(
          const ProtectedPage(
            allowedRoles: [AppRole.admin],
            child: AdminLayout(initialIndex: 6),
          ),
        );
      case adminPermissions:
        return _fade(
          const ProtectedPage(
            allowedRoles: [AppRole.admin],
            child: AdminLayout(initialIndex: 8),
          ),
        );
      case adminAiControls:
        return _fade(
          const ProtectedPage(
            allowedRoles: [AppRole.admin],
            child: AdminLayout(initialIndex: 9),
          ),
        );
      case adminUploadLimits:
        return _fade(
          const ProtectedPage(
            allowedRoles: [AppRole.admin],
            child: AdminLayout(initialIndex: 10),
          ),
        );
      case adminPlatform:
        return _fade(
          const ProtectedPage(
            allowedRoles: [AppRole.admin],
            child: AdminLayout(initialIndex: 11),
          ),
        );
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
