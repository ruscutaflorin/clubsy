import 'package:flutter/material.dart';
import 'package:clubsy/data/classes/pilot_metrics_model.dart';
import 'package:clubsy/data/classes/pilot_scorecard_model.dart';
import 'package:clubsy/services/admin_service.dart';
import 'package:clubsy/services/api_client.dart';

class AdminMetricsPage extends StatefulWidget {
  final AdminService? service;

  const AdminMetricsPage({super.key, this.service});

  @override
  State<AdminMetricsPage> createState() => _AdminMetricsPageState();
}

class _AdminMetricsPageState extends State<AdminMetricsPage> {
  late final AdminService _service = widget.service ?? AdminService();
  int _days = 7;
  PilotMetricsModel? _metrics;
  PilotScorecardModel? _scorecard;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
    _loadScorecard();
  }

  Future<void> _loadScorecard() async {
    try {
      final scorecard = await _service.getPilotScorecard();
      if (mounted) setState(() => _scorecard = scorecard);
    } catch (_) {
      // The scorecard is supplementary; the metrics below still load.
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final metrics = await _service.getMetrics(_days);
      if (!mounted) return;
      setState(() => _metrics = metrics);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not load metrics');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final metrics = _metrics;
    return Scaffold(
      appBar: AppBar(title: const Text('Pilot metrics')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_scorecard != null) ...[
            PilotScorecardSection(scorecard: _scorecard!),
            const SizedBox(height: 24),
          ],
          SegmentedButton<int>(
            key: const Key('metricsDays'),
            segments: const [
              ButtonSegment(value: 7, label: Text('7 days')),
              ButtonSegment(value: 30, label: Text('30 days')),
              ButtonSegment(value: 90, label: Text('90 days')),
            ],
            selected: {_days},
            onSelectionChanged: (s) {
              setState(() => _days = s.first);
              _load();
            },
          ),
          const SizedBox(height: 16),
          if (_loading) const LinearProgressIndicator(),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: Colors.redAccent)),
          if (metrics != null) ...[
            MetricsKpiTiles(metrics: metrics),
            const SizedBox(height: 24),
            Text(
              'Daily check-ins',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            DailyBars(daily: metrics.daily),
            const SizedBox(height: 24),
            Text('Top clubs', style: Theme.of(context).textTheme.titleMedium),
            for (final c in metrics.topClubs)
              ListTile(
                dense: true,
                title: Text(c.name),
                trailing: Text('${c.count} · ${c.uniqueVisitors} visitors'),
              ),
          ],
        ],
      ),
    );
  }
}

class PilotScorecardSection extends StatelessWidget {
  final PilotScorecardModel scorecard;

  const PilotScorecardSection({super.key, required this.scorecard});

  static const _rateIds = {'activation', 'retention'};

  String _format(ScorecardCriterion c, num value) =>
      _rateIds.contains(c.id) ? '${(value * 100).round()}%' : '$value';

  @override
  Widget build(BuildContext context) {
    final max = scorecard.wacu.fold<int>(
      0,
      (m, w) => w.activeUsers > m ? w.activeUsers : m,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pilot exit criteria',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        for (final c in scorecard.criteria)
          ListTile(
            key: Key('criterion_${c.id}'),
            dense: true,
            title: Text(c.label),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  c.value == null
                      ? '—'
                      : '${_format(c, c.value!)} / ${_format(c, c.target)}',
                ),
                const SizedBox(width: 8),
                Icon(
                  c.met ? Icons.check_circle : Icons.cancel,
                  color: c.met ? Colors.green : Colors.redAccent,
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        Text('Weekly active check-in users'),
        const SizedBox(height: 8),
        SizedBox(
          key: const Key('wacuBars'),
          height: 80,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final w in scorecard.wacu)
                Expanded(
                  child: Tooltip(
                    message:
                        '${w.weekStart.split('T').first}: ${w.activeUsers}',
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      height: max == 0 ? 2 : 2 + 78 * w.activeUsers / max,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class MetricsKpiTiles extends StatelessWidget {
  final PilotMetricsModel metrics;

  const MetricsKpiTiles({super.key, required this.metrics});

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

  @override
  Widget build(BuildContext context) {
    final activation = '${(metrics.activationRate * 100).round()}%';
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.8,
      children: [
        _tile(
          'kpiWacu',
          metrics.days == 7 ? 'WACU' : 'Active users',
          '${metrics.activeCheckInUsers}',
        ),
        _tile('kpiCheckIns', 'Check-ins', '${metrics.checkIns}'),
        _tile('kpiActivation', 'Activation', activation),
        _tile('kpiReturning', 'Returning users', '${metrics.returningUsers}'),
      ],
    );
  }
}

class DailyBars extends StatelessWidget {
  final List<DailyMetric> daily;

  const DailyBars({super.key, required this.daily});

  @override
  Widget build(BuildContext context) {
    final max = daily.fold<int>(0, (m, d) => d.checkIns > m ? d.checkIns : m);
    return SizedBox(
      height: 100,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final d in daily)
            Expanded(
              child: Tooltip(
                message: '${d.date}: ${d.checkIns}',
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  height: max == 0 ? 2 : 2 + 98 * d.checkIns / max,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
