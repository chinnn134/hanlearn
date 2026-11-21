import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_session.dart';
import '../dictionary/saved_word_repository.dart';
import '../learning/learning_repository.dart';
import '../learning/review_scheduler.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  _DashboardData? _data;
  Object? _error;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    setState(() {
      _data = null;
      _error = null;
    });
    try {
      final uid = ref.read(authSessionProvider).identity!.uid;
      final savedFuture = ref
          .read(savedWordRepositoryProvider)
          .listSnapshot(uid);
      final schedulesFuture = ref
          .read(learningRepositoryProvider)
          .listSchedulesSnapshot(uid);
      final quizFuture = ref
          .read(learningRepositoryProvider)
          .listQuizResultsSnapshot(uid, limit: 5);
      final savedSnapshot = await savedFuture;
      final scheduleSnapshot = await schedulesFuture;
      final quizSnapshot = await quizFuture;
      final saved = savedSnapshot.items;
      final schedules = scheduleSnapshot.items;
      final quizzes = quizSnapshot.items;
      final savedIds = saved.map((word) => word.vocabId).toSet();
      final scheduleById = {
        for (final schedule in schedules) schedule.vocabId: schedule,
      };
      const scheduler = ReviewScheduler();
      final now = DateTime.now();
      final learned = savedIds.where((id) {
        final schedule = scheduleById[id];
        return schedule != null && schedule.reviewCount > 0;
      }).length;
      final due = savedIds.where((id) {
        final schedule = scheduleById[id];
        return schedule == null || scheduler.isDue(schedule, now);
      }).length;
      final recentReviews =
          schedules
              .where((schedule) => schedule.lastReviewedAt != null)
              .toList(growable: false)
            ..sort((a, b) => b.lastReviewedAt!.compareTo(a.lastReviewedAt!));
      if (mounted) {
        setState(() {
          _data = _DashboardData(
            savedCount: saved.length,
            learnedCount: learned,
            dueCount: due,
            quizzes: quizzes,
            recentReviews: recentReviews.take(5).toList(growable: false),
            isFromCache:
                savedSnapshot.isFromCache ||
                scheduleSnapshot.isFromCache ||
                quizSnapshot.isFromCache,
            mayBeCapped:
                savedSnapshot.mayHaveMore || scheduleSnapshot.mayHaveMore,
          );
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    return RefreshIndicator(
      onRefresh: _load,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 900
              ? 3
              : constraints.maxWidth >= 560
              ? 2
              : 1;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Chào mừng đến HanLearn AI',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              const Text('Theo dõi tiến độ và tiếp tục phiên học gần nhất.'),
              const SizedBox(height: 20),
              const Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _HomeAction(
                    label: 'Tra từ',
                    icon: Icons.search,
                    path: '/dictionary',
                  ),
                  _HomeAction(
                    label: 'Từ đã lưu',
                    icon: Icons.bookmark_outline,
                    path: '/saved-words',
                  ),
                  _HomeAction(
                    label: 'Ôn Flashcard',
                    icon: Icons.style_outlined,
                    path: '/flashcards',
                  ),
                  _HomeAction(
                    label: 'Làm Quiz',
                    icon: Icons.quiz_outlined,
                    path: '/quiz',
                  ),
                  _HomeAction(
                    label: 'Ôn hôm nay',
                    icon: Icons.today_outlined,
                    path: '/progress',
                  ),
                  _HomeAction(
                    label: 'Scanner',
                    icon: Icons.document_scanner_outlined,
                    path: '/scanner',
                  ),
                ],
              ),
              const SizedBox(height: 28),
              if (_error != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Không thể tải Dashboard',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        const Text('Kiểm tra kết nối rồi thử lại.'),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _load,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (data == null)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Row(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(width: 16),
                        Text('Đang tải Dashboard...'),
                      ],
                    ),
                  ),
                )
              else ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Chip(
                    avatar: Icon(
                      data.isFromCache
                          ? Icons.cloud_off_outlined
                          : Icons.cloud_done_outlined,
                      size: 18,
                    ),
                    label: Text(
                      data.isFromCache
                          ? 'Dữ liệu lưu cục bộ'
                          : 'Đã đồng bộ từ máy chủ',
                    ),
                  ),
                ),
                if (data.isFromCache)
                  const Text(
                    'Bạn đang xem dữ liệu cache. Kéo xuống để thử đồng bộ lại khi có mạng.',
                  ),
                if (data.mayBeCapped)
                  const Text(
                    'Dashboard đang hiển thị tối đa 100 từ/lịch ôn gần nhất.',
                  ),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: columns,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: columns == 1 ? 3.2 : 2.2,
                  children: [
                    _MetricCard(
                      label: 'Từ đã lưu',
                      value: data.savedCount,
                      icon: Icons.bookmark_outline,
                    ),
                    _MetricCard(
                      label: 'Từ đã học',
                      value: data.learnedCount,
                      icon: Icons.school_outlined,
                    ),
                    _MetricCard(
                      label: 'Đến hạn hôm nay',
                      value: data.dueCount,
                      icon: Icons.today_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                _SectionTitle(
                  title: 'Quiz gần đây',
                  empty: data.quizzes.isEmpty,
                  emptyMessage: 'Chưa có kết quả Quiz.',
                ),
                for (final result in data.quizzes)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.quiz_outlined),
                    title: Text(
                      '${result.score}/${result.totalQuestions} câu đúng',
                    ),
                    subtitle: Text(
                      '${result.answeredQuestions} đã trả lời · '
                      '${result.skippedQuestions} bỏ qua · ${_formatDate(result.createdAt)}',
                    ),
                  ),
                const SizedBox(height: 20),
                _SectionTitle(
                  title: 'Lịch sử học',
                  empty: data.recentReviews.isEmpty,
                  emptyMessage: 'Chưa có lượt ôn Flashcard hoặc Quiz.',
                ),
                for (final schedule in data.recentReviews)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.history),
                    title: Text('Đã ôn ${schedule.reviewCount} lượt'),
                    subtitle: Text(
                      'Mã từ ${schedule.vocabId} · ${_formatDate(schedule.lastReviewedAt!)}',
                    ),
                  ),
                const SizedBox(height: 16),
                const Text(
                  'Lịch sử quét sẽ xuất hiện sau khi OCR thật được tích hợp.',
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _DashboardData {
  const _DashboardData({
    required this.savedCount,
    required this.learnedCount,
    required this.dueCount,
    required this.quizzes,
    required this.recentReviews,
    required this.isFromCache,
    required this.mayBeCapped,
  });

  final int savedCount;
  final int learnedCount;
  final int dueCount;
  final List<QuizResult> quizzes;
  final List<ReviewSchedule> recentReviews;
  final bool isFromCache;
  final bool mayBeCapped;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 32),
          const SizedBox(width: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$value', style: Theme.of(context).textTheme.headlineMedium),
              Text(label),
            ],
          ),
        ],
      ),
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.empty,
    required this.emptyMessage,
  });

  final String title;
  final bool empty;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleLarge),
      if (empty) ...[const SizedBox(height: 8), Text(emptyMessage)],
    ],
  );
}

class _HomeAction extends StatelessWidget {
  const _HomeAction({
    required this.label,
    required this.icon,
    required this.path,
  });

  final String label;
  final IconData icon;
  final String path;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 180,
    height: 152,
    child: Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.go(path),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              Text(label, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ),
    ),
  );
}

String _formatDate(DateTime value) {
  final local = value.toLocal();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year} '
      '${two(local.hour)}:${two(local.minute)}';
}
