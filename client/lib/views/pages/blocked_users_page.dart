import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:clubsy/src/core/controllers/friend_controller.dart';

class BlockedUsersPage extends StatefulWidget {
  const BlockedUsersPage({super.key});

  @override
  State<BlockedUsersPage> createState() => _BlockedUsersPageState();
}

class _BlockedUsersPageState extends State<BlockedUsersPage> {
  late final FriendController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<FriendController>()
        ? Get.find<FriendController>()
        : Get.put(FriendController());
    controller.loadBlocked();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Blocked users')),
      body: Obx(() {
        if (controller.blocked.isEmpty) {
          return const Center(child: Text('You have not blocked anyone.'));
        }
        return ListView(
          children: [
            for (final b in controller.blocked)
              ListTile(
                leading: const Icon(Icons.block),
                title: Text(b.label),
                trailing: TextButton(
                  key: Key('unblock-${b.userId}'),
                  onPressed: () => controller.unblock(b),
                  child: const Text('Unblock'),
                ),
              ),
          ],
        );
      }),
    );
  }
}
