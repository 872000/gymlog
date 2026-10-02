import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/models/workout_session.dart';
import 'package:gymlog/models/workout_set.dart';
import 'package:gymlog/services/workout_stats.dart';

WorkoutSet set(String exercise, DateTime at, int reps, double weight) =>
    WorkoutSet(
      id: '$exercise-$at',
      sessionId: 'sess',
      exerciseId: exercise,
      reps: reps,
      weightKg: weight,
      loggedAt: at,
    );

void main() {
  const stats = WorkoutStats();

  group('volumeByDay', () {
    test('aggregates volume per calendar day, oldest first', () {
      final sessions = [
        WorkoutSession(
          id: 'a',
          startedAt: DateTime(2026, 10, 2, 18, 0),
          sets: [
            set('bench-press', DateTime(2026, 10, 2, 18, 0), 8, 60),
            set('squat', DateTime(2026, 10, 2, 18, 30), 5, 100),
          ],
        ),
        WorkoutSession(
          id: 'b',
          startedAt: DateTime(2026, 9, 30, 18, 0),
          sets: [set('bench-press', DateTime(2026, 9, 30, 18, 0), 10, 50)],
        ),
      ];

      final points = stats.volumeByDay(sessions);

      expect(points, hasLength(2));
      expect(points.first.date, DateTime(2026, 9, 30));
      expect(points.first.value, 500); // 10x50
      expect(points.last.date, DateTime(2026, 10, 2));
      expect(points.last.value, 980); // 8x60 + 5x100
    });

    test('two sessions on the same day merge into one point', () {
      final sessions = [
        WorkoutSession(
          id: 'a',
          startedAt: DateTime(2026, 10, 2, 8, 0),
          sets: [set('bench-press', DateTime(2026, 10, 2, 8, 0), 8, 60)],
        ),
        WorkoutSession(
          id: 'b',
          startedAt: DateTime(2026, 10, 2, 18, 0),
          sets: [set('bench-press', DateTime(2026, 10, 2, 18, 0), 8, 60)],
        ),
      ];

      final points = stats.volumeByDay(sessions);

      expect(points, hasLength(1));
      expect(points.first.value, 960);
    });

    test('empty input gives empty output', () {
      expect(stats.volumeByDay(const []), isEmpty);
    });
  });

  group('bestE1rmByDay', () {
    test('picks the best estimated 1RM per day', () {
      final sets = [
        set('bench-press', DateTime(2026, 10, 1, 18, 0), 8, 60), // ~76
        set('bench-press', DateTime(2026, 10, 1, 18, 30), 5, 70), // ~81.7
        set('bench-press', DateTime(2026, 10, 3, 18, 0), 8, 62.5), // ~79.2
      ];

      final points = stats.bestE1rmByDay(sets);

      expect(points, hasLength(2));
      expect(points.first.date, DateTime(2026, 10, 1));
      expect(points.first.value, closeTo(70 * (1 + 5 / 30), 0.01));
      expect(points.last.value, closeTo(62.5 * (1 + 8 / 30), 0.01));
    });

    test('skips invalid sets', () {
      final sets = [
        set('bench-press', DateTime(2026, 10, 1), 0, 100),
        set('bench-press', DateTime(2026, 10, 1), 8, 0),
        set('bench-press', DateTime(2026, 10, 1), 8, 60),
      ];

      final points = stats.bestE1rmByDay(sets);

      expect(points, hasLength(1));
    });
  });
}
