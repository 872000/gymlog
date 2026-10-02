import 'package:flutter/material.dart';

import '../services/workout_repository.dart';
import 'home_screen.dart';

/// Root widget. The [WorkoutRepository] is injectable so widget tests can
/// use the in-memory implementation while the app uses sqflite.
class GymLogApp extends StatelessWidget {
  const GymLogApp({super.key, required this.repository});

  final WorkoutRepository repository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GymLog',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B5E20),
        ),
      ),
      home: HomeScreen(repository: repository),
    );
  }
}
