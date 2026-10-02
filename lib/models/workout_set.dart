/// One logged set: reps × weight at a point in time.
class WorkoutSet {
  const WorkoutSet({
    required this.id,
    required this.sessionId,
    required this.exerciseId,
    required this.reps,
    required this.weightKg,
    required this.loggedAt,
  });

  final String id;
  final String sessionId;
  final String exerciseId;
  final int reps;
  final double weightKg;
  final DateTime loggedAt;

  /// Mechanical work proxy used for volume charts.
  double get volume => reps * weightKg;

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'session_id': sessionId,
        'exercise_id': exerciseId,
        'reps': reps,
        'weight_kg': weightKg,
        'logged_at': loggedAt.toIso8601String(),
      };

  factory WorkoutSet.fromMap(Map<String, Object?> map) => WorkoutSet(
        id: map['id'] as String,
        sessionId: map['session_id'] as String,
        exerciseId: map['exercise_id'] as String,
        reps: (map['reps'] as num).toInt(),
        weightKg: (map['weight_kg'] as num).toDouble(),
        loggedAt: DateTime.parse(map['logged_at'] as String),
      );
}
