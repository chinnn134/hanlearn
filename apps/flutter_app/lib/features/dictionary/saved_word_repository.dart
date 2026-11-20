import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/firebase/firebase_bootstrap.dart';

class SavedWord {
  const SavedWord({
    required this.vocabId,
    required this.savedAt,
    required this.masteryLevel,
  });

  final String vocabId;
  final DateTime savedAt;
  final int masteryLevel;
}

abstract class SavedWordRepository {
  Future<List<SavedWord>> list(String expectedUid);
  Future<bool> isSaved(String expectedUid, String vocabId);
  Future<void> save(String expectedUid, String vocabId);
  Future<void> remove(String expectedUid, String vocabId);
}

class FirestoreSavedWordRepository implements SavedWordRepository {
  FirestoreSavedWordRepository(this._auth, this._firestore);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String expectedUid) {
    final user = _auth.currentUser;
    if (user == null || user.uid != expectedUid) {
      throw StateError('Phiên đăng nhập đã thay đổi.');
    }
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('saved_words');
  }

  @override
  Future<List<SavedWord>> list(String expectedUid) async {
    final snapshot = await _collection(expectedUid)
        .orderBy('savedAt', descending: true)
        .limit(100)
        .get();
    return snapshot.docs
        .map((document) {
          final data = document.data();
          return SavedWord(
            vocabId: data['vocabId'] as String,
            savedAt: (data['savedAt'] as Timestamp).toDate(),
            masteryLevel: data['masteryLevel'] as int,
          );
        })
        .toList(growable: false);
  }

  @override
  Future<bool> isSaved(String expectedUid, String vocabId) async =>
      (await _collection(expectedUid).doc(vocabId).get()).exists;

  @override
  Future<void> save(String expectedUid, String vocabId) async {
    if (vocabId.isEmpty || vocabId.length > 128) {
      throw ArgumentError('vocabId không hợp lệ.');
    }
    final document = _collection(expectedUid).doc(vocabId);
    await _firestore.runTransaction((transaction) async {
      if ((await transaction.get(document)).exists) return;
      transaction.set(document, {
        'vocabId': vocabId,
        'savedAt': FieldValue.serverTimestamp(),
        'masteryLevel': 0,
      });
    });
  }

  @override
  Future<void> remove(String expectedUid, String vocabId) =>
      _collection(expectedUid).doc(vocabId).delete();
}

final savedWordRepositoryProvider = Provider<SavedWordRepository>(
  (ref) => FirestoreSavedWordRepository(
    FirebaseBootstrap.auth,
    FirebaseBootstrap.firestore,
  ),
);
