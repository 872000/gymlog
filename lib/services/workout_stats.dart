import '../models/workout_session.dart';
import '../models/workout_set.dart';
import 'pr_calculator.dart';

/// One aggregated data point for the progress charts.
class DailyPoint {
  const DailyPoint(this.date, this.value);

  final DateTime date;
  final double value;
}

/// Aggregates raw sets/sessions into chart-ready series. Pure logic.
class WorkoutStats {
  const WorkoutStats();

  /// Total volume (reps × kg) per calendar day, oldest first.
  List<DailyPoint> volumeByDay(List<WorkoutSession> sessions) {
    final totals = <DateTime, double>{};
    for (final session in sessions) {
      final day = DateTime(
        session.startedAt.year,
        session.startedAt.month,
        session.startedAt.day,
      );
      totals[day] = (totals[day] ?? 0) + session.totalVolume;
    }
    return _sorted(totals);
  }

  /// Best estimated 1RM per calendar day for one exercise, oldest first.
  List<DailyPoint> bestE1rmByDay(List<WorkoutSet> sets) {
    const calc = PrCalculator();
    final best = <DateTime, double>{};
    for (final set in sets) {
      if (set.reps <= 0 || set.weightKg <= 0) continue;
      final day = DateTime(
        set.loggedAt.year,
        set.loggedAt.month,
        set.loggedAt.day,
      );
      final value = calc.e1rm(weightKg: set.weightKg, reps: set.reps);
      if (value > (best[day] ?? 0)) best[day] = value;
    }
    return _sorted(best);
  }

  List<DailyPoint> _sorted(Map<DateTime, double> byDay) {
    final points = byDay.entries
        .map((e) => DailyPoint(e.key, e.value))
        .toList();
    points.sort((a, b) => a.date.compareTo(b.date));
    return points;
  }
}
