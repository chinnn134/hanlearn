import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/core/app.dart';
import 'package:flutter_app/core/data/sync_snapshot.dart';
import 'package:flutter_app/features/auth/auth_session.dart';
import 'package:flutter_app/features/auth/user_profile_repository.dart';
import 'package:flutter_app/features/dictionary/dictionary_repository.dart';
import 'package:flutter_app/features/dictionary/saved_word_repository.dart';
import 'package:flutter_app/features/learning/learning_repository.dart';
import 'package:flutter_app/features/learning/quiz_engine.dart';
import 'package:flutter_app/features/learning/review_scheduler.dart';
import 'package:flutter_app/features/scanner/image_selection_service.dart';

class FakeUserProfileRepository implements UserProfileRepository {
  UserProfile? profile;
  bool failNextEnsure = false;

  @override
  Future<UserProfile> ensureCurrentUser(String expectedUid) async {
    if (failNextEnsure) {
      failNextEnsure = false;
      throw StateError('Mất kết nối thử nghiệm');
    }
    return profile ??= UserProfile(
      uid: expectedUid,
      displayName: 'Người học',
      email: 'test@example.com',
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );
  }

  @override
  Future<UserProfile> readCurrentUser(String expectedUid) =>
      ensureCurrentUser(expectedUid);

  @override
  Future<UserProfile> updateDisplayName(
    String expectedUid,
    String displayName,
  ) async {
    final current = await ensureCurrentUser(expectedUid);
    return profile = UserProfile(
      uid: current.uid,
      displayName: displayName,
      email: current.email,
      createdAt: current.createdAt,
      updatedAt: DateTime.utc(2026),
    );
  }
}

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository(this.current);

  AuthIdentity? current;
  final _changes = StreamController<AuthIdentity?>.broadcast();

  @override
  Stream<AuthIdentity?> authStateChanges() async* {
    yield current;
    yield* _changes.stream;
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    current = AuthIdentity(uid: 'test-user', email: email);
    _changes.add(current);
  }

  @override
  Future<void> register({required String email, required String password}) =>
      signIn(email: email, password: password);

  @override
  Future<void> signOut() async {
    current = null;
    _changes.add(null);
  }

  @override
  Future<String> getIdToken({bool forceRefresh = false}) async => 'test-token';

  Future<void> dispose() => _changes.close();
}

class FakeDictionaryRepository implements DictionaryRepository {
  bool fail = false;

  @override
  Future<List<DictionaryItem>> search(String query) async {
    if (fail) throw const DictionaryApiException('Mất kết nối thử nghiệm');
    if (query == 'none') return [];
    return const [
      DictionaryItem(
        vocabId: 'ocd-test',
        hanzi: '学习',
        pinyin: 'xué xí',
        meaningVi: 'học tập',
        levels: {'hsk3': 1},
        sourceId: 'opencidian-17873f1',
      ),
    ];
  }

  @override
  Future<DictionaryDetail> detail(String vocabId) async {
    if (vocabId == 'friend-test') {
      return const DictionaryDetail(
        item: DictionaryItem(
          vocabId: 'friend-test',
          hanzi: '朋友',
          pinyin: 'péng you',
          meaningVi: 'bạn bè',
          levels: {'hsk3': 1},
          sourceId: 'opencidian-17873f1',
        ),
        traditional: '朋友',
        pinyinNumeric: 'peng2 you5',
        meaningViSenses: ['bạn bè'],
        examples: [],
        license: 'CC-BY-SA-4.0',
        attribution: 'OpenCidian by Perxel',
      );
    }
    return const DictionaryDetail(
      item: DictionaryItem(
        vocabId: 'ocd-test',
        hanzi: '学习',
        pinyin: 'xué xí',
        meaningVi: 'học tập',
        levels: {'hsk3': 1},
        sourceId: 'opencidian-17873f1',
      ),
      traditional: '學習',
      pinyinNumeric: 'xue2 xi2',
      meaningViSenses: ['học tập'],
      examples: [],
      license: 'CC-BY-SA-4.0',
      attribution: 'OpenCidian by Perxel',
    );
  }
}

