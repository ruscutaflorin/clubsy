import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:clubsy/data/classes/check_in_grouping.dart';
import 'package:clubsy/data/classes/feed_model.dart';
import 'package:clubsy/services/feed_service.dart';
import 'package:clubsy/src/core/controllers/club_controller.dart';
import 'package:clubsy/views/pages/club_details_page.dart';

class FriendNightsPage extends StatefulWidget {
  final String userId;
  final String label;
  final FeedService? service;

  const FriendNightsPage({
    super.key,
    required this.userId,
    required this.label,
    this.service,
  });

  @override
  State<FriendNightsPage> createState() => _FriendNightsPageState();
}

class _FriendNightsPageState extends State<FriendNightsPage> {
  late final FeedService _service = widget.service ?? FeedService();
  final List<FeedNight> _nights = [];
  int _page = 0;
  int _sharedClubCount = 0;
  List<({String id, String name, String? city})> _newToYou = const [];
  bool _hasMore = false;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMore();
  }

  Future<void> _loadMore() async {
    setState(() => _loading = true);
    try {
      final result = await _service.getFriendNights(
        widget.userId,
        page: _page + 1,
      );
      if (!mounted) return;
      setState(() {
        _page++;
        _nights.addAll(result.nights);
        _hasMore = result.hasMore;
        if (_page == 1) {
          _sharedClubCount = result.sharedClubCount;
          _newToYou = result.newToYou;
        }
        _error = null;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load nights.';
        _loading = false;
      });
    }
  }

  String _title(FeedNight n) {
    final date = formatNightLabel(DateTime.parse(n.nightDate));
    final city = n.city;
    return city == null || city.isEmpty
        ? '$date · ${n.clubName}'
        : '$date · ${n.clubName}, $city';
  }

  VoidCallback? _openClub(String id) {
    if (!Get.isRegistered<ClubController>()) return null;
    final club = Get.find<ClubController>().clubs.firstWhereOrNull(
      (c) => c.id == id,
    );
    if (club == null) return null;
    return () => Get.to(() => ClubDetailsPage(club: club));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.label)),
      body: ListView(
        children: [
          if (_sharedClubCount > 0)
            Padding(
              key: const Key('sharedClubCount'),
              padding: const EdgeInsets.all(16),
              child: Text(
                "You've both been to $_sharedClubCount "
                "${_sharedClubCount == 1 ? 'club' : 'clubs'}",
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          if (_newToYou.isNotEmpty)
            Column(
              key: const Key('newToYou'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Text(
                    "Been there, you haven't",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                for (final c in _newToYou)
                  ListTile(
                    key: Key('newToYou_${c.id}'),
                    title: Text(c.name),
                    subtitle: (c.city ?? '').isEmpty ? null : Text(c.city!),
                    onTap: _openClub(c.id),
                  ),
              ],
            ),
          for (final n in _nights) ListTile(title: Text(_title(n))),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_hasMore)
            TextButton(onPressed: _loadMore, child: const Text('Load more'))
          else if (_nights.isEmpty && _error == null)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'No shared nights yet. They appear here when you both share your nights.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
