import 'package:flutter/material.dart';

import '../models/exercise.dart';
import '../models/personal_record.dart';
import '../services/workout_repository.dart';
import '../services/workout_stats.dart';
import 'widgets/charts.dart';

/// Progress charts: estimated-1RM trend per exercise and volume per day,
/// drawn with CustomPainters (no chart dependency).
class ProgressTab extends StatefulWidget {
  const ProgressTab({
    super.key,
    required this.repository,
    required this.refresh,
  });

  final WorkoutRepository repository;
  final ValueNotifier<int> refresh;

  @override
  State<ProgressTab> createState() => _ProgressTabState();
}

class _ProgressTabState extends State<ProgressTab> {
  List<Exercise> _exercises = [];
  String? _selectedId;
  List<DailyPoint> _e1rm = [];
  List<DailyPoint> _volume = [];
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
    final exercises = await widget.repository.listExercises();
    if (!mounted) return;
    String? selectedId = _selectedId;
    if (selectedId == null ||
        exercises.every((e) => e.id != selectedId)) {
      Exercise? preferred;
      for (final e in exercises) {
        if (e.id == 'bench-press') preferred = e;
      }
      selectedId = (preferred ?? (exercises.isEmpty ? null : exercises.first))
          ?.id;
    }
    const stats = WorkoutStats();
    final sets = selectedId == null
        ? const <DailyPoint>[]
        : stats.bestE1rmByDay(
            await widget.repository.setsForExercise(selectedId),
          );
    final sessions = await widget.repository.listSessions(limit: 200);
    final volume = stats.volumeByDay(sessions);
    final prs = selectedId == null
        ? <PersonalRecord>[]
        : await widget.repository.listPrs(selectedId);
    if (!mounted) return;
    setState(() {
      _exercises = exercises;
      _selectedId = selectedId;
      _e1rm = sets;
      _volume = volume.length > 14
          ? volume.sublist(volume.length - 14)
          : volume;
      _prs = prs;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_exercises.isEmpty) {
      return const Center(child: Text('No exercises found.'));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        DropdownButton<String>(
          value: _selectedId,
          isExpanded: true,
          items: _exercises
              .map((e) => DropdownMenuItem(value: e.id, child: Text(e.name)))
              .toList(),
          onChanged: (id) {
            setState(() => _selectedId = id);
            _load();
          },
        ),
        const SizedBox(height: 8),
        if (_prs.isNotEmpty)
          Wrap(
            spacing: 8,
            children: _prs
                .take(2)
                .map(
                  (pr) => Chip(
                    avatar: const Icon(Icons.emoji_events, size: 18),
                    label: Text(
                      '${pr.label}: ${pr.value.toStringAsFixed(1)} kg',
                    ),
                  ),
                )
                .toList(),
          ),
        const SizedBox(height: 8),
        _ChartCard(
          title: 'Estimated 1RM trend',
          subtitle: 'Best Epley 1RM per day',
          child: TrendChart(points: _e1rm, unit: 'kg'),
        ),
        const SizedBox(height: 12),
        _ChartCard(
          title: 'Volume per day',
          subtitle: 'Total kg lifted · last 14 days with data',
          child: VolumeBars(points: _volume, unit: 'kg'),
        ),
      ],
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}