class FakeSavedWordRepository implements SavedWordRepository {
  final saved = <String>{};
  bool fail = false;
  bool fromCache = false;

  @override
  Future<bool> isSaved(String expectedUid, String vocabId) async =>
      saved.contains(vocabId);

  @override
  Future<List<SavedWord>> list(String expectedUid) async {
    if (fail) throw StateError('Mất kết nối thử nghiệm');
    return saved
        .map(
          (id) => SavedWord(
            vocabId: id,
            savedAt: DateTime.utc(2026),
            masteryLevel: 0,
          ),
        )
        .toList();
  }

  @override
  Future<SyncSnapshot<SavedWord>> listSnapshot(String expectedUid) async =>
      SyncSnapshot(
        items: await list(expectedUid),
        isFromCache: fromCache,
        readLimit: 100,
      );

  @override
  Future<void> remove(String expectedUid, String vocabId) async {
    if (fail) throw StateError('Mất kết nối thử nghiệm');
    saved.remove(vocabId);
  }

  @override
  Future<void> save(String expectedUid, String vocabId) async {
    if (fail) throw StateError('Mất kết nối thử nghiệm');
    saved.add(vocabId);
  }
}

class FakeLearningRepository implements LearningRepository {
  final schedules = <String, ReviewSchedule>{};
  final results = <QuizResult>[];
  bool fail = false;
  bool fromCache = false;

  @override
  Future<List<ReviewSchedule>> listSchedules(String expectedUid) async =>
      schedules.values.toList();

  @override
  Future<SyncSnapshot<ReviewSchedule>> listSchedulesSnapshot(
    String expectedUid,
  ) async => SyncSnapshot(
    items: await listSchedules(expectedUid),
    isFromCache: fromCache,
    readLimit: 100,
  );

  @override
  Future<List<QuizResult>> listQuizResults(
    String expectedUid, {
    int limit = 20,
  }) async => results.take(limit).toList();

  @override
  Future<SyncSnapshot<QuizResult>> listQuizResultsSnapshot(
    String expectedUid, {
    int limit = 20,
  }) async => SyncSnapshot(
    items: await listQuizResults(expectedUid, limit: limit),
    isFromCache: fromCache,
    readLimit: limit,
  );

  @override
  Future<ReviewSchedule> recordFlashcardReview(
    String expectedUid,
    String vocabId,
    ReviewRating rating,
    DateTime reviewedAt,
  ) async {
    if (fail) throw StateError('Mất kết nối thử nghiệm');
    final current =
        schedules[vocabId] ?? ReviewSchedule.initial(vocabId, reviewedAt);
    return schedules[vocabId] = const ReviewScheduler().apply(
      current,
      rating,
      reviewedAt,
    );
  }

  @override
  Future<QuizResult> recordQuizResult(
    String expectedUid,
    List<QuizQuestion> questions,
    Map<String, String> answers,
    DateTime completedAt,
  ) async {
    if (fail) throw StateError('Mất kết nối thử nghiệm');
    const engine = QuizEngine();
    const scheduler = ReviewScheduler();
    final score = engine.score(questions, answers);
    for (final question in questions) {
      final current =
          schedules[question.id] ??
          ReviewSchedule.initial(question.id, completedAt);
      schedules[question.id] = scheduler.apply(
        current,
        answers[question.id] == question.correctAnswer
            ? ReviewRating.good
            : ReviewRating.again,
        completedAt,
      );
    }
    final result = QuizResult(
      id: 'result-${results.length + 1}',
      score: score.correct,
      totalQuestions: score.total,
      answeredQuestions: score.answered,
      skippedQuestions: score.skipped,
      createdAt: completedAt.toUtc(),
      wordIds: questions.map((question) => question.id).toList(),
    );
    results.add(result);
    return result;
  }
}

