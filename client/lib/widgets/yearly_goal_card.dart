import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clubsy/data/classes/yearly_goal.dart';
import 'package:clubsy/src/core/controllers/club_controller.dart';

String yearlyGoalKey(int year) => 'yearly_goal_$year';

/// A personal nights-out goal for the year, kept on this device only.
class YearlyGoalCard extends StatefulWidget {
  final DateTime? now;

  const YearlyGoalCard({super.key, this.now});

  @override
  State<YearlyGoalCard> createState() => _YearlyGoalCardState();
}

class _YearlyGoalCardState extends State<YearlyGoalCard> {
  late final DateTime _now = widget.now ?? DateTime.now();
  int? _goal;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final goal = prefs.getInt(yearlyGoalKey(_now.year));
    if (mounted) setState(() => _goal = goal);
  }

  Future<void> _edit() async {
    final value = await showDialog<int>(
      context: context,
      builder: (_) => _GoalDialog(initial: _goal, year: _now.year),
    );
    if (value == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(yearlyGoalKey(_now.year), value);
    if (mounted) setState(() => _goal = value);
  }

  @override
  Widget build(BuildContext context) {
    final goal = _goal;
    if (goal == null) {
      return Card(
        child: ListTile(
          title: Text('Set a goal for ${_now.year}'),
          trailing: TextButton(
            key: const Key('setYearlyGoal'),
            onPressed: _edit,
            child: const Text('Set goal'),
          ),
        ),
      );
    }
    final controller = Get.find<ClubController>();
    return Obx(() {
      final p = yearlyGoalProgress(controller.myCheckIns, goal, _now);
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      goalHeadline(p),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    key: const Key('editYearlyGoal'),
                    icon: const Icon(Icons.edit),
                    onPressed: _edit,
                  ),
                ],
              ),
              LinearProgressIndicator(
                value: (p.nightsSoFar / p.goal).clamp(0.0, 1.0),
              ),
              const SizedBox(height: 8),
              Text(goalPaceLine(p)),
            ],
          ),
        ),
      );
    });
  }
}

class _GoalDialog extends StatefulWidget {
  final int? initial;
  final int year;

  const _GoalDialog({required this.initial, required this.year});

  @override
  State<_GoalDialog> createState() => _GoalDialogState();
}

class _GoalDialogState extends State<_GoalDialog> {
  late final _controller = TextEditingController(
    text: widget.initial?.toString() ?? '',
  );
  String? _error;

  void _save() {
    final n = int.tryParse(_controller.text.trim());
    if (n == null || n < 1 || n > 365) {
      setState(() => _error = 'Enter a number from 1 to 365');
      return;
    }
    Navigator.of(context).pop(n);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Nights out in ${widget.year}'),
      content: TextField(
        key: const Key('yearlyGoalField'),
        controller: _controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(labelText: 'Goal', errorText: _error),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('saveYearlyGoal'),
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
