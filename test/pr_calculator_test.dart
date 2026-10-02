import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/models/personal_record.dart';
import 'package:gymlog/models/workout_set.dart';
import 'package:gymlog/services/pr_calculator.dart';

WorkoutSet set(String id, {required int reps, required double weight}) =>
    WorkoutSet(
      id: id,
      sessionId: 'sess',
      exerciseId: 'bench-press',
      reps: reps,
      weightKg: weight,
      loggedAt: DateTime(2026, 10, 2, 12, 0),
    );

PersonalRecord pr(PrType type, double value) => PersonalRecord(
      id: 'old',
      exerciseId: 'bench-press',
      type: type,
      value: value,
      reps: 5,
      achievedAt: DateTime(2026, 9, 1),
    );

void main() {
  const calc = PrCalculator();

  group('e1rm', () {
    test('single rep returns the weight itself', () {
      expect(calc.e1rm(weightKg: 100, reps: 1), 100);
    });

    test('Epley formula for rep ranges', () {
      // 100 kg x 10 -> 100 * (1 + 10/30)
      expect(calc.e1rm(weightKg: 100, reps: 10), closeTo(133.33, 0.01));
      expect(calc.e1rm(weightKg: 60, reps: 5), closeTo(70.0, 0.01));
    });
  });

  group('detectPrs', () {
    test('first ever set records both weight and e1rm PRs', () {
      final prs = calc.detectPrs(
        exerciseId: 'bench-press',
        newSets: [set('a', reps: 8, weight: 60)],
        history: const [],
        now: DateTime(2026, 10, 2),
      );

      expect(prs.map((p) => p.type), containsAll([PrType.maxWeight, PrType.bestE1rm]));
      expect(prs.firstWhere((p) => p.type == PrType.maxWeight).value, 60);
    });

    test('no PR when below history', () {
      final prs = calc.detectPrs(
        exerciseId: 'bench-press',
        newSets: [set('a', reps: 8, weight: 55)],
        history: [pr(PrType.maxWeight, 60), pr(PrType.bestE1rm, 80)],
        now: DateTime(2026, 10, 2),
      );

      expect(prs, isEmpty);
    });

    test('weight PR without e1rm PR when only the top weight improves', () {
      // 105 x 1: heavier than 100, but e1rm 105 < previous best 130.
      final prs = calc.detectPrs(
        exerciseId: 'bench-press',
        newSets: [set('a', reps: 1, weight: 105)],
        history: [pr(PrType.maxWeight, 100), pr(PrType.bestE1rm, 130)],
        now: DateTime(2026, 10, 2),
      );

      expect(prs.map((p) => p.type), [PrType.maxWeight]);
    });

    test('e1rm PR without weight PR on a high-rep set', () {
      // 80 x 12 -> e1rm 112 > 100, but 80 kg < 100 kg top weight.
      final prs = calc.detectPrs(
        exerciseId: 'bench-press',
        newSets: [set('a', reps: 12, weight: 80)],
        history: [pr(PrType.maxWeight, 100), pr(PrType.bestE1rm, 100)],
        now: DateTime(2026, 10, 2),
      );

      expect(prs.map((p) => p.type), [PrType.bestE1rm]);
    });

    test('best of a batch is compared, not every set', () {
      final prs = calc.detectPrs(
        exerciseId: 'bench-press',
        newSets: [
          set('a', reps: 8, weight: 50),
          set('b', reps: 8, weight: 70),
        ],
        history: [pr(PrType.maxWeight, 60), pr(PrType.bestE1rm, 75)],
        now: DateTime(2026, 10, 2),
      );

      final weightPr = prs.firstWhere((p) => p.type == PrType.maxWeight);
      expect(weightPr.value, 70);
      expect(weightPr.reps, 8);
    });

    test('equal to history is not a PR', () {
      final prs = calc.detectPrs(
        exerciseId: 'bench-press',
        newSets: [set('a', reps: 5, weight: 60)],
        history: [pr(PrType.maxWeight, 60)],
        now: DateTime(2026, 10, 2),
      );

      expect(prs.where((p) => p.type == PrType.maxWeight), isEmpty);
    });

    test('invalid sets are ignored', () {
      final prs = calc.detectPrs(
        exerciseId: 'bench-press',
        newSets: [
          set('a', reps: 0, weight: 100),
          set('b', reps: 8, weight: 0),
        ],
        history: const [],
        now: DateTime(2026, 10, 2),
      );

      expect(prs, isEmpty);
    });

    test('history for other exercises does not count', () {
      final other = PersonalRecord(
        id: 'x',
        exerciseId: 'squat',
        type: PrType.maxWeight,
        value: 200,
        reps: 5,
        achievedAt: DateTime(2026, 9, 1),
      );
      final prs = calc.detectPrs(
        exerciseId: 'bench-press',
        newSets: [set('a', reps: 8, weight: 60)],
        history: [other],
        now: DateTime(2026, 10, 2),
      );

      expect(prs, hasLength(2));
    });
  });
}
