import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/utils/file_utils.dart';
import '../models/material_model.dart';
import '../models/permissions_model.dart';
import '../models/upload_limits_model.dart';
import 'permissions_service.dart';
import 'upload_limits_service.dart';

class MaterialService {
  MaterialService._();

  static final instance = MaterialService._();

  static const bucketName = 'course-materials';

  SupabaseClient get _client => Supabase.instance.client;

  Future<List<MaterialModel>> getCourseMaterials(String courseId) async {
    final response = await _client
        .from('materials')
        .select('*, profiles!materials_uploaded_by_fkey(full_name)')
        .eq('course_id', courseId)
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map(
          (item) =>
              MaterialModel.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<MaterialModel> getMaterial(String materialId) async {
    final response = await _client
        .from('materials')
        .select('*, profiles!materials_uploaded_by_fkey(full_name)')
        .eq('id', materialId)
        .single();

    return MaterialModel.fromJson(Map<String, dynamic>.from(response));
  }

  Future<MaterialModel> uploadMaterial({
    required String courseId,
    required PlatformFile file,
    String? title,
    String description = '',
  }) async {
    await PermissionsService.instance.requireInstructorPermission(
      PermissionKeys.uploadMaterials,
    );
    await UploadLimitsService.instance.validateUpload(
      source: UploadSources.material,
      file: file,
      courseId: courseId,
    );
    final bytes = await _readFileBytes(file);
    final fileName = file.name;
    final extension = FileUtils.fileExtension(fileName).toLowerCase();
    final userId = _client.auth.currentUser!.id;
    final objectPath =
        '$courseId/${DateTime.now().millisecondsSinceEpoch}_${p.basename(fileName)}';

    await _client.storage
        .from(bucketName)
        .uploadBinary(
          objectPath,
          bytes,
          fileOptions: FileOptions(
            contentType: file.extension == null
                ? null
                : _guessMime(file.extension!),
            upsert: false,
          ),
        );

    final response = await _client
        .from('materials')
        .insert({
          'course_id': courseId,
          'title': (title == null || title.trim().isEmpty)
              ? p.basenameWithoutExtension(fileName)
              : title.trim(),
          'description': description.trim(),
          'file_name': fileName,
          'file_type': extension.toUpperCase(),
          'file_size_bytes': file.size,
          'mime_type': _guessMime(file.extension ?? ''),
          'storage_path': objectPath,
          'uploaded_by': userId,
        })
        .select('*, profiles!materials_uploaded_by_fkey(full_name)')
        .single();
    final material = MaterialModel.fromJson(Map<String, dynamic>.from(response));
    await UploadLimitsService.instance.recordUploadMetadata(
      bucket: bucketName,
      source: UploadSources.material,
      file: file,
      mimeType: _guessMime(file.extension ?? ''),
      storagePath: objectPath,
      courseId: courseId,
      materialId: material.id,
    );
    return material;
  }

  Future<MaterialModel> updateMaterial({
    required String materialId,
    required String title,
    required String description,
  }) async {
    await PermissionsService.instance.requireInstructorPermission(
      PermissionKeys.uploadMaterials,
    );
    final response = await _client
        .from('materials')
        .update({
          'title': title.trim(),
          'description': description.trim(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', materialId)
        .select('*, profiles!materials_uploaded_by_fkey(full_name)')
        .single();

    return MaterialModel.fromJson(Map<String, dynamic>.from(response));
  }

  Future<void> deleteMaterial(MaterialModel material) async {
    await PermissionsService.instance.requireInstructorPermission(
      PermissionKeys.uploadMaterials,
    );
    if (material.storagePath != null && material.storagePath!.isNotEmpty) {
      await _client.storage.from(bucketName).remove([material.storagePath!]);
    }
    await _client.from('materials').delete().eq('id', material.id);
  }

  Future<String?> createSignedUrl(MaterialModel material) async {
    await PermissionsService.instance.requireStudentPermission(
      PermissionKeys.downloadMaterials,
    );
    final path = material.storagePath;
    if (path == null || path.isEmpty) {
      return null;
    }
    return _client.storage.from(bucketName).createSignedUrl(path, 3600);
  }

  Future<Uint8List> _readFileBytes(PlatformFile file) async {
    if (file.bytes != null) {
      return file.bytes!;
    }
    final readStream = file.readStream;
    if (readStream != null) {
      final chunks = <int>[];
      await for (final chunk in readStream) {
        chunks.addAll(chunk);
      }
      return Uint8List.fromList(chunks);
    }
    throw const MaterialUploadException(
      'Unable to read the selected file. Try selecting it again.',
    );
  }

  String _guessMime(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'mp4':
        return 'video/mp4';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      default:
        return 'application/octet-stream';
    }
  }
}

class MaterialUploadException implements Exception {
  const MaterialUploadException(this.message);

  final String message;

  @override
  String toString() => message;
}
