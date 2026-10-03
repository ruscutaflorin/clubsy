import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:clubsy/data/classes/personal_records.dart';
import 'package:clubsy/src/core/controllers/club_controller.dart';

const _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

String _plural(int n, String word) => '$n $word${n == 1 ? '' : 's'}';

String _date(DateTime d) =>
    '${d.day} ${_monthNames[d.month - 1].substring(0, 3)} ${d.year}';

/// "Your records" card: personal bests from the user's own check-ins.
class PersonalRecordsCard extends StatelessWidget {
  const PersonalRecordsCard({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ClubController>()) return const SizedBox.shrink();
    final controller = Get.find<ClubController>();
    return Obx(() {
      final r = personalRecords(controller.myCheckIns.toList());
      if (r == null) return const SizedBox.shrink();
      final biggest = r.biggestNight;
      final busiest = r.busiestMonth;
      final rows = [
        'Biggest night: ${_plural(biggest.clubs, 'club')} · ${_date(biggest.night)}',
        'Busiest month: ${_plural(busiest.nights, 'night')} · ${_monthNames[busiest.month - 1]} ${busiest.year}',
        'First night out: ${_date(r.firstNight)}',
        'Most nights in: ${r.mostVisitedCity}',
      ];
      return Card(
        key: const Key('personalRecordsCard'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your records',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              for (final row in rows) ...[const SizedBox(height: 8), Text(row)],
            ],
          ),
        ),
      );
    });
  }
}
