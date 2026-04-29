import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/auth/app_role.dart';
import '../core/config/app_env.dart';
import '../models/assignment_model.dart';
import '../models/flashcard_model.dart';
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
  static const _maxContextChars = 16000;
  static const _maxMaterialBytes = 2 * 1024 * 1024;
  static const _maxContextFileBytes = 3 * 1024 * 1024;
  static const _maxRawMaterialBytes = 8 * 1024 * 1024;
  static const _maxContextFiles = 3;
  static const _maxOutputTokens = 8192;
  static const _quizImageFolder = 'quiz-images';
  static const _assignmentAttachmentFolder = 'assignment-attachments';
  static const _minExtractedChars = 20;
  static const _minReadableRatio = 0.35;
  static const _materialReadError =
      'Could not read enough content from the selected material. Please try another file or upload a clearer version.';
  static const _noQuestionContextError =
      'Add a prompt, image, or readable course material before generating a question.';
  static const _unsupportedGenerationError =
      'The AI response was not grounded enough in the selected material. Please try again with fewer questions or clearer material.';
  static const _invalidQuestionError =
      'Gemini returned an invalid question format. Please try again.';

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
    List<PlatformFile> contextImages = const [],
  }) async {
    await _ensureCanGenerate(courseId);
    final cleanMaterials = _requireMaterials(materials);
    final normalizedTypes = _normalizeQuestionTypes(questionTypes);
    final safeQuestionCount = questionCount.clamp(1, 30).toInt();
    final safeMarks = totalMarks.clamp(1, 500).toInt();
    final uploadedContextImages = await _uploadQuizContextImages(
      courseId: courseId,
      files: contextImages,
      maxImages: safeQuestionCount,
    );
    final groundedContext = await _buildGroundedContext(cleanMaterials);
    final contextParts = [
      ...groundedContext.contextParts,
      ...uploadedContextImages
          .where((file) => file.inlinePart != null)
          .map((file) => file.toContextPart()),
    ];
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
      'contextImages': uploadedContextImages
          .map((file) => {'name': file.name, 'size': file.size})
          .toList(),
      'ctx': groundedContext.fingerprint,
    });
    final cached = _memoryCache[cacheKey];
    if (cached != null) return AiQuizDraft.fromJson(cached);
    final stored = await _findStoredDraft('quiz', cacheKey);
    if (stored != null) {
      _memoryCache[cacheKey] = stored;
      return AiQuizDraft.fromJson(stored);
    }

    final promptText =
        'JSON only. Use only the PROVIDED MATERIAL CONTENT, including extracted text and any attached original material files. Do not add outside knowledge. '
        'All questions must be derived strictly from the provided lecture content. Do not use general knowledge about the topic. If a concept is not explicitly present in the material, do not include it. '
        'Do not generate questions from the broad topic; every question must be answerable from explicit text in the context. '
        'If the context is insufficient, return {"failure":"insufficient_context"} only. '
        'Make a quiz. Types only: MCQ, True / False, Short Answer, Matching. '
        'Do not mention source material names, file names, "according to the material", "based on the lecture", "based on the uploaded file", or similar internal source wording in any student-visible text. '
        'Context images are visual question assets, not lecture materials. When a context image is useful, create a question that requires looking at the image, refer to it naturally as "the image below", "the diagram below", "the chart below", "the code snippet below", or "the figure below", and set context_image_name to the image file name only in that JSON field. Do not include the image file name in question_text, options, explanation, sample_answer, items, or targets. Do not use context images as hidden grounding text. '
        'Available context images: ${_uploadedFileNames(uploadedContextImages)}. '
        'Schema: {"title":string,"description":string,"instructions":string,"questions":[{"type":string,"question_text":string,"options":string[],"correct_option":number,"marks":number,"explanation":string,"sample_answer":string,"items":string[],"targets":string[],"correct_mapping":object,"context_image_name":string,"source_ref":{"material_id":string,"material_name":string,"page":string,"excerpt":string}}]}. '
        'source_ref.excerpt must be copied from the provided context and must directly support the item. '
        'Count $safeQuestionCount. Types ${normalizedTypes.join(", ")}. Difficulty ${_cleanShort(difficulty, fallback: "medium")}. Total marks $safeMarks. '
        'Use concise wording. No markdown. Custom: ${_cleanShort(prompt, max: 500, fallback: "none")}.\nPROVIDED MATERIAL CONTEXT:\n${groundedContext.promptText}';

    final json = await _generateJson(promptText, contextParts);
    final draft = _validateQuizDraft(
      json,
      context: groundedContext,
      materialIds: cleanMaterials.map((material) => material.id).toList(),
      materialNames: cleanMaterials.map((material) => material.title).toList(),
      contextImages: uploadedContextImages,
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
    final assignmentAttachments = await _uploadAssignmentContextFiles(
      courseId: courseId,
      files: contextFiles,
    );
    final groundedContext = await _buildGroundedContext(cleanMaterials);
    final contextParts = [
      ...groundedContext.contextParts,
      ...assignmentAttachments
          .where((file) => file.inlinePart != null)
          .map((file) => file.toContextPart()),
    ];
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
      'files': assignmentAttachments
          .map((file) => {'name': file.name, 'size': file.size})
          .toList(),
      'ctx': groundedContext.fingerprint,
    });
    final cached = _memoryCache[cacheKey];
    if (cached != null) return AiAssignmentDraft.fromJson(cached);
    final stored = await _findStoredDraft('assignment', cacheKey);
    if (stored != null) {
      _memoryCache[cacheKey] = stored;
      return AiAssignmentDraft.fromJson(stored);
    }

    final promptText =
        'JSON only. Use only the PROVIDED MATERIAL CONTENT, including extracted text and any attached original material files. Do not add outside knowledge. '
        'All tasks must be derived strictly from the provided lecture content. Do not use general knowledge about the topic. If a concept is not explicitly present in the material, do not include it. '
        'Do not create tasks from the broad topic; every task and rubric row must be answerable from explicit text in the context. '
        'If the context is insufficient, return {"failure":"insufficient_context"} only. '
        'Make an assignment. '
        'Context files are student-visible assignment attachments, not lecture materials. When context files are provided, generated tasks should directly reference the attached files by name where appropriate. Attached files: ${_uploadedFileNames(assignmentAttachments)}. '
        'Schema: {"title":string,"instructions":string,"attachment_requirements":string,"tasks":[{"task":string,"source_ref":{"material_id":string,"material_name":string,"page":string,"excerpt":string}}],"rubric":[{"criterion":string,"description":string,"marks":number,"source_ref":{"material_id":string,"material_name":string,"page":string,"excerpt":string}}]}. '
        'Each source_ref.excerpt must be copied from the provided context and must directly support the task or criterion. '
        'Difficulty ${_cleanShort(difficulty, fallback: "medium")}. Tasks $safeTaskCount. Total marks $safeMarks. '
        'Rubric ${includeRubric ? "yes" : "no"}. No markdown. Custom: ${_cleanShort(prompt, max: 500, fallback: "none")}.\nPROVIDED MATERIAL CONTEXT:\n${groundedContext.promptText}';

    final json = await _generateJson(promptText, contextParts);
    final draft = _validateAssignmentDraft(
      json,
      context: groundedContext,
      taskCount: safeTaskCount,
      totalMarks: safeMarks,
      deadline: deadline,
      includeRubric: includeRubric,
      attachments: assignmentAttachments
          .map((file) => file.attachment)
          .toList(),
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

  Future<AiFlashcardDraft> generateFlashcardDraft({
    required String courseId,
    required List<MaterialModel> materials,
    required String prompt,
    required int cardCount,
    required String difficulty,
  }) async {
    await _ensureStudentCanGenerateFlashcards(courseId);
    final cleanMaterials = _requireMaterials(materials);
    final safeCardCount = cardCount.clamp(1, 40).toInt();
    final groundedContext = await _buildGroundedContext(cleanMaterials);
    final cacheKey = _cacheKey({
      'kind': 'flashcards',
      'course': courseId,
      'student': _client.auth.currentUser?.id,
      'materials': cleanMaterials.map((m) => m.id).toList(),
      'prompt': prompt.trim(),
      'count': safeCardCount,
      'difficulty': difficulty,
      'ctx': groundedContext.fingerprint,
    });
    final cached = _memoryCache[cacheKey];
    if (cached != null) return AiFlashcardDraft.fromJson(cached);
    final stored = await _findStoredDraft('flashcards', cacheKey);
    if (stored != null) {
      _memoryCache[cacheKey] = stored;
      return AiFlashcardDraft.fromJson(stored);
    }

    final promptText =
        'JSON only. Use only the PROVIDED MATERIAL CONTENT, including extracted text and any attached original material files. Do not add outside knowledge. '
        'Every flashcard must be derived strictly from explicit lecture content in the provided context. Do not use general knowledge about the topic. Do not invent information. '
        'Do not create generic topic-level cards. Make each card specific to the way the selected lecture content presents the concept, step, example, distinction, or fact. '
        'Do not mention source material names, file names, lecture names, "according to the material", "based on the lecture", "based on the uploaded file", or similar source wording in front or back text. '
        'Make natural study flashcards. Keep front and back concise. Avoid long paragraphs. Do not include marks, grading, scores, correct flags, or evaluation logic. '
        'Do not generate general definitions unless that definition is explicitly present in the provided context. '
        'If the context is insufficient, return {"failure":"insufficient_context"} only. '
        'Schema: {"title":string,"cards":[{"front":string,"back":string,"difficulty":string,"tag":string,"source_ref":{"material_id":string,"material_name":string,"page":string,"excerpt":string}}]}. '
        'source_ref.excerpt must be copied from the provided context and must directly support the flashcard. '
        'Count $safeCardCount. Difficulty ${_cleanShort(difficulty, fallback: "mixed")}. Custom: ${_cleanShort(prompt, max: 500, fallback: "none")}.\nPROVIDED MATERIAL CONTEXT:\n${groundedContext.promptText}';

    final text = await _requestJsonText(
      promptText,
      groundedContext.contextParts,
    );
    final Map<String, dynamic> json;
    try {
      json = _decodeJsonMap(text);
    } catch (_) {
      throw const GeminiAiException(
        'Gemini returned invalid flashcards. Please try again with fewer cards.',
      );
    }
    final draft = _validateFlashcardDraft(
      json,
      context: groundedContext,
      cardCount: safeCardCount,
      materialIds: cleanMaterials.map((material) => material.id).toList(),
    );
    _memoryCache[cacheKey] = draft.toJson();
    await _storeAiDraft(
      courseId: courseId,
      materials: cleanMaterials,
      contentType: 'flashcards',
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
    String existingQuizContext = '',
    String? quizId,
  }) async {
    await _ensureCanGenerate(courseId);
    final normalizedType = _normalizeQuestionTypes([type]).first;
    final contextImage = image == null
        ? null
        : await _uploadSingleQuestionContextImage(
            courseId: courseId,
            image: image,
          );
    final scopedMaterials = materials.isNotEmpty
        ? materials
        : quizId == null
        ? materials
        : await _resolveQuizMaterials(quizId: quizId, courseId: courseId);
    final groundedContext = await _buildSingleQuestionContext(
      materials: scopedMaterials,
      prompt: prompt,
      contextImage: contextImage,
      existingQuizContext: existingQuizContext,
    );
    final parts = groundedContext.contextParts;
    final promptText =
        'JSON only. Use only the PROVIDED MATERIAL CONTENT, including extracted text and any attached original material files. Do not add outside knowledge. '
        'The question must be derived strictly from the provided lecture content. Do not use general knowledge about the topic. If a concept is not explicitly present in the material, do not include it. '
        'Do not generate from the broad topic; the question must be answerable from explicit text in the context. '
        'If the context is insufficient, return {"failure":"insufficient_context"} only. '
        'Make one quiz question. Type $normalizedType only. '
        'Do not mention source material names, file names, "according to the material", "based on the lecture", "based on the uploaded file", or similar internal source wording in any student-visible text. '
        'The optional context image is a visual question asset, not lecture material. If provided, use it directly, make the question require looking at the image, refer to it naturally as "the image below", "the diagram below", "the chart below", "the code snippet below", or "the figure below", and set context_image_name to the image file name only in that JSON field. Do not include the image file name in question_text, options, explanation, sample_answer, items, or targets. Context image: ${contextImage?.name ?? "none"}. '
        'Schema: {"type":string,"question_text":string,"options":string[],"correct_option":number,"marks":number,"explanation":string,"sample_answer":string,"items":string[],"targets":string[],"correct_mapping":object,"context_image_name":string,"source_ref":{"material_id":string,"material_name":string,"page":string,"excerpt":string}}. '
        'source_ref.excerpt must be copied from the provided context and must directly support the item. '
        'Marks ${marks <= 0 ? 1 : marks}. Custom: ${_cleanShort(prompt, max: 400, fallback: "none")}.\nPROVIDED MATERIAL CONTEXT:\n${groundedContext.promptText}';
    final json = await _generateJson(promptText, parts);
    try {
      return _validateQuestion(
        json,
        context: groundedContext,
        contextImages: [?contextImage],
        requireContextImage: contextImage != null,
        usedContextImageNames: <String>{},
        fallbackType: normalizedType,
        fallbackMarks: marks,
      );
    } on GeminiAiException catch (error) {
      if (error.message == _unsupportedGenerationError) {
        throw const GeminiAiException(_invalidQuestionError);
      }
      rethrow;
    }
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

    final firstText = await _requestJsonText(prompt, contextParts);
    try {
      return _decodeJsonMap(firstText);
    } catch (_) {
      _log('Invalid JSON response: ${_cleanShort(firstText, max: 500)}');
    }

    final retryPrompt =
        '$prompt\n\nYour previous response was invalid or incomplete JSON. '
        'Return ONE complete minified JSON object only. '
        'No markdown, no prose, no trailing commas, no line breaks outside string values. '
        'Keep every text field concise so the JSON object is complete.';
    final retryText = await _requestJsonText(retryPrompt, contextParts);
    try {
      return _decodeJsonMap(retryText);
    } catch (_) {
      _log('Invalid JSON retry response: ${_cleanShort(retryText, max: 500)}');
      throw const GeminiAiException(
        'Gemini returned invalid JSON after retrying. Please try again with fewer items.',
      );
    }
  }

  Future<String> _requestJsonText(
    String prompt,
    List<Map<String, dynamic>> contextParts,
  ) async {
    final parts = <Map<String, dynamic>>[
      {
        'text':
            '$prompt\n\nJSON OUTPUT RULES: return one complete minified JSON object only; no markdown; no prose; no comments; no trailing commas; keep text fields concise.',
      },
      ...contextParts.map((item) => item['part'] as Map<String, dynamic>),
    ];
    final body = jsonEncode({
      'contents': [
        {'role': 'user', 'parts': parts},
      ],
      'generationConfig': {
        'temperature': 0.2,
        'topP': 0.8,
        'maxOutputTokens': _maxOutputTokens,
        'responseMimeType': 'application/json',
      },
    });
    final response = await _generateWithFallback(body);
    final text = _responseText(response.body);
    if (text.isEmpty) {
      throw const GeminiAiException('Gemini returned an empty response.');
    }
    return text;
  }

  String _responseText(String body) {
    final envelope = jsonDecode(body) as Map<String, dynamic>;
    final candidates = envelope['candidates'] as List<dynamic>? ?? const [];
    final content = candidates.isEmpty
        ? null
        : (candidates.first as Map<String, dynamic>)['content'];
    final partsResponse = content is Map
        ? content['parts'] as List<dynamic>? ?? const []
        : const [];
    return partsResponse
        .whereType<Map>()
        .map((part) => part['text']?.toString() ?? '')
        .join()
        .trim();
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
    return 'Gemini request failed after trying the available models. Please try again later.';
  }

  void _log(String message) {
    debugPrint('[GeminiAiService] $message');
  }

  Future<_GroundedContext> _buildGroundedContext(
    List<MaterialModel> materials,
  ) async {
    final sources = <_GroundedSource>[];
    final contextParts = <Map<String, dynamic>>[];
    for (final material in materials.take(8)) {
      final Uint8List bytes;
      try {
        bytes = await _downloadMaterialBytes(material);
      } on GeminiAiException {
        continue;
      }
      final extracted = _extractText(material, bytes);
      final hasUsableText = _hasUsableText(extracted);
      final canAttachRaw =
          _supportedContextMime(_mimeForMaterial(material)) &&
          material.fileSizeBytes <= _maxRawMaterialBytes;
      if (!hasUsableText && !canAttachRaw) {
        continue;
      }
      if ((!hasUsableText || _shouldPreferRawFile(material, extracted)) &&
          canAttachRaw) {
        contextParts.add(_inlineMaterialPart(material, bytes));
      }
      final chunks = hasUsableText
          ? _selectRepresentativeChunks(extracted)
          : <String>[];
      sources.add(
        _GroundedSource(
          materialId: material.id,
          materialName: material.title,
          fileName: material.fileName,
          rawFileAttached: contextParts.any(
            (part) => part['material_id'] == material.id,
          ),
          headings: hasUsableText ? _extractHeadings(extracted) : const [],
          keyBullets: hasUsableText ? _extractBullets(extracted) : const [],
          definitions: hasUsableText
              ? _extractDefinitions(extracted)
              : const [],
          examples: hasUsableText ? _extractExamples(extracted) : const [],
          chunks: chunks,
        ),
      );
    }
    if (sources.isEmpty) {
      throw const GeminiAiException(_materialReadError);
    }
    final context = _GroundedContext(
      sources: sources,
      contextParts: contextParts,
    );
    if (!context.hasAnyUsableContent) {
      throw const GeminiAiException(_materialReadError);
    }
    return context;
  }

  Future<List<MaterialModel>> _resolveQuizMaterials({
    required String quizId,
    required String courseId,
  }) async {
    try {
      final quiz = await _client
          .from('quizzes')
          .select('question_schema')
          .eq('id', quizId)
          .single();
      final schema = (quiz as Map)['question_schema'] as List<dynamic>? ?? [];
      final linkedIds = _materialIdsFromQuestionSchema(schema);
      if (linkedIds.isEmpty) {
        return MaterialService.instance.getCourseMaterials(courseId);
      }
      final rows = await _client
          .from('materials')
          .select('*, profiles!materials_uploaded_by_fkey(full_name)')
          .inFilter('id', linkedIds);
      final materials = (rows as List<dynamic>)
          .map(
            (item) =>
                MaterialModel.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
      return materials.isEmpty
          ? MaterialService.instance.getCourseMaterials(courseId)
          : materials;
    } catch (_) {
      return MaterialService.instance.getCourseMaterials(courseId);
    }
  }

  List<String> _materialIdsFromQuestionSchema(List<dynamic> schema) {
    final ids = <String>{};
    for (final item in schema.whereType<Map>()) {
      final sourceRef = item['source_ref'];
      if (sourceRef is! Map) continue;
      final selected = sourceRef['selected_material_ids'];
      if (selected is List) {
        ids.addAll(
          selected.map((id) => id.toString()).where((id) => id.isNotEmpty),
        );
      }
      final materialId = sourceRef['material_id']?.toString() ?? '';
      if (materialId.isNotEmpty &&
          materialId != 'user_prompt' &&
          materialId != 'question_image' &&
          materialId != 'existing_quiz_context') {
        ids.add(materialId);
      }
    }
    return ids.toList();
  }

  Future<_GroundedContext> _buildSingleQuestionContext({
    required List<MaterialModel> materials,
    required String prompt,
    required _UploadedAiFile? contextImage,
    required String existingQuizContext,
  }) async {
    _GroundedContext? materialContext;
    GeminiAiException? materialError;
    final cleanMaterials = materials.take(8).toList();
    if (cleanMaterials.isNotEmpty) {
      try {
        materialContext = await _buildGroundedContext(cleanMaterials);
      } on GeminiAiException catch (error) {
        materialError = error;
      }
    }

    final sources = <_GroundedSource>[...?materialContext?.sources];
    final contextParts = <Map<String, dynamic>>[
      ...?materialContext?.contextParts,
    ];

    final cleanPrompt = _cleanLong(prompt, max: 1200);
    if (cleanPrompt.isNotEmpty) {
      sources.add(
        _GroundedSource(
          materialId: 'user_prompt',
          materialName: 'User prompt',
          fileName: 'Prompt',
          rawFileAttached: false,
          headings: const [],
          keyBullets: const [],
          definitions: const [],
          examples: const [],
          chunks: [cleanPrompt],
        ),
      );
    }

    final cleanExistingContext = _cleanLong(existingQuizContext, max: 2200);
    if (cleanExistingContext.isNotEmpty) {
      sources.add(
        _GroundedSource(
          materialId: 'existing_quiz_context',
          materialName: 'Existing quiz context',
          fileName: 'Quiz editor',
          rawFileAttached: false,
          headings: const [],
          keyBullets: const [],
          definitions: const [],
          examples: const [],
          chunks: [cleanExistingContext],
        ),
      );
    }

    if (contextImage != null) {
      if (contextImage.inlinePart != null) {
        contextParts.add(contextImage.toContextPart());
      }
      sources.add(
        _GroundedSource(
          materialId: 'question_image',
          materialName: contextImage.name,
          fileName: contextImage.name,
          rawFileAttached: true,
          headings: const [],
          keyBullets: const [],
          definitions: const [],
          examples: const [],
          chunks: const [],
        ),
      );
    }

    final context = _GroundedContext(
      sources: sources,
      contextParts: contextParts,
    );
    if (context.hasAnyUsableContent) {
      return context;
    }
    if (materialError != null && cleanMaterials.isNotEmpty) {
      throw const GeminiAiException(_materialReadError);
    }
    throw const GeminiAiException(_noQuestionContextError);
  }

  Future<Uint8List> _downloadMaterialBytes(MaterialModel material) async {
    if ((material.storagePath ?? '').isEmpty) {
      throw const GeminiAiException(_materialReadError);
    }
    final extension = material.fileType.toLowerCase();
    final textLike = {'txt', 'md', 'csv', 'json'}.contains(extension);
    final canUseRaw = _supportedContextMime(_mimeForMaterial(material));
    if ((!textLike && material.fileSizeBytes > _maxRawMaterialBytes) ||
        (material.fileSizeBytes > _maxMaterialBytes && !canUseRaw)) {
      throw const GeminiAiException(_materialReadError);
    }
    try {
      return await _client.storage
          .from(MaterialService.bucketName)
          .download(material.storagePath!);
    } catch (_) {
      throw const GeminiAiException(_materialReadError);
    }
  }

  String _extractText(MaterialModel material, Uint8List bytes) {
    final extension = material.fileType.toLowerCase();
    if (!{'txt', 'md', 'csv', 'json'}.contains(extension)) {
      return '';
    }
    try {
      return _normalizeExtractedText(utf8.decode(bytes, allowMalformed: true));
    } catch (_) {
      return '';
    }
  }

  bool _hasUsableText(String text) {
    final clean = text.trim();
    if (clean.length < _minExtractedChars) return false;
    if (_readableRatio(clean) < _minReadableRatio) return false;
    final wordCount = RegExp(
      r'[A-Za-z0-9\u0600-\u06FF]{2,}',
    ).allMatches(clean).length;
    final hasStructure =
        RegExp(r'[.!?]\s|^[-*]|\n', multiLine: true).hasMatch(clean) ||
        clean.contains(':');
    return wordCount >= 3 && hasStructure;
  }

  bool _shouldPreferRawFile(MaterialModel material, String extracted) {
    final extension = material.fileType.toLowerCase();
    if (!{'pdf', 'png', 'jpg', 'jpeg', 'webp'}.contains(extension)) {
      return false;
    }
    return extracted.length < 1200;
  }

  Map<String, dynamic> _inlineMaterialPart(
    MaterialModel material,
    Uint8List bytes,
  ) {
    return {
      'name': material.fileName,
      'material_id': material.id,
      'part': {
        'inlineData': {
          'mimeType': _mimeForMaterial(material),
          'data': base64Encode(bytes),
        },
      },
    };
  }

  String _normalizeExtractedText(String text) {
    return text
        .replaceAll('\u0000', ' ')
        .replaceAll(RegExp(r'[ \t]+\n'), '\n')
        .replaceAll(RegExp(r'\n{4,}'), '\n\n\n')
        .trim();
  }

  double _readableRatio(String text) {
    final clean = text.trim();
    if (clean.isEmpty) return 0;
    final readable = RegExp(
      "[A-Za-z0-9\\u0600-\\u06FF\\s.,;:!?()\\[\\]{}\\-_/%+=#@'\"`]",
    ).allMatches(clean).length;
    return readable / clean.length;
  }

  List<String> _selectRepresentativeChunks(String text) {
    final fullText = _cleanExcerpt(text, max: _maxContextChars);
    if (fullText.length <= _maxContextChars &&
        text.length <= _maxContextChars) {
      return [fullText];
    }
    final paragraphs = text
        .split(RegExp(r'\n\s*\n|(?=^#{1,6}\s)', multiLine: true))
        .map((item) => _cleanExcerpt(item, max: 900))
        .where((item) => item.length >= 80)
        .toList();
    if (paragraphs.isEmpty) {
      final clean = _cleanExcerpt(text, max: _maxContextChars);
      return clean.length < _minExtractedChars ? const [] : [clean];
    }

    final selected = <String>[];
    void addIndex(int index) {
      if (index < 0 || index >= paragraphs.length) return;
      final value = paragraphs[index];
      if (!selected.contains(value)) selected.add(value);
    }

    addIndex(0);
    addIndex(1);
    addIndex((paragraphs.length / 4).floor());
    addIndex((paragraphs.length / 2).floor());
    addIndex((paragraphs.length * 3 / 4).floor());
    addIndex(paragraphs.length - 2);
    addIndex(paragraphs.length - 1);

    for (final paragraph in paragraphs) {
      final lower = paragraph.toLowerCase();
      final important =
          lower.contains('definition') ||
          lower.contains('example') ||
          lower.contains('table') ||
          lower.contains('figure') ||
          lower.contains('diagram') ||
          lower.contains(':');
      if (important && !selected.contains(paragraph)) {
        selected.add(paragraph);
      }
      if (selected.join('\n').length >= _maxContextChars) break;
    }

    final budgeted = <String>[];
    var used = 0;
    for (final chunk in selected) {
      final remaining = _maxContextChars - used;
      if (remaining <= 200) break;
      final value = _cleanExcerpt(
        chunk,
        max: remaining.clamp(200, 900).toInt(),
      );
      budgeted.add(value);
      used += value.length + 2;
    }
    return budgeted;
  }

  List<String> _extractHeadings(String text) {
    return text
        .split('\n')
        .map((line) => line.trim())
        .where((line) {
          if (line.length < 4 || line.length > 90) return false;
          return line.startsWith('#') ||
              RegExp(
                r'^(chapter|lecture|unit|module|section|slide)\b',
                caseSensitive: false,
              ).hasMatch(line) ||
              (!line.endsWith('.') &&
                  line.split(RegExp(r'\s+')).length <= 9 &&
                  line.toUpperCase() == line);
        })
        .map((line) => line.replaceFirst(RegExp(r'^#+\s*'), ''))
        .take(12)
        .toList();
  }

  List<String> _extractBullets(String text) {
    return text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => RegExp(r'^([-*]|\d+[.)])\s+').hasMatch(line))
        .map((line) => _cleanExcerpt(line, max: 180))
        .where((line) => line.length >= 20)
        .take(18)
        .toList();
  }

  List<String> _extractDefinitions(String text) {
    return text
        .split(RegExp(r'(?<=[.!?])\s+|\n+'))
        .map((item) => _cleanExcerpt(item, max: 220))
        .where((item) {
          final lower = item.toLowerCase();
          return item.length >= 30 &&
              (lower.contains(' is ') ||
                  lower.contains(' refers to ') ||
                  lower.contains(' defined as ') ||
                  lower.contains(' means '));
        })
        .take(12)
        .toList();
  }

  List<String> _extractExamples(String text) {
    return text
        .split(RegExp(r'(?<=[.!?])\s+|\n+'))
        .map((item) => _cleanExcerpt(item, max: 220))
        .where((item) {
          final lower = item.toLowerCase();
          return item.length >= 25 &&
              (lower.contains('example') ||
                  lower.contains('for instance') ||
                  lower.contains('e.g.'));
        })
        .take(10)
        .toList();
  }

  Future<List<_UploadedAiFile>> _uploadQuizContextImages({
    required String courseId,
    required List<PlatformFile> files,
    required int maxImages,
  }) async {
    if (files.length > maxImages) {
      throw GeminiAiException(
        'Add at most $maxImages context images for this quiz.',
      );
    }
    final uploaded = <_UploadedAiFile>[];
    for (final file in files) {
      final mime = _mimeForExtension(file.extension ?? '');
      if (!_isImageMime(mime)) {
        throw GeminiAiException(
          '${file.name} is not supported. Quiz context images must be PNG, JPG, or WEBP.',
        );
      }
      uploaded.add(
        await _uploadAiFile(
          courseId: courseId,
          file: file,
          folder: _quizImageFolder,
          mime: mime,
          inlineForGemini: true,
          attachmentKey: 'image_path',
        ),
      );
    }
    return uploaded;
  }

  Future<_UploadedAiFile> _uploadSingleQuestionContextImage({
    required String courseId,
    required PlatformFile image,
  }) async {
    final mime = _mimeForExtension(image.extension ?? '');
    if (!_isImageMime(mime)) {
      throw GeminiAiException(
        '${image.name} is not supported. Choose a PNG, JPG, or WEBP image.',
      );
    }
    return _uploadAiFile(
      courseId: courseId,
      file: image,
      folder: _quizImageFolder,
      mime: mime,
      inlineForGemini: true,
      attachmentKey: 'image_path',
    );
  }

  Future<List<_UploadedAiFile>> _uploadAssignmentContextFiles({
    required String courseId,
    required List<PlatformFile> files,
  }) async {
    if (files.length > _maxContextFiles) {
      throw GeminiAiException(
        'Attach at most $_maxContextFiles assignment context files.',
      );
    }
    final uploaded = <_UploadedAiFile>[];
    for (final file in files) {
      final mime = _mimeForExtension(file.extension ?? '');
      if (!_isSupportedAssignmentAttachment(file.extension ?? '')) {
        throw GeminiAiException(
          '${file.name} is not a supported assignment attachment.',
        );
      }
      uploaded.add(
        await _uploadAiFile(
          courseId: courseId,
          file: file,
          folder: _assignmentAttachmentFolder,
          mime: mime,
          inlineForGemini: _supportedContextMime(mime),
          attachmentKey: 'path',
        ),
      );
    }
    return uploaded;
  }

  Future<_UploadedAiFile> _uploadAiFile({
    required String courseId,
    required PlatformFile file,
    required String folder,
    required String mime,
    required bool inlineForGemini,
    required String attachmentKey,
  }) async {
    if (file.size > _maxContextFileBytes && inlineForGemini) {
      throw GeminiAiException('${file.name} is too large for AI context.');
    }
    final bytes = await _readFileBytes(file);
    final objectPath =
        '$courseId/$folder/${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.name)}';
    await _client.storage
        .from(MaterialService.bucketName)
        .uploadBinary(
          objectPath,
          bytes,
          fileOptions: FileOptions(contentType: mime, upsert: false),
        );
    return _UploadedAiFile(
      name: file.name,
      path: objectPath,
      size: file.size,
      mimeType: mime,
      inlinePart: inlineForGemini
          ? {
              'inlineData': {'mimeType': mime, 'data': base64Encode(bytes)},
            }
          : null,
      attachmentKey: attachmentKey,
    );
  }

  _UploadedAiFile? _resolveQuestionImage(
    String requestedName,
    String questionText,
    List<_UploadedAiFile> contextImages,
    bool requireContextImage,
    Set<String> usedContextImageNames,
  ) {
    if (contextImages.isEmpty) return null;
    final cleanName = requestedName.trim().toLowerCase();
    if (cleanName.isNotEmpty) {
      for (final image in contextImages) {
        if (image.name.toLowerCase() == cleanName) {
          usedContextImageNames.add(image.name);
          return image;
        }
      }
    }
    final text = questionText.toLowerCase();
    for (final image in contextImages) {
      if (usedContextImageNames.contains(image.name)) continue;
      if (text.contains(image.name.toLowerCase()) ||
          text.contains('image') ||
          text.contains('figure') ||
          text.contains('diagram')) {
        usedContextImageNames.add(image.name);
        return image;
      }
    }
    if (requireContextImage) {
      usedContextImageNames.add(contextImages.first.name);
      return contextImages.first;
    }
    return null;
  }

  String _uploadedFileNames(List<_UploadedAiFile> files) {
    if (files.isEmpty) return 'none';
    return files.map((file) => file.name).join(', ');
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

  Future<void> _ensureStudentCanGenerateFlashcards(String courseId) async {
    final user = AuthService.instance.currentUser;
    if (user == null || user.role != AppRole.student) {
      throw const GeminiAiException('Only students can generate flashcards.');
    }
    final rows = await _client
        .from('enrollments')
        .select('id')
        .eq('course_id', courseId)
        .eq('student_id', user.id)
        .eq('status', 'active')
        .limit(1);
    if ((rows as List<dynamic>).isEmpty) {
      throw const GeminiAiException(
        'You can only generate flashcards for your enrolled courses.',
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
    required _GroundedContext context,
    required List<String> materialIds,
    required List<String> materialNames,
    required List<_UploadedAiFile> contextImages,
    required int questionCount,
    required int totalMarks,
    required int? durationMinutes,
    required DateTime? deadline,
    required bool allowRetakes,
    required bool showCorrectAnswers,
    required bool showQuestionMarks,
  }) {
    _throwIfStructuredFailure(json);
    final rawQuestions = json['questions'] as List<dynamic>? ?? const [];
    final usedImageNames = <String>{};
    final questions = rawQuestions
        .whereType<Map>()
        .take(questionCount)
        .map(
          (item) => _validateQuestion(
            Map<String, dynamic>.from(item),
            context: context,
            contextImages: contextImages,
            requireContextImage: false,
            usedContextImageNames: usedImageNames,
            fallbackType: 'MCQ',
            fallbackMarks: totalMarks / questionCount,
          ).toJson(),
        )
        .toList();
    if (questions.isEmpty) {
      throw const GeminiAiException(_unsupportedGenerationError);
    }
    if (questions.length < questionCount) {
      throw const GeminiAiException(_unsupportedGenerationError);
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
      materialIds: materialIds,
      materialNames: materialNames,
    );
  }

  AiAssignmentDraft _validateAssignmentDraft(
    Map<String, dynamic> json, {
    required _GroundedContext context,
    required int taskCount,
    required int totalMarks,
    required DateTime? deadline,
    required bool includeRubric,
    required List<Map<String, dynamic>> attachments,
  }) {
    _throwIfStructuredFailure(json);
    final tasks = (json['tasks'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .take(taskCount)
        .map<Map<String, dynamic>>((item) {
          final task = Map<String, dynamic>.from(item);
          final text = _cleanLong(task['task']?.toString() ?? '');
          final sourceRef = _validateSourceRef(task['source_ref'], context);
          if (text.isEmpty) {
            throw const GeminiAiException(_unsupportedGenerationError);
          }
          return {'task': text, 'source_ref': sourceRef};
        })
        .toList();
    if (tasks.length < taskCount) {
      throw const GeminiAiException(_unsupportedGenerationError);
    }
    final rubric = includeRubric
        ? (json['rubric'] as List<dynamic>? ?? const [])
              .whereType<Map>()
              .take(10)
              .map<Map<String, dynamic>>((item) {
                final row = Map<String, dynamic>.from(item);
                return {
                  'criterion': _cleanShort(row['criterion']?.toString() ?? ''),
                  'description': _cleanLong(
                    row['description']?.toString() ?? '',
                  ),
                  'marks': ((row['marks'] as num?)?.toInt() ?? 1)
                      .clamp(1, totalMarks)
                      .toInt(),
                  'source_ref': _validateSourceRef(row['source_ref'], context),
                };
              })
              .where((item) => (item['criterion'] as String).isNotEmpty)
              .toList()
        : <Map<String, dynamic>>[];
    if (includeRubric && rubric.isEmpty) {
      throw const GeminiAiException(_unsupportedGenerationError);
    }
    final taskLines = tasks
        .map((item) => item['task']?.toString() ?? '')
        .where((item) => item.isNotEmpty)
        .toList();
    final generatedInstructions = _cleanLong(
      json['instructions']?.toString() ?? '',
    );
    final visibleInstructions = taskLines.isEmpty
        ? generatedInstructions
        : [
            if (generatedInstructions.isNotEmpty) generatedInstructions,
            'Tasks:',
            ...taskLines.asMap().entries.map(
              (entry) => '${entry.key + 1}. ${entry.value}',
            ),
          ].join('\n');
    return AiAssignmentDraft(
      title: _cleanShort(
        json['title']?.toString() ?? '',
        fallback: 'AI Assignment',
      ),
      instructions: _cleanLong(visibleInstructions),
      attachmentRequirements: _cleanLong(
        json['attachment_requirements']?.toString() ?? '',
      ),
      dueAt: deadline,
      maxPoints: totalMarks,
      rubric: rubric,
      attachments: attachments,
      sourceGrounding: {'tasks': tasks},
    );
  }

  AiFlashcardDraft _validateFlashcardDraft(
    Map<String, dynamic> json, {
    required _GroundedContext context,
    required int cardCount,
    required List<String> materialIds,
  }) {
    _throwIfStructuredFailure(json);
    final cards = (json['cards'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .take(cardCount)
        .map<FlashcardItem>((item) {
          final card = Map<String, dynamic>.from(item);
          final front = _cleanQuestionText(
            card['front']?.toString() ?? '',
            contextImages: const [],
            context: context,
            max: 220,
          );
          final back = _cleanQuestionText(
            card['back']?.toString() ?? '',
            contextImages: const [],
            context: context,
            max: 500,
          );
          final sourceRef = _validateSourceRef(card['source_ref'], context);
          if (front.isEmpty || back.isEmpty) {
            throw const GeminiAiException(_unsupportedGenerationError);
          }
          return FlashcardItem(
            front: front,
            back: back,
            difficulty: _cleanShort(card['difficulty']?.toString() ?? ''),
            tag: _cleanShort(card['tag']?.toString() ?? '', max: 60),
            sourceReference: sourceRef,
          );
        })
        .toList();
    if (cards.length < cardCount) {
      throw const GeminiAiException(_unsupportedGenerationError);
    }
    return AiFlashcardDraft(
      title: _cleanShort(
        json['title']?.toString() ?? '',
        fallback: 'Study Flashcards',
      ),
      cards: cards,
      materialIds: materialIds,
    );
  }

  QuizQuestionModel _validateQuestion(
    Map<String, dynamic> json, {
    required _GroundedContext context,
    required List<_UploadedAiFile> contextImages,
    required bool requireContextImage,
    required Set<String> usedContextImageNames,
    required String fallbackType,
    required double fallbackMarks,
  }) {
    final type = _normalizeQuestionTypes([
      json['type']?.toString() ?? fallbackType,
    ]).first;
    final options = (json['options'] as List<dynamic>? ?? const [])
        .map(
          (item) => _cleanQuestionText(
            item.toString(),
            contextImages: contextImages,
            context: context,
            max: 140,
          ),
        )
        .where((item) => item.isNotEmpty)
        .take(4)
        .toList();
    final mapping = Map<String, String>.from(
      (json['correct_mapping'] as Map? ?? const {}).map(
        (key, value) => MapEntry(
          _cleanQuestionText(
            key.toString(),
            contextImages: contextImages,
            context: context,
            max: 120,
          ),
          _cleanQuestionText(
            value.toString(),
            contextImages: contextImages,
            context: context,
            max: 120,
          ),
        ),
      ),
    )..removeWhere((key, value) => key.isEmpty || value.isEmpty);
    final questionText = _cleanQuestionText(
      json['question_text']?.toString() ?? '',
      contextImages: contextImages,
      context: context,
      max: 1800,
    );
    if (questionText.isEmpty) {
      throw const GeminiAiException(_unsupportedGenerationError);
    }
    final contextImage = _resolveQuestionImage(
      json['context_image_name']?.toString() ?? '',
      questionText,
      contextImages,
      requireContextImage,
      usedContextImageNames,
    );
    if (contextImage != null && !_referencesVisual(questionText)) {
      throw const GeminiAiException(_unsupportedGenerationError);
    }
    final sourceRef = _validateSourceRef(json['source_ref'], context);
    return QuizQuestionModel(
      type: type,
      questionText: questionText,
      options: type == 'MCQ'
          ? List.generate(
              4,
              (index) => index < options.length
                  ? _cleanQuestionText(
                      options[index],
                      contextImages: contextImages,
                      context: context,
                      max: 140,
                    )
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
      explanation: _cleanQuestionText(
        json['explanation']?.toString() ?? '',
        contextImages: contextImages,
        context: context,
        max: 1800,
      ),
      sampleAnswer: _cleanQuestionText(
        json['sample_answer']?.toString() ?? '',
        contextImages: contextImages,
        context: context,
        max: 1800,
      ),
      imagePath: contextImage?.path ?? '',
      imageName: contextImage?.name ?? '',
      items: type == 'Matching' ? mapping.keys.toList() : const [],
      targets: type == 'Matching' ? mapping.values.toSet().toList() : const [],
      correctMapping: type == 'Matching' ? mapping : const {},
      sourceReference: sourceRef,
    );
  }

  void _throwIfStructuredFailure(Map<String, dynamic> json) {
    if ((json['failure']?.toString() ?? '').isNotEmpty) {
      throw const GeminiAiException(_unsupportedGenerationError);
    }
  }

  Map<String, dynamic> _validateSourceRef(
    Object? value,
    _GroundedContext context,
  ) {
    if (value is! Map) {
      throw const GeminiAiException(_unsupportedGenerationError);
    }
    final ref = Map<String, dynamic>.from(value);
    final materialId = ref['material_id']?.toString().trim() ?? '';
    final materialName = ref['material_name']?.toString().trim() ?? '';
    final excerpt = _cleanExcerpt(ref['excerpt']?.toString() ?? '', max: 260);
    final page = _cleanShort(ref['page']?.toString() ?? '', max: 40);
    if (materialId.isEmpty || materialName.isEmpty || excerpt.length < 12) {
      throw const GeminiAiException(_unsupportedGenerationError);
    }
    if (!context.supports(materialId: materialId, excerpt: excerpt)) {
      throw const GeminiAiException(_unsupportedGenerationError);
    }
    return {
      'material_id': materialId,
      'material_name': materialName,
      if (page.isNotEmpty) 'page': page,
      'excerpt': excerpt,
      'selected_material_ids': context.materialIds,
    };
  }

  String _cleanQuestionText(
    String value, {
    required List<_UploadedAiFile> contextImages,
    required _GroundedContext context,
    int max = 1800,
  }) {
    var clean = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.isEmpty) return '';

    for (final image in contextImages) {
      clean = clean.replaceAll(image.name, _visualReferenceFor(clean));
      clean = clean.replaceAll(
        RegExp(RegExp.escape(image.name), caseSensitive: false),
        _visualReferenceFor(clean),
      );
    }
    for (final source in context.sources) {
      clean = clean.replaceAll(source.fileName, '');
      clean = clean.replaceAll(source.materialName, '');
      clean = clean.replaceAll(
        RegExp(RegExp.escape(source.fileName), caseSensitive: false),
        '',
      );
      clean = clean.replaceAll(
        RegExp(RegExp.escape(source.materialName), caseSensitive: false),
        '',
      );
    }

    final replacements = <RegExp, String>{
      RegExp(
        r'\baccording to (the )?(provided |selected |uploaded )?(lecture )?material[:,]?\s*',
        caseSensitive: false,
      ): '',
      RegExp(
        r'\bbased on (the )?(provided |selected |uploaded )?(lecture |file|material)[:,]?\s*',
        caseSensitive: false,
      ): '',
      RegExp(
        r'\bfrom (the )?(provided |selected |uploaded )?(lecture |file|material)[:,]?\s*',
        caseSensitive: false,
      ): '',
      RegExp(r'\bin (the )?provided lecture[:,]?\s*', caseSensitive: false): '',
      RegExp(r'\bprovided image\s*[,:\-]?\s*', caseSensitive: false):
          _visualReferenceFor(clean),
      RegExp(r'\buploaded file\s*[,:\-]?\s*', caseSensitive: false): '',
    };
    for (final entry in replacements.entries) {
      clean = clean.replaceAll(entry.key, entry.value);
    }

    clean = clean
        .replaceAll(RegExp(r'\s+([,?.!;:])'), r'$1')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();
    if (clean.isEmpty) return '';
    clean = clean[0].toUpperCase() + clean.substring(1);
    if (clean.length <= max) return clean;
    return clean.substring(0, max).trim();
  }

  bool _referencesVisual(String text) {
    final lower = text.toLowerCase();
    return lower.contains('image below') ||
        lower.contains('diagram below') ||
        lower.contains('chart below') ||
        lower.contains('figure below') ||
        lower.contains('code snippet below') ||
        lower.contains('shown below') ||
        lower.contains('below,') ||
        lower.contains('below:');
  }

  String _visualReferenceFor(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('diagram')) return 'the diagram below';
    if (lower.contains('chart')) return 'the chart below';
    if (lower.contains('code')) return 'the code snippet below';
    if (lower.contains('figure')) return 'the figure below';
    return 'the image below';
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
        .replaceFirst('\uFEFF', '')
        .replaceFirst(RegExp(r'^\s*```json\s*', caseSensitive: false), '')
        .replaceFirst(RegExp(r'^\s*```\s*'), '')
        .replaceFirst(RegExp(r'\s*```$'), '')
        .trim();
  }

  Map<String, dynamic> _decodeJsonMap(String text) {
    final clean = _stripJsonFence(text);
    final direct = _tryDecodeJsonMap(clean);
    if (direct != null) return direct;

    for (final candidate in _jsonObjectCandidates(clean)) {
      final decoded = _tryDecodeJsonMap(candidate);
      if (decoded != null) return decoded;
      final repaired = _tryDecodeJsonMap(_repairJson(candidate));
      if (repaired != null) return repaired;
    }

    final repaired = _tryDecodeJsonMap(_repairJson(clean));
    if (repaired != null) return repaired;
    throw const FormatException('No JSON object found.');
  }

  Map<String, dynamic>? _tryDecodeJsonMap(String text) {
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      if (decoded is List) {
        final firstMap = decoded.whereType<Map>().firstOrNull;
        if (firstMap != null) return Map<String, dynamic>.from(firstMap);
      }
      if (decoded is String && decoded != text) {
        return _tryDecodeJsonMap(_stripJsonFence(decoded));
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  List<String> _jsonObjectCandidates(String text) {
    final candidates = <String>[];
    final clean = _stripJsonFence(text);

    for (var start = 0; start < clean.length; start++) {
      if (clean[start] != '{') continue;
      final end = _balancedObjectEnd(clean, start);
      if (end != null) candidates.add(clean.substring(start, end + 1));
    }
    return candidates;
  }

  int? _balancedObjectEnd(String text, int start) {
    var depth = 0;
    var inString = false;
    var escaped = false;
    for (var index = start; index < text.length; index++) {
      final char = text[index];
      if (escaped) {
        escaped = false;
        continue;
      }
      if (char == '\\') {
        escaped = true;
        continue;
      }
      if (char == '"') {
        inString = !inString;
        continue;
      }
      if (inString) continue;
      if (char == '{') depth++;
      if (char == '}') {
        depth--;
        if (depth == 0) {
          return index;
        }
      }
    }
    return null;
  }

  String _repairJson(String text) {
    return text
        .replaceAllMapped(RegExp(r',\s*([}\]])'), (match) => match.group(1)!)
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll('‘', "'")
        .replaceAll('’', "'");
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

  String _cleanExcerpt(String value, {int max = 260}) {
    final clean = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.length <= max) return clean;
    return clean.substring(0, max).trim();
  }

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
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'txt':
      case 'md':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }

  String _mimeForMaterial(MaterialModel material) {
    final extension = material.fileType.toLowerCase();
    if ({'txt', 'md', 'csv', 'json'}.contains(extension)) {
      return 'text/plain';
    }
    final mime = material.mimeType.trim();
    if (mime.isNotEmpty && mime != 'application/octet-stream') return mime;
    return _mimeForExtension(material.fileType);
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

  bool _isImageMime(String mime) {
    return {'image/png', 'image/jpeg', 'image/webp'}.contains(mime);
  }

  bool _isSupportedAssignmentAttachment(String extension) {
    return {
      'pdf',
      'png',
      'jpg',
      'jpeg',
      'webp',
      'txt',
      'md',
      'doc',
      'docx',
    }.contains(extension.toLowerCase());
  }
}

class _UploadedAiFile {
  const _UploadedAiFile({
    required this.name,
    required this.path,
    required this.size,
    required this.mimeType,
    required this.inlinePart,
    required this.attachmentKey,
  });

  final String name;
  final String path;
  final int size;
  final String mimeType;
  final Map<String, dynamic>? inlinePart;
  final String attachmentKey;

  Map<String, dynamic> toContextPart() {
    return {'name': name, 'part': inlinePart!};
  }

  Map<String, dynamic> get attachment {
    return {
      attachmentKey: path,
      'path': path,
      'name': name,
      'size': size,
      'mime_type': mimeType,
    };
  }
}

class _GroundedContext {
  const _GroundedContext({required this.sources, required this.contextParts});

  final List<_GroundedSource> sources;
  final List<Map<String, dynamic>> contextParts;

  bool get hasAnyUsableContent =>
      sources.any((source) => source.hasText || source.rawFileAttached);

  List<String> get materialIds => sources
      .map((source) => source.materialId)
      .where(
        (id) =>
            id.isNotEmpty &&
            id != 'user_prompt' &&
            id != 'question_image' &&
            id != 'existing_quiz_context',
      )
      .toSet()
      .toList();

  String get promptText {
    final budgetPerSource = (GeminiAiService._maxContextChars / sources.length)
        .floor()
        .clamp(1200, GeminiAiService._maxContextChars)
        .toInt();
    final parts = <String>[];
    for (final source in sources) {
      parts.add(source.toPromptText(budgetPerSource));
    }
    final joined = parts.join('\n---\n');
    if (joined.length <= GeminiAiService._maxContextChars) return joined;
    return joined.substring(0, GeminiAiService._maxContextChars);
  }

  String get fingerprint => base64Url.encode(utf8.encode(promptText));

  bool supports({required String materialId, required String excerpt}) {
    _GroundedSource? source;
    for (final item in sources) {
      if (item.materialId == materialId) {
        source = item;
        break;
      }
    }
    if (source == null) return false;
    final normalizedHaystack = _normalizeForMatch(source.searchText);
    final normalizedNeedle = _normalizeForMatch(excerpt);
    if (source.rawFileAttached && normalizedNeedle.length >= 12) return true;
    if (normalizedNeedle.length < 18) return false;
    if (normalizedHaystack.contains(normalizedNeedle)) return true;
    final words = normalizedNeedle
        .split(' ')
        .where((word) => word.length > 3)
        .toSet();
    if (words.length < 3) return false;
    final matched = words
        .where((word) => normalizedHaystack.contains(' $word '))
        .length;
    return matched / words.length >= 0.45;
  }

  static String _normalizeForMatch(String value) {
    return ' ${value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\u0600-\u06ff]+'), ' ').trim()} ';
  }
}

class _GroundedSource {
  const _GroundedSource({
    required this.materialId,
    required this.materialName,
    required this.fileName,
    required this.rawFileAttached,
    required this.headings,
    required this.keyBullets,
    required this.definitions,
    required this.examples,
    required this.chunks,
  });

  final String materialId;
  final String materialName;
  final String fileName;
  final bool rawFileAttached;
  final List<String> headings;
  final List<String> keyBullets;
  final List<String> definitions;
  final List<String> examples;
  final List<String> chunks;

  bool get hasText =>
      headings.isNotEmpty ||
      keyBullets.isNotEmpty ||
      definitions.isNotEmpty ||
      examples.isNotEmpty ||
      chunks.isNotEmpty;

  String get searchText => [
    ...headings,
    ...keyBullets,
    ...definitions,
    ...examples,
    ...chunks,
  ].join(' ');

  String toPromptText(int budget) {
    final buffer = StringBuffer()
      ..writeln('MATERIAL_ID: $materialId')
      ..writeln('MATERIAL_NAME: $materialName')
      ..writeln('FILE: $fileName');
    if (headings.isNotEmpty) {
      buffer.writeln('HEADINGS: ${headings.join(' | ')}');
    }
    if (keyBullets.isNotEmpty) {
      buffer.writeln('KEY_BULLETS: ${keyBullets.join(' | ')}');
    }
    if (definitions.isNotEmpty) {
      buffer.writeln('DEFINITIONS: ${definitions.join(' | ')}');
    }
    if (examples.isNotEmpty) {
      buffer.writeln('EXAMPLES: ${examples.join(' | ')}');
    }
    if (rawFileAttached) {
      buffer.writeln(
        'RAW_FILE_CONTEXT: The original material file is attached to this request. Use it as source content for this material only.',
      );
    }
    for (var index = 0; index < chunks.length; index++) {
      buffer.writeln('SOURCE_EXCERPT ${index + 1} page: unknown');
      buffer.writeln(chunks[index]);
      if (buffer.length >= budget) break;
    }
    final text = buffer.toString();
    if (text.length <= budget) return text;
    return text.substring(0, budget);
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
    this.materialIds = const [],
    this.materialNames = const [],
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
  final List<String> materialIds;
  final List<String> materialNames;

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
      materialIds: (json['material_ids'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .where((item) => item.isNotEmpty)
          .toList(),
      materialNames: (json['material_names'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .where((item) => item.isNotEmpty)
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
      if (materialIds.isNotEmpty) 'material_ids': materialIds,
      if (materialNames.isNotEmpty) 'material_names': materialNames,
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
    this.attachments = const [],
    this.sourceGrounding = const {},
  });

  final String title;
  final String instructions;
  final String attachmentRequirements;
  final DateTime? dueAt;
  final int maxPoints;
  final List<Map<String, dynamic>> rubric;
  final List<Map<String, dynamic>> attachments;
  final Map<String, dynamic> sourceGrounding;

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
      attachments: (json['attachments'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(),
      sourceGrounding: Map<String, dynamic>.from(
        json['source_grounding'] as Map? ?? const {},
      ),
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
      if (attachments.isNotEmpty) 'attachments': attachments,
      if (sourceGrounding.isNotEmpty) 'source_grounding': sourceGrounding,
    };
  }
}

class AiFlashcardDraft {
  const AiFlashcardDraft({
    required this.title,
    required this.cards,
    this.materialIds = const [],
  });

  final String title;
  final List<FlashcardItem> cards;
  final List<String> materialIds;

  factory AiFlashcardDraft.fromJson(Map<String, dynamic> json) {
    return AiFlashcardDraft(
      title: json['title'] as String? ?? 'Study Flashcards',
      cards: (json['cards'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => FlashcardItem.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      materialIds: (json['material_ids'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .where((item) => item.isNotEmpty)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'cards': cards.map((card) => card.toJson()).toList(),
      if (materialIds.isNotEmpty) 'material_ids': materialIds,
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
