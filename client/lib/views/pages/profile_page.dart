import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:clubsy/data/classes/check_in_stats_model.dart';
import 'package:clubsy/data/classes/genre_taste.dart';
import 'package:clubsy/src/core/controllers/auth_controller.dart';
import 'package:clubsy/src/core/controllers/club_controller.dart';
import 'package:clubsy/src/core/controllers/theme_controller.dart';
import 'package:clubsy/services/api_client.dart';
import 'package:clubsy/services/data_export_service.dart';
import 'package:clubsy/views/pages/achievements_page.dart';
import 'package:clubsy/views/pages/admin/admin_clubs_page.dart';
import 'package:clubsy/views/pages/change_password_page.dart';
import 'package:clubsy/views/pages/edit_profile_page.dart';
import 'package:clubsy/views/pages/blocked_users_page.dart';
import 'package:clubsy/views/pages/friends_page.dart';
import 'package:clubsy/views/pages/friends_feed_page.dart';
import 'package:clubsy/src/core/controllers/friend_controller.dart';
import 'package:clubsy/views/pages/legal_page.dart';
import 'package:clubsy/views/pages/my_cities_page.dart';
import 'package:clubsy/views/pages/recap_page.dart';
import 'package:clubsy/views/pages/want_to_go_page.dart';
import 'package:clubsy/widgets/been_a_while_card.dart';
import 'package:clubsy/widgets/error_banner_widget.dart';
import 'package:clubsy/widgets/map_milestones_card.dart';
import 'package:clubsy/widgets/next_goals_card.dart';
import 'package:clubsy/widgets/personal_records_card.dart';
import 'package:clubsy/widgets/privacy_section.dart';
import 'package:clubsy/widgets/rhythm_card.dart';
import 'package:clubsy/widgets/streak_nudge_banner.dart';

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

Future<void> _exportMyData() => _runExport((s) => s.exportMyData());

Future<void> _exportMyCheckInsCsv() =>
    _runExport((s) => s.exportMyCheckInsCsv());

Future<void> _runExport(
  Future<void> Function(DataExportService service) run,
) async {
  final service = Get.isRegistered<DataExportService>()
      ? Get.find<DataExportService>()
      : DataExportService();
  try {
    await run(service);
  } catch (e) {
    Get.snackbar(
      'Export failed',
      e is ApiException ? e.message : "Couldn't export your data",
    );
  }
}

