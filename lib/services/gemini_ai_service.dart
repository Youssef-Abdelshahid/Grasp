import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/auth/app_role.dart';
import '../core/config/app_env.dart';
import '../models/assignment_model.dart';
import '../models/material_model.dart';
import '../models/quiz_model.dart';
import '../models/quiz_question_model.dart';
import 'auth_service.dart';
import 'material_service.dart';

class GeminiAiService {
  GeminiAiService._();

  static final instance = GeminiAiService._();

  static const _baseEndpoint =
      'https://generativelanguage.googleapis.com/v1beta/models';
  static const _requestTimeout = Duration(seconds: 45);
  static const _maxContextChars = 9000;
  static const _maxMaterialBytes = 180000;
  static const _maxContextFileBytes = 3 * 1024 * 1024;
  static const _maxContextFiles = 3;

  final Map<String, Map<String, dynamic>> _memoryCache = {};

  SupabaseClient get _client => Supabase.instance.client;

  Future<AiQuizDraft> generateQuizDraft({
    required String courseId,
    required List<MaterialModel> materials,
    required String prompt,
    required int questionCount,
    required List<String> questionTypes,
    required String difficulty,
    required int totalMarks,
    required int? timeLimitMinutes,
    required DateTime? deadline,
    required bool allowRetakes,
    required bool showCorrectAnswers,
    required bool showQuestionMarks,
    List<PlatformFile> contextFiles = const [],
  }) async {
    await _ensureCanGenerate(courseId);
    final cleanMaterials = _requireMaterials(materials);
    final normalizedTypes = _normalizeQuestionTypes(questionTypes);
    final safeQuestionCount = questionCount.clamp(1, 30).toInt();
    final safeMarks = totalMarks.clamp(1, 500).toInt();
    final materialContext = await _buildMaterialContext(cleanMaterials);
    if (materialContext.trim().isEmpty) {
      throw const GeminiAiException('No usable material content found.');
    }
    final contextParts = await _contextFileParts(contextFiles);
    final cacheKey = _cacheKey({
      'kind': 'quiz',
      'course': courseId,
      'materials': cleanMaterials.map((m) => m.id).toList(),
      'prompt': prompt.trim(),
      'count': safeQuestionCount,
      'types': normalizedTypes,
      'difficulty': difficulty,
      'marks': safeMarks,
      'minutes': timeLimitMinutes,
      'deadline': deadline?.toUtc().toIso8601String(),
      'retakes': allowRetakes,
      'answers': showCorrectAnswers,
      'marksVisible': showQuestionMarks,
      'files': contextParts.map((p) => p['name']).toList(),
      'ctx': materialContext,
    });
    final cached = _memoryCache[cacheKey];
    if (cached != null) return AiQuizDraft.fromJson(cached);
    final stored = await _findStoredDraft('quiz', cacheKey);
    if (stored != null) {
      _memoryCache[cacheKey] = stored;
      return AiQuizDraft.fromJson(stored);
    }

    final promptText =
        'JSON only. Make a quiz from MATERIALS. Types only: MCQ, True / False, Short Answer, Matching. '
        'Schema: {"title":string,"description":string,"instructions":string,"questions":[{"type":string,"question_text":string,"options":string[],"correct_option":number,"marks":number,"explanation":string,"sample_answer":string,"items":string[],"targets":string[],"correct_mapping":object}]}. '
        'Count $safeQuestionCount. Types ${normalizedTypes.join(", ")}. Difficulty ${_cleanShort(difficulty, fallback: "medium")}. Total marks $safeMarks. '
        'Use concise wording. No markdown. Custom: ${_cleanShort(prompt, max: 500, fallback: "none")}.\nMATERIALS:\n$materialContext';

    final json = await _generateJson(promptText, contextParts);
    final draft = _validateQuizDraft(
      json,
      questionCount: safeQuestionCount,
      totalMarks: safeMarks,
      durationMinutes: _limitNullableInt(timeLimitMinutes, 1, 300),
      deadline: deadline,
      allowRetakes: allowRetakes,
      showCorrectAnswers: showCorrectAnswers,
      showQuestionMarks: showQuestionMarks,
    );
    _memoryCache[cacheKey] = draft.toJson();
    await _storeAiDraft(
      courseId: courseId,
      materials: cleanMaterials,
      contentType: 'quiz',
      generationKey: cacheKey,
      payload: draft.toJson(),
    );
    return draft;
  }

