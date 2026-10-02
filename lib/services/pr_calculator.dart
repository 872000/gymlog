import '../models/personal_record.dart';
import '../models/workout_set.dart';

/// Strength math: Epley estimated one-rep max plus automatic PR detection.
///
/// Pure logic — no I/O — so it is fully unit-testable.
class PrCalculator {
  const PrCalculator();

  /// Epley formula estimate of a one-rep max from a working set.
  double e1rm({required double weightKg, required int reps}) {
    if (reps <= 1 || weightKg <= 0) return weightKg;
    return weightKg * (1 + reps / 30);
  }

  /// Compares [newSets] against [history] and returns the fresh PRs they
  /// contain. Two PR types are tracked per exercise: heaviest weight lifted
  /// and best estimated 1RM. Nothing is persisted here — the caller records
  /// the returned entries via the repository.
  List<PersonalRecord> detectPrs({
    required String exerciseId,
    required List<WorkoutSet> newSets,
    required List<PersonalRecord> history,
    required DateTime now,
  }) {
    final valid =
        newSets.where((s) => s.reps > 0 && s.weightKg > 0).toList();
    if (valid.isEmpty) return const [];

    double previousBest(PrType type) {
      var best = 0.0;
      for (final pr in history) {
        if (pr.exerciseId == exerciseId &&
            pr.type == type &&
            pr.value > best) {
          best = pr.value;
        }
      }
      return best;
    }

    final prs = <PersonalRecord>[];

    final heaviest =
        valid.reduce((a, b) => a.weightKg >= b.weightKg ? a : b);
    if (heaviest.weightKg > previousBest(PrType.maxWeight)) {
      prs.add(
        PersonalRecord(
          id: 'pr_${now.microsecondsSinceEpoch}_w',
          exerciseId: exerciseId,
          type: PrType.maxWeight,
          value: heaviest.weightKg,
          reps: heaviest.reps,
          achievedAt: now,
        ),
      );
    }

    WorkoutSet? bestSet;
    var bestE1rm = 0.0;
    for (final set in valid) {
      final value = e1rm(weightKg: set.weightKg, reps: set.reps);
      if (value > bestE1rm) {
        bestE1rm = value;
        bestSet = set;
      }
    }
    if (bestSet != null && bestE1rm > previousBest(PrType.bestE1rm)) {
      prs.add(
        PersonalRecord(
          id: 'pr_${now.microsecondsSinceEpoch}_e',
          exerciseId: exerciseId,
          type: PrType.bestE1rm,
          value: bestE1rm,
          reps: bestSet.reps,
          achievedAt: now,
        ),
      );
    }
    return prs;
  }
}
