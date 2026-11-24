import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/core/app.dart';
import 'package:flutter_app/features/auth/auth_session.dart';

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

  Future<void> dispose() => _changes.close();
}

void main() {
  testWidgets('home navigates to a clearly marked unfinished feature', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = FakeAuthRepository(
      const AuthIdentity(uid: 'test-user', email: 'test@example.com'),
    );
    addTearDown(repository.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: const HanLearnApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chào mừng đến HanLearn AI'), findsOneWidget);
    await tester.tap(find.text('Tra từ').first);
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Chức năng sẽ được triển khai ở Phase 03.'),
      findsOneWidget,
    );
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
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: const HanLearnApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsOneWidget);
  });

  testWidgets('sign in and sign out update protected routes', (tester) async {
    final repository = FakeAuthRepository(null);
    addTearDown(repository.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
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
    await tester.tap(find.text('Đăng xuất'));
    await tester.pumpAndSettle();

    expect(find.text('Chưa có tài khoản? Tạo mới'), findsOneWidget);
    expect(find.text('Chào mừng đến HanLearn AI'), findsNothing);
  });
}
