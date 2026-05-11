import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/assignment_model.dart';
import 'material_service.dart';
import '../models/permissions_model.dart';
import 'permissions_service.dart';

class AssignmentService {
  AssignmentService._();

  static final instance = AssignmentService._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<List<AssignmentModel>> getCourseAssignments(String courseId) async {
    final response = await _client
        .from('assignments')
        .select()
        .eq('course_id', courseId)
        .order('is_published', ascending: false)
        .order('due_at', ascending: true, nullsFirst: false)
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map(
          (item) =>
              AssignmentModel.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<AssignmentModel> getAssignmentDetails(String assignmentId) async {
    final response = await _client
        .from('assignments')
        .select()
        .eq('id', assignmentId)
        .single();
    return AssignmentModel.fromJson(Map<String, dynamic>.from(response));
  }

  Future<AssignmentModel> createAssignment({
    required String courseId,
    required String title,
    required String instructions,
    required String attachmentRequirements,
    required DateTime? dueAt,
    required int maxPoints,
    required bool isPublished,
    required List<Map<String, dynamic>> rubric,
    required List<Map<String, dynamic>> attachments,
  }) async {
    await PermissionsService.instance.requireInstructorPermission(
      PermissionKeys.manageAssignments,
    );
    final userId = _client.auth.currentUser!.id;
    final response = await _client
        .from('assignments')
        .insert({
          'course_id': courseId,
          'title': title.trim(),
          'instructions': instructions.trim(),
          'attachment_requirements': attachmentRequirements.trim(),
          'due_at': dueAt?.toUtc().toIso8601String(),
          'max_points': maxPoints,
          'is_published': isPublished,
          'published_at': isPublished
              ? DateTime.now().toUtc().toIso8601String()
              : null,
          'rubric': rubric,
          'attachments': attachments,
          'created_by': userId,
        })
        .select()
        .single();

    return AssignmentModel.fromJson(Map<String, dynamic>.from(response));
  }

  Future<AssignmentModel> updateAssignment({
    required String assignmentId,
    required String title,
    required String instructions,
    required String attachmentRequirements,
    required DateTime? dueAt,
    required int maxPoints,
    required bool isPublished,
    required List<Map<String, dynamic>> rubric,
    required List<Map<String, dynamic>> attachments,
  }) async {
    await PermissionsService.instance.requireInstructorPermission(
      PermissionKeys.manageAssignments,
    );
    try {
      final response = await _client
          .from('assignments')
          .update({
            'title': title.trim(),
            'instructions': instructions.trim(),
            'attachment_requirements': attachmentRequirements.trim(),
            'due_at': dueAt?.toUtc().toIso8601String(),
            'max_points': maxPoints,
            'is_published': isPublished,
            'published_at': isPublished
                ? DateTime.now().toUtc().toIso8601String()
                : null,
            'rubric': rubric,
            'attachments': attachments,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', assignmentId)
          .select();

      final rows = response as List<dynamic>;
      if (rows.isNotEmpty) {
        return AssignmentModel.fromJson(
          Map<String, dynamic>.from(rows.first as Map),
        );
      }
    } on PostgrestException catch (error) {
      if (!error.message.contains('single JSON object')) {
        rethrow;
      }
    }

    final adminResponse = await _client.rpc(
      'admin_update_assignment_full',
      params: {
        'p_assignment_id': assignmentId,
        'p_title': title,
        'p_instructions': instructions,
        'p_attachment_requirements': attachmentRequirements,
        'p_due_at': dueAt?.toUtc().toIso8601String(),
        'p_max_points': maxPoints,
        'p_is_published': isPublished,
        'p_rubric': rubric,
        'p_attachments': attachments,
      },
    );

    return AssignmentModel.fromJson(
      Map<String, dynamic>.from(adminResponse as Map),
    );
  }

  Future<AssignmentModel> setPublished({
    required String assignmentId,
    required bool isPublished,
  }) async {
    await PermissionsService.instance.requireInstructorPermission(
      PermissionKeys.manageAssignments,
    );
    final response = await _client
        .from('assignments')
        .update({
          'is_published': isPublished,
          'published_at': isPublished
              ? DateTime.now().toUtc().toIso8601String()
              : null,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', assignmentId)
        .select()
        .single();

    return AssignmentModel.fromJson(Map<String, dynamic>.from(response));
  }

  Future<void> deleteAssignment(String assignmentId) async {
    await PermissionsService.instance.requireInstructorPermission(
      PermissionKeys.manageAssignments,
    );
    await _client.from('assignments').delete().eq('id', assignmentId);
  }

  Future<Map<String, dynamic>> uploadAttachment({
    required String courseId,
    required PlatformFile file,
  }) async {
    await PermissionsService.instance.requireInstructorPermission(
      PermissionKeys.manageAssignments,
    );
    final bytes = await _readFileBytes(file);
    final objectPath =
        '$courseId/assignment-attachments/${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.name)}';
    await _client.storage
        .from(MaterialService.bucketName)
        .uploadBinary(
          objectPath,
          bytes,
          fileOptions: FileOptions(
            contentType: _guessMime(file.extension ?? ''),
            upsert: false,
          ),
        );
    return {
      'path': objectPath,
      'name': file.name,
      'size': file.size,
      'mime_type': _guessMime(file.extension ?? ''),
    };
  }

  Future<String?> createAttachmentUrl(Map<String, dynamic> attachment) {
    final path = attachment['path']?.toString() ?? '';
    if (path.isEmpty) return Future.value();
    return _client.storage
        .from(MaterialService.bucketName)
        .createSignedUrl(path, 3600);
  }

  Future<Uint8List> _readFileBytes(PlatformFile file) async {
    if (file.bytes != null) return file.bytes!;
    final stream = file.readStream;
    if (stream != null) {
      final chunks = <int>[];
      await for (final chunk in stream) {
        chunks.addAll(chunk);
      }
      return Uint8List.fromList(chunks);
    }
    throw const AssignmentException('Unable to read the selected file.');
  }

  String _guessMime(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }
}

class AssignmentException implements Exception {
  const AssignmentException(this.message);

  final String message;

  @override
  String toString() => message;
}
