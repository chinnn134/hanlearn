import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/firebase/firebase_bootstrap.dart';

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
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => FirebaseAuthRepository(FirebaseBootstrap.auth),
);

class AuthSessionController extends ChangeNotifier {
  AuthSessionController(this._repository) {
    _subscribe();
  }

  final AuthRepository _repository;
  StreamSubscription<AuthIdentity?>? _subscription;
  bool ready = false;
  AuthIdentity? identity;
  Object? error;

  void _subscribe() {
    _subscription = _repository.authStateChanges().listen(
      (value) {
        identity = value;
        error = null;
        ready = true;
        notifyListeners();
      },
      onError: (Object failure) {
        error = failure;
        ready = true;
        notifyListeners();
      },
    );
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
    _subscription?.cancel();
    super.dispose();
  }
}

final authSessionProvider = Provider<AuthSessionController>((ref) {
  final session = AuthSessionController(ref.watch(authRepositoryProvider));
  ref.onDispose(session.dispose);
  return session;
});
