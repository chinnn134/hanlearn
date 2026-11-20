import 'package:flutter_app/features/learning/review_scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const scheduler = ReviewScheduler();
  final now = DateTime.utc(2026, 11, 21, 8);

  test('initial schedule is due immediately and stores UTC', () {
    final localInstant = DateTime.parse('2026-11-21T15:00:00+07:00');
    final schedule = ReviewSchedule.initial('word-1', localInstant);

    expect(schedule.dueAt, now);
    expect(schedule.dueAt.isUtc, isTrue);
    expect(schedule.intervalDays, 0);
    expect(schedule.lastReviewedAt, isNull);
    expect(schedule.reviewCount, 0);
    expect(scheduler.isDue(schedule, now), isTrue);
  });

  test('again schedules a short retry without claiming a full day', () {
    final current = ReviewSchedule.initial('word-1', now);
    final next = scheduler.apply(current, ReviewRating.again, now);

    expect(next.intervalDays, 0);
    expect(next.dueAt, now.add(const Duration(minutes: 10)));
    expect(next.lastReviewedAt, now);
    expect(next.reviewCount, 1);
  });

  test('hard good and easy advance bounded intervals', () {
    ReviewSchedule current = ReviewSchedule.initial('word-1', now);
    current = scheduler.apply(current, ReviewRating.hard, now);
    expect(current.intervalDays, 1);
    current = scheduler.apply(current, ReviewRating.good, now);
    expect(current.intervalDays, 2);
    current = scheduler.apply(current, ReviewRating.easy, now);
    expect(current.intervalDays, 6);

    const bounded = ReviewScheduler(maximumIntervalDays: 30);
    final long = ReviewSchedule(
      vocabId: 'word-1',
      dueAt: now,
      intervalDays: 20,
      lastReviewedAt: now,
      reviewCount: 5,
    );
    expect(bounded.apply(long, ReviewRating.easy, now).intervalDays, 30);
  });

  test('due comparison represents the same instant across timezones', () {
    final schedule = ReviewSchedule(
      vocabId: 'word-1',
      dueAt: DateTime.parse('2026-11-21T15:00:00+07:00'),
      intervalDays: 1,
      lastReviewedAt: null,
      reviewCount: 0,
    );

    expect(
      scheduler.isDue(schedule, DateTime.parse('2026-11-21T07:59:59Z')),
      isFalse,
    );
    expect(
      scheduler.isDue(schedule, DateTime.parse('2026-11-21T08:00:00Z')),
      isTrue,
    );
  });

  test('due schedules handles empty input and sorts oldest first', () {
    expect(scheduler.dueSchedules(const [], now), isEmpty);
    final later = ReviewSchedule.initial('later', now);
    final earlier = ReviewSchedule.initial(
      'earlier',
      now.subtract(const Duration(days: 1)),
    );
    final future = ReviewSchedule.initial(
      'future',
      now.add(const Duration(minutes: 1)),
    );

    expect(
      scheduler
          .dueSchedules([later, future, earlier], now)
          .map((item) => item.vocabId),
      ['earlier', 'later'],
    );
  });
}