  Future<AiAssignmentDraft> generateAssignmentDraft({
    required String courseId,
    required List<MaterialModel> materials,
    required String prompt,
    required String difficulty,
    required int taskCount,
    required int marks,
    required bool includeRubric,
    required DateTime? deadline,
    List<PlatformFile> contextFiles = const [],
  }) async {
    await _ensureCanGenerate(courseId);
    final cleanMaterials = _requireMaterials(materials);
    final safeTaskCount = taskCount.clamp(1, 20).toInt();
    final safeMarks = marks.clamp(1, 500).toInt();
    final materialContext = await _buildMaterialContext(cleanMaterials);
    if (materialContext.trim().isEmpty) {
      throw const GeminiAiException('No usable material content found.');
    }
    final contextParts = await _contextFileParts(contextFiles);
    final cacheKey = _cacheKey({
      'kind': 'assignment',
      'course': courseId,
      'materials': cleanMaterials.map((m) => m.id).toList(),
      'prompt': prompt.trim(),
      'difficulty': difficulty,
      'tasks': safeTaskCount,
      'marks': safeMarks,
      'rubric': includeRubric,
      'deadline': deadline?.toUtc().toIso8601String(),
      'files': contextParts.map((p) => p['name']).toList(),
      'ctx': materialContext,
    });
    final cached = _memoryCache[cacheKey];
    if (cached != null) return AiAssignmentDraft.fromJson(cached);
    final stored = await _findStoredDraft('assignment', cacheKey);
    if (stored != null) {
      _memoryCache[cacheKey] = stored;
      return AiAssignmentDraft.fromJson(stored);
    }

    final promptText =
        'JSON only. Make an assignment from MATERIALS. '
        'Schema: {"title":string,"instructions":string,"attachment_requirements":string,"rubric":[{"criterion":string,"description":string,"marks":number}]}. '
        'Difficulty ${_cleanShort(difficulty, fallback: "medium")}. Tasks $safeTaskCount. Total marks $safeMarks. '
        'Rubric ${includeRubric ? "yes" : "no"}. No markdown. Custom: ${_cleanShort(prompt, max: 500, fallback: "none")}.\nMATERIALS:\n$materialContext';

    final json = await _generateJson(promptText, contextParts);
    final draft = _validateAssignmentDraft(
      json,
      totalMarks: safeMarks,
      deadline: deadline,
      includeRubric: includeRubric,
    );
    _memoryCache[cacheKey] = draft.toJson();
    await _storeAiDraft(
      courseId: courseId,
      materials: cleanMaterials,
      contentType: 'assignment',
      generationKey: cacheKey,
      payload: draft.toJson(),
    );
    return draft;
  }

  Future<QuizQuestionModel> generateSingleQuestion({
    required String courseId,
    required List<MaterialModel> materials,
    required String type,
    required String prompt,
    required double marks,
    PlatformFile? image,
  }) async {
    await _ensureCanGenerate(courseId);
    final cleanMaterials = _requireMaterials(materials);
    final normalizedType = _normalizeQuestionTypes([type]).first;
    final materialContext = await _buildMaterialContext(cleanMaterials);
    if (materialContext.trim().isEmpty) {
      throw const GeminiAiException('No usable material content found.');
    }
    final parts = image == null
        ? const <Map<String, dynamic>>[]
        : await _contextFileParts([image]);
    final promptText =
        'JSON only. Make one quiz question. Type $normalizedType only. '
        'Schema: {"type":string,"question_text":string,"options":string[],"correct_option":number,"marks":number,"explanation":string,"sample_answer":string,"items":string[],"targets":string[],"correct_mapping":object}. '
        'Marks ${marks <= 0 ? 1 : marks}. Custom: ${_cleanShort(prompt, max: 400, fallback: "none")}.\nMATERIALS:\n$materialContext';
    final json = await _generateJson(promptText, parts);
    return _validateQuestion(
      json,
      fallbackType: normalizedType,
      fallbackMarks: marks,
    );
  }

