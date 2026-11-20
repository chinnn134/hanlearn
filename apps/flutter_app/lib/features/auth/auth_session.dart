import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/firebase/firebase_bootstrap.dart';
import 'user_profile_repository.dart';

@immutable
class AuthIdentity {
  const AuthIdentity({required this.uid, this.email});

  final String uid;
  final String? email;
}

abstract class AuthRepository {
  Stream<AuthIdentity?> authStateChanges();
  Future<void> signIn({required String email, required String password});
  Future<void> register({required String email, required String password});
  Future<void> signOut();
  Future<String> getIdToken();
}

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth);

  final FirebaseAuth _auth;

  @override
  Stream<AuthIdentity?> authStateChanges() => _auth.authStateChanges().map(
    (user) =>
        user == null ? null : AuthIdentity(uid: user.uid, email: user.email),
  );

  @override
  Future<void> signIn({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  @override
  Future<void> register({
    required String email,
    required String password,
  }) async {
    await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<String> getIdToken() async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Chưa đăng nhập.');
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) {
      throw StateError('Không lấy được Firebase ID token.');
    }
    return token;
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => FirebaseAuthRepository(FirebaseBootstrap.auth),
);

class AuthSessionController extends ChangeNotifier {
  AuthSessionController(this._repository, this._profiles) {
    _subscribe();
  }

  final AuthRepository _repository;
  final UserProfileRepository _profiles;
  StreamSubscription<AuthIdentity?>? _subscription;
  int _generation = 0;
  bool ready = false;
  AuthIdentity? identity;
  Object? error;
  UserProfile? profile;
  Object? profileError;
  bool profileLoading = false;

  void _subscribe() {
    _subscription = _repository.authStateChanges().listen(
      (value) {
        final generation = ++_generation;
        identity = value;
        error = null;
        ready = true;
        profile = null;
        profileError = null;
        profileLoading = value != null;
        notifyListeners();
        if (value != null) {
          _ensureProfile(value.uid, generation);
        }
      },
      onError: (Object failure) {
        error = failure;
        ready = true;
        notifyListeners();
      },
    );
  }

  Future<void> _ensureProfile(String uid, int generation) async {
    try {
      final result = await _profiles.ensureCurrentUser(uid);
      if (generation != _generation) return;
      profile = result;
      profileError = null;
    } catch (failure) {
      if (generation != _generation) return;
      profileError = failure;
    } finally {
      if (generation == _generation) {
        profileLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> retryProfile() async {
    final uid = identity?.uid;
    if (uid == null) return;
    profileLoading = true;
    profileError = null;
    notifyListeners();
    await _ensureProfile(uid, _generation);
  }

  Future<void> updateDisplayName(String name) async {
    final uid = identity?.uid;
    if (uid == null) throw StateError('Chưa đăng nhập.');
    profile = await _profiles.updateDisplayName(uid, name);
    notifyListeners();
  }

  Future<void> retry() async {
    await _subscription?.cancel();
    ready = false;
    error = null;
    notifyListeners();
    _subscribe();
  }

  @override
  void dispose() {
    ++_generation;
    _subscription?.cancel();
    super.dispose();
  }
}

final authSessionProvider = Provider<AuthSessionController>((ref) {
  final session = AuthSessionController(
    ref.watch(authRepositoryProvider),
    ref.watch(userProfileRepositoryProvider),
  );
  ref.onDispose(session.dispose);
  return session;
});