/// Confirm dialog for account deletion. Pops `true` once the account is gone.
class DeleteAccountDialog extends StatefulWidget {
  const DeleteAccountDialog({super.key});

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await Get.find<AuthController>().deleteAccount(_password.text);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e is ApiException && e.statusCode == 401
            ? 'Wrong password'
            : e is ApiException
            ? e.message
            : "Couldn't delete your account";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete account?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This permanently deletes your account and every check-in on '
              'your map. This can\'t be undone.',
            ),
            TextButton.icon(
              key: const Key('deleteAccountExport'),
              onPressed: _exportMyData,
              icon: const Icon(Icons.download_outlined),
              label: const Text('Download my data first'),
            ),
            TextField(
              key: const Key('deleteAccountPassword'),
              controller: _password,
              obscureText: true,
              enabled: !_busy,
              decoration: InputDecoration(
                labelText: 'Password',
                errorText: _error,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          key: const Key('deleteAccountConfirm'),
          onPressed: _busy || _password.text.isEmpty ? null : _delete,
          child: const Text('Delete', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
}

/// Dialog to edit the display name. Pops `true` once the name is saved.
class EditNameDialog extends StatefulWidget {
  final String initialName;

  const EditNameDialog({super.key, required this.initialName});

  @override
  State<EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<EditNameDialog> {
  late final _name = TextEditingController(text: widget.initialName);
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Name is required');
      return;
    }
    if (name.length > 50) {
      setState(() => _error = 'Name must be at most 50 characters');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await Get.find<AuthController>().updateName(name);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      Navigator.of(context).pop(false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is ApiException ? e.message : "Couldn't update your name",
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change name'),
      content: TextField(
        key: const Key('nameField'),
        controller: _name,
        enabled: !_busy,
        autofocus: true,
        decoration: InputDecoration(labelText: 'Name', errorText: _error),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          key: const Key('nameSave'),
          onPressed: _busy ? null : _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

Widget _friendsTrailing(int pending) => Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    if (pending > 0) Badge(label: Text('$pending')),
    const Icon(Icons.chevron_right),
  ],
);

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
          const StreakNudgeBanner(),
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
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Obx(
                        () => Text(
                          authController.user?['name'] ?? 'User',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      key: const Key('editName'),
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Change name',
                      onPressed: () async {
                        final saved = await showDialog<bool>(
                          context: context,
                          builder: (_) => EditNameDialog(
                            initialName: authController.user?['name'] ?? '',
                          ),
                        );
                        if (saved == true && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Name updated')),
                          );
                        }
                      },
                    ),
                  ],
                ),
                Obx(() {
                  final username = authController.user?['username'];
                  return username == null
                      ? const SizedBox.shrink()
                      : Text('@$username', key: const Key('profileHandle'));
                }),
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
                  GestureDetector(
                    key: const Key('profileStatsCardTap'),
                    onTap: () => Get.to(() => const MyCitiesPage()),
                    child: ProfileStatsCard(stats: stats),
                  )
                else if (error == null)
                  const Text(
                    "No stats yet — scan a club's QR to add your first pin",
                    textAlign: TextAlign.center,
                  ),
              ],
            );
          }),
          Obx(() {
            final text = yourSoundText(
              genreNights(clubController.myCheckIns.toList()),
            );
            if (text == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                text,
                key: const Key('yourSoundText'),
                textAlign: TextAlign.center,
              ),
            );
          }),
          Obx(() {
            final a = clubController.achievements.value;
            if (a == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 12),
              child: AchievementsSummaryTile(
                achievements: a,
                onTap: () => Get.to(() => const AchievementsPage()),
              ),
            );
          }),
          NextGoalsCard(onTap: () => Get.to(() => const AchievementsPage())),
          const PersonalRecordsCard(),
          const MapMilestonesCard(),
          const BeenAWhileCard(),
          const RhythmCard(),
          ListTile(
            key: const Key('recapTile'),
            leading: const Icon(Icons.auto_awesome),
            title: Text('Your ${lastMonthName(DateTime.now())}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Get.to(() => const RecapPage()),
          ),
          ListTile(
            key: const Key('friendsTile'),
            leading: const Icon(Icons.people),
            title: const Text('Friends'),
            trailing: Get.isRegistered<FriendController>()
                ? Obx(
                    () => _friendsTrailing(
                      Get.find<FriendController>().pendingCount,
                    ),
                  )
                : _friendsTrailing(0),
            onTap: () => Get.to(() => const FriendsPage()),
          ),
          ListTile(
            key: const Key('openWantToGo'),
            leading: const Icon(Icons.favorite),
            title: const Text('Want to go'),
            trailing: Obx(
              () => Text('${Get.find<ClubController>().favoriteIds.length}'),
            ),
            onTap: () => Get.to(() => const WantToGoPage()),
          ),
          ListTile(
            key: const Key('friendsFeedTile'),
            leading: const Icon(Icons.nightlife),
            title: const Text("Friends' nights"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Get.to(() => const FriendsFeedPage()),
          ),
          ListTile(
            key: const Key('blockedUsersTile'),
            leading: const Icon(Icons.block),
            title: const Text('Blocked users'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Get.to(() => const BlockedUsersPage()),
          ),
          const SizedBox(height: 24),
          Obx(
            () => authController.isAdmin
                ? ListTile(
                    key: const Key('adminTile'),
                    leading: const Icon(Icons.admin_panel_settings),
                    title: const Text('Admin'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Get.to(() => const AdminClubsPage()),
                  )
                : const SizedBox.shrink(),
          ),
          const PrivacySection(),
          ListTile(
            key: const Key('privacyTile'),
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Get.to(() => const LegalPage.privacy()),
          ),
          ListTile(
            key: const Key('termsTile'),
            leading: const Icon(Icons.description_outlined),
            title: const Text('Terms of Use'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Get.to(() => const LegalPage.terms()),
          ),
          ListTile(
            key: const Key('exportTile'),
            leading: const Icon(Icons.download_outlined),
            title: const Text('Download my data'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _exportMyData,
          ),
          ListTile(
            key: const Key('exportCsvTile'),
            leading: const Icon(Icons.table_chart_outlined),
            title: const Text('Download as spreadsheet (CSV)'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _exportMyCheckInsCsv,
          ),
          ListTile(
            key: const Key('editProfileTile'),
            leading: const Icon(Icons.person_outline),
            title: const Text('Edit profile'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Get.to(() => const EditProfilePage()),
          ),
          ListTile(
            key: const Key('changePasswordTile'),
            leading: const Icon(Icons.lock_outline),
            title: const Text('Change password'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Get.to(() => const ChangePasswordPage()),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await authController.signOut();
              Get.offAllNamed('/login');
            },
          ),
          ListTile(
            key: const Key('signOutAllTile'),
            leading: const Icon(Icons.devices_other, color: Colors.red),
            title: const Text(
              'Sign out of all devices',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () async {
              try {
                await authController.signOutAll();
                Get.offAllNamed('/login');
              } catch (_) {
                Get.snackbar('Error', 'Could not sign out of all devices');
              }
            },
          ),
          ListTile(
            key: const Key('deleteAccountTile'),
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text(
              'Delete account',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () async {
              final deleted = await showDialog<bool>(
                context: context,
                builder: (_) => const DeleteAccountDialog(),
              );
              if (deleted == true) {
                Get.offAllNamed('/login');
                Get.snackbar(
                  'Account deleted',
                  'Your account and history were deleted',
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
