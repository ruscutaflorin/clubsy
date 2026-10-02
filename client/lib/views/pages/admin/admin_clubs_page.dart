import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:clubsy/src/core/controllers/admin_controller.dart';
import 'package:clubsy/views/pages/admin/admin_club_form_page.dart';
import 'package:clubsy/views/pages/admin/admin_club_qr_page.dart';

class AdminClubsPage extends StatefulWidget {
  const AdminClubsPage({super.key});

  @override
  State<AdminClubsPage> createState() => _AdminClubsPageState();
}

class _AdminClubsPageState extends State<AdminClubsPage> {
  late final AdminController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<AdminController>()
        ? Get.find<AdminController>()
        : Get.put(AdminController());
    controller.load();
  }

  Widget _chip(String label, int count, AdminClubFilter value) => ChoiceChip(
    label: Text('$label ($count)'),
    selected: controller.filter.value == value,
    onSelected: (_) => controller.filter.value = value,
  );

  Future<void> _toggle(String id, bool approved) async {
    final ok = await controller.setApproved(id, approved);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(controller.actionError.value ?? 'Failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin · Clubs')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('adminAddClub'),
        onPressed: () => Get.to(() => const AdminClubFormPage()),
        icon: const Icon(Icons.add),
        label: const Text('Add club'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Obx(
              () => Wrap(
                spacing: 8,
                children: [
                  _chip('All', controller.allCount, AdminClubFilter.all),
                  _chip(
                    'Pending',
                    controller.pendingCount,
                    AdminClubFilter.pending,
                  ),
                  _chip(
                    'Approved',
                    controller.approvedCount,
                    AdminClubFilter.approved,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.clubs.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              final error = controller.loadError.value;
              if (error != null && controller.clubs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(error),
                      TextButton(
                        onPressed: controller.load,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }
              final items = controller.filtered;
              if (items.isEmpty) {
                return const Center(child: Text('No clubs here'));
              }
              return RefreshIndicator(
                onRefresh: controller.load,
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final club = items[i];
                    return ListTile(
                      key: Key('adminClub-${club.id}'),
                      title: Text(club.name),
                      subtitle: Row(
                        children: [
                          Flexible(child: Text(club.city)),
                          const SizedBox(width: 8),
                          Chip(
                            visualDensity: VisualDensity.compact,
                            label: Text(
                              club.isApproved ? 'Approved' : 'Pending',
                            ),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            key: Key('adminEdit-${club.id}'),
                            icon: const Icon(Icons.edit),
                            tooltip: 'Edit',
                            onPressed: () =>
                                Get.to(() => AdminClubFormPage(club: club)),
                          ),
                          Switch(
                            value: club.isApproved,
                            onChanged: (v) => _toggle(club.id, v),
                          ),
                        ],
                      ),
                      onTap: () => Get.to(() => AdminClubQrPage(club: club)),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
