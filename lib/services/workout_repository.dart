import '../models/exercise.dart';
import '../models/personal_record.dart';
import '../models/workout_session.dart';
import '../models/workout_set.dart';

/// Storage contract for workouts.
///
/// The app ships [SqfliteWorkoutRepository] (real on-device SQLite); tests
/// and previews use [InMemoryWorkoutRepository]. Both behave identically.
abstract class WorkoutRepository {
  Future<List<Exercise>> listExercises();

  Future<Exercise> addCustomExercise({
    required String name,
    required String muscleGroup,
    required String equipment,
  });

  Future<WorkoutSession> startSession({DateTime? startedAt});

  Future<void> finishSession(String sessionId, {DateTime? endedAt});

  Future<WorkoutSet> logSet({
    required String sessionId,
    required String exerciseId,
    required int reps,
    required double weightKg,
    DateTime? loggedAt,
  });

  Future<void> deleteSet(String setId);

  /// Most recent first, each with its sets attached.
  Future<List<WorkoutSession>> listSessions({int limit = 50});

  Future<WorkoutSession?> getSession(String sessionId);

  /// Every set ever logged for one exercise, oldest first.
  Future<List<WorkoutSet>> setsForExercise(String exerciseId);

  Future<List<PersonalRecord>> listPrs(String exerciseId);

  Future<void> recordPr(PersonalRecord pr);
}