class FakeImageSelectionService implements ImageSelectionService {
  bool fail = false;
  ImageSelectionSource? lastSource;

  @override
  Future<SelectedImage?> pick(ImageSelectionSource source) async {
    lastSource = source;
    if (fail) {
      throw const ImageSelectionException('Ảnh vượt quá giới hạn 8 MiB.');
    }
    return SelectedImage(
      bytes: base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      ),
      fileName: 'hanzi.png',
      mimeType: 'image/png',
      width: 1,
      height: 1,
    );
  }
}

void main() {
  testWidgets('scanner previews a local image without claiming OCR', (
    tester,
  ) async {
    final auth = FakeAuthRepository(
      const AuthIdentity(uid: 'test-user', email: 'test@example.com'),
    );
    addTearDown(auth.dispose);
    final images = FakeImageSelectionService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          userProfileRepositoryProvider.overrideWithValue(
            FakeUserProfileRepository(),
          ),
          savedWordRepositoryProvider.overrideWithValue(
            FakeSavedWordRepository(),
          ),
          learningRepositoryProvider.overrideWithValue(
            FakeLearningRepository(),
          ),
          imageSelectionServiceProvider.overrideWithValue(images),
        ],
        child: const HanLearnApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Scanner'));
    await tester.pumpAndSettle();
    expect(find.textContaining('OCR chưa được cấu hình'), findsOneWidget);
    await tester.tap(find.text('Chọn từ thư viện'));
    await tester.pumpAndSettle();

    expect(find.textContaining('hanzi.png · 1×1'), findsOneWidget);
    final recognize = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Nhận dạng — OCR chưa được cấu hình'),
    );
    expect(recognize.onPressed, isNull);
    expect(find.textContaining('kết quả OCR'), findsNothing);
    await tester.tap(find.text('Chụp bằng camera'));
    await tester.pumpAndSettle();
    expect(images.lastSource, ImageSelectionSource.camera);
  });

  testWidgets('dashboard summarizes saved, learned, due and recent quiz data', (
    tester,
  ) async {
    final auth = FakeAuthRepository(
      const AuthIdentity(uid: 'test-user', email: 'test@example.com'),
    );
    final savedWords = FakeSavedWordRepository()
      ..saved.addAll(['ocd-test', 'friend-test']);
    final learning = FakeLearningRepository();
    final now = DateTime.now();
    learning.schedules['ocd-test'] = const ReviewScheduler().apply(
      ReviewSchedule.initial('ocd-test', now),
      ReviewRating.again,
      now,
    );
    learning.results.add(
      QuizResult(
        id: 'recent',
        score: 1,
        totalQuestions: 2,
        answeredQuestions: 1,
        skippedQuestions: 1,
        createdAt: now,
        wordIds: const ['ocd-test', 'friend-test'],
      ),
    );
    addTearDown(auth.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          userProfileRepositoryProvider.overrideWithValue(
            FakeUserProfileRepository(),
          ),
          savedWordRepositoryProvider.overrideWithValue(savedWords),
          learningRepositoryProvider.overrideWithValue(learning),
        ],
        child: const HanLearnApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Quiz gần đây'),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Từ đã lưu'), findsWidgets);
    expect(find.text('Từ đã học'), findsOneWidget);
    expect(find.text('Đến hạn hôm nay'), findsOneWidget);
    expect(find.text('2'), findsWidgets);
    expect(find.text('1/2 câu đúng'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Lịch sử học'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Lịch sử học'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Lịch sử quét sẽ xuất hiện sau khi OCR thật được tích hợp.'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.text('Lịch sử quét sẽ xuất hiện sau khi OCR thật được tích hợp.'),
      findsOneWidget,
    );
  });

  testWidgets('dashboard labels cached data instead of claiming sync', (
    tester,
  ) async {
    final auth = FakeAuthRepository(
      const AuthIdentity(uid: 'test-user', email: 'test@example.com'),
    );
    final savedWords = FakeSavedWordRepository()..fromCache = true;
    final learning = FakeLearningRepository()..fromCache = true;
    addTearDown(auth.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          userProfileRepositoryProvider.overrideWithValue(
            FakeUserProfileRepository(),
          ),
          savedWordRepositoryProvider.overrideWithValue(savedWords),
          learningRepositoryProvider.overrideWithValue(learning),
        ],
        child: const HanLearnApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Dữ liệu lưu cục bộ'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Dữ liệu lưu cục bộ'), findsOneWidget);
    expect(find.text('Đã đồng bộ từ máy chủ'), findsNothing);
  });

  testWidgets('dictionary searches and opens source-aware detail', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = FakeAuthRepository(
      const AuthIdentity(uid: 'test-user', email: 'test@example.com'),
    );
    final savedWords = FakeSavedWordRepository();
    addTearDown(repository.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          userProfileRepositoryProvider.overrideWithValue(
            FakeUserProfileRepository(),
          ),
          dictionaryRepositoryProvider.overrideWithValue(
            FakeDictionaryRepository(),
          ),
          savedWordRepositoryProvider.overrideWithValue(savedWords),
        ],
        child: const HanLearnApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chào mừng đến HanLearn AI'), findsOneWidget);
    await tester.tap(find.text('Tra từ').first);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '学习');
    await tester.tap(
      find.descendant(
        of: find.byType(TextField),
        matching: find.byType(IconButton),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('学习  xué xí'), findsOneWidget);
    await tester.tap(find.textContaining('学习  xué xí'));
    await tester.pumpAndSettle();
    expect(find.text('Phồn thể: 學習'), findsOneWidget);
    expect(find.textContaining('OpenCidian'), findsWidgets);
    await tester.tap(find.text('Lưu từ'));
    await tester.pumpAndSettle();
    expect(savedWords.saved, contains('ocd-test'));
    expect(find.text('Bỏ lưu'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('wide layout uses a navigation rail', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = FakeAuthRepository(
      const AuthIdentity(uid: 'test-user', email: 'test@example.com'),
    );
    addTearDown(repository.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          userProfileRepositoryProvider.overrideWithValue(
            FakeUserProfileRepository(),
          ),
        ],
        child: const HanLearnApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsOneWidget);
  });

  testWidgets('dictionary shows empty and retryable error states', (
    tester,
  ) async {
    final auth = FakeAuthRepository(
      const AuthIdentity(uid: 'test-user', email: 'test@example.com'),
    );
    final dictionary = FakeDictionaryRepository();
    addTearDown(auth.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          userProfileRepositoryProvider.overrideWithValue(
            FakeUserProfileRepository(),
          ),
          dictionaryRepositoryProvider.overrideWithValue(dictionary),
          savedWordRepositoryProvider.overrideWithValue(
            FakeSavedWordRepository(),
          ),
        ],
        child: const HanLearnApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tra từ').first);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'none');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.textContaining('Không tìm thấy mục từ'), findsOneWidget);

    dictionary.fail = true;
    await tester.enterText(find.byType(TextField), '学习');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.textContaining('Không thể tra từ'), findsOneWidget);
    dictionary.fail = false;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.textContaining('学习  xué xí'), findsOneWidget);
  });

  testWidgets('saved words lists and removes an idempotent reference', (
    tester,
  ) async {
    final auth = FakeAuthRepository(
      const AuthIdentity(uid: 'test-user', email: 'test@example.com'),
    );
    final savedWords = FakeSavedWordRepository()..saved.add('ocd-test');
    addTearDown(auth.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          userProfileRepositoryProvider.overrideWithValue(
            FakeUserProfileRepository(),
          ),
          dictionaryRepositoryProvider.overrideWithValue(
            FakeDictionaryRepository(),
          ),
          savedWordRepositoryProvider.overrideWithValue(savedWords),
        ],
        child: const HanLearnApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Từ đã lưu').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('学习  xué xí'), findsOneWidget);
    await tester.tap(find.byTooltip('Bỏ lưu 学习'));
    await tester.pumpAndSettle();
    expect(find.text('Bỏ lưu 学习?'), findsOneWidget);
    expect(savedWords.saved, contains('ocd-test'));
    await tester.tap(find.widgetWithText(FilledButton, 'Bỏ lưu'));
    await tester.pumpAndSettle();
    expect(find.text('Bạn chưa lưu từ nào.'), findsOneWidget);
    expect(savedWords.saved, isEmpty);
  });

  testWidgets('core navigation stays usable on a narrow large-text display', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final auth = FakeAuthRepository(
      const AuthIdentity(uid: 'test-user', email: 'test@example.com'),
    );
    addTearDown(auth.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          userProfileRepositoryProvider.overrideWithValue(
            FakeUserProfileRepository(),
          ),
          savedWordRepositoryProvider.overrideWithValue(
            FakeSavedWordRepository(),
          ),
          learningRepositoryProvider.overrideWithValue(
            FakeLearningRepository(),
          ),
        ],
        child: const HanLearnApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Hồ sơ'));
    await tester.pumpAndSettle();
    expect(find.text('Tài khoản'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('flashcards load saved words, flip and record a rating', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final auth = FakeAuthRepository(
      const AuthIdentity(uid: 'test-user', email: 'test@example.com'),
    );
    final savedWords = FakeSavedWordRepository()..saved.add('ocd-test');
    final learning = FakeLearningRepository();
    addTearDown(auth.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          userProfileRepositoryProvider.overrideWithValue(
            FakeUserProfileRepository(),
          ),
          dictionaryRepositoryProvider.overrideWithValue(
            FakeDictionaryRepository(),
          ),
          savedWordRepositoryProvider.overrideWithValue(savedWords),
          learningRepositoryProvider.overrideWithValue(learning),
        ],
        child: const HanLearnApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ôn Flashcard'));
    await tester.pumpAndSettle();

    expect(find.text('Thẻ 1/1'), findsOneWidget);
    expect(find.text('学习'), findsOneWidget);
    expect(find.text('xué xí'), findsNothing);
    await tester.tap(find.byKey(const Key('flashcard-surface')));
    await tester.pumpAndSettle();
    expect(find.text('xué xí'), findsOneWidget);
    expect(find.text('học tập'), findsOneWidget);
    expect(
      find.text('Chưa có ví dụ đã được xác minh cho mục từ này.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Đã biết'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Đã đánh giá toàn bộ 1 thẻ'), findsOneWidget);
    expect(learning.schedules['ocd-test']?.reviewCount, 1);
  });

  testWidgets('flashcards explain the empty saved-word state', (tester) async {
    final auth = FakeAuthRepository(
      const AuthIdentity(uid: 'test-user', email: 'test@example.com'),
    );
    addTearDown(auth.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          userProfileRepositoryProvider.overrideWithValue(
            FakeUserProfileRepository(),
          ),
          dictionaryRepositoryProvider.overrideWithValue(
            FakeDictionaryRepository(),
          ),
          savedWordRepositoryProvider.overrideWithValue(
            FakeSavedWordRepository(),
          ),
        ],
        child: const HanLearnApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ôn Flashcard'));
    await tester.pumpAndSettle();
    expect(find.text('Chưa có Flashcard'), findsOneWidget);
  });

  testWidgets('quiz answers, explains, skips and reports an honest score', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final auth = FakeAuthRepository(
      const AuthIdentity(uid: 'test-user', email: 'test@example.com'),
    );
    final savedWords = FakeSavedWordRepository()
      ..saved.addAll(['ocd-test', 'friend-test']);
    final learning = FakeLearningRepository();
    addTearDown(auth.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          userProfileRepositoryProvider.overrideWithValue(
            FakeUserProfileRepository(),
          ),
          dictionaryRepositoryProvider.overrideWithValue(
            FakeDictionaryRepository(),
          ),
          savedWordRepositoryProvider.overrideWithValue(savedWords),
          learningRepositoryProvider.overrideWithValue(learning),
        ],
        child: const HanLearnApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Làm Quiz'));
    await tester.pumpAndSettle();

    expect(find.text('Câu 1/2'), findsOneWidget);
    await tester.tap(find.text('học tập'));
    await tester.pump();
    await tester.ensureVisible(find.text('Kiểm tra'));
    await tester.tap(find.text('Kiểm tra'));
    await tester.pumpAndSettle();
    expect(find.text('Chính xác!'), findsOneWidget);
    expect(find.textContaining('Giải thích:'), findsOneWidget);
    await tester.ensureVisible(find.text('Câu tiếp theo'));
    await tester.tap(find.text('Câu tiếp theo'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Bỏ qua'));
    await tester.tap(find.text('Bỏ qua'));
    await tester.pumpAndSettle();
    expect(find.text('Bạn đã bỏ qua câu này.'), findsOneWidget);
    await tester.ensureVisible(find.text('Xem kết quả'));
    await tester.tap(find.text('Xem kết quả'));
    await tester.pumpAndSettle();
    expect(find.text('Hoàn thành Quiz'), findsOneWidget);
    expect(find.text('Đúng 1/2 · Đã trả lời 1 · Bỏ qua 1'), findsOneWidget);
    expect(learning.results.single.score, 1);
    expect(learning.schedules, hasLength(2));
  });

  testWidgets('quiz explains when saved words are insufficient', (
    tester,
  ) async {
    final auth = FakeAuthRepository(
      const AuthIdentity(uid: 'test-user', email: 'test@example.com'),
    );
    final savedWords = FakeSavedWordRepository()..saved.add('ocd-test');
    addTearDown(auth.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          userProfileRepositoryProvider.overrideWithValue(
            FakeUserProfileRepository(),
          ),
          dictionaryRepositoryProvider.overrideWithValue(
            FakeDictionaryRepository(),
          ),
          savedWordRepositoryProvider.overrideWithValue(savedWords),
        ],
        child: const HanLearnApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Làm Quiz'));
    await tester.pumpAndSettle();
    expect(find.text('Chưa đủ từ để tạo Quiz'), findsOneWidget);
  });

  testWidgets('today review counts unscheduled words and completes due cards', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final auth = FakeAuthRepository(
      const AuthIdentity(uid: 'test-user', email: 'test@example.com'),
    );
    final savedWords = FakeSavedWordRepository()
      ..saved.addAll(['ocd-test', 'friend-test']);
    final learning = FakeLearningRepository();
    final now = DateTime.now();
    learning.schedules['friend-test'] = const ReviewScheduler().apply(
      ReviewSchedule.initial('friend-test', now),
      ReviewRating.good,
      now,
    );
    addTearDown(auth.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          userProfileRepositoryProvider.overrideWithValue(
            FakeUserProfileRepository(),
          ),
          dictionaryRepositoryProvider.overrideWithValue(
            FakeDictionaryRepository(),
          ),
          savedWordRepositoryProvider.overrideWithValue(savedWords),
          learningRepositoryProvider.overrideWithValue(learning),
        ],
        child: const HanLearnApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ôn tập'));
    await tester.pumpAndSettle();

    expect(find.text('1 từ đến hạn'), findsOneWidget);
    expect(find.textContaining('学习  xué xí'), findsOneWidget);
    expect(find.textContaining('朋友  péng you'), findsNothing);
    await tester.tap(find.text('Ôn từ đến hạn'));
    await tester.pumpAndSettle();
    expect(find.text('Thẻ 1/1'), findsOneWidget);
    await tester.tap(find.text('Đã biết'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ôn tập'));
    await tester.pumpAndSettle();
    expect(find.text('Đã hoàn thành ôn hôm nay'), findsOneWidget);
    expect(find.textContaining('0 từ đến hạn'), findsOneWidget);
  });

  testWidgets('today review explains the no-saved-words state', (tester) async {
    final auth = FakeAuthRepository(
      const AuthIdentity(uid: 'test-user', email: 'test@example.com'),
    );
    addTearDown(auth.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          userProfileRepositoryProvider.overrideWithValue(
            FakeUserProfileRepository(),
          ),
          savedWordRepositoryProvider.overrideWithValue(
            FakeSavedWordRepository(),
          ),
          learningRepositoryProvider.overrideWithValue(
            FakeLearningRepository(),
          ),
        ],
        child: const HanLearnApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ôn tập'));
    await tester.pumpAndSettle();
    expect(find.text('Chưa có lịch ôn'), findsOneWidget);
  });

  testWidgets('sign in and sign out update protected routes', (tester) async {
    final repository = FakeAuthRepository(null);
    final profiles = FakeUserProfileRepository();
    addTearDown(repository.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          userProfileRepositoryProvider.overrideWithValue(profiles),
        ],
        child: const HanLearnApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chào mừng đến HanLearn AI'), findsNothing);
    expect(find.text('Chưa có tài khoản? Tạo mới'), findsOneWidget);
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'test@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'secret123');
    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.pumpAndSettle();

    expect(find.text('Chào mừng đến HanLearn AI'), findsOneWidget);
    await tester.tap(find.byTooltip('Hồ sơ'));
    await tester.pumpAndSettle();
    expect(find.text('test@example.com'), findsOneWidget);
    expect(profiles.profile?.uid, 'test-user');
    await tester.tap(find.text('Sửa tên hiển thị'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).last, 'Tên mới');
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();
    expect(find.text('Tên hiển thị: Tên mới'), findsOneWidget);
    expect(profiles.profile?.displayName, 'Tên mới');
    await tester.tap(find.text('Đăng xuất'));
    await tester.pumpAndSettle();

    expect(find.text('Chưa có tài khoản? Tạo mới'), findsOneWidget);
    expect(find.text('Chào mừng đến HanLearn AI'), findsNothing);
  });

  testWidgets('profile load error can be retried after connection returns', (
    tester,
  ) async {
    final auth = FakeAuthRepository(
      const AuthIdentity(uid: 'test-user', email: 'test@example.com'),
    );
    final profiles = FakeUserProfileRepository()..failNextEnsure = true;
    addTearDown(auth.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          userProfileRepositoryProvider.overrideWithValue(profiles),
        ],
        child: const HanLearnApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Hồ sơ'));
    await tester.pumpAndSettle();
    expect(find.text('Không thể tải hồ sơ.'), findsOneWidget);
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('Tên hiển thị: Người học'), findsOneWidget);
  });

  testWidgets('profile opens UID-scoped core settings', (tester) async {
    final auth = FakeAuthRepository(
      const AuthIdentity(uid: 'test-user', email: 'test@example.com'),
    );
    addTearDown(auth.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          userProfileRepositoryProvider.overrideWithValue(
            FakeUserProfileRepository(),
          ),
          savedWordRepositoryProvider.overrideWithValue(
            FakeSavedWordRepository(),
          ),
          learningRepositoryProvider.overrideWithValue(
            FakeLearningRepository(),
          ),
        ],
        child: const HanLearnApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Hồ sơ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mở cài đặt'));
    await tester.pumpAndSettle();

    expect(find.text('UID dữ liệu'), findsOneWidget);
    expect(find.text('test-user'), findsOneWidget);
    expect(find.text('Backend từ điển'), findsOneWidget);
    expect(find.text('OCR'), findsOneWidget);
    expect(find.text('AI giải thích'), findsOneWidget);
  });
}
