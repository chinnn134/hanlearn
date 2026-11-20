import 'dart:math';

import 'package:flutter/foundation.dart';

enum ReviewRating { again, hard, good, easy }

@immutable
class ReviewSchedule {
  const ReviewSchedule({
    required this.vocabId,
    required this.dueAt,
    required this.intervalDays,
    required this.lastReviewedAt,
    required this.reviewCount,
  });

  final String vocabId;
  final DateTime dueAt;
  final int intervalDays;
  final DateTime? lastReviewedAt;
  final int reviewCount;

  factory ReviewSchedule.initial(String vocabId, DateTime now) {
    if (vocabId.trim().isEmpty) throw ArgumentError.value(vocabId, 'vocabId');
    return ReviewSchedule(
      vocabId: vocabId,
      dueAt: now.toUtc(),
      intervalDays: 0,
      lastReviewedAt: null,
      reviewCount: 0,
    );
  }
}

class ReviewScheduler {
  const ReviewScheduler({this.maximumIntervalDays = 365});

  final int maximumIntervalDays;

  ReviewSchedule apply(
    ReviewSchedule current,
    ReviewRating rating,
    DateTime reviewedAt,
  ) {
    if (maximumIntervalDays < 1) {
      throw ArgumentError.value(
        maximumIntervalDays,
        'maximumIntervalDays',
        'must be positive',
      );
    }
    final reviewedAtUtc = reviewedAt.toUtc();
    final interval = switch (rating) {
      ReviewRating.again => 0,
      ReviewRating.hard =>
        current.intervalDays == 0
            ? 1
            : max(1, (current.intervalDays * 1.2).ceil()),
      ReviewRating.good =>
        current.intervalDays == 0 ? 1 : current.intervalDays * 2,
      ReviewRating.easy =>
        current.intervalDays == 0 ? 3 : current.intervalDays * 3,
    };
    final cappedInterval = min(interval, maximumIntervalDays);
    final dueAt = rating == ReviewRating.again
        ? reviewedAtUtc.add(const Duration(minutes: 10))
        : reviewedAtUtc.add(Duration(days: cappedInterval));
    return ReviewSchedule(
      vocabId: current.vocabId,
      dueAt: dueAt,
      intervalDays: cappedInterval,
      lastReviewedAt: reviewedAtUtc,
      reviewCount: current.reviewCount + 1,
    );
  }

  bool isDue(ReviewSchedule schedule, DateTime now) =>
      !schedule.dueAt.toUtc().isAfter(now.toUtc());

  List<ReviewSchedule> dueSchedules(
    Iterable<ReviewSchedule> schedules,
    DateTime now,
  ) {
    final due = schedules.where((schedule) => isDue(schedule, now)).toList()
      ..sort((a, b) => a.dueAt.compareTo(b.dueAt));
    return due;
  }
}
