import 'package:flutter/material.dart';

import '../models/exercise.dart';
import '../models/personal_record.dart';
import '../models/workout_session.dart';
import '../services/workout_repository.dart';
import 'widgets/format.dart';

/// Workout history: past sessions with per-set breakdowns, plus a
/// personal-record viewer per exercise.
class HistoryTab extends StatefulWidget {
  const HistoryTab({
    super.key,
    required this.repository,
    required this.refresh,
  });

  final WorkoutRepository repository;
  final ValueNotifier<int> refresh;

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  List<WorkoutSession> _sessions = [];
  List<Exercise> _exercises = [];
  String? _prExerciseId;
  List<PersonalRecord> _prs = [];
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
    final sessions = await widget.repository.listSessions();
    final exercises = await widget.repository.listExercises();
    if (!mounted) return;
    String? prId = _prExerciseId;
    if (prId == null || exercises.every((e) => e.id != prId)) {
      prId = exercises.isEmpty ? null : exercises.first.id;
    }
    final prs = prId == null
        ? <PersonalRecord>[]
        : await widget.repository.listPrs(prId);
    if (!mounted) return;
    setState(() {
      _sessions = sessions;
      _exercises = exercises;
      _prExerciseId = prId;
      _prs = prs;
      _loading = false;
    });
  }

  void _showSession(WorkoutSession session) {
    final names = {for (final e in _exercises) e.id: e.name};
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(formatDateTime(session.startedAt)),
        content: SizedBox(
          width: double.maxFinite,
          child: session.sets.isEmpty
              ? const Text('No sets logged.')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: session.sets.length,
                  itemBuilder: (context, index) {
                    final set = session.sets[index];
                    return ListTile(
                      dense: true,
                      title: Text(names[set.exerciseId] ?? set.exerciseId),
                      trailing: Text(
                        '${set.reps} × ${set.weightKg.toStringAsFixed(1)} kg',
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Personal records',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (_exercises.isNotEmpty)
          DropdownButton<String>(
            value: _prExerciseId,
            isExpanded: true,
            items: _exercises
                .map((e) => DropdownMenuItem(value: e.id, child: Text(e.name)))
                .toList(),
            onChanged: (id) {
              setState(() => _prExerciseId = id);
              _load();
            },
          ),
        if (_prs.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('No PRs yet — log a workout and set one!'),
          )
        else
          for (final pr in _prs)
            ListTile(
              leading: const Icon(Icons.emoji_events),
              title: Text(pr.label),
              subtitle: Text(formatDateTime(pr.achievedAt)),
              trailing: Text(
                '${pr.value.toStringAsFixed(1)} kg × ${pr.reps}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
        const Divider(height: 32),
        Text(
          'Sessions',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (_sessions.isEmpty)
          const Text('No workouts logged yet.'),
        for (final session in _sessions)
          Card(
            child: ListTile(
              title: Text(formatDateTime(session.startedAt)),
              subtitle: Text(
                '${session.totalSets} sets · '
                '${session.totalVolume.toStringAsFixed(0)} kg volume',
              ),
              trailing: session.isActive
                  ? const Chip(label: Text('Active'))
                  : const Icon(Icons.chevron_right),
              onTap: () => _showSession(session),
            ),
          ),
      ],
    );
  }
}
