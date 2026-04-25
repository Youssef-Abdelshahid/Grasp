import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/dashboard_models.dart';
import 'admin_service.dart';

class DashboardService {
  DashboardService._();

  static final instance = DashboardService._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<InstructorDashboardSummary> getInstructorSummary() async {
    final response = await _client.rpc('get_instructor_dashboard_summary');
    return InstructorDashboardSummary.fromJson(
      Map<String, dynamic>.from(response as Map),
    );
  }

  Future<StudentDashboardSummary> getStudentSummary() async {
    final response = await _client.rpc('get_student_dashboard_summary');
    return StudentDashboardSummary.fromJson(
      Map<String, dynamic>.from(response as Map),
    );
  }

  Future<AdminDashboardSummary> getAdminSummary() async {
    return AdminService.instance.getDashboardSummary();
  }
}
