import 'package:flutter/material.dart';

import '../models/exercise.dart';
import '../services/workout_repository.dart';

const _equipmentOptions = <String>[
  'Barbell',
  'Dumbbell',
  'Machine',
  'Cable',
  'Bodyweight',
  'Other',
];

/// Bundled exercise library, grouped by muscle group, plus user-added
/// custom exercises.
class ExercisesTab extends StatefulWidget {
  const ExercisesTab({
    super.key,
    required this.repository,
    required this.refresh,
  });

  final WorkoutRepository repository;
  final ValueNotifier<int> refresh;

  @override
  State<ExercisesTab> createState() => _ExercisesTabState();
}

class _ExercisesTabState extends State<ExercisesTab> {
  List<Exercise> _exercises = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    widget.refresh.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    widget.refresh.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final exercises = await widget.repository.listExercises();
    if (!mounted) return;
    setState(() {
      _exercises = exercises;
      _loading = false;
    });
  }

  Future<void> _showAddDialog() async {
    final nameCtrl = TextEditingController();
    final groups = _exercises.map((e) => e.muscleGroup).toSet().toList()
      ..sort();
    var group = groups.isEmpty ? 'Custom' : groups.first;
    var equipment = _equipmentOptions.first;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add custom exercise'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
                autofocus: true,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: group,
                decoration: const InputDecoration(labelText: 'Muscle group'),
                items: groups
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (v) =>
                    setDialogState(() => group = v ?? group),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: equipment,
                decoration: const InputDecoration(labelText: 'Equipment'),
                items: _equipmentOptions
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) =>
                    setDialogState(() => equipment = v ?? equipment),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (saved == true && nameCtrl.text.trim().isNotEmpty && mounted) {
      await widget.repository.addCustomExercise(
        name: nameCtrl.text.trim(),
        muscleGroup: group,
        equipment: equipment,
      );
      _load();
    }
    nameCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final groups = <String, List<Exercise>>{};
    for (final e in _exercises) {
      groups.putIfAbsent(e.muscleGroup, () => []).add(e);
    }
    final groupNames = groups.keys.toList()..sort();

    return Scaffold(
      body: ListView.builder(
        itemCount: groupNames.length,
        itemBuilder: (context, index) {
          final groupName = groupNames[index];
          final items = groups[groupName]!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text(
                  groupName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              for (final e in items)
                ListTile(
                  leading: const Icon(Icons.fitness_center),
                  title: Text(e.name),
                  subtitle: Text(e.equipment),
                  trailing: e.isCustom
                      ? const Chip(label: Text('Custom'))
                      : null,
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add),
        label: const Text('Custom'),
      ),
    );
  }
}
