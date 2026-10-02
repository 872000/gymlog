import 'package:flutter/material.dart';

import 'services/sqflite_workout_repository.dart';
import 'ui/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(GymLogApp(repository: SqfliteWorkoutRepository()));
}
