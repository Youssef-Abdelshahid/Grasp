import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/upload_limits_model.dart';

class UploadLimitsService {
  UploadLimitsService._();

  static final instance = UploadLimitsService._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<UploadLimitsConfig> getAdminConfig() async {
    try {
      final response = await _client.rpc('get_admin_upload_limits_config');
      return UploadLimitsConfig.fromJson(
        Map<String, dynamic>.from(response as Map),
      );
    } catch (error) {
      throw UploadLimitsException(_friendlyMessage(error));
    }
  }

  Future<UploadLimitsConfig> getEffectiveConfig() async {
    try {
      final response = await _client.rpc('get_effective_upload_limits');
      return UploadLimitsConfig.fromJson(
        Map<String, dynamic>.from(response as Map),
      );
    } catch (error) {
      throw UploadLimitsException(_friendlyMessage(error));
    }
  }

  Future<UploadLimitsConfig> updateAdminConfig(
    UploadLimitsConfig config,
  ) async {
    try {
      final response = await _client.rpc(
        'update_admin_upload_limits_config',
        params: {'p_config': config.toJson()},
      );
      return UploadLimitsConfig.fromJson(
        Map<String, dynamic>.from(response as Map),
      );
    } catch (error) {
      throw UploadLimitsException(_friendlyMessage(error));
    }
  }

  Future<UploadLimitsConfig> resetAdminConfig() async {
    try {
      final response = await _client.rpc('reset_admin_upload_limits_config');
      return UploadLimitsConfig.fromJson(
        Map<String, dynamic>.from(response as Map),
      );
    } catch (error) {
      throw UploadLimitsException(_friendlyMessage(error));
    }
  }

  Future<UploadStorageOverview> getStorageOverview() async {
    try {
      final response = await _client.rpc('get_admin_upload_storage_overview');
      return UploadStorageOverview.fromJson(
        Map<String, dynamic>.from(response as Map),
      );
    } catch (error) {
      throw UploadLimitsException(_friendlyMessage(error));
    }
  }

  Future<UploadLimitsConfig> validateUpload({
    required String source,
    required PlatformFile file,
    int fileCount = 1,
    String? courseId,
  }) async {
    try {
      await _client.rpc(
        'validate_upload_request',
        params: {
          'p_source': source,
          'p_file_name': file.name,
          'p_file_size_bytes': file.size,
          'p_file_count': fileCount,
          'p_course_id': courseId,
        },
      );
      return getEffectiveConfig();
    } catch (error) {
      throw UploadLimitsException(_friendlyMessage(error));
    }
  }

  Future<void> recordUploadMetadata({
    required String bucket,
    required String source,
    required PlatformFile file,
    required String mimeType,
    required String storagePath,
    String? courseId,
    String? materialId,
    String? assignmentId,
    String? submissionId,
  }) async {
    try {
      await _client.rpc(
        'record_upload_file_metadata',
        params: {
          'p_bucket': bucket,
          'p_source': source,
          'p_file_name': file.name,
          'p_mime_type': mimeType,
          'p_size_bytes': file.size,
          'p_storage_path': storagePath,
          'p_course_id': courseId,
          'p_material_id': materialId,
          'p_assignment_id': assignmentId,
          'p_submission_id': submissionId,
        },
      );
    } catch (_) {
      // Metadata improves reporting, but should not make a completed upload unusable.
    }
  }

  String extensionFor(PlatformFile file) {
    final ext = (file.extension ?? p.extension(file.name).replaceFirst('.', ''))
        .trim()
        .toUpperCase();
    return ext;
  }

  String _friendlyMessage(Object error) {
    if (error is UploadLimitsException) return error.message;
    if (error is PostgrestException) {
      final message = error.message.toLowerCase();
      if (message.contains('file type')) {
        return 'This file type is not allowed.';
      }
      if (message.contains('maximum allowed size')) {
        return 'This file exceeds the maximum allowed size.';
      }
      if (message.contains('one file') || message.contains('up to')) {
        return error.message;
      }
      if (message.contains('storage quota')) {
        return 'This upload would exceed the storage quota.';
      }
      if (message.contains('invalid') ||
          message.contains('unknown') ||
          message.contains('empty')) {
        return 'The upload limits configuration is invalid. Refresh and try again.';
      }
      if (message.contains('permission') || error.code == '42501') {
        return 'You do not currently have permission to upload this file.';
      }
    }
    return 'Unable to upload this file right now. Please try again.';
  }
}

class UploadLimitsException implements Exception {
  const UploadLimitsException(this.message);

  final String message;

  @override
  String toString() => message;
}
