import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:clubsy/data/classes/city_progress_model.dart';
import 'package:clubsy/src/core/controllers/club_controller.dart';
import 'package:clubsy/views/pages/city_checklist_page.dart';

/// Per-city collection progress: visited vs. listed clubs.
class MyCitiesPage extends StatelessWidget {
  const MyCitiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ClubController>();
    return Scaffold(
      appBar: AppBar(title: const Text('My cities')),
      body: Obx(() {
        final cities = controller.cityProgress.toList();
        if (cities.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Check in somewhere to start your collection',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: cities.length,
          separatorBuilder: (_, _) => const SizedBox(height: 16),
          itemBuilder: (_, i) => _CityRow(city: cities[i]),
        );
      }),
    );
  }
}

class _CityRow extends StatelessWidget {
  final CityProgressModel city;

  const _CityRow({required this.city});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: Key('city_${city.city}'),
      onTap: () => Get.to(() => CityChecklistPage(city: city.city)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(city.city, style: Theme.of(context).textTheme.titleMedium),
              Text('${city.visitedClubs} of ${city.totalClubs} clubs'),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: city.fraction),
        ],
      ),
    );
  }
}
