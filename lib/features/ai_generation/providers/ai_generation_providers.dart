import 'package:flutter_riverpod/flutter_riverpod.dart';

class AiGenerationState<T> {
  const AiGenerationState({this.isLoading = false, this.result, this.error});

  final bool isLoading;
  final T? result;
  final Object? error;

  AiGenerationState<T> loading() => AiGenerationState<T>(isLoading: true);

  AiGenerationState<T> success(T value) => AiGenerationState(result: value);

  AiGenerationState<T> failure(Object error) => AiGenerationState(error: error);
}

class AiGenerationNotifier<T> extends Notifier<AiGenerationState<T>> {
  @override
  AiGenerationState<T> build() => AiGenerationState<T>();

  Future<T> run(Future<T> Function() task) async {
    if (state.isLoading) {
      throw StateError('A generation request is already running.');
    }
    state = state.loading();
    try {
      final result = await task();
      state = state.success(result);
      return result;
    } catch (error) {
      state = state.failure(error);
      rethrow;
    }
  }

  void clear() {
    state = AiGenerationState<T>();
  }
}

final quizGenerationStateProvider =
    NotifierProvider<AiGenerationNotifier<Object>, AiGenerationState<Object>>(
      AiGenerationNotifier<Object>.new,
    );

final assignmentGenerationStateProvider =
    NotifierProvider<AiGenerationNotifier<Object>, AiGenerationState<Object>>(
      AiGenerationNotifier<Object>.new,
    );

final flashcardGenerationStateProvider =
    NotifierProvider<AiGenerationNotifier<Object>, AiGenerationState<Object>>(
      AiGenerationNotifier<Object>.new,
    );

final studyNoteGenerationStateProvider =
    NotifierProvider<AiGenerationNotifier<Object>, AiGenerationState<Object>>(
      AiGenerationNotifier<Object>.new,
    );
