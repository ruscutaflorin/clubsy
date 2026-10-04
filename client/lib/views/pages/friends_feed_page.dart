import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:clubsy/src/core/controllers/feed_controller.dart';

class FriendsFeedPage extends StatefulWidget {
  const FriendsFeedPage({super.key});

  @override
  State<FriendsFeedPage> createState() => _FriendsFeedPageState();
}

class _FriendsFeedPageState extends State<FriendsFeedPage> {
  late final FeedController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<FeedController>()
        ? Get.find<FeedController>()
        : Get.put(FeedController());
    controller.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Friends' nights")),
      body: Obx(() {
        if (controller.nights.isEmpty) {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                controller.error.value ??
                    'Nothing here yet. Nights show up the morning after, when '
                        'you and your friend both share your nights.',
                key: const Key('feedEmpty'),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return ListView(
          children: [
            for (final n in controller.nights)
              ListTile(
                leading: const Icon(Icons.nightlife),
                title: Text(n.clubName),
                subtitle: Text(
                  '${n.friendLabel} · ${n.nightDate}'
                  '${n.city != null ? ' · ${n.city}' : ''}',
                ),
              ),
            if (controller.hasMore.value)
              TextButton(
                key: const Key('feedLoadMore'),
                onPressed: controller.loadMore,
                child: const Text('Load more'),
              ),
          ],
        );
      }),
    );
  }
}
