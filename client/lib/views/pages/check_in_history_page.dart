import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:clubsy/src/core/controllers/club_controller.dart';

class CheckInHistoryPage extends StatelessWidget {
  const CheckInHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final clubController = Get.find<ClubController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Check-in history')),
      body: RefreshIndicator(
        onRefresh: clubController.refresh,
        child: Obx(() {
          final checkIns = clubController.myCheckIns;

          if (checkIns.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 120),
                Center(child: Text('No check-ins yet. Go find a club!')),
              ],
            );
          }

          return ListView.builder(
            itemCount: checkIns.length,
            itemBuilder: (context, index) {
              final checkIn = checkIns[index];
              return ListTile(
                leading: const Icon(Icons.local_bar),
                title: Text(checkIn.club.name),
                subtitle: Text('${checkIn.club.city} · ${checkIn.checkedInAt.toLocal()}'),
              );
            },
          );
        }),
      ),
    );
  }
}
