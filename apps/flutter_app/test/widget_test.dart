import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/core/app.dart';
import 'package:flutter_app/features/auth/auth_session.dart';
import 'package:flutter_app/features/auth/user_profile_repository.dart';
import 'package:flutter_app/features/dictionary/dictionary_repository.dart';
import 'package:flutter_app/features/dictionary/saved_word_repository.dart';

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
  Future<String> getIdToken() async => 'test-token';

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
  Future<DictionaryDetail> detail(String vocabId) async =>
      const DictionaryDetail(
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

class FakeSavedWordRepository implements SavedWordRepository {
  final saved = <String>{};
  bool fail = false;

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

void main() {
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
    expect(find.text('Bạn chưa lưu từ nào.'), findsOneWidget);
    expect(savedWords.saved, isEmpty);
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
}
