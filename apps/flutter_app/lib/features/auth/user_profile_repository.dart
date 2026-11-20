import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/firebase/firebase_bootstrap.dart';

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.createdAt,
    required this.updatedAt,
  });

  final String uid;
  final String displayName;
  final String? email;
  final DateTime createdAt;
  final DateTime updatedAt;
}

abstract class UserProfileRepository {
  Future<UserProfile> ensureCurrentUser(String expectedUid);
  Future<UserProfile> readCurrentUser(String expectedUid);
  Future<UserProfile> updateDisplayName(String expectedUid, String displayName);
}

class FirestoreUserProfileRepository implements UserProfileRepository {
  FirestoreUserProfileRepository(this._auth, this._firestore);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _document(String expectedUid) {
    final user = _auth.currentUser;
    if (user == null || user.uid != expectedUid) {
      throw StateError('Phiên đăng nhập đã thay đổi.');
    }
    return _firestore.collection('users').doc(user.uid);
  }

  UserProfile _decode(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    if (data == null) throw StateError('Hồ sơ chưa tồn tại.');
    return UserProfile(
      uid: snapshot.id,
      displayName: data['displayName'] as String,
      email: data['email'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  @override
  Future<UserProfile> ensureCurrentUser(String expectedUid) async {
    final document = _document(expectedUid);
    final user = _auth.currentUser!;
    await _firestore.runTransaction((transaction) async {
      final existing = await transaction.get(document);
      if (existing.exists) return;
      final name = user.displayName?.trim();
      transaction.set(document, {
        'displayName': name == null || name.isEmpty ? 'Người học' : name,
        'email': user.email,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
    return _decode(await document.get(const GetOptions(source: Source.server)));
  }

  @override
  Future<UserProfile> readCurrentUser(String expectedUid) async => _decode(
    await _document(expectedUid).get(const GetOptions(source: Source.server)),
  );

  @override
  Future<UserProfile> updateDisplayName(
    String expectedUid,
    String displayName,
  ) async {
    final name = displayName.trim();
    if (name.isEmpty || name.length > 80) {
      throw ArgumentError('Tên hiển thị cần từ 1 đến 80 ký tự.');
    }
    final document = _document(expectedUid);
    await document.update({
      'displayName': name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return _decode(await document.get(const GetOptions(source: Source.server)));
  }
}

final userProfileRepositoryProvider = Provider<UserProfileRepository>(
  (ref) => FirestoreUserProfileRepository(
    FirebaseBootstrap.auth,
    FirebaseBootstrap.firestore,
  ),
);
