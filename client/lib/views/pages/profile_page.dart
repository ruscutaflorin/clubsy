import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:clubsy/data/classes/check_in_stats_model.dart';
import 'package:clubsy/src/core/controllers/auth_controller.dart';
import 'package:clubsy/src/core/controllers/club_controller.dart';
import 'package:clubsy/src/core/controllers/theme_controller.dart';
import 'package:clubsy/widgets/error_banner_widget.dart';

/// A single stat in the Profile stats card: a number and the label under it.
class ProfileStatTile extends StatelessWidget {
  final String value;
  final String label;

  const ProfileStatTile({super.key, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

/// Summary of a user's personal map: clubs visited, cities, and their favourite
/// spot. Renders nothing meaningful from an empty-history [CheckInStatsModel]
/// beyond zeros, which is the correct state for a brand-new user.
class ProfileStatsCard extends StatelessWidget {
  final CheckInStatsModel stats;

  const ProfileStatsCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('profileStatsCard'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Theme.of(context).cardColor,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ProfileStatTile(
                value: '${stats.totalCheckIns}',
                label: 'Check-ins',
              ),
              ProfileStatTile(value: '${stats.uniqueClubs}', label: 'Clubs'),
              ProfileStatTile(value: '${stats.uniqueCities}', label: 'Cities'),
            ],
          ),
          if (stats.mostVisitedClub != null) ...[
            const SizedBox(height: 16),
            Text(
              'Most visited: ${stats.mostVisitedClub!.name} '
              '(${stats.mostVisitedClub!.visits} visits)',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final themeController = Get.find<ThemeController>();
    final clubController = Get.find<ClubController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          Obx(
            () => IconButton(
              onPressed: () => themeController.toggleTheme(),
              icon: Icon(
                themeController.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Theme.of(context).cardColor,
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  child: Obx(
                    () => Text(
                      authController.user?['name']
                              ?.substring(0, 1)
                              .toUpperCase() ??
                          'U',
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Obx(
                  () => Text(
                    authController.user?['name'] ?? 'User',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Obx(() => Text(authController.user?['email'] ?? '')),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Obx(() {
            final stats = clubController.stats.value;
            final error = clubController.loadError.value;
            return Column(
              children: [
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ErrorBanner(
                      error: error,
                      savedAt: clubController.dataSavedAt.value,
                      onRetry: clubController.refresh,
                    ),
                  ),
                if (stats != null)
                  ProfileStatsCard(stats: stats)
                else if (error == null)
                  const Text(
                    "No stats yet — scan a club's QR to add your first pin",
                    textAlign: TextAlign.center,
                  ),
              ],
            );
          }),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await authController.signOut();
              Get.offAllNamed('/login');
            },
          ),
        ],
      ),
    );
  }
}
