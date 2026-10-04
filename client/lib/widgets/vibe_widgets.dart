import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:clubsy/data/classes/check_in_model.dart';
import 'package:clubsy/src/core/controllers/club_controller.dart';

/// Five tappable stars; [value] of them are filled.
class VibeStars extends StatelessWidget {
  final int? value;
  final ValueChanged<int> onSelected;

  const VibeStars({super.key, this.value, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          IconButton(
            key: Key('vibe_star_$i'),
            tooltip: '$i of 5',
            icon: Icon(
              i <= (value ?? 0) ? Icons.star : Icons.star_border,
              color: Colors.amber,
            ),
            onPressed: () => onSelected(i),
          ),
      ],
    );
  }
}

/// One-tap "How was the club?" card shown on the map the morning after.
class VibePromptCard extends StatelessWidget {
  final CheckInModel checkIn;
  final ValueChanged<int> onRate;
  final VoidCallback onDismiss;

  const VibePromptCard({
    super.key,
    required this.checkIn,
    required this.onRate,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const Key('vibe_prompt_card'),
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'How was ${checkIn.club.name}?',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  key: const Key('vibe_prompt_dismiss'),
                  tooltip: 'Not now',
                  icon: const Icon(Icons.close),
                  onPressed: onDismiss,
                ),
              ],
            ),
            VibeStars(onSelected: onRate),
          ],
        ),
      ),
    );
  }
}

/// Edits the private note and vibe of [checkIn] from history.
Future<void> showDiaryEditor(BuildContext context, CheckInModel checkIn) async {
  final controller = Get.find<ClubController>();
  final noteController = TextEditingController(text: checkIn.note ?? '');
  var vibe = checkIn.vibe;
  final canRate =
      DateTime.now().difference(checkIn.checkedInAt) <= const Duration(days: 7);
  final save = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(checkIn.club.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canRate)
              VibeStars(
                value: vibe,
                onSelected: (v) => setState(() => vibe = v),
              ),
            TextField(
              key: const Key('diary_note'),
              controller: noteController,
              maxLength: 280,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Private note',
                helperText: 'Only you can see this',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            key: const Key('diary_save'),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
  final note = noteController.text;
  noteController.dispose();
  if (save != true) return;
  try {
    await controller.updateDiary(
      checkIn.id,
      note: note == (checkIn.note ?? '') ? null : note,
      vibe: vibe == checkIn.vibe ? null : vibe,
    );
  } catch (_) {
    Get.snackbar('Error', "Couldn't save. Try again.");
  }
}
