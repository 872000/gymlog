import 'workout_set.dart';

/// One training session: a time window holding a list of sets.
class WorkoutSession {
  const WorkoutSession({
    required this.id,
    required this.startedAt,
    this.endedAt,
    this.notes = '',
    this.sets = const <WorkoutSet>[],
  });

  final String id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String notes;
  final List<WorkoutSet> sets;

  bool get isActive => endedAt == null;

  double get totalVolume =>
      sets.fold<double>(0, (sum, set) => sum + set.volume);

  int get totalSets => sets.length;

  WorkoutSession copyWith({
    List<WorkoutSet>? sets,
    DateTime? endedAt,
    String? notes,
  }) {
    return WorkoutSession(
      id: id,
      startedAt: startedAt,
      endedAt: endedAt ?? this.endedAt,
      notes: notes ?? this.notes,
      sets: sets ?? this.sets,
    );
  }

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'started_at': startedAt.toIso8601String(),
        'ended_at': endedAt?.toIso8601String(),
        'notes': notes,
      };

  factory WorkoutSession.fromMap(Map<String, Object?> map) => WorkoutSession(
        id: map['id'] as String,
        startedAt: DateTime.parse(map['started_at'] as String),
        endedAt: map['ended_at'] == null
            ? null
            : DateTime.parse(map['ended_at'] as String),
        notes: map['notes'] as String? ?? '',
      );
}
