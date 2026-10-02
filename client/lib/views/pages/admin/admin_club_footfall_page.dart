import 'package:flutter/material.dart';
import 'package:clubsy/data/classes/club_footfall_model.dart';
import 'package:clubsy/data/classes/club_model.dart';
import 'package:clubsy/services/admin_service.dart';
import 'package:clubsy/services/api_client.dart';

class AdminClubFootfallPage extends StatefulWidget {
  final ClubModel club;
  final AdminService? service;

  /// When set, shown instead of loading from the server.
  final ClubFootfallModel? footfall;

  const AdminClubFootfallPage({
    super.key,
    required this.club,
    this.service,
    this.footfall,
  });

  @override
  State<AdminClubFootfallPage> createState() => _AdminClubFootfallPageState();
}

class _AdminClubFootfallPageState extends State<AdminClubFootfallPage> {
  ClubFootfallModel? _footfall;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _footfall = widget.footfall;
    if (_footfall == null) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final service = widget.service ?? AdminService();
      final data = await service.getClubFootfall(widget.club.id);
      if (!mounted) return;
      setState(() => _footfall = data);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not load footfall');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _tile(String key, String label, String value) => Card(
    key: Key(key),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(label, textAlign: TextAlign.center),
        ],
      ),
    ),
  );

  String _pct(double v) => '${(v * 100).round()}%';

  Widget _distanceCard(DistanceHealth d) {
    final enough = d.status != 'insufficient' && d.medianMeters != null;
    return Card(
      key: const Key('footfallDistance'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Check-in distance',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (d.medianMeters != null && d.p90Meters != null)
              Text('Median ${d.medianMeters} m · 90% within ${d.p90Meters} m'),
            if (d.nearLimitShare != null)
              Text('${_pct(d.nearLimitShare!)} close to the 150 m limit'),
            if (!enough)
              const Text('Not enough check-ins yet')
            else if (d.status == 'marginal')
              const Text(
                "Many check-ins are close to the 150 m limit: check the pin's position",
                style: TextStyle(color: Colors.orangeAccent),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = _footfall;
    return Scaffold(
      appBar: AppBar(title: Text('Footfall · ${widget.club.name}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_loading) const LinearProgressIndicator(),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: Colors.redAccent)),
          if (data != null) ...[
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.8,
              children: [
                _tile(
                  'footfallUnique',
                  'Unique visitors',
                  '${data.uniqueVisitors}',
                ),
                _tile('footfallTotal', 'Check-ins', '${data.totalCheckIns}'),
                _tile(
                  'footfallReturning',
                  'Returning visitors',
                  _pct(data.returningVisitorRate),
                ),
                _tile(
                  'footfallFirstTime',
                  'First-time share',
                  _pct(data.firstTimeShare),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Weekly check-ins',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            WeeklyBars(weekly: data.weekly),
            if (data.distance != null) ...[
              const SizedBox(height: 24),
              _distanceCard(data.distance!),
            ],
          ],
        ],
      ),
    );
  }
}

class WeeklyBars extends StatelessWidget {
  final List<FootfallWeek> weekly;

  const WeeklyBars({super.key, required this.weekly});

  @override
  Widget build(BuildContext context) {
    final max = weekly.fold<int>(0, (m, w) => w.checkIns > m ? w.checkIns : m);
    return SizedBox(
      height: 100,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final w in weekly)
            Expanded(
              child: Tooltip(
                message: '${w.weekStart}: ${w.checkIns}',
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  height: max == 0 ? 2 : 2 + 98 * w.checkIns / max,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
