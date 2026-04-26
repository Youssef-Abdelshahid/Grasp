import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/announcement_model.dart';

class AnnouncementService {
  AnnouncementService._();

  static final instance = AnnouncementService._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<List<AnnouncementModel>> getCourseAnnouncements(
    String courseId,
  ) async {
    final response = await _client
        .from('announcements')
        .select('*, profiles!announcements_created_by_fkey(full_name)')
        .eq('course_id', courseId)
        .order('is_pinned', ascending: false)
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map(
          (item) => AnnouncementModel.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<AnnouncementModel> createAnnouncement({
    required String courseId,
    required String title,
    required String body,
    bool isPinned = false,
  }) async {
    final userId = _client.auth.currentUser!.id;
    final response = await _client
        .from('announcements')
        .insert({
          'course_id': courseId,
          'title': title.trim(),
          'body': body.trim(),
          'is_pinned': isPinned,
          'created_by': userId,
        })
        .select('*, profiles!announcements_created_by_fkey(full_name)')
        .single();

    return AnnouncementModel.fromJson(Map<String, dynamic>.from(response));
  }

  Future<AnnouncementModel> updateAnnouncement({
    required String announcementId,
    required String title,
    required String body,
    required bool isPinned,
  }) async {
    final response = await _client
        .from('announcements')
        .update({
          'title': title.trim(),
          'body': body.trim(),
          'is_pinned': isPinned,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', announcementId)
        .select('*, profiles!announcements_created_by_fkey(full_name)')
        .single();

    return AnnouncementModel.fromJson(Map<String, dynamic>.from(response));
  }

  Future<void> deleteAnnouncement(String announcementId) async {
    await _client.from('announcements').delete().eq('id', announcementId);
  }
}
