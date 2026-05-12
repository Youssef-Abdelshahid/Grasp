import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../models/flashcard_model.dart';
import '../../models/material_model.dart';
import '../../models/study_note_model.dart';
import 'app_local_database.dart';
import 'local_file_store.dart';
import 'local_tables.dart';

class LocalCacheService {
  LocalCacheService._();

  static final instance = LocalCacheService._();

  Future<Database> get _db => AppLocalDatabase.instance.database;

  Future<void> cacheFlashcards(
    List<FlashcardModel> items, {
    bool pruneStaleForCourse = false,
  }) async {
    if (kIsWeb) return;
    if (items.isEmpty) return;
    final db = await _db;
    final batch = db.batch();
    final now = DateTime.now().toUtc().toIso8601String();
    for (final item in items) {
      batch.insert(
        LocalTables.cachedFlashcards,
        _flashcardRow(item, now),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
    if (pruneStaleForCourse) {
      await _removeStaleRemoteRows(
        table: LocalTables.cachedFlashcards,
        ownerColumn: 'student_id',
        ownerId: items.first.studentId,
        courseId: items.first.courseId,
        remoteIds: items.map((item) => item.id).toSet(),
      );
    }
  }

  Future<List<FlashcardModel>> getCachedFlashcards({
    required String studentId,
    required String courseId,
  }) async {
    if (kIsWeb) return const [];
    final db = await _db;
    final rows = await db.query(
      LocalTables.cachedFlashcards,
      where: 'student_id = ? and course_id = ?',
      whereArgs: [studentId, courseId],
      orderBy: 'updated_at desc',
    );
    return rows.map(_flashcardFromRow).toList();
  }

  Future<void> removeCachedFlashcard(String remoteId, String studentId) async {
    if (kIsWeb) return;
    final db = await _db;
    await db.delete(
      LocalTables.cachedFlashcards,
      where: 'remote_id = ? and student_id = ?',
      whereArgs: [remoteId, studentId],
    );
  }

  Future<void> cacheStudyNotes(
    List<StudyNoteModel> items, {
    bool pruneStaleForCourse = false,
  }) async {
    if (kIsWeb) return;
    if (items.isEmpty) return;
    final db = await _db;
    final batch = db.batch();
    final now = DateTime.now().toUtc().toIso8601String();
    for (final item in items) {
      batch.insert(
        LocalTables.cachedStudyNotes,
        _studyNoteRow(item, now),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
    if (pruneStaleForCourse) {
      await _removeStaleRemoteRows(
        table: LocalTables.cachedStudyNotes,
        ownerColumn: 'student_id',
        ownerId: items.first.studentId,
        courseId: items.first.courseId,
        remoteIds: items.map((item) => item.id).toSet(),
      );
    }
  }

  Future<List<StudyNoteModel>> getCachedStudyNotes({
    required String studentId,
    required String courseId,
  }) async {
    if (kIsWeb) return const [];
    final db = await _db;
    final rows = await db.query(
      LocalTables.cachedStudyNotes,
      where: 'student_id = ? and course_id = ?',
      whereArgs: [studentId, courseId],
      orderBy: 'updated_at desc',
    );
    return rows.map(_studyNoteFromRow).toList();
  }

  Future<void> removeCachedStudyNote(String remoteId, String studentId) async {
    if (kIsWeb) return;
    final db = await _db;
    await db.delete(
      LocalTables.cachedStudyNotes,
      where: 'remote_id = ? and student_id = ?',
      whereArgs: [remoteId, studentId],
    );
  }

  Future<void> cacheMaterials(
    List<MaterialModel> items, {
    bool pruneStaleForCourse = false,
  }) async {
    if (kIsWeb) return;
    if (items.isEmpty) return;
    final db = await _db;
    final batch = db.batch();
    final now = DateTime.now().toUtc().toIso8601String();
    for (final item in items) {
      final existing = await db.query(
        LocalTables.cachedMaterialMetadata,
        columns: ['is_downloaded', 'local_file_path', 'last_opened_at'],
        where: 'remote_id = ?',
        whereArgs: [item.id],
        limit: 1,
      );
      final existingRow = existing.isEmpty ? null : existing.first;
      batch.insert(
        LocalTables.cachedMaterialMetadata,
        _materialRow(
          item,
          now,
          isDownloaded: (existingRow?['is_downloaded'] as int?) == 1,
          localFilePath: existingRow?['local_file_path'] as String?,
          lastOpenedAt: existingRow?['last_opened_at'] as String?,
        ),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
    if (pruneStaleForCourse) {
      await _removeStaleRemoteRows(
        table: LocalTables.cachedMaterialMetadata,
        ownerColumn: null,
        ownerId: null,
        courseId: items.first.courseId,
        remoteIds: items.map((item) => item.id).toSet(),
      );
    }
  }

  Future<List<MaterialModel>> getCachedMaterials(String courseId) async {
    if (kIsWeb) return const [];
    final db = await _db;
    final rows = await db.query(
      LocalTables.cachedMaterialMetadata,
      where: 'course_id = ?',
      whereArgs: [courseId],
      orderBy: 'uploaded_at desc',
    );
    return rows.map(_materialFromRow).toList();
  }

  Future<void> markMaterialOpened({
    required MaterialModel material,
    String? studentId,
    int? lastOpenedPage,
    double? completionPercent,
  }) async {
    if (kIsWeb) return;
    final db = await _db;
    final now = DateTime.now().toUtc().toIso8601String();
    await db.insert(
      LocalTables.recentlyOpenedMaterials,
      {
        'id': material.id,
        'material_id': material.id,
        'course_id': material.courseId,
        'title': material.title,
        'opened_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await db.update(
      LocalTables.cachedMaterialMetadata,
      {'last_opened_at': now},
      where: 'remote_id = ?',
      whereArgs: [material.id],
    );
    if (studentId != null && studentId.isNotEmpty) {
      await db.insert(
        LocalTables.materialReadingProgress,
        {
          'id': '${studentId}_${material.id}',
          'material_id': material.id,
          'course_id': material.courseId,
          'student_id': studentId,
          'last_opened_page': lastOpenedPage,
          'completion_percent': completionPercent,
          'last_studied_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await _trimRecentMaterials(db);
  }

  Future<List<CachedRecentMaterial>> getRecentMaterials({int limit = 20}) async {
    if (kIsWeb) return const [];
    final db = await _db;
    final rows = await db.query(
      LocalTables.recentlyOpenedMaterials,
      orderBy: 'opened_at desc',
      limit: limit,
    );
    return rows.map(CachedRecentMaterial.fromRow).toList();
  }

  Future<bool> isMaterialFavorite({
    required String materialId,
    required String studentId,
  }) async {
    if (kIsWeb) return false;
    final db = await _db;
    final rows = await db.query(
      LocalTables.materialFavorites,
      columns: ['is_favorite'],
      where: 'material_id = ? and student_id = ?',
      whereArgs: [materialId, studentId],
      limit: 1,
    );
    return (rows.isEmpty ? null : rows.first['is_favorite'] as int?) == 1;
  }

  Future<Set<String>> favoriteMaterialIds(String studentId) async {
    if (kIsWeb) return const <String>{};
    final db = await _db;
    final rows = await db.query(
      LocalTables.materialFavorites,
      columns: ['material_id'],
      where: 'student_id = ? and is_favorite = 1',
      whereArgs: [studentId],
    );
    return rows.map((row) => row['material_id'] as String).toSet();
  }

  Future<void> setMaterialFavorite({
    required MaterialModel material,
    required String studentId,
    required bool isFavorite,
  }) async {
    if (kIsWeb) return;
    final db = await _db;
    await db.insert(
      LocalTables.materialFavorites,
      {
        'id': '${studentId}_${material.id}',
        'material_id': material.id,
        'course_id': material.courseId,
        'student_id': studentId,
        'is_favorite': isFavorite ? 1 : 0,
        'saved_at': DateTime.now().toUtc().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> localMaterialPath(String materialId) async {
    if (kIsWeb) return null;
    final db = await _db;
    final rows = await db.query(
      LocalTables.cachedMaterialMetadata,
      columns: ['is_downloaded', 'local_file_path'],
      where: 'remote_id = ?',
      whereArgs: [materialId],
      limit: 1,
    );
    final row = rows.isEmpty ? null : rows.first;
    if (row == null || row['is_downloaded'] != 1) return null;
    final path = row['local_file_path'] as String?;
    if (path == null || path.isEmpty) return null;
    if (!await LocalFileStore.exists(path)) {
      await markMaterialNotDownloaded(materialId);
      return null;
    }
    return path;
  }

  Future<String> saveDownloadedMaterial({
    required MaterialModel material,
    required Uint8List bytes,
  }) async {
    if (kIsWeb) {
      throw const LocalCacheException(
        'Offline material downloads are not available in the web build.',
      );
    }
    final path = await LocalFileStore.saveDownloadedMaterial(
      materialId: material.id,
      fileName: material.fileName,
      bytes: bytes,
    );

    final db = await _db;
    final now = DateTime.now().toUtc().toIso8601String();
    await db.insert(
      LocalTables.cachedMaterialMetadata,
      _materialRow(
        material,
        now,
        isDownloaded: true,
        localFilePath: path,
        lastOpenedAt: now,
      ),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return path;
  }

  Future<void> markMaterialNotDownloaded(String materialId) async {
    if (kIsWeb) return;
    final db = await _db;
    await db.update(
      LocalTables.cachedMaterialMetadata,
      {'is_downloaded': 0, 'local_file_path': null},
      where: 'remote_id = ?',
      whereArgs: [materialId],
    );
  }

  Map<String, dynamic> _flashcardRow(FlashcardModel item, String cachedAt) {
    return {
      'id': item.id,
      'remote_id': item.id,
      'student_id': item.studentId,
      'course_id': item.courseId,
      'title': item.title,
      'prompt': item.prompt,
      'difficulty': item.difficulty,
      'material_ids_json': jsonEncode(item.materialIds),
      'material_names_json': jsonEncode(item.materialNames),
      'cards_json': jsonEncode(item.cards.map((card) => card.toJson()).toList()),
      'created_at': item.createdAt.toUtc().toIso8601String(),
      'updated_at': item.updatedAt.toUtc().toIso8601String(),
      'cached_at': cachedAt,
    };
  }

  FlashcardModel _flashcardFromRow(Map<String, Object?> row) {
    return FlashcardModel.fromJson({
      'id': row['remote_id'],
      'course_id': row['course_id'],
      'student_id': row['student_id'],
      'title': row['title'],
      'prompt': row['prompt'],
      'difficulty': row['difficulty'],
      'selected_material_ids': _decodeList(row['material_ids_json']),
      'material_names': _decodeList(row['material_names_json']),
      'cards': _decodeList(row['cards_json']),
      'created_at': row['created_at'],
      'updated_at': row['updated_at'],
    });
  }

  Map<String, dynamic> _studyNoteRow(StudyNoteModel item, String cachedAt) {
    return {
      'id': item.id,
      'remote_id': item.id,
      'student_id': item.studentId,
      'course_id': item.courseId,
      'title': item.title,
      'prompt': item.prompt,
      'material_ids_json': jsonEncode(item.materialIds),
      'material_names_json': jsonEncode(item.materialNames),
      'content': item.content,
      'created_at': item.createdAt.toUtc().toIso8601String(),
      'updated_at': item.updatedAt.toUtc().toIso8601String(),
      'cached_at': cachedAt,
    };
  }

  StudyNoteModel _studyNoteFromRow(Map<String, Object?> row) {
    return StudyNoteModel.fromJson({
      'id': row['remote_id'],
      'course_id': row['course_id'],
      'student_id': row['student_id'],
      'title': row['title'],
      'prompt': row['prompt'],
      'selected_material_ids': _decodeList(row['material_ids_json']),
      'material_names': _decodeList(row['material_names_json']),
      'content': row['content'],
      'created_at': row['created_at'],
      'updated_at': row['updated_at'],
    });
  }

  Map<String, dynamic> _materialRow(
    MaterialModel item,
    String cachedAt, {
    bool isDownloaded = false,
    String? localFilePath,
    String? lastOpenedAt,
  }) {
    return {
      'id': item.id,
      'remote_id': item.id,
      'course_id': item.courseId,
      'title': item.title,
      'description': item.description,
      'file_name': item.fileName,
      'file_type': item.fileType,
      'file_size': item.fileSizeBytes,
      'mime_type': item.mimeType,
      'storage_path': item.storagePath,
      'uploaded_by': item.uploadedBy,
      'uploaded_by_name': item.uploadedByName,
      'uploaded_at': item.createdAt.toUtc().toIso8601String(),
      'last_opened_at': lastOpenedAt,
      'is_downloaded': isDownloaded ? 1 : 0,
      'local_file_path': localFilePath,
      'cached_at': cachedAt,
    };
  }

  MaterialModel _materialFromRow(Map<String, Object?> row) {
    return MaterialModel.fromJson({
      'id': row['remote_id'],
      'course_id': row['course_id'],
      'title': row['title'],
      'description': row['description'],
      'file_name': row['file_name'],
      'file_type': row['file_type'],
      'file_size_bytes': row['file_size'],
      'mime_type': row['mime_type'],
      'storage_path': row['storage_path'],
      'uploaded_by': row['uploaded_by'] ?? '',
      'profiles': {'full_name': row['uploaded_by_name'] ?? ''},
      'created_at': row['uploaded_at'],
    });
  }

  List<dynamic> _decodeList(Object? value) {
    if (value is! String || value.isEmpty) return const [];
    final decoded = jsonDecode(value);
    return decoded is List ? decoded : const [];
  }

  Future<void> _trimRecentMaterials(Database db) async {
    final rows = await db.query(
      LocalTables.recentlyOpenedMaterials,
      columns: ['id'],
      orderBy: 'opened_at desc',
      limit: 1000,
      offset: 50,
    );
    if (rows.isEmpty) return;
    await db.delete(
      LocalTables.recentlyOpenedMaterials,
      where: 'id in (${List.filled(rows.length, '?').join(',')})',
      whereArgs: rows.map((row) => row['id']).toList(),
    );
  }

  Future<void> _removeStaleRemoteRows({
    required String table,
    required String? ownerColumn,
    required String? ownerId,
    required String courseId,
    required Set<String> remoteIds,
  }) async {
    if (remoteIds.isEmpty) return;
    final db = await _db;
    final placeholders = List.filled(remoteIds.length, '?').join(',');
    final ownerClause = ownerColumn == null ? '' : ' and $ownerColumn = ?';
    final args = <Object?>[
      courseId,
      if (ownerColumn != null) ownerId,
      ...remoteIds,
    ];
    await db.delete(
      table,
      where: 'course_id = ?$ownerClause and remote_id not in ($placeholders)',
      whereArgs: args,
    );
  }
}

class CachedRecentMaterial {
  const CachedRecentMaterial({
    required this.materialId,
    required this.courseId,
    required this.title,
    required this.openedAt,
  });

  final String materialId;
  final String courseId;
  final String title;
  final DateTime openedAt;

  factory CachedRecentMaterial.fromRow(Map<String, Object?> row) {
    return CachedRecentMaterial(
      materialId: row['material_id'] as String,
      courseId: row['course_id'] as String,
      title: row['title'] as String,
      openedAt: DateTime.parse(row['opened_at'] as String),
    );
  }
}

class LocalCacheException implements Exception {
  const LocalCacheException(this.message);

  final String message;

  @override
  String toString() => message;
}
