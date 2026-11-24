import 'dart:math';

import 'package:flutter/foundation.dart';

import '../dictionary/dictionary_repository.dart';

@immutable
class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.prompt,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
  });

  final String id;
  final String prompt;
  final List<String> options;
  final String correctAnswer;
  final String explanation;
}

@immutable
class QuizScore {
  const QuizScore({
    required this.correct,
    required this.total,
    required this.answered,
  });

  final int correct;
  final int total;
  final int answered;

  int get skipped => total - answered;
}

class QuizEngine {
  const QuizEngine({this.maximumOptions = 4});

  final int maximumOptions;

  List<QuizQuestion> createQuestions(
    List<DictionaryDetail> words, {
    int seed = 0,
  }) {
    if (maximumOptions < 2) {
      throw ArgumentError.value(maximumOptions, 'maximumOptions', 'must be 2+');
    }
    final candidates = <String, DictionaryDetail>{};
    for (final word in words) {
      candidates.putIfAbsent(word.item.vocabId, () => word);
    }
    final allAnswers = <String, String>{};
    for (final word in candidates.values) {
      final answer = word.item.meaningVi.trim();
      if (answer.isNotEmpty) allAnswers.putIfAbsent(_key(answer), () => answer);
    }
    if (allAnswers.length < 2) return const [];

    final random = Random(seed);
    final questions = <QuizQuestion>[];
    for (final word in candidates.values) {
      final correct = word.item.meaningVi.trim();
      if (correct.isEmpty) continue;
      final distractors =
          allAnswers.entries
              .where((entry) => entry.key != _key(correct))
              .map((entry) => entry.value)
              .toList()
            ..shuffle(random);
      final options = <String>[correct, ...distractors.take(maximumOptions - 1)]
        ..shuffle(random);
      if (options.map(_key).toSet().length != options.length) continue;
      questions.add(
        QuizQuestion(
          id: word.item.vocabId,
          prompt: word.item.hanzi,
          options: List.unmodifiable(options),
          correctAnswer: correct,
          explanation:
              '${word.item.hanzi} (${word.item.pinyin}): ${word.item.meaningVi}',
        ),
      );
    }
    return List.unmodifiable(questions);
  }

  QuizScore score(List<QuizQuestion> questions, Map<String, String> answers) {
    var correct = 0;
    var answered = 0;
    for (final question in questions) {
      final selected = answers[question.id];
      if (selected == null) continue;
      answered++;
      if (_key(selected) == _key(question.correctAnswer)) correct++;
    }
    return QuizScore(
      correct: correct,
      total: questions.length,
      answered: answered,
    );
  }

  static String _key(String value) => value.trim().toLowerCase();
}
