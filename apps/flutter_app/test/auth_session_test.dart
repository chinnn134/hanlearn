import 'dart:async';

import 'package:flutter_app/features/auth/auth_session.dart';
import 'package:flutter_app/features/auth/user_profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class ControlledAuthRepository implements AuthRepository {
  final changes = StreamController<AuthIdentity?>.broadcast();

  @override
  Stream<AuthIdentity?> authStateChanges() => changes.stream;

  @override
  Future<String> getIdToken({bool forceRefresh = false}) async => 'token';

  @override
  Future<void> register({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signOut() async => changes.add(null);

  Future<void> dispose() => changes.close();
}

class ControlledProfileRepository implements UserProfileRepository {
  final pending = <String, Completer<UserProfile>>{};
  String? updatedUid;
  String? updatedName;

  @override
  Future<UserProfile> ensureCurrentUser(String expectedUid) =>
      pending.putIfAbsent(expectedUid, Completer<UserProfile>.new).future;

  @override
  Future<UserProfile> readCurrentUser(String expectedUid) =>
      ensureCurrentUser(expectedUid);

  @override
  Future<UserProfile> updateDisplayName(
    String expectedUid,
    String displayName,
  ) async {
    updatedUid = expectedUid;
    updatedName = displayName;
    return profile(expectedUid, displayName);
  }

  UserProfile profile(String uid, [String name = 'Người học']) => UserProfile(
    uid: uid,
    displayName: name,
    email: '$uid@example.com',
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );
}

Future<void> flushEvents() => Future<void>.delayed(Duration.zero);

void main() {
  test(
    'ignores a stale profile result after the signed-in UID changes',
    () async {
      final auth = ControlledAuthRepository();
      final profiles = ControlledProfileRepository();
      final session = AuthSessionController(auth, profiles);
      addTearDown(session.dispose);
      addTearDown(auth.dispose);

      auth.changes.add(const AuthIdentity(uid: 'user-a'));
      await flushEvents();
      expect(session.profileLoading, isTrue);

      auth.changes.add(null);
      await flushEvents();
      profiles.pending['user-a']!.complete(profiles.profile('user-a'));
      await flushEvents();

      expect(session.identity, isNull);
      expect(session.profile, isNull);
      expect(session.profileError, isNull);
      expect(session.profileLoading, isFalse);
    },
  );

  test('updates a display name only for the active UID', () async {
    final auth = ControlledAuthRepository();
    final profiles = ControlledProfileRepository();
    final session = AuthSessionController(auth, profiles);
    addTearDown(session.dispose);
    addTearDown(auth.dispose);

    expect(
      () => session.updateDisplayName('Không hợp lệ'),
      throwsA(isA<StateError>()),
    );
    auth.changes.add(const AuthIdentity(uid: 'user-b'));
    await flushEvents();
    profiles.pending['user-b']!.complete(profiles.profile('user-b'));
    await flushEvents();

    await session.updateDisplayName('Tên mới');

    expect(profiles.updatedUid, 'user-b');
    expect(profiles.updatedName, 'Tên mới');
    expect(session.profile?.displayName, 'Tên mới');
  });
}
