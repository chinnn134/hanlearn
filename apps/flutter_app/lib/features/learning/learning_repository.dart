import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/firebase/firebase_bootstrap.dart';
import 'quiz_engine.dart';
import 'review_scheduler.dart';

@immutable
class QuizResult {
  const QuizResult({
    required this.id,
    required this.score,
    required this.totalQuestions,
    required this.answeredQuestions,
    required this.skippedQuestions,
    required this.createdAt,
    required this.wordIds,
  });

  final String id;
  final int score;
  final int totalQuestions;
  final int answeredQuestions;
  final int skippedQuestions;
  final DateTime createdAt;
  final List<String> wordIds;
}

abstract class LearningRepository {
  Future<List<ReviewSchedule>> listSchedules(String expectedUid);

  Future<ReviewSchedule> recordFlashcardReview(
    String expectedUid,
    String vocabId,
    ReviewRating rating,
    DateTime reviewedAt,
  );

  Future<QuizResult> recordQuizResult(
    String expectedUid,
    List<QuizQuestion> questions,
    Map<String, String> answers,
    DateTime completedAt,
  );

  Future<List<QuizResult>> listQuizResults(
    String expectedUid, {
    int limit = 20,
  });
}

class FirestoreLearningRepository implements LearningRepository {
  FirestoreLearningRepository(
    this._auth,
    this._firestore, {
    this.scheduler = const ReviewScheduler(),
    this.quizEngine = const QuizEngine(),
  });

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final ReviewScheduler scheduler;
  final QuizEngine quizEngine;

  DocumentReference<Map<String, dynamic>> _user(String expectedUid) {
    final user = _auth.currentUser;
    if (user == null || user.uid != expectedUid) {
      throw StateError('Phiên đăng nhập đã thay đổi.');
    }
    return _firestore.collection('users').doc(user.uid);
  }

  CollectionReference<Map<String, dynamic>> _schedules(String uid) =>
      _user(uid).collection('review_schedule');

  CollectionReference<Map<String, dynamic>> _results(String uid) =>
      _user(uid).collection('quiz_results');

  ReviewSchedule _scheduleFrom(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data()!;
    return ReviewSchedule(
      vocabId: data['vocabId'] as String,
      dueAt: (data['dueAt'] as Timestamp).toDate().toUtc(),
      intervalDays: data['intervalDays'] as int,
      lastReviewedAt: (data['lastReviewedAt'] as Timestamp).toDate().toUtc(),
      reviewCount: data['reviewCount'] as int,
    );
  }

  Map<String, dynamic> _scheduleData(ReviewSchedule schedule) => {
    'vocabId': schedule.vocabId,
    'dueAt': Timestamp.fromDate(schedule.dueAt),
    'intervalDays': schedule.intervalDays,
    'lastReviewedAt': Timestamp.fromDate(schedule.lastReviewedAt!),
    'reviewCount': schedule.reviewCount,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  @override
  Future<List<ReviewSchedule>> listSchedules(String expectedUid) async {
    final snapshot = await _schedules(expectedUid)
        .orderBy('dueAt')
        .limit(100)
        .get();
    return snapshot.docs.map(_scheduleFrom).toList(growable: false);
  }

  @override
  Future<ReviewSchedule> recordFlashcardReview(
    String expectedUid,
    String vocabId,
    ReviewRating rating,
    DateTime reviewedAt,
  ) async {
    if (vocabId.isEmpty || vocabId.length > 128) {
      throw ArgumentError('vocabId không hợp lệ.');
    }
    final reference = _schedules(expectedUid).doc(vocabId);
    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      final current = snapshot.exists
          ? _scheduleFrom(snapshot)
          : ReviewSchedule.initial(vocabId, reviewedAt);
      final next = scheduler.apply(current, rating, reviewedAt);
      transaction.set(reference, _scheduleData(next));
      return next;
    });
  }

  @override
  Future<QuizResult> recordQuizResult(
    String expectedUid,
    List<QuizQuestion> questions,
    Map<String, String> answers,
    DateTime completedAt,
  ) async {
    if (questions.isEmpty || questions.length > 100) {
      throw ArgumentError('Số câu hỏi phải từ 1 đến 100.');
    }
    final ids = questions
        .map((question) => question.id)
        .toList(growable: false);
    if (ids.toSet().length != ids.length || ids.any((id) => id.isEmpty)) {
      throw ArgumentError('Mã câu hỏi không hợp lệ hoặc bị trùng.');
    }
    _user(expectedUid);
    final resultReference = _results(expectedUid).doc();
    final scheduleReferences = [
      for (final id in ids) _schedules(expectedUid).doc(id),
    ];
    final score = quizEngine.score(questions, answers);
    final completedAtUtc = completedAt.toUtc();
    await _firestore.runTransaction((transaction) async {
      final snapshots = await Future.wait(
        scheduleReferences.map(transaction.get),
      );
      for (var index = 0; index < questions.length; index++) {
        final question = questions[index];
        final snapshot = snapshots[index];
        final current = snapshot.exists
            ? _scheduleFrom(snapshot)
            : ReviewSchedule.initial(question.id, completedAtUtc);
        final selected = answers[question.id];
        final rating = selected == question.correctAnswer
            ? ReviewRating.good
            : ReviewRating.again;
        final next = scheduler.apply(current, rating, completedAtUtc);
        transaction.set(scheduleReferences[index], _scheduleData(next));
      }
      transaction.set(resultReference, {
        'score': score.correct,
        'totalQuestions': score.total,
        'answeredQuestions': score.answered,
        'skippedQuestions': score.skipped,
        'createdAt': FieldValue.serverTimestamp(),
        'wordIds': ids,
      });
    });
    return QuizResult(
      id: resultReference.id,
      score: score.correct,
      totalQuestions: score.total,
      answeredQuestions: score.answered,
      skippedQuestions: score.skipped,
      createdAt: completedAtUtc,
      wordIds: ids,
    );
  }

  @override
  Future<List<QuizResult>> listQuizResults(
    String expectedUid, {
    int limit = 20,
  }) async {
    if (limit < 1 || limit > 100) throw ArgumentError.value(limit, 'limit');
    final snapshot = await _results(expectedUid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs
        .map((document) {
          final data = document.data();
          return QuizResult(
            id: document.id,
            score: data['score'] as int,
            totalQuestions: data['totalQuestions'] as int,
            answeredQuestions: data['answeredQuestions'] as int,
            skippedQuestions: data['skippedQuestions'] as int,
            createdAt: (data['createdAt'] as Timestamp).toDate().toUtc(),
            wordIds: List<String>.from(data['wordIds'] as List),
          );
        })
        .toList(growable: false);
  }
}

final learningRepositoryProvider = Provider<LearningRepository>(
  (ref) => FirestoreLearningRepository(
    FirebaseBootstrap.auth,
    FirebaseBootstrap.firestore,
  ),
);
