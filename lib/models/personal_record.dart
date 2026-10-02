/// The kinds of personal records GymLog tracks per exercise.
enum PrType {
  /// Heaviest single set, in kg.
  maxWeight,

  /// Best estimated one-rep max (Epley), in kg.
  bestE1rm,
}

/// One entry in an exercise's PR history.
class PersonalRecord {
  const PersonalRecord({
    required this.id,
    required this.exerciseId,
    required this.type,
    required this.value,
    required this.reps,
    required this.achievedAt,
  });

  final String id;
  final String exerciseId;
  final PrType type;

  /// Kilograms: raw weight for [PrType.maxWeight], Epley estimate for
  /// [PrType.bestE1rm].
  final double value;
  final int reps;
  final DateTime achievedAt;

  String get label =>
      type == PrType.maxWeight ? 'Heaviest lift' : 'Best est. 1RM';

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'exercise_id': exerciseId,
        'type': type.name,
        'value': value,
        'reps': reps,
        'achieved_at': achievedAt.toIso8601String(),
      };

  factory PersonalRecord.fromMap(Map<String, Object?> map) => PersonalRecord(
        id: map['id'] as String,
        exerciseId: map['exercise_id'] as String,
        type: PrType.values.byName(map['type'] as String),
        value: (map['value'] as num).toDouble(),
        reps: (map['reps'] as num).toInt(),
        achievedAt: DateTime.parse(map['achieved_at'] as String),
      );
}
