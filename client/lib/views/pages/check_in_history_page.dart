import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:clubsy/src/core/controllers/club_controller.dart';
import 'package:clubsy/widgets/error_banner_widget.dart';

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
          final error = clubController.loadError.value;
          final banner = error == null
              ? null
              : ErrorBanner(
                  error: error,
                  savedAt: clubController.dataSavedAt.value,
                  onRetry: clubController.refresh,
                );

          if (checkIns.isEmpty) {
            return ListView(
              children: [
                ?banner,
                const SizedBox(height: 120),
                Center(
                  child: Text(
                    error != null ? "Couldn't load your check-ins" : "No check-ins yet — scan a club's QR to add your first pin",
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            );
          }

          return ListView.builder(
            itemCount: checkIns.length + (banner == null ? 0 : 1),
            itemBuilder: (context, index) {
              if (banner != null) {
                if (index == 0) return banner;
                index -= 1;
              }
              final checkIn = checkIns[index];
              return ListTile(
                leading: const Icon(Icons.local_bar),
                title: Text(checkIn.club.name),
                subtitle: Text(
                  '${checkIn.club.city} · ${checkIn.checkedInAt.toLocal()}',
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
