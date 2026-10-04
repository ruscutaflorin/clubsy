import 'package:flutter/material.dart';
import 'package:clubsy/data/classes/admin_report_model.dart';
import 'package:clubsy/services/admin_service.dart';
import 'package:clubsy/services/api_client.dart';

/// The moderation queue: open reports, oldest first. Users with 3+ open
/// reports are flagged for review.
class AdminReportsPage extends StatefulWidget {
  final AdminService? service;

  const AdminReportsPage({super.key, this.service});

  @override
  State<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportsPage> {
  late final AdminService _service = widget.service ?? AdminService();
  List<AdminReport> _reports = [];
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final reports = await _service.getOpenReports();
      if (mounted) setState(() => _reports = reports);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not load reports');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resolve(AdminReport report, String status) async {
    try {
      await _service.resolveReport(report.id, status);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
      return;
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin · Reports')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (_loading && _reports.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (!_loading && _error == null && _reports.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: Text('No open reports.')),
              ),
            for (final r in _reports)
              Card(
                key: Key('report-${r.id}'),
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${r.reportedLabel} · ${r.reasonLabel}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text('Reported by ${r.reporterLabel}'),
                      if (r.details != null && r.details!.isNotEmpty)
                        Text(r.details!),
                      if (r.flagged)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Chip(
                            key: Key('flagged-${r.id}'),
                            avatar: const Icon(Icons.flag, size: 16),
                            label: Text(
                              'Flagged for review · ${r.openReports} open reports',
                            ),
                          ),
                        ),
                      OverflowBar(
                        alignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            key: Key('dismiss-${r.id}'),
                            onPressed: () => _resolve(r, 'DISMISSED'),
                            child: const Text('Dismiss'),
                          ),
                          FilledButton(
                            key: Key('action-${r.id}'),
                            onPressed: () => _resolve(r, 'ACTIONED'),
                            child: const Text('Mark actioned'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
