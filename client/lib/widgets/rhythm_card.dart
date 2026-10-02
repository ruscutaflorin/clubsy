import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:clubsy/data/classes/going_out_rhythm.dart';
import 'package:clubsy/src/core/controllers/club_controller.dart';

const _weekdayNames = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];
const _weekdayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

/// "Your rhythm" card: which nights the user goes out and when they arrive.
class RhythmCard extends StatelessWidget {
  const RhythmCard({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ClubController>()) return const SizedBox.shrink();
    final controller = Get.find<ClubController>();
    return Obx(() {
      final rhythm = goingOutRhythm(controller.myCheckIns.toList());
      if (rhythm == null) return const SizedBox.shrink();
      final max = rhythm.nightsByWeekday.fold<int>(0, (m, n) => n > m ? n : m);
      final arrival = rhythm.typicalArrival;
      final time =
          '${arrival.hour.toString().padLeft(2, '0')}:${arrival.minute.toString().padLeft(2, '0')}';
      return Card(
        key: const Key('rhythmCard'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your rhythm',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text('Mostly ${_weekdayNames[rhythm.topWeekday]}s'),
              Text('Usually in by $time'),
              const SizedBox(height: 12),
              SizedBox(
                height: 60,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < 7; i++)
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              height: max == 0
                                  ? 2
                                  : 2 + 38 * rhythm.nightsByWeekday[i] / max,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _weekdayLetters[i],
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
