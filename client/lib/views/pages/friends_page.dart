import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:clubsy/data/classes/friend_model.dart';
import 'package:clubsy/src/core/controllers/friend_controller.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  final _username = TextEditingController();
  late final FriendController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<FriendController>()
        ? Get.find<FriendController>()
        : Get.put(FriendController());
    controller.load();
  }

  @override
  void dispose() {
    _username.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (await controller.sendRequest(_username.text)) _username.clear();
  }

  Widget _section(
    String title,
    List<FriendEntry> entries,
    Widget Function(FriendEntry) actions,
  ) {
    if (entries.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        for (final e in entries)
          ListTile(
            leading: const Icon(Icons.person),
            title: Text(e.label),
            subtitle: e.username != null ? Text(e.name) : null,
            trailing: actions(e),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Friends')),
      body: RefreshIndicator(
        onRefresh: controller.load,
        child: Obx(
          () => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('friendUsernameField'),
                        controller: _username,
                        autocorrect: false,
                        decoration: const InputDecoration(
                          labelText: 'Add by exact username',
                          prefixText: '@',
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    IconButton(
                      key: const Key('sendFriendRequestButton'),
                      icon: const Icon(Icons.person_add),
                      onPressed: _send,
                    ),
                  ],
                ),
              ),
              if (controller.notice.value != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(controller.notice.value!),
                ),
              if (controller.error.value != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    controller.error.value!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              _section(
                'Requests (${controller.incoming.length})',
                controller.incoming.toList(),
                (e) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check),
                      tooltip: 'Accept',
                      onPressed: () => controller.accept(e),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: 'Decline',
                      onPressed: () => controller.decline(e),
                    ),
                  ],
                ),
              ),
              _section(
                'Sent',
                controller.outgoing.toList(),
                (e) => TextButton(
                  onPressed: () => controller.cancel(e),
                  child: const Text('Cancel'),
                ),
              ),
              _section(
                'Friends (${controller.friends.length})',
                controller.friends.toList(),
                (e) => IconButton(
                  icon: const Icon(Icons.person_remove),
                  tooltip: 'Unfriend',
                  onPressed: () => controller.unfriend(e),
                ),
              ),
              if (!controller.isLoading.value &&
                  controller.friends.isEmpty &&
                  controller.incoming.isEmpty &&
                  controller.outgoing.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text('No friends yet. Add someone by username.'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
