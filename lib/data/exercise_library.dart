import '../models/exercise.dart';

/// Bundled offline exercise library. Seeded into the local database on
/// first launch; users can add their own on top.
const List<Exercise> exerciseLibrary = <Exercise>[
  Exercise(id: 'bench-press', name: 'Bench Press', muscleGroup: 'Chest', equipment: 'Barbell'),
  Exercise(id: 'incline-db-press', name: 'Incline Dumbbell Press', muscleGroup: 'Chest', equipment: 'Dumbbell'),
  Exercise(id: 'push-up', name: 'Push-Up', muscleGroup: 'Chest', equipment: 'Bodyweight'),
  Exercise(id: 'overhead-press', name: 'Overhead Press', muscleGroup: 'Shoulders', equipment: 'Barbell'),
  Exercise(id: 'lateral-raise', name: 'Lateral Raise', muscleGroup: 'Shoulders', equipment: 'Dumbbell'),
  Exercise(id: 'face-pull', name: 'Face Pull', muscleGroup: 'Shoulders', equipment: 'Cable'),
  Exercise(id: 'pull-up', name: 'Pull-Up', muscleGroup: 'Back', equipment: 'Bodyweight'),
  Exercise(id: 'barbell-row', name: 'Barbell Row', muscleGroup: 'Back', equipment: 'Barbell'),
  Exercise(id: 'lat-pulldown', name: 'Lat Pulldown', muscleGroup: 'Back', equipment: 'Cable'),
  Exercise(id: 'seated-cable-row', name: 'Seated Cable Row', muscleGroup: 'Back', equipment: 'Cable'),
  Exercise(id: 'squat', name: 'Squat', muscleGroup: 'Legs', equipment: 'Barbell'),
  Exercise(id: 'front-squat', name: 'Front Squat', muscleGroup: 'Legs', equipment: 'Barbell'),
  Exercise(id: 'deadlift', name: 'Deadlift', muscleGroup: 'Legs', equipment: 'Barbell'),
  Exercise(id: 'romanian-deadlift', name: 'Romanian Deadlift', muscleGroup: 'Legs', equipment: 'Barbell'),
  Exercise(id: 'leg-press', name: 'Leg Press', muscleGroup: 'Legs', equipment: 'Machine'),
  Exercise(id: 'lunge', name: 'Lunge', muscleGroup: 'Legs', equipment: 'Dumbbell'),
  Exercise(id: 'leg-curl', name: 'Leg Curl', muscleGroup: 'Legs', equipment: 'Machine'),
  Exercise(id: 'calf-raise', name: 'Calf Raise', muscleGroup: 'Legs', equipment: 'Machine'),
  Exercise(id: 'hip-thrust', name: 'Hip Thrust', muscleGroup: 'Legs', equipment: 'Barbell'),
  Exercise(id: 'biceps-curl', name: 'Biceps Curl', muscleGroup: 'Arms', equipment: 'Dumbbell'),
  Exercise(id: 'triceps-pushdown', name: 'Triceps Pushdown', muscleGroup: 'Arms', equipment: 'Cable'),
  Exercise(id: 'plank', name: 'Plank', muscleGroup: 'Core', equipment: 'Bodyweight'),
  Exercise(id: 'hanging-leg-raise', name: 'Hanging Leg Raise', muscleGroup: 'Core', equipment: 'Bodyweight'),
  Exercise(id: 'chest-supported-row', name: 'Chest-Supported Row', muscleGroup: 'Back', equipment: 'Dumbbell'),
];
