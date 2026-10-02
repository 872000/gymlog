import '../data/exercise_library.dart';
import '../models/exercise.dart';
import '../models/personal_record.dart';
import '../models/workout_session.dart';
import '../models/workout_set.dart';
import 'workout_repository.dart';

/// In-memory [WorkoutRepository]. Used by widget tests and as a predictable
/// demo backend; behaves identically to the sqflite implementation.
class InMemoryWorkoutRepository implements WorkoutRepository {
  InMemoryWorkoutRepository() {
    for (final exercise in exerciseLibrary) {
      _exercises[exercise.id] = exercise;
    }
  }

  final Map<String, Exercise> _exercises = {};
  final Map<String, WorkoutSession> _sessions = {};
  final Map<String, WorkoutSet> _sets = {};
  final List<PersonalRecord> _prs = [];
  int _seq = 0;

  String _id(String prefix) =>
      '${prefix}_${DateTime.now().microsecondsSinceEpoch}_${_seq++}';

  @override
  Future<List<Exercise>> listExercises() async {
    final list = _exercises.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  @override
  Future<Exercise> addCustomExercise({
    required String name,
    required String muscleGroup,
    required String equipment,
  }) async {
    final exercise = Exercise(
      id: _id('ex'),
      name: name,
      muscleGroup: muscleGroup,
      equipment: equipment,
      isCustom: true,
    );
    _exercises[exercise.id] = exercise;
    return exercise;
  }

  @override
  Future<WorkoutSession> startSession({DateTime? startedAt}) async {
    final session = WorkoutSession(
      id: _id('sess'),
      startedAt: startedAt ?? DateTime.now(),
    );
    _sessions[session.id] = session;
    return session;
  }

  @override
  Future<void> finishSession(String sessionId, {DateTime? endedAt}) async {
    final session = _sessions[sessionId];
    if (session == null) return;
    _sessions[sessionId] =
        session.copyWith(endedAt: endedAt ?? DateTime.now());
  }

  @override
  Future<WorkoutSet> logSet({
    required String sessionId,
    required String exerciseId,
    required int reps,
    required double weightKg,
    DateTime? loggedAt,
  }) async {
    final set = WorkoutSet(
      id: _id('set'),
      sessionId: sessionId,
      exerciseId: exerciseId,
      reps: reps,
      weightKg: weightKg,
      loggedAt: loggedAt ?? DateTime.now(),
    );
    _sets[set.id] = set;
    return set;
  }

  @override
  Future<void> deleteSet(String setId) async {
    _sets.remove(setId);
  }

  List<WorkoutSet> _setsOf(String sessionId) {
    final list = _sets.values
        .where((s) => s.sessionId == sessionId)
        .toList()
      ..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
    return list;
  }

  @override
  Future<List<WorkoutSession>> listSessions({int limit = 50}) async {
    final list = _sessions.values.toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return list
        .take(limit)
        .map((s) => s.copyWith(sets: _setsOf(s.id)))
        .toList();
  }

  @override
  Future<WorkoutSession?> getSession(String sessionId) async {
    final session = _sessions[sessionId];
    if (session == null) return null;
    return session.copyWith(sets: _setsOf(sessionId));
  }

  @override
  Future<List<WorkoutSet>> setsForExercise(String exerciseId) async {
    final list = _sets.values
        .where((s) => s.exerciseId == exerciseId)
        .toList()
      ..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
    return list;
  }

  @override
  Future<List<PersonalRecord>> listPrs(String exerciseId) async {
    final list = _prs.where((p) => p.exerciseId == exerciseId).toList()
      ..sort((a, b) => b.achievedAt.compareTo(a.achievedAt));
    return list;
  }

  @override
  Future<void> recordPr(PersonalRecord pr) async {
    _prs.add(pr);
  }
}
