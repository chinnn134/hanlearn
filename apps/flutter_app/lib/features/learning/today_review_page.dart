import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/state_panel.dart';
import '../auth/auth_session.dart';
import '../dictionary/dictionary_repository.dart';
import '../dictionary/saved_word_repository.dart';
import 'learning_repository.dart';
import 'review_scheduler.dart';

class TodayReviewPage extends ConsumerStatefulWidget {
  const TodayReviewPage({super.key});

  @override
  ConsumerState<TodayReviewPage> createState() => _TodayReviewPageState();
}

class _TodayReviewPageState extends ConsumerState<TodayReviewPage> {
  List<DictionaryDetail>? _dueWords;
  var _hasSavedWords = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    setState(() {
      _dueWords = null;
      _error = null;
    });
    try {
      final uid = ref.read(authSessionProvider).identity!.uid;
      final results = await Future.wait([
        ref.read(savedWordRepositoryProvider).list(uid),
        ref.read(learningRepositoryProvider).listSchedules(uid),
      ]);
      final saved = results[0] as List<SavedWord>;
      final schedules = results[1] as List<ReviewSchedule>;
      final scheduleById = {
        for (final schedule in schedules) schedule.vocabId: schedule,
      };
      const scheduler = ReviewScheduler();
      final now = DateTime.now();
      final dueIds = saved
          .where((word) {
            final schedule = scheduleById[word.vocabId];
            return schedule == null || scheduler.isDue(schedule, now);
          })
          .map((word) => word.vocabId);
      final details = await Future.wait(
        dueIds.map((id) => ref.read(dictionaryRepositoryProvider).detail(id)),
      );
      if (mounted) {
        setState(() {
          _hasSavedWords = saved.isNotEmpty;
          _dueWords = details;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dueWords = _dueWords;
    return Scaffold(
      appBar: AppBar(title: const Text('Ôn hôm nay')),
      body: _error != null
          ? StatePanel(
              state: ViewState.error,
              title: 'Không thể tải lịch ôn',
              message: 'Kiểm tra kết nối rồi thử lại.',
              onRetry: _load,
            )
          : dueWords == null
          ? const StatePanel(
              state: ViewState.loading,
              title: 'Đang kiểm tra lịch ôn',
              message: 'Đang tìm các từ đến hạn của bạn.',
            )
          : dueWords.isEmpty
          ? StatePanel(
              state: ViewState.empty,
              title: _hasSavedWords
                  ? 'Đã hoàn thành ôn hôm nay'
                  : 'Chưa có lịch ôn',
              message: _hasSavedWords
                  ? '0 từ đến hạn. Hãy quay lại khi lịch ôn tiếp theo đến.'
                  : 'Hãy lưu từ trong Từ điển rồi học Flashcard để bắt đầu.',
            )
          : _buildDueList(context, dueWords),
    );
  }

  Widget _buildDueList(BuildContext context, List<DictionaryDetail> dueWords) =>
      Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                '${dueWords.length} từ đến hạn',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text('Từ chưa từng ôn cũng được tính là đến hạn.'),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => context.go('/flashcards?due=1'),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Ôn từ đến hạn'),
              ),
              const SizedBox(height: 16),
              for (final detail in dueWords)
                Card(
                  child: ListTile(
                    title: Text('${detail.item.hanzi}  ${detail.item.pinyin}'),
                    subtitle: Text(detail.item.meaningVi),
                  ),
                ),
            ],
          ),
        ),
      );
}
