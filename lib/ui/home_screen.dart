import 'package:flutter/material.dart';

import '../services/workout_repository.dart';
import 'exercises_tab.dart';
import 'history_tab.dart';
import 'log_tab.dart';
import 'progress_tab.dart';

/// Bottom-navigation shell. [refresh] is bumped whenever the visible tab
/// changes so every tab re-reads the repository.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.repository});

  final WorkoutRepository repository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  final _refresh = ValueNotifier<int>(0);

  void _select(int index) {
    setState(() => _index = index);
    _refresh.value++;
  }

  @override
  void dispose() {
    _refresh.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GymLog')),
      body: IndexedStack(
        index: _index,
        children: [
          LogTab(repository: widget.repository, refresh: _refresh),
          ExercisesTab(repository: widget.repository, refresh: _refresh),
          ProgressTab(repository: widget.repository, refresh: _refresh),
          HistoryTab(repository: widget.repository, refresh: _refresh),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _select,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.fitness_center),
            label: 'Log',
          ),
          NavigationDestination(icon: Icon(Icons.list), label: 'Exercises'),
          NavigationDestination(
            icon: Icon(Icons.show_chart),
            label: 'Progress',
          ),
          NavigationDestination(icon: Icon(Icons.history), label: 'History'),
        ],
      ),
    );
  }
}
