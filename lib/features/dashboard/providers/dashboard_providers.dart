import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/service_providers.dart';
import '../../../models/dashboard_models.dart';

final instructorDashboardProvider = FutureProvider<InstructorDashboardSummary>((
  ref,
) {
  return ref.watch(dashboardServiceProvider).getInstructorSummary();
});

final studentDashboardProvider = FutureProvider<StudentDashboardSummary>((ref) {
  return ref.watch(dashboardServiceProvider).getStudentSummary();
});

final adminDashboardProvider = FutureProvider<AdminDashboardSummary>((ref) {
  return ref.watch(adminServiceProvider).getDashboardSummary();
});
