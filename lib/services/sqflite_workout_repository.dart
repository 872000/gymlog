import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../data/exercise_library.dart';
import '../models/exercise.dart';
import '../models/personal_record.dart';
import '../models/workout_session.dart';
import '../models/workout_set.dart';
import 'workout_repository.dart';

/// On-device SQLite [WorkoutRepository]. Everything stays local:
/// one database file, no network, no accounts.
class SqfliteWorkoutRepository implements WorkoutRepository {
  SqfliteWorkoutRepository({this.dbName = 'gymlog.db'});

  final String dbName;
  Database? _db;
  static int _seq = 0;

  String _id(String prefix) =>
      '${prefix}_${DateTime.now().microsecondsSinceEpoch}_${_seq++}';

  Future<Database> get _database async {
    final existing = _db;
    if (existing != null) return existing;
    final dir = await getDatabasesPath();
    _db = await openDatabase(
      p.join(dir, dbName),
      version: 1,
      onCreate: _create,
      onOpen: _seedLibrary,
    );
    return _db!;
  }

  Future<void> _create(Database db, int version) async {
    await db.execute(
      'CREATE TABLE exercises('
      'id TEXT PRIMARY KEY, '
      'name TEXT NOT NULL, '
      'muscle_group TEXT NOT NULL, '
      'equipment TEXT NOT NULL, '
      'is_custom INTEGER NOT NULL)',
    );
    await db.execute(
      'CREATE TABLE sessions('
      'id TEXT PRIMARY KEY, '
      'started_at TEXT NOT NULL, '
      'ended_at TEXT, '
      'notes TEXT NOT NULL)',
    );
    await db.execute(
      'CREATE TABLE sets('
      'id TEXT PRIMARY KEY, '
      'session_id TEXT NOT NULL, '
      'exercise_id TEXT NOT NULL, '
      'reps INTEGER NOT NULL, '
      'weight_kg REAL NOT NULL, '
      'logged_at TEXT NOT NULL)',
    );
    await db.execute(
      'CREATE TABLE prs('
      'id TEXT PRIMARY KEY, '
      'exercise_id TEXT NOT NULL, '
      'type TEXT NOT NULL, '
      'value REAL NOT NULL, '
      'reps INTEGER NOT NULL, '
      'achieved_at TEXT NOT NULL)',
    );
  }

  Future<void> _seedLibrary(Database db) async {
    final count =
        Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM exercises')) ?? 0;
    if (count > 0) return;
    final batch = db.batch();
    for (final exercise in exerciseLibrary) {
      batch.insert('exercises', exercise.toMap());
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<List<Exercise>> listExercises() async {
    final db = await _database;
    final rows = await db.query('exercises', orderBy: 'name ASC');
    return rows.map(Exercise.fromMap).toList();
  }

  @override
  Future<Exercise> addCustomExercise({
    required String name,
    required String muscleGroup,
    required String equipment,
  }) async {
    final db = await _database;
    final exercise = Exercise(
      id: _id('ex'),
      name: name,
      muscleGroup: muscleGroup,
      equipment: equipment,
      isCustom: true,
    );
    await db.insert('exercises', exercise.toMap());
    return exercise;
  }

  @override
  Future<WorkoutSession> startSession({DateTime? startedAt}) async {
    final db = await _database;
    final session = WorkoutSession(
      id: _id('sess'),
      startedAt: startedAt ?? DateTime.now(),
    );
    await db.insert('sessions', session.toMap());
    return session;
  }

  @override
  Future<void> finishSession(String sessionId, {DateTime? endedAt}) async {
    final db = await _database;
    await db.update(
      'sessions',
      {'ended_at': (endedAt ?? DateTime.now()).toIso8601String()},
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  @override
  Future<WorkoutSet> logSet({
    required String sessionId,
    required String exerciseId,
    required int reps,
    required double weightKg,
    DateTime? loggedAt,
  }) async {
    final db = await _database;
    final set = WorkoutSet(
      id: _id('set'),
      sessionId: sessionId,
      exerciseId: exerciseId,
      reps: reps,
      weightKg: weightKg,
      loggedAt: loggedAt ?? DateTime.now(),
    );
    await db.insert('sets', set.toMap());
    return set;
  }

  @override
  Future<void> deleteSet(String setId) async {
    final db = await _database;
    await db.delete('sets', where: 'id = ?', whereArgs: [setId]);
  }

  Future<List<WorkoutSet>> _setsOf(Database db, String sessionId) async {
    final rows = await db.query(
      'sets',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'logged_at ASC',
    );
    return rows.map(WorkoutSet.fromMap).toList();
  }

  @override
  Future<List<WorkoutSession>> listSessions({int limit = 50}) async {
    final db = await _database;
    final rows = await db.query(
      'sessions',
      orderBy: 'started_at DESC',
      limit: limit,
    );
    final sessions = <WorkoutSession>[];
    for (final row in rows) {
      final session = WorkoutSession.fromMap(row);
      sessions.add(session.copyWith(sets: await _setsOf(db, session.id)));
    }
    return sessions;
  }

  @override
  Future<WorkoutSession?> getSession(String sessionId) async {
    final db = await _database;
    final rows = await db.query(
      'sessions',
      where: 'id = ?',
      whereArgs: [sessionId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final session = WorkoutSession.fromMap(rows.first);
    return session.copyWith(sets: await _setsOf(db, sessionId));
  }

  @override
  Future<List<WorkoutSet>> setsForExercise(String exerciseId) async {
    final db = await _database;
    final rows = await db.query(
      'sets',
      where: 'exercise_id = ?',
      whereArgs: [exerciseId],
      orderBy: 'logged_at ASC',
    );
    return rows.map(WorkoutSet.fromMap).toList();
  }

  @override
  Future<List<PersonalRecord>> listPrs(String exerciseId) async {
    final db = await _database;
    final rows = await db.query(
      'prs',
      where: 'exercise_id = ?',
      whereArgs: [exerciseId],
      orderBy: 'achieved_at DESC',
    );
    return rows.map(PersonalRecord.fromMap).toList();
  }

  @override
  Future<void> recordPr(PersonalRecord pr) async {
    final db = await _database;
    await db.insert('prs', pr.toMap());
  }
}