  Future<QuizModel> publishQuizDraft(QuizModel quiz) {
    return _client
        .from('quizzes')
        .update({
          'is_published': true,
          'published_at': DateTime.now().toUtc().toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', quiz.id)
        .select()
        .single()
        .then((value) => QuizModel.fromJson(Map<String, dynamic>.from(value)));
  }

  Future<AssignmentModel> publishAssignmentDraft(AssignmentModel assignment) {
    return _client
        .from('assignments')
        .update({
          'is_published': true,
          'published_at': DateTime.now().toUtc().toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', assignment.id)
        .select()
        .single()
        .then(
          (value) => AssignmentModel.fromJson(Map<String, dynamic>.from(value)),
        );
  }

  Future<void> rejectQuizDraft(QuizModel quiz) async {
    if (quiz.isPublished) {
      throw const GeminiAiException('Published quizzes cannot be rejected.');
    }
    await _client.from('quizzes').delete().eq('id', quiz.id);
  }

  Future<void> rejectAssignmentDraft(AssignmentModel assignment) async {
    if (assignment.isPublished) {
      throw const GeminiAiException(
        'Published assignments cannot be rejected.',
      );
    }
    await _client.from('assignments').delete().eq('id', assignment.id);
  }

  Future<Map<String, dynamic>> _generateJson(
    String prompt,
    List<Map<String, dynamic>> contextParts,
  ) async {
    if (!AppEnv.isGeminiConfigured) {
      throw const GeminiAiException(
        'Gemini API key is missing. Add GEMINI_API_KEY to .env.',
      );
    }

    final parts = <Map<String, dynamic>>[
      {'text': prompt},
      ...contextParts.map((item) => item['part'] as Map<String, dynamic>),
    ];
    final body = jsonEncode({
      'contents': [
        {'role': 'user', 'parts': parts},
      ],
      'generationConfig': {
        'temperature': 0.35,
        'topP': 0.8,
        'maxOutputTokens': 4096,
        'responseMimeType': 'application/json',
      },
    });
    final response = await _generateWithFallback(body);

    final envelope = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = envelope['candidates'] as List<dynamic>? ?? const [];
    final content = candidates.isEmpty
        ? null
        : (candidates.first as Map<String, dynamic>)['content'];
    final partsResponse = content is Map
        ? content['parts'] as List<dynamic>? ?? const []
        : const [];
    final text = partsResponse
        .whereType<Map>()
        .map((part) => part['text']?.toString() ?? '')
        .join()
        .trim();
    if (text.isEmpty) {
      throw const GeminiAiException('Gemini returned an empty response.');
    }

    try {
      final decoded = jsonDecode(_stripJsonFence(text));
      if (decoded is Map<String, dynamic>) return decoded;
      throw const FormatException('Root was not an object.');
    } catch (_) {
      throw const GeminiAiException(
        'Gemini returned invalid JSON. Please regenerate.',
      );
    }
  }

  Future<http.Response> _generateWithFallback(String body) async {
    final models = _fallbackModels();
    _GeminiFallbackException? lastFailure;

    for (var index = 0; index < models.length; index++) {
      final model = models[index];
      _log('Attempting model: $model');
      try {
        final response = await _postToModel(model, body);
        _log('Final model used: $model');
        return response;
      } on _GeminiFallbackException catch (error) {
        lastFailure = error;
        final hasFallback = index < models.length - 1;
        if (!hasFallback || !error.canFallback) {
          _log('Final failure on $model: ${error.reason}');
          throw error.toUserException();
        }
        _log('Fallback from $model: ${error.reason}');
      }
    }

    _log('Final failure: ${lastFailure?.reason ?? 'no models configured'}');
    throw lastFailure?.toUserException() ??
        const GeminiAiException('Gemini request failed. Try again later.');
  }

  Future<http.Response> _postToModel(String model, String body) async {
    try {
      final response = await http
          .post(
            Uri.parse(
              '$_baseEndpoint/$model:generateContent'
              '?key=${Uri.encodeQueryComponent(AppEnv.geminiApiKey)}',
            ),
            headers: const {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(_requestTimeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response;
      }
      final reason = _fallbackReason(response);
      throw _GeminiFallbackException(
        message: _userMessageForStatus(response.statusCode),
        reason: reason,
        canFallback: _canFallback(response.statusCode, response.body),
      );
    } on TimeoutException {
      throw const _GeminiFallbackException(
        message: 'Gemini request timed out. Try again later.',
        reason: 'request timed out',
      );
    } on http.ClientException catch (error) {
      throw _GeminiFallbackException(
        message: 'Gemini request failed. Try again later.',
        reason: 'network error: ${error.message}',
      );
    } on _GeminiFallbackException {
      rethrow;
    } catch (error) {
      throw _GeminiFallbackException(
        message: 'Gemini request failed. Try again later.',
        reason: 'request error: ${error.runtimeType}',
      );
    }
  }

  List<String> _fallbackModels() {
    final seen = <String>{};
    return [
      AppEnv.geminiPrimaryModel,
      AppEnv.geminiFallbackModel1,
      AppEnv.geminiFallbackModel2,
    ].map((model) => model.trim()).where((model) {
      final clean = model.trim();
      return clean.isNotEmpty && seen.add(clean);
    }).toList();
  }

  String _fallbackReason(http.Response response) {
    final detail = _geminiErrorDetail(response.body);
    if (detail.isEmpty) return 'status ${response.statusCode}';
    return 'status ${response.statusCode}: $detail';
  }

  String _geminiErrorDetail(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final error = decoded['error'];
        if (error is Map) {
          return [
            error['status']?.toString(),
            error['message']?.toString(),
          ].where((item) => item != null && item.trim().isNotEmpty).join(' - ');
        }
      }
    } catch (_) {
      return '';
    }
    return '';
  }

  bool _canFallback(int statusCode, String body) {
    if (statusCode == 408 || statusCode == 409 || statusCode == 429) {
      return true;
    }
    if (statusCode >= 500 && statusCode < 600) return true;
    final detail = _geminiErrorDetail(body).toUpperCase();
    return statusCode == 404 ||
        (statusCode == 403 && detail.contains('RESOURCE_EXHAUSTED'));
  }

  String _userMessageForStatus(int statusCode) {
    if (statusCode == 429) {
      return 'Gemini rate limit reached. Please wait and try again.';
    }
    return 'Gemini request failed ($statusCode). Try again later.';
  }

  void _log(String message) {
    debugPrint('[GeminiAiService] $message');
  }

  Future<String> _buildMaterialContext(List<MaterialModel> materials) async {
    final chunks = <String>[];
    final perMaterialBudget = (_maxContextChars / materials.length).floor();
    for (final material in materials.take(8)) {
      final buffer = StringBuffer()
        ..writeln('Title: ${material.title}')
        ..writeln('File: ${material.fileName}')
        ..writeln('Type: ${material.fileType}');
      if (material.description.trim().isNotEmpty) {
        buffer.writeln('Description: ${material.description.trim()}');
      }
      final extracted = await _extractText(material);
      if (extracted.trim().isNotEmpty) {
        buffer.writeln('Text: ${_trim(extracted, perMaterialBudget)}');
      }
      chunks.add(_trim(buffer.toString(), perMaterialBudget));
    }
    return _trim(chunks.join('\n---\n'), _maxContextChars);
  }

  Future<String> _extractText(MaterialModel material) async {
    final extension = material.fileType.toLowerCase();
    if (!{'txt', 'md', 'csv', 'json'}.contains(extension)) {
      return '';
    }
    if ((material.storagePath ?? '').isEmpty ||
        material.fileSizeBytes > _maxMaterialBytes) {
      return '';
    }
    try {
      final bytes = await _client.storage
          .from(MaterialService.bucketName)
          .download(material.storagePath!);
      return utf8.decode(bytes, allowMalformed: true);
    } catch (_) {
      return '';
    }
  }

  Future<List<Map<String, dynamic>>> _contextFileParts(
    List<PlatformFile> files,
  ) async {
    if (files.length > _maxContextFiles) {
      throw GeminiAiException(
        'Attach at most $_maxContextFiles context files.',
      );
    }
    final parts = <Map<String, dynamic>>[];
    for (final file in files) {
      if (file.size > _maxContextFileBytes) {
        throw GeminiAiException('${file.name} is too large for AI context.');
      }
      final bytes = await _readFileBytes(file);
      final mime = _mimeForExtension(file.extension ?? '');
      if (!_supportedContextMime(mime)) {
        throw GeminiAiException(
          '${file.name} is not a supported AI context file.',
        );
      }
      parts.add({
        'name': file.name,
        'part': {
          'inlineData': {'mimeType': mime, 'data': base64Encode(bytes)},
        },
      });
    }
    return parts;
  }

  Future<Uint8List> _readFileBytes(PlatformFile file) async {
    if (file.bytes != null) return file.bytes!;
    final stream = file.readStream;
    if (stream == null) {
      throw GeminiAiException('Unable to read ${file.name}.');
    }
    final chunks = <int>[];
    await for (final chunk in stream) {
      chunks.addAll(chunk);
    }
    return Uint8List.fromList(chunks);
  }

  Future<void> _ensureCanGenerate(String courseId) async {
    final user = AuthService.instance.currentUser;
    if (user == null || user.role == AppRole.student) {
      throw const GeminiAiException(
        'Only instructors and admins can generate.',
      );
    }
    if (user.role == AppRole.admin) return;
    final rows = await _client
        .from('courses')
        .select('id')
        .eq('id', courseId)
        .eq('instructor_id', user.id)
        .limit(1);
    if ((rows as List<dynamic>).isEmpty) {
      throw const GeminiAiException(
        'You can only generate for your own courses.',
      );
    }
  }

  Future<void> _storeAiDraft({
    required String courseId,
    required List<MaterialModel> materials,
    required String contentType,
    required String generationKey,
    required Map<String, dynamic> payload,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await _client.from('ai_generated_content').insert({
        'course_id': courseId,
        'material_id': materials.first.id,
        'generated_by': userId,
        'content_type': contentType,
        'status': 'draft',
        'payload': {
          ...payload,
          'generation_key': generationKey,
          'material_ids': materials.map((m) => m.id).toList(),
        },
      });
    } catch (_) {
      // Generation should still be usable if audit storage is unavailable.
    }
  }

  Future<Map<String, dynamic>?> _findStoredDraft(
    String contentType,
    String generationKey,
  ) async {
    try {
      final rows = await _client
          .from('ai_generated_content')
          .select('payload')
          .eq('content_type', contentType)
          .eq('status', 'draft')
          .contains('payload', {'generation_key': generationKey})
          .order('created_at', ascending: false)
          .limit(1);
      final list = rows as List<dynamic>;
      if (list.isEmpty) return null;
      final payload = Map<String, dynamic>.from(
        (list.first as Map)['payload'] as Map,
      );
      return payload;
    } catch (_) {
      return null;
    }
  }

  AiQuizDraft _validateQuizDraft(
    Map<String, dynamic> json, {
    required int questionCount,
    required int totalMarks,
    required int? durationMinutes,
    required DateTime? deadline,
    required bool allowRetakes,
    required bool showCorrectAnswers,
    required bool showQuestionMarks,
  }) {
    final rawQuestions = json['questions'] as List<dynamic>? ?? const [];
    final questions = rawQuestions
        .whereType<Map>()
        .take(questionCount)
        .map(
          (item) => _validateQuestion(
            Map<String, dynamic>.from(item),
            fallbackType: 'MCQ',
            fallbackMarks: totalMarks / questionCount,
          ).toJson(),
        )
        .toList();
    if (questions.isEmpty) {
      throw const GeminiAiException(
        'Gemini did not generate usable questions.',
      );
    }
    return AiQuizDraft(
      title: _cleanShort(json['title']?.toString() ?? '', fallback: 'AI Quiz'),
      description: _cleanShort(json['description']?.toString() ?? ''),
      instructions: _cleanLong(json['instructions']?.toString() ?? ''),
      dueAt: deadline,
      maxPoints: totalMarks,
      durationMinutes: durationMinutes,
      allowRetakes: allowRetakes,
      showCorrectAnswers: showCorrectAnswers,
      showQuestionMarks: showQuestionMarks,
      questionSchema: questions,
    );
  }

  AiAssignmentDraft _validateAssignmentDraft(
    Map<String, dynamic> json, {
    required int totalMarks,
    required DateTime? deadline,
    required bool includeRubric,
  }) {
    final rubric = includeRubric
        ? (json['rubric'] as List<dynamic>? ?? const [])
              .whereType<Map>()
              .take(10)
              .map((item) {
                final row = Map<String, dynamic>.from(item);
                return {
                  'criterion': _cleanShort(row['criterion']?.toString() ?? ''),
                  'description': _cleanLong(
                    row['description']?.toString() ?? '',
                  ),
                  'marks': ((row['marks'] as num?)?.toInt() ?? 1)
                      .clamp(1, totalMarks)
                      .toInt(),
                };
              })
              .where((item) => (item['criterion'] as String).isNotEmpty)
              .toList()
        : <Map<String, dynamic>>[];
    return AiAssignmentDraft(
      title: _cleanShort(
        json['title']?.toString() ?? '',
        fallback: 'AI Assignment',
      ),
      instructions: _cleanLong(json['instructions']?.toString() ?? ''),
      attachmentRequirements: _cleanLong(
        json['attachment_requirements']?.toString() ?? '',
      ),
      dueAt: deadline,
      maxPoints: totalMarks,
      rubric: rubric,
    );
  }

  QuizQuestionModel _validateQuestion(
    Map<String, dynamic> json, {
    required String fallbackType,
    required double fallbackMarks,
  }) {
    final type = _normalizeQuestionTypes([
      json['type']?.toString() ?? fallbackType,
    ]).first;
    final options = (json['options'] as List<dynamic>? ?? const [])
        .map((item) => _cleanShort(item.toString(), max: 140))
        .where((item) => item.isNotEmpty)
        .take(4)
        .toList();
    final mapping = Map<String, String>.from(
      (json['correct_mapping'] as Map? ?? const {}).map(
        (key, value) => MapEntry(
          _cleanShort(key.toString(), max: 120),
          _cleanShort(value.toString(), max: 120),
        ),
      ),
    )..removeWhere((key, value) => key.isEmpty || value.isEmpty);
    final questionText = _cleanLong(json['question_text']?.toString() ?? '');
    if (questionText.isEmpty) {
      throw const GeminiAiException('Gemini generated an empty question.');
    }
    return QuizQuestionModel(
      type: type,
      questionText: questionText,
      options: type == 'MCQ'
          ? List.generate(
              4,
              (index) => index < options.length
                  ? options[index]
                  : 'Option ${index + 1}',
            )
          : type == 'True / False'
          ? const ['True', 'False']
          : const [],
      correctOption: ((json['correct_option'] as num?)?.toInt() ?? 0)
          .clamp(0, 3)
          .toInt(),
      marks: fallbackMarks <= 0
          ? ((json['marks'] as num?)?.toDouble() ?? 1)
                .clamp(0.5, 100)
                .toDouble()
          : fallbackMarks,
      explanation: _cleanLong(json['explanation']?.toString() ?? ''),
      sampleAnswer: _cleanLong(json['sample_answer']?.toString() ?? ''),
      items: type == 'Matching' ? mapping.keys.toList() : const [],
      targets: type == 'Matching' ? mapping.values.toSet().toList() : const [],
      correctMapping: type == 'Matching' ? mapping : const {},
    );
  }

  List<MaterialModel> _requireMaterials(List<MaterialModel> materials) {
    if (materials.isEmpty) {
      throw const GeminiAiException('Select at least one material first.');
    }
    return materials.take(8).toList();
  }

  List<String> _normalizeQuestionTypes(List<String> types) {
    final normalized = types
        .map((type) {
          final value = type.trim().toLowerCase();
          if (value == 'true/false' || value == 'true / false') {
            return 'True / False';
          }
          if (value == 'short answer') return 'Short Answer';
          if (value == 'matching') return 'Matching';
          return 'MCQ';
        })
        .toSet()
        .toList();
    return normalized.isEmpty ? ['MCQ'] : normalized;
  }

  int? _limitNullableInt(int? value, int min, int max) {
    if (value == null) return null;
    return value.clamp(min, max).toInt();
  }

  String _cacheKey(Map<String, dynamic> values) {
    return base64Url.encode(utf8.encode(jsonEncode(values)));
  }

  String _stripJsonFence(String text) {
    return text
        .replaceFirst(RegExp(r'^```json\s*', multiLine: true), '')
        .replaceFirst(RegExp(r'^```\s*', multiLine: true), '')
        .replaceFirst(RegExp(r'\s*```$'), '')
        .trim();
  }

  String _trim(String text, int max) {
    final clean = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.length <= max) return clean;
    return clean.substring(0, max);
  }

  String _cleanShort(String value, {int max = 120, String fallback = ''}) {
    final clean = _trim(value, max);
    return clean.isEmpty ? fallback : clean;
  }

  String _cleanLong(String value, {int max = 1800}) => _trim(value, max);

  String _mimeForExtension(String extension) {
    switch (extension.toLowerCase()) {
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      case 'txt':
      case 'md':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }

  bool _supportedContextMime(String mime) {
    return {
      'image/png',
      'image/jpeg',
      'image/webp',
      'application/pdf',
      'text/plain',
    }.contains(mime);
  }
}

class AiQuizDraft {
  const AiQuizDraft({
    required this.title,
    required this.description,
    required this.instructions,
    required this.dueAt,
    required this.maxPoints,
    required this.durationMinutes,
    required this.allowRetakes,
    required this.showCorrectAnswers,
    required this.showQuestionMarks,
    required this.questionSchema,
  });

  final String title;
  final String description;
  final String instructions;
  final DateTime? dueAt;
  final int maxPoints;
  final int? durationMinutes;
  final bool allowRetakes;
  final bool showCorrectAnswers;
  final bool showQuestionMarks;
  final List<Map<String, dynamic>> questionSchema;

  factory AiQuizDraft.fromJson(Map<String, dynamic> json) {
    return AiQuizDraft(
      title: json['title'] as String? ?? 'AI Quiz',
      description: json['description'] as String? ?? '',
      instructions: json['instructions'] as String? ?? '',
      dueAt: json['due_at'] == null
          ? null
          : DateTime.parse(json['due_at'] as String),
      maxPoints: (json['max_points'] as num?)?.toInt() ?? 100,
      durationMinutes: (json['duration_minutes'] as num?)?.toInt(),
      allowRetakes: json['allow_retakes'] as bool? ?? false,
      showCorrectAnswers: json['show_correct_answers'] as bool? ?? false,
      showQuestionMarks: json['show_question_marks'] as bool? ?? true,
      questionSchema: (json['question_schema'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'instructions': instructions,
      'due_at': dueAt?.toUtc().toIso8601String(),
      'max_points': maxPoints,
      'duration_minutes': durationMinutes,
      'allow_retakes': allowRetakes,
      'show_correct_answers': showCorrectAnswers,
      'show_question_marks': showQuestionMarks,
      'question_schema': questionSchema,
    };
  }
}

class AiAssignmentDraft {
  const AiAssignmentDraft({
    required this.title,
    required this.instructions,
    required this.attachmentRequirements,
    required this.dueAt,
    required this.maxPoints,
    required this.rubric,
  });

  final String title;
  final String instructions;
  final String attachmentRequirements;
  final DateTime? dueAt;
  final int maxPoints;
  final List<Map<String, dynamic>> rubric;

  factory AiAssignmentDraft.fromJson(Map<String, dynamic> json) {
    return AiAssignmentDraft(
      title: json['title'] as String? ?? 'AI Assignment',
      instructions: json['instructions'] as String? ?? '',
      attachmentRequirements: json['attachment_requirements'] as String? ?? '',
      dueAt: json['due_at'] == null
          ? null
          : DateTime.parse(json['due_at'] as String),
      maxPoints: (json['max_points'] as num?)?.toInt() ?? 100,
      rubric: (json['rubric'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'instructions': instructions,
      'attachment_requirements': attachmentRequirements,
      'due_at': dueAt?.toUtc().toIso8601String(),
      'max_points': maxPoints,
      'rubric': rubric,
    };
  }
}

class GeminiAiException implements Exception {
  const GeminiAiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class _GeminiFallbackException implements Exception {
  const _GeminiFallbackException({
    required this.message,
    required this.reason,
    this.canFallback = true,
  });

  final String message;
  final String reason;
  final bool canFallback;

  GeminiAiException toUserException() => GeminiAiException(message);
}
