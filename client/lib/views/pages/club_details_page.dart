import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:clubsy/data/classes/club_model.dart';
import 'package:clubsy/data/classes/visit_summary.dart';
import 'package:clubsy/src/core/controllers/club_controller.dart';
import 'package:clubsy/views/pages/check_in_primer_page.dart';

class ClubDetailsPage extends StatelessWidget {
  final ClubModel club;

  const ClubDetailsPage({super.key, required this.club});

  @override
  Widget build(BuildContext context) {
    final clubController = Get.find<ClubController>();

    return Scaffold(
      appBar: AppBar(title: Text(club.name)),
      body: Obx(() {
        final summary = clubController.visitSummaryFor(club.id);
        final isVisited = summary != null;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  club.imageUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                club.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text('${club.address}, ${club.city}'),
              const SizedBox(height: 8),
              if (isVisited) ...[
                const Chip(
                  avatar: Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: Text('Checked in before'),
                  backgroundColor: Colors.green,
                  labelStyle: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  summary.visits == 1
                      ? '1 visit · on ${formatShortDate(summary.firstVisit)}'
                      : '${summary.visits} visits · last on '
                            '${formatShortDate(summary.lastVisit)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Check in'),
                  onPressed: () => openCheckIn(club),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
