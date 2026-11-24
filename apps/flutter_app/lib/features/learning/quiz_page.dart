import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/state_panel.dart';
import '../auth/auth_session.dart';
import '../dictionary/dictionary_repository.dart';
import '../dictionary/saved_word_repository.dart';
import 'quiz_engine.dart';
import 'learning_repository.dart';

class QuizPage extends ConsumerStatefulWidget {
  const QuizPage({super.key});

  @override
  ConsumerState<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends ConsumerState<QuizPage> {
  static const _engine = QuizEngine();

  List<QuizQuestion>? _questions;
  final Map<String, String> _answers = {};
  Object? _error;
  String? _selected;
  var _index = 0;
  var _submitted = false;
  var _finished = false;
  var _saving = false;
  Object? _saveError;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    setState(() {
      _questions = null;
      _answers.clear();
      _error = null;
      _selected = null;
      _index = 0;
      _submitted = false;
      _finished = false;
      _saving = false;
      _saveError = null;
    });
    try {
      final uid = ref.read(authSessionProvider).identity!.uid;
      final saved = await ref.read(savedWordRepositoryProvider).list(uid);
      final details = await Future.wait(
        saved.map(
          (word) => ref.read(dictionaryRepositoryProvider).detail(word.vocabId),
        ),
      );
      if (mounted) {
        setState(() => _questions = _engine.createQuestions(details));
      }
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  void _submit({required bool skip}) {
    final question = _questions![_index];
    if (!skip && _selected == null) return;
    setState(() {
      if (!skip) _answers[question.id] = _selected!;
      _submitted = true;
    });
  }

  Future<void> _next() async {
    final questions = _questions!;
    if (_index < questions.length - 1) {
      setState(() {
        _index++;
        _selected = null;
        _submitted = false;
      });
      return;
    }
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      final uid = ref.read(authSessionProvider).identity!.uid;
      await ref
          .read(learningRepositoryProvider)
          .recordQuizResult(uid, questions, _answers, DateTime.now());
      if (mounted) setState(() => _finished = true);
    } catch (error) {
      if (mounted) setState(() => _saveError = error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final questions = _questions;
    return Scaffold(
      appBar: AppBar(title: const Text('Quiz')),
      body: _error != null
          ? StatePanel(
              state: ViewState.error,
              title: 'Không thể tải Quiz',
              message: 'Kiểm tra kết nối rồi thử lại.',
              onRetry: _load,
            )
          : questions == null
          ? const StatePanel(
              state: ViewState.loading,
              title: 'Đang chuẩn bị Quiz',
              message: 'Đang tạo câu hỏi từ các từ bạn đã lưu.',
            )
          : questions.isEmpty
          ? const StatePanel(
              state: ViewState.empty,
              title: 'Chưa đủ từ để tạo Quiz',
              message:
                  'Hãy lưu ít nhất hai từ có nghĩa khác nhau trong Từ điển.',
            )
          : _finished
          ? _buildResult(context, questions)
          : _buildQuestion(context, questions),
    );
  }

  Widget _buildQuestion(BuildContext context, List<QuizQuestion> questions) {
    final question = questions[_index];
    final selectedIsCorrect = _selected == question.correctAnswer;
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Câu ${_index + 1}/${questions.length}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: (_index + 1) / questions.length),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Text('Chọn nghĩa đúng của từ'),
                      const SizedBox(height: 12),
                      Text(
                        question.prompt,
                        style: Theme.of(context).textTheme.displayMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              RadioGroup<String>(
                groupValue: _selected,
                onChanged: _submitted
                    ? (_) {}
                    : (value) => setState(() => _selected = value),
                child: Column(
                  children: [
                    for (final option in question.options)
                      Card(
                        child: RadioListTile<String>(
                          value: option,
                          enabled: !_submitted,
                          title: Text(option),
                        ),
                      ),
                  ],
                ),
              ),
              if (_submitted) ...[
                const SizedBox(height: 12),
                Card(
                  color: _selected == null
                      ? Theme.of(context).colorScheme.surfaceContainerHighest
                      : selectedIsCorrect
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _selected == null
                              ? 'Bạn đã bỏ qua câu này.'
                              : selectedIsCorrect
                              ? 'Chính xác!'
                              : 'Chưa chính xác.',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text('Đáp án: ${question.correctAnswer}'),
                        Text('Giải thích: ${question.explanation}'),
                      ],
                    ),
                  ),
                ),
              ],
              if (_saveError != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Không thể lưu kết quả và lịch ôn. Vui lòng thử lại.',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 16),
              if (_submitted)
                FilledButton.icon(
                  onPressed: _saving ? null : _next,
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.arrow_forward),
                  label: Text(
                    _saving
                        ? 'Đang lưu'
                        : _index == questions.length - 1
                        ? 'Xem kết quả'
                        : 'Câu tiếp theo',
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _submit(skip: true),
                        child: const Text('Bỏ qua'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _selected == null
                            ? null
                            : () => _submit(skip: false),
                        child: const Text('Kiểm tra'),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResult(BuildContext context, List<QuizQuestion> questions) {
    final score = _engine.score(questions, _answers);
    return StatePanelWithAction(
      title: 'Hoàn thành Quiz',
      message:
          'Đúng ${score.correct}/${score.total} · Đã trả lời ${score.answered} · Bỏ qua ${score.skipped}',
      onPressed: _load,
      actionLabel: 'Làm lại',
    );
  }
}

class StatePanelWithAction extends StatelessWidget {
  const StatePanelWithAction({
    super.key,
    required this.title,
    required this.message,
    required this.onPressed,
    required this.actionLabel,
  });

  final String title;
  final String message;
  final VoidCallback onPressed;
  final String actionLabel;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.emoji_events_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: onPressed, child: Text(actionLabel)),
            ],
          ),
        ),
      ),
    ),
  );
}
