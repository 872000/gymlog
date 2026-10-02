import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/models/personal_record.dart';
import 'package:gymlog/services/in_memory_workout_repository.dart';

void main() {
  late InMemoryWorkoutRepository repo;

  setUp(() {
    repo = InMemoryWorkoutRepository();
  });

  group('InMemoryWorkoutRepository', () {
    test('seeds the bundled exercise library', () async {
      final exercises = await repo.listExercises();

      expect(exercises.length, greaterThan(20));
      expect(exercises.map((e) => e.name), contains('Bench Press'));
      expect(exercises.map((e) => e.name), contains('Deadlift'));
    });

    test('adds a custom exercise', () async {
      final custom = await repo.addCustomExercise(
        name: 'Zercher Squat',
        muscleGroup: 'Legs',
        equipment: 'Barbell',
      );

      expect(custom.isCustom, isTrue);
      final exercises = await repo.listExercises();
      expect(exercises.map((e) => e.name), contains('Zercher Squat'));
    });

    test('logs sets into a session and reads them back', () async {
      final session = await repo.startSession();
      await repo.logSet(
        sessionId: session.id,
        exerciseId: 'bench-press',
        reps: 8,
        weightKg: 60,
      );
      await repo.logSet(
        sessionId: session.id,
        exerciseId: 'bench-press',
        reps: 6,
        weightKg: 70,
      );

      final fetched = await repo.getSession(session.id);
      expect(fetched, isNotNull);
      expect(fetched!.totalSets, 2);
      // 8x60 + 6x70 = 900
      expect(fetched.totalVolume, 900);
    });

    test('sessions list newest first with sets attached', () async {
      final first = await repo.startSession(
        startedAt: DateTime(2026, 9, 1, 10, 0),
      );
      await repo.logSet(
        sessionId: first.id,
        exerciseId: 'squat',
        reps: 5,
        weightKg: 100,
      );
      await repo.startSession(startedAt: DateTime(2026, 10, 1, 10, 0));

      final sessions = await repo.listSessions();
      expect(sessions, hasLength(2));
      expect(sessions.first.startedAt.day, 1);
      expect(sessions.first.startedAt.month, 10);
      expect(sessions.last.sets, hasLength(1));
    });

    test('finishSession marks the session done', () async {
      final session = await repo.startSession();
      expect((await repo.getSession(session.id))!.isActive, isTrue);

      await repo.finishSession(session.id);

      expect((await repo.getSession(session.id))!.isActive, isFalse);
    });

    test('deleteSet removes the set', () async {
      final session = await repo.startSession();
      final set = await repo.logSet(
        sessionId: session.id,
        exerciseId: 'bench-press',
        reps: 8,
        weightKg: 60,
      );

      await repo.deleteSet(set.id);

      expect((await repo.getSession(session.id))!.sets, isEmpty);
    });

    test('setsForExercise filters across sessions', () async {
      final a = await repo.startSession();
      final b = await repo.startSession();
      await repo.logSet(
        sessionId: a.id,
        exerciseId: 'bench-press',
        reps: 8,
        weightKg: 60,
      );
      await repo.logSet(
        sessionId: b.id,
        exerciseId: 'squat',
        reps: 5,
        weightKg: 100,
      );

      final bench = await repo.setsForExercise('bench-press');
      expect(bench, hasLength(1));
      expect(bench.first.weightKg, 60);
    });

    test('records and lists PRs newest first', () async {
      final now = DateTime(2026, 10, 2);
      await repo.recordPr(
        PersonalRecord(
          id: '1',
          exerciseId: 'bench-press',
          type: PrType.maxWeight,
          value: 80,
          reps: 5,
          achievedAt: DateTime(2026, 9, 1),
        ),
      );
      await repo.recordPr(
        PersonalRecord(
          id: '2',
          exerciseId: 'bench-press',
          type: PrType.maxWeight,
          value: 85,
          reps: 3,
          achievedAt: now,
        ),
      );

      final prs = await repo.listPrs('bench-press');
      expect(prs.map((p) => p.value), [85, 80]);
    });

    test('getSession returns null for unknown ids', () async {
      expect(await repo.getSession('nope'), isNull);
    });
  });
}
