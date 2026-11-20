import 'package:flutter_app/features/dictionary/dictionary_repository.dart';
import 'package:flutter_app/features/learning/quiz_engine.dart';
import 'package:flutter_test/flutter_test.dart';

DictionaryDetail word(String id, String hanzi, String pinyin, String meaning) =>
    DictionaryDetail(
      item: DictionaryItem(
        vocabId: id,
        hanzi: hanzi,
        pinyin: pinyin,
        meaningVi: meaning,
        levels: const {},
        sourceId: 'test-source',
      ),
      traditional: hanzi,
      pinyinNumeric: '',
      meaningViSenses: [meaning],
      examples: const [],
      license: 'test-only',
      attribution: 'test-only',
    );

void main() {
  const engine = QuizEngine();

  test('creates deterministic questions with unique valid options', () {
    final questions = engine.createQuestions([
      word('1', '学习', 'xué xí', 'học tập'),
      word('2', '朋友', 'péng you', 'bạn bè'),
      word('3', '中国', 'Zhōng guó', 'Trung Quốc'),
      word('4', '学生', 'xué sheng', 'học sinh'),
      word('4', '学生', 'xué sheng', 'học sinh'),
    ], seed: 42);

    expect(questions, hasLength(4));
    expect(questions.map((question) => question.id).toSet(), hasLength(4));
    for (final question in questions) {
      expect(question.options, contains(question.correctAnswer));
      expect(
        question.options.map((item) => item.toLowerCase()).toSet(),
        hasLength(question.options.length),
      );
      expect(question.options.length, inInclusiveRange(2, 4));
      expect(question.explanation, contains(question.correctAnswer));
    }
    expect(
      engine
          .createQuestions([
            word('1', '学习', 'xué xí', 'học tập'),
            word('2', '朋友', 'péng you', 'bạn bè'),
          ], seed: 42)
          .first
          .options,
      engine
          .createQuestions([
            word('1', '学习', 'xué xí', 'học tập'),
            word('2', '朋友', 'péng you', 'bạn bè'),
          ], seed: 42)
          .first
          .options,
    );
  });

  test('returns no questions when distinct answers cannot form a quiz', () {
    expect(engine.createQuestions([]), isEmpty);
    expect(
      engine.createQuestions([word('1', '学习', 'xué xí', 'học tập')]),
      isEmpty,
    );
    expect(
      engine.createQuestions([
        word('1', '学习', 'xué xí', 'học tập'),
        word('2', '学习者', 'xué xí zhě', ' HỌC TẬP '),
      ]),
      isEmpty,
    );
  });

  test('scores only selected answers and never counts skipped as correct', () {
    final questions = engine.createQuestions([
      word('1', '学习', 'xué xí', 'học tập'),
      word('2', '朋友', 'péng you', 'bạn bè'),
      word('3', '中国', 'Zhōng guó', 'Trung Quốc'),
    ], seed: 9);
    final score = engine.score(questions, {
      questions[0].id: questions[0].correctAnswer,
      questions[1].id: questions[0].correctAnswer,
      'unknown-id': 'ignored',
    });

    expect(score.total, 3);
    expect(score.answered, 2);
    expect(score.correct, 1);
    expect(score.skipped, 1);
  });
}
