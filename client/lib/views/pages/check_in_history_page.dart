import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:clubsy/src/core/controllers/club_controller.dart';
import 'package:clubsy/data/classes/check_in_grouping.dart';
import 'package:clubsy/data/classes/on_this_night.dart';
import 'package:clubsy/views/pages/club_details_page.dart';
import 'package:clubsy/widgets/error_banner_widget.dart';
import 'package:clubsy/widgets/vibe_widgets.dart';

class CheckInHistoryPage extends StatefulWidget {
  const CheckInHistoryPage({super.key});

  @override
  State<CheckInHistoryPage> createState() => _CheckInHistoryPageState();
}

class _CheckInHistoryPageState extends State<CheckInHistoryPage> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<bool> _confirmRemove(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: const Text(
          "Remove this visit from your map? This can't be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _remove(ClubController controller, String id) async {
    try {
      await controller.removeCheckIn(id);
    } catch (_) {
      Get.snackbar('Error', "Couldn't remove this visit. Try again.");
    }
  }

  Future<void> _toggleHidden(
    ClubController controller,
    String id,
    bool hidden,
  ) async {
    try {
      await controller.setHiddenFromFriends(id, hidden);
    } catch (_) {
      Get.snackbar('Error', "Couldn't update this visit. Try again.");
    }
  }

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

          final searching = _query.trim().isNotEmpty;
          final groups = filterNightGroups(groupByNight(checkIns), _query);
          final summary = searching ? null : monthSummary(checkIns);
          final memories = searching
              ? <NightMemory>[]
              : onThisNight(checkIns, DateTime.now().toLocal());
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              ?banner,
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: TextField(
                  key: const Key('history_search'),
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search clubs or cities',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            key: const Key('history_search_clear'),
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) => setState(() => _query = value),
                ),
              ),
              if (searching)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(
                    groups.isEmpty
                        ? 'No nights match "${_query.trim()}"'
                        : groups.length == 1
                        ? '1 night matches'
                        : '${groups.length} nights match',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              if (summary != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(
                    summary,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              if (memories.isNotEmpty)
                Card(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'On this night',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        for (final memory in memories) ...[
                          const SizedBox(height: 8),
                          Text(
                            memory.label,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          for (final club in memory.clubs)
                            InkWell(
                              onTap: () =>
                                  Get.to(() => ClubDetailsPage(club: club)),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Text(club.name),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              for (final group in groups) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text(
                    formatGroupHeader(group),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                for (final checkIn in group.checkIns)
                  Dismissible(
                    key: ValueKey(checkIn.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (_) => _confirmRemove(context),
                    onDismissed: (_) => _remove(clubController, checkIn.id),
                    child: ListTile(
                      leading: const Icon(Icons.local_bar),
                      title: Text(checkIn.club.name),
                      subtitle: Text(
                        [
                          '${checkIn.club.city} · ${formatTime(checkIn.checkedInAt.toLocal())}',
                          if (checkIn.vibe != null) '★' * checkIn.vibe!,
                          if (checkIn.note != null) checkIn.note!,
                        ].join('\n'),
                      ),
                      isThreeLine: checkIn.vibe != null || checkIn.note != null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            key: Key('hide_from_friends_${checkIn.id}'),
                            tooltip: checkIn.hiddenFromFriends
                                ? 'Hidden from friends (tap to show)'
                                : 'Hide from friends',
                            icon: Icon(
                              checkIn.hiddenFromFriends
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () => _toggleHidden(
                              clubController,
                              checkIn.id,
                              !checkIn.hiddenFromFriends,
                            ),
                          ),
                          IconButton(
                            key: Key('edit_diary_${checkIn.id}'),
                            tooltip: 'Note and rating',
                            icon: const Icon(Icons.edit_note),
                            onPressed: () => showDiaryEditor(context, checkIn),
                          ),
                        ],
                      ),
                      onTap: () =>
                          Get.to(() => ClubDetailsPage(club: checkIn.club)),
                      onLongPress: () async {
                        final remove = await showModalBottomSheet<bool>(
                          context: context,
                          builder: (ctx) => SafeArea(
                            child: ListTile(
                              leading: const Icon(Icons.delete),
                              title: const Text('Remove'),
                              onTap: () => Navigator.pop(ctx, true),
                            ),
                          ),
                        );
                        if (remove == true && context.mounted) {
                          if (await _confirmRemove(context)) {
                            await _remove(clubController, checkIn.id);
                          }
                        }
                      },
                    ),
                  ),
              ],
            ],
          );
        }),
      ),
    );
  }
}
