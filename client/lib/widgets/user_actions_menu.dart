import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:clubsy/data/classes/admin_report_model.dart';
import 'package:clubsy/data/classes/friend_model.dart';
import 'package:clubsy/src/core/controllers/friend_controller.dart';

/// Block / report menu for any surface that shows another user.
class UserActionsMenu extends StatelessWidget {
  final FriendEntry entry;

  const UserActionsMenu({super.key, required this.entry});

  FriendController get _controller => Get.isRegistered<FriendController>()
      ? Get.find<FriendController>()
      : Get.put(FriendController());

  Future<void> _block(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Block ${entry.label}?'),
        content: const Text(
          'You will disappear for each other everywhere, and any friendship '
          'or request between you ends. Unblocking will not restore it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            key: const Key('confirmBlock'),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Block'),
          ),
        ],
      ),
    );
    if (ok == true) await _controller.block(entry);
  }

  Future<void> _report(BuildContext context) async {
    var reason = reportReasons.keys.first;
    final details = TextEditingController();
    final send = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('Report ${entry.label}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                key: const Key('reportReason'),
                isExpanded: true,
                value: reason,
                items: [
                  for (final e in reportReasons.entries)
                    DropdownMenuItem(value: e.key, child: Text(e.value)),
                ],
                onChanged: (v) => setState(() => reason = v ?? reason),
              ),
              TextField(
                key: const Key('reportDetails'),
                controller: details,
                maxLength: 500,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Details'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              key: const Key('sendReport'),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Send'),
            ),
          ],
        ),
      ),
    );
    final text = details.text;
    details.dispose();
    if (send != true) return;
    final sent = await _controller.report(entry, reason, details: text);
    Get.snackbar(
      sent ? 'Report sent' : 'Report failed',
      sent
          ? 'Thanks, our team will review it.'
          : (_controller.error.value ?? 'Please try again.'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      key: Key('userActions-${entry.userId}'),
      icon: const Icon(Icons.more_vert),
      onSelected: (v) => v == 'block' ? _block(context) : _report(context),
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'report', child: Text('Report')),
        PopupMenuItem(value: 'block', child: Text('Block')),
      ],
    );
  }
}
