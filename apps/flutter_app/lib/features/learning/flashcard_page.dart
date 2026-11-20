import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/state_panel.dart';
import '../auth/auth_session.dart';
import '../dictionary/dictionary_repository.dart';
import '../dictionary/saved_word_repository.dart';

class FlashcardPage extends ConsumerStatefulWidget {
  const FlashcardPage({super.key});

  @override
  ConsumerState<FlashcardPage> createState() => _FlashcardPageState();
}

class _FlashcardPageState extends ConsumerState<FlashcardPage> {
  List<DictionaryDetail>? _cards;
  final Map<String, bool> _sessionRatings = {};
  Object? _error;
  var _index = 0;
  var _showAnswer = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    setState(() {
      _cards = null;
      _error = null;
      _index = 0;
      _showAnswer = false;
      _sessionRatings.clear();
    });
    try {
      final uid = ref.read(authSessionProvider).identity!.uid;
      final saved = await ref.read(savedWordRepositoryProvider).list(uid);
      final cards = await Future.wait(
        saved.map(
          (word) => ref.read(dictionaryRepositoryProvider).detail(word.vocabId),
        ),
      );
      if (mounted) setState(() => _cards = cards);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  void _move(int offset) {
    final cards = _cards!;
    setState(() {
      _index = (_index + offset).clamp(0, cards.length - 1);
      _showAnswer = false;
    });
  }

  void _rate(bool known) {
    final cards = _cards!;
    setState(() {
      _sessionRatings[cards[_index].item.vocabId] = known;
      if (_index < cards.length - 1) {
        _index++;
        _showAnswer = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cards = _cards;
    return Scaffold(
      appBar: AppBar(title: const Text('Flashcard')),
      body: _error != null
          ? StatePanel(
              state: ViewState.error,
              title: 'Không thể tải Flashcard',
              message: 'Kiểm tra kết nối rồi thử lại.',
              onRetry: _load,
            )
          : cards == null
          ? const StatePanel(
              state: ViewState.loading,
              title: 'Đang chuẩn bị Flashcard',
              message: 'Đang tải các từ bạn đã lưu.',
            )
          : cards.isEmpty
          ? const StatePanel(
              state: ViewState.empty,
              title: 'Chưa có Flashcard',
              message: 'Hãy lưu ít nhất một từ trong Từ điển để bắt đầu học.',
            )
          : _buildSession(context, cards),
    );
  }

  Widget _buildSession(BuildContext context, List<DictionaryDetail> cards) {
    final detail = cards[_index];
    final completed = _sessionRatings.length == cards.length;
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Thẻ ${_index + 1}/${cards.length}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Text('Đã đánh giá ${_sessionRatings.length}/${cards.length}'),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: _sessionRatings.length / cards.length,
              ),
              const SizedBox(height: 20),
              Semantics(
                button: true,
                label: _showAnswer ? 'Ẩn đáp án' : 'Lật thẻ xem đáp án',
                child: InkWell(
                  key: const Key('flashcard-surface'),
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => setState(() => _showAnswer = !_showAnswer),
                  child: Card(
                    child: AnimatedSize(
                      duration: const Duration(milliseconds: 180),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 40,
                        ),
                        child: _showAnswer
                            ? _Answer(detail: detail)
                            : Column(
                                children: [
                                  Text(
                                    detail.item.hanzi,
                                    style: Theme.of(context)
                                        .textTheme
                                        .displayMedium,
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 20),
                                  const Text('Chạm vào thẻ để xem đáp án'),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _index == 0 ? null : () => _move(-1),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Trước'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () => setState(() => _showAnswer = !_showAnswer),
                    icon: const Icon(Icons.flip),
                    label: Text(_showAnswer ? 'Ẩn đáp án' : 'Lật thẻ'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _index == cards.length - 1
                        ? null
                        : () => _move(1),
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Sau'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rate(false),
                      icon: const Icon(Icons.replay),
                      label: const Text('Chưa biết'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _rate(true),
                      icon: const Icon(Icons.check),
                      label: const Text('Đã biết'),
                    ),
                  ),
                ],
              ),
              if (completed) ...[
                const SizedBox(height: 20),
                Card(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.celebration_outlined),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Đã đánh giá toàn bộ ${cards.length} thẻ trong lượt học này.',
                          ),
                        ),
                        TextButton(
                          onPressed: _load,
                          child: const Text('Học lại'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Answer extends StatelessWidget {
  const _Answer({required this.detail});

  final DictionaryDetail detail;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        detail.item.hanzi,
        style: Theme.of(context).textTheme.displaySmall,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 12),
      Text(
        detail.item.pinyin,
        style: Theme.of(context).textTheme.headlineSmall,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 8),
      Text(
        detail.meaningViSenses.join('; '),
        style: Theme.of(context).textTheme.titleLarge,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 20),
      Text('Ví dụ', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 6),
      if (detail.examples.isEmpty)
        const Text('Chưa có ví dụ đã được xác minh cho mục từ này.')
      else
        ...detail.examples.map(
          (example) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              [example['zh'], example['pinyin'], example['vi']]
                  .whereType<String>()
                  .where((value) => value.isNotEmpty)
                  .join('\n'),
            ),
          ),
        ),
    ],
  );
}
