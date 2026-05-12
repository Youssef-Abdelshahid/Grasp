import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'local_database_factory.dart';
import 'local_tables.dart';

class AppLocalDatabase {
  AppLocalDatabase._();

  static final instance = AppLocalDatabase._();

  static const _databaseName = 'grasp_local_cache.db';
  static const _databaseVersion = 1;

  Database? _database;
  bool _factoryInitialized = false;

  Future<Database> get database async {
    final existing = _database;
    if (existing != null) return existing;

    _initializeFactory();
    final path = p.join(await getDatabasesPath(), _databaseName);
    final opened = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _create,
      onUpgrade: _upgrade,
    );
    _database = opened;
    return opened;
  }

  void _initializeFactory() {
    if (_factoryInitialized || kIsWeb) return;
    configureLocalDatabaseFactory();
    _factoryInitialized = true;
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }

  Future<void> _create(Database db, int version) async {
    await db.execute('''
      create table ${LocalTables.cachedFlashcards} (
        id text primary key,
        remote_id text not null,
        student_id text not null,
        course_id text not null,
        title text not null,
        prompt text not null default '',
        difficulty text not null default '',
        material_ids_json text not null default '[]',
        material_names_json text not null default '[]',
        cards_json text not null default '[]',
        created_at text not null,
        updated_at text not null,
        cached_at text not null,
        unique(remote_id, student_id)
      )
    ''');

    await db.execute('''
      create table ${LocalTables.cachedStudyNotes} (
        id text primary key,
        remote_id text not null,
        student_id text not null,
        course_id text not null,
        title text not null,
        prompt text not null default '',
        material_ids_json text not null default '[]',
        material_names_json text not null default '[]',
        content text not null,
        created_at text not null,
        updated_at text not null,
        cached_at text not null,
        unique(remote_id, student_id)
      )
    ''');

    await db.execute('''
      create table ${LocalTables.cachedMaterialMetadata} (
        id text primary key,
        remote_id text not null,
        course_id text not null,
        title text not null,
        description text not null default '',
        file_name text not null,
        file_type text not null,
        file_size integer not null default 0,
        mime_type text not null default '',
        storage_path text,
        uploaded_by text not null default '',
        uploaded_by_name text not null default '',
        uploaded_at text not null,
        last_opened_at text,
        is_downloaded integer not null default 0,
        local_file_path text,
        cached_at text not null,
        unique(remote_id)
      )
    ''');

    await db.execute('''
      create table ${LocalTables.recentlyOpenedMaterials} (
        id text primary key,
        material_id text not null,
        course_id text not null,
        title text not null,
        opened_at text not null,
        unique(material_id)
      )
    ''');

    await db.execute('''
      create table ${LocalTables.materialReadingProgress} (
        id text primary key,
        material_id text not null,
        course_id text not null,
        student_id text not null,
        last_opened_page integer,
        completion_percent real,
        last_studied_at text not null,
        unique(material_id, student_id)
      )
    ''');

    await db.execute('''
      create table ${LocalTables.materialFavorites} (
        id text primary key,
        material_id text not null,
        course_id text not null,
        student_id text not null,
        is_favorite integer not null default 0,
        saved_at text not null,
        unique(material_id, student_id)
      )
    ''');

    await db.execute(
      'create index idx_cached_flashcards_student_course on ${LocalTables.cachedFlashcards}(student_id, course_id)',
    );
    await db.execute(
      'create index idx_cached_notes_student_course on ${LocalTables.cachedStudyNotes}(student_id, course_id)',
    );
    await db.execute(
      'create index idx_cached_materials_course on ${LocalTables.cachedMaterialMetadata}(course_id)',
    );
    await db.execute(
      'create index idx_recent_materials_opened on ${LocalTables.recentlyOpenedMaterials}(opened_at desc)',
    );
  }

  Future<void> _upgrade(Database db, int oldVersion, int newVersion) async {
    // Future local-cache migrations live here. Supabase remains the source of truth.
  }
}
