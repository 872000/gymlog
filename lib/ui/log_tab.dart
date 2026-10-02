import 'package:flutter/material.dart';

import '../models/exercise.dart';
import '../models/workout_session.dart';
import '../services/pr_calculator.dart';
import '../services/workout_repository.dart';
import 'widgets/format.dart';

/// Active workout logging: start a session, add sets (reps × weight),
/// get automatic PR celebrations, finish the session.
class LogTab extends StatefulWidget {
  const LogTab({super.key, required this.repository, required this.refresh});

  final WorkoutRepository repository;
  final ValueNotifier<int> refresh;

  @override
  State<LogTab> createState() => _LogTabState();
}

class _LogTabState extends State<LogTab> {
  List<Exercise> _exercises = [];
  WorkoutSession? _active;
  Exercise? _selected;
  final _repsCtrl = TextEditingController(text: '8');
  final _weightCtrl = TextEditingController(text: '60');
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    widget.refresh.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    widget.refresh.removeListener(_load);
    _repsCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final exercises = await widget.repository.listExercises();
    final sessions = await widget.repository.listSessions(limit: 5);
    final active = sessions.where((s) => s.isActive);
    if (!mounted) return;
    Exercise? preferred;
    for (final e in exercises) {
      if (e.id == 'bench-press') preferred = e;
    }
    setState(() {
      _exercises = exercises;
      _selected = exercises.isEmpty ? null : (preferred ?? exercises.first);
      _active = active.isEmpty ? null : active.first;
      _loading = false;
    });
  }

  Future<void> _start() async {
    final session = await widget.repository.startSession();
    if (!mounted) return;
    setState(() => _active = session);
  }

  Future<void> _finish() async {
    final active = _active;
    if (active == null) return;
    await widget.repository.finishSession(active.id);
    if (!mounted) return;
    setState(() => _active = null);
    widget.refresh.value++;
  }

  Future<void> _addSet() async {
    final exercise = _selected;
    final active = _active;
    if (exercise == null || active == null) return;
    final reps = int.tryParse(_repsCtrl.text.trim());
    final weight = double.tryParse(_weightCtrl.text.trim());
    if (reps == null || reps <= 0 || weight == null || weight <= 0) {
      setState(() => _error = 'Enter reps and weight above zero.');
      return;
    }
    setState(() => _error = null);

    final set = await widget.repository.logSet(
      sessionId: active.id,
      exerciseId: exercise.id,
      reps: reps,
      weightKg: weight,
    );
    final history = await widget.repository.listPrs(exercise.id);
    final prs = const PrCalculator().detectPrs(
      exerciseId: exercise.id,
      newSets: [set],
      history: history,
      now: DateTime.now(),
    );
    for (final pr in prs) {
      await widget.repository.recordPr(pr);
    }
    final updated = await widget.repository.getSession(active.id);
    if (!mounted) return;
    setState(() => _active = updated);
    if (prs.isNotEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'New PR! ${prs.map((p) => '${p.label}: ${p.value.toStringAsFixed(1)} kg').join(' · ')}',
          ),
        ),
      );
    }
  }

  Future<void> _deleteSet(String setId) async {
    await widget.repository.deleteSet(setId);
    final active = _active;
    if (active == null || !mounted) return;
    final updated = await widget.repository.getSession(active.id);
    if (!mounted) return;
    setState(() => _active = updated);
  }

  String _trim(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  void _bump(TextEditingController ctrl, double delta) {
    final v = (double.tryParse(ctrl.text.trim()) ?? 0) + delta;
    ctrl.text = _trim(v.clamp(0, 10000));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final active = _active;
    if (active == null) return _buildStartCard();
    return _buildLogger(active);
  }

  Widget _buildStartCard() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.fitness_center, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Ready to train?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Start a workout and log every set. GymLog tracks your '
              'volume and spots personal records automatically.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _start,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start workout'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogger(WorkoutSession active) {
    final names = {for (final e in _exercises) e.id: e.name};
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButton<Exercise>(
                    value: _selected,
                    isExpanded: true,
                    items: _exercises
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text('${e.name} (${e.muscleGroup})'),
                          ),
                        )
                        .toList(),
                    onChanged: (e) => setState(() => _selected = e),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _numberField(
                        controller: _repsCtrl,
                        label: 'Reps',
                        step: 1,
                        decimal: false,
                      ),
                      const SizedBox(width: 12),
                      _numberField(
                        controller: _weightCtrl,
                        label: 'Weight (kg)',
                        step: 2.5,
                        decimal: true,
                      ),
                    ],
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: _addSet,
                    icon: const Icon(Icons.add),
                    label: const Text('Log set'),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              Text(
                '${active.totalSets} sets · ${active.totalVolume.toStringAsFixed(0)} kg volume',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _finish,
                icon: const Icon(Icons.check),
                label: const Text('Finish workout'),
              ),
            ],
          ),
        ),
        Expanded(
          child: active.sets.isEmpty
              ? const Center(child: Text('No sets yet — log your first one.'))
              : ListView.builder(
                  itemCount: active.sets.length,
                  itemBuilder: (context, index) {
                    final set = active.sets[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text('${index + 1}'),
                      ),
                      title: Text(names[set.exerciseId] ?? set.exerciseId),
                      subtitle: Text(
                        '${set.reps} reps × ${_trim(set.weightKg)} kg · ${formatDateTime(set.loggedAt)}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Delete set',
                        onPressed: () => _deleteSet(set.id),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _numberField({
    required TextEditingController controller,
    required String label,
    required double step,
    required bool decimal,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: () => _bump(controller, -step),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.numberWithOptions(
                    decimal: decimal,
                  ),
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _bump(controller, step),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
