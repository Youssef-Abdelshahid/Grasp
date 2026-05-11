import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/assignment_model.dart';
import '../models/permissions_model.dart';
import '../models/quiz_model.dart';
import '../models/quiz_question_model.dart';
import '../models/submission_model.dart';
import 'permissions_service.dart';

class SubmissionService {
  SubmissionService._();

  static final instance = SubmissionService._();

  static const assignmentBucketName = 'assignment-submissions';

  SupabaseClient get _client => Supabase.instance.client;

  Future<List<SubmissionModel>> getQuizAttempts(String quizId) async {
    final response = await _client
        .from('submissions')
        .select()
        .eq('quiz_id', quizId)
        .order('submitted_at', ascending: false);

    return (response as List<dynamic>)
        .map(
          (item) =>
              SubmissionModel.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<List<SubmissionModel>> getAssignmentSubmissions(
    String assignmentId,
  ) async {
    final response = await _client
        .from('submissions')
        .select()
        .eq('assignment_id', assignmentId)
        .order('submitted_at', ascending: false);

    return (response as List<dynamic>)
        .map(
          (item) =>
              SubmissionModel.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<Map<String, SubmissionModel>> getLatestQuizAttemptsForCourse(
    String courseId,
  ) async {
    final quizzes = await _client
        .from('quizzes')
        .select('id')
        .eq('course_id', courseId);
    final quizIds = (quizzes as List<dynamic>)
        .map((item) => (item as Map)['id'] as String)
        .toList();
    if (quizIds.isEmpty) {
      return {};
    }

    final submissions = await _client
        .from('submissions')
        .select()
        .inFilter('quiz_id', quizIds)
        .order('submitted_at', ascending: false);

    final result = <String, SubmissionModel>{};
    for (final row in submissions as List<dynamic>) {
      final submission = SubmissionModel.fromJson(
        Map<String, dynamic>.from(row as Map),
      );
      final quizId = submission.quizId;
      if (quizId != null && !result.containsKey(quizId)) {
        result[quizId] = submission;
      }
    }
    return result;
  }

  Future<Map<String, SubmissionModel>> getLatestAssignmentSubmissionsForCourse(
    String courseId,
  ) async {
    final assignments = await _client
        .from('assignments')
        .select('id')
        .eq('course_id', courseId);
    final assignmentIds = (assignments as List<dynamic>)
        .map((item) => (item as Map)['id'] as String)
        .toList();
    if (assignmentIds.isEmpty) {
      return {};
    }

    final submissions = await _client
        .from('submissions')
        .select()
        .inFilter('assignment_id', assignmentIds)
        .order('submitted_at', ascending: false);

    final result = <String, SubmissionModel>{};
    for (final row in submissions as List<dynamic>) {
      final submission = SubmissionModel.fromJson(
        Map<String, dynamic>.from(row as Map),
      );
      final assignmentId = submission.assignmentId;
      if (assignmentId != null && !result.containsKey(assignmentId)) {
        result[assignmentId] = submission;
      }
    }
    return result;
  }

  Future<SubmissionModel> submitQuiz({
    required QuizModel quiz,
    required Map<int, dynamic> answers,
    required int elapsedSeconds,
  }) async {
    await PermissionsService.instance.requireStudentPermission(
      PermissionKeys.takeQuizzes,
    );
    if (!quiz.allowRetakes) {
      final existing = await _client
          .from('submissions')
          .select('id')
          .eq('quiz_id', quiz.id)
          .eq('student_id', _client.auth.currentUser!.id)
          .limit(1);
      if ((existing as List).isNotEmpty) {
        throw const SubmissionException(
          'You have already submitted this quiz.',
        );
      }
    }
    final userId = _client.auth.currentUser!.id;
    final attempts = await _client
        .from('submissions')
        .select('id')
        .eq('quiz_id', quiz.id);
    final attemptNumber = (attempts as List).length + 1;

    final questionModels = quiz.questionSchema
        .map(QuizQuestionModel.fromJson)
        .toList();
    final totalMarks = questionModels.fold<double>(
      0,
      (sum, item) => sum + item.marks,
    );

    var autoScore = 0.0;
    var hasManualReview = false;
    final answersPayload = <Map<String, dynamic>>[];

    for (var index = 0; index < questionModels.length; index++) {
      final question = questionModels[index];
      final answer = answers[index];
      bool? isCorrect = false;
      var awardedMarks = 0.0;
      var correctCount = 0;
      var totalCount = 0;

      final questionType = _normalizedType(question.type);
      if (_isWritten(questionType)) {
        hasManualReview = true;
        isCorrect = null;
      } else if (answer is int && answer == question.correctOption) {
        isCorrect = true;
        awardedMarks = question.marks;
        autoScore += awardedMarks;
      } else if (_isPartialType(questionType)) {
        final submitted = _stringMap(answer);
        final expected = question.correctMapping;
        totalCount = expected.length;
        correctCount = expected.entries
            .where((entry) => submitted[entry.key] == entry.value)
            .length;
        awardedMarks = totalCount == 0
            ? 0
            : (correctCount * (question.marks / totalCount));
        awardedMarks = awardedMarks.clamp(0, question.marks).toDouble();
        autoScore += awardedMarks;
        isCorrect = totalCount > 0 && correctCount == totalCount;
      }

      answersPayload.add({
        'question_index': index,
        'question_text': question.questionText,
        'type': questionType,
        'answer': answer,
        'correct_option': question.correctOption,
        'correct_mapping': question.correctMapping,
        'is_correct': isCorrect,
        'marks': question.marks,
        'auto_awarded_marks': awardedMarks,
        'correct_count': correctCount,
        'total_count': totalCount,
      });
    }

    final questionGrades = <Map<String, dynamic>>[];
    for (final answer in answersPayload) {
      final isCorrect = answer['is_correct'];
      final marks = (answer['marks'] as num?)?.toDouble() ?? 0;
      questionGrades.add({
        'question_index': answer['question_index'],
        'marks':
            (answer['auto_awarded_marks'] as num?)?.toDouble() ??
            (isCorrect == true ? marks : 0),
        'feedback': '',
      });
    }

    final response = await _client
        .from('submissions')
        .insert({
          'student_id': userId,
          'quiz_id': quiz.id,
          'attempt_number': attemptNumber,
          'score': autoScore,
          'status': hasManualReview ? 'submitted' : 'graded',
          'graded_at': hasManualReview
              ? null
              : DateTime.now().toUtc().toIso8601String(),
          'grading_details': {'question_grades': questionGrades},
          'content': {
            'answers': answersPayload,
            'elapsed_seconds': elapsedSeconds,
            'total_marks': totalMarks,
            'auto_scored_marks': autoScore,
            'quiz_title': quiz.title,
          },
        })
        .select()
        .single();

    return SubmissionModel.fromJson(Map<String, dynamic>.from(response));
  }

  Future<SubmissionModel> submitAssignment({
    required AssignmentModel assignment,
    String textAnswer = '',
    PlatformFile? file,
  }) async {
    await PermissionsService.instance.requireStudentPermission(
      PermissionKeys.submitAssignments,
    );
    final userId = _client.auth.currentUser!.id;
    final attempts = await _client
        .from('submissions')
        .select('id')
        .eq('assignment_id', assignment.id);
    final attemptNumber = (attempts as List).length + 1;

    String? storagePath;
    String? fileName;
    int? fileSizeBytes;

    if (file != null) {
      final bytes = await _readFileBytes(file);
      fileName = file.name;
      fileSizeBytes = file.size;
      storagePath =
          '$userId/${assignment.id}/${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.name)}';
      await _client.storage
          .from(assignmentBucketName)
          .uploadBinary(
            storagePath,
            bytes,
            fileOptions: FileOptions(
              contentType: _guessMime(file.extension ?? ''),
              upsert: false,
            ),
          );
    }

    final response = await _client
        .from('submissions')
        .insert({
          'student_id': userId,
          'assignment_id': assignment.id,
          'attempt_number': attemptNumber,
          'file_name': fileName,
          'file_size_bytes': fileSizeBytes,
          'storage_path': storagePath,
          'content': {
            'text_answer': textAnswer.trim(),
            'assignment_title': assignment.title,
          },
        })
        .select()
        .single();

    return SubmissionModel.fromJson(Map<String, dynamic>.from(response));
  }

  Future<String?> createSubmissionFileUrl(SubmissionModel submission) async {
    final path = submission.storagePath;
    if (path == null || path.isEmpty) {
      return null;
    }
    return _client.storage
        .from(assignmentBucketName)
        .createSignedUrl(path, 3600);
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
    throw const SubmissionException('Unable to read the selected file.');
  }

  String _guessMime(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'zip':
        return 'application/zip';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      default:
        return 'application/octet-stream';
    }
  }

  bool _isWritten(String type) => _normalizedType(type) == 'Short Answer';

  bool _isPartialType(String type) {
    final normalized = _normalizedType(type);
    return normalized == 'Matching';
  }

  String _normalizedType(String type) {
    final normalized = type.trim().toLowerCase();
    if (normalized == 'essay' || normalized == 'short answer') {
      return 'Short Answer';
    }
    if (normalized == 'matching' ||
        normalized == 'drag and drop' ||
        normalized == 'classification') {
      return 'Matching';
    }
    if (normalized == 'true / false' || normalized == 'true/false') {
      return 'True / False';
    }
    return normalized == 'mcq' ? 'MCQ' : type;
  }

  Map<String, String> _stringMap(dynamic value) {
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val.toString()));
    }
    return const {};
  }
}

class SubmissionException implements Exception {
  const SubmissionException(this.message);

  final String message;

  @override
  String toString() => message;
}
