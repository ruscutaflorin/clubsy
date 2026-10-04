import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:clubsy/data/classes/club_data_health_model.dart';
import 'package:clubsy/services/admin_service.dart';
import 'package:clubsy/services/api_client.dart';
import 'package:clubsy/services/club_service.dart';
import 'package:clubsy/views/pages/admin/admin_club_form_page.dart';

class AdminClubDataHealthPage extends StatefulWidget {
  final AdminService? service;

  const AdminClubDataHealthPage({super.key, this.service});

  @override
  State<AdminClubDataHealthPage> createState() =>
      _AdminClubDataHealthPageState();
}

class _AdminClubDataHealthPageState extends State<AdminClubDataHealthPage> {
  ClubDataHealthModel? _data;
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
      final service = widget.service ?? AdminService();
      final data = await service.getClubDataHealth();
      if (!mounted) return;
      setState(() => _data = data);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not load data health');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Widget> _section(String title, List<String> rows) {
    if (rows.isEmpty) return [];
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(title, style: Theme.of(context).textTheme.titleMedium),
      ),
      for (final row in rows) ListTile(dense: true, title: Text(row)),
    ];
  }

  Future<void> _openClub(String id) async {
    try {
      final club = await ClubService().getClubById(id);
      Get.to(() => AdminClubFormPage(club: club));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Could not open club')));
    }
  }

  static const _missingLabels = {
    'openingHours': 'opening hours',
    'genres': 'genres',
    'description': 'description',
  };

  List<Widget> _incompleteSection(List<IncompleteProfileEntry> entries) {
    if (entries.isEmpty) return [];
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(
          'Incomplete profiles',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      for (final e in entries)
        ListTile(
          dense: true,
          title: Text('${e.name} · ${e.city}'),
          subtitle: Text(
            'Missing: ${e.missing.map((m) => _missingLabels[m] ?? m).join(', ')}',
          ),
          onTap: () => _openClub(e.id),
        ),
    ];
  }

  Widget _body() {
    final data = _data;
    if (data == null) {
      if (_loading) return const Center(child: CircularProgressIndicator());
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error ?? 'Could not load data health'),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (data.isEmpty) {
      return const Center(child: Text('No data issues found'));
    }
    return ListView(
      children: [
        ..._section('Invalid coordinates', [
          for (final c in data.invalidCoordinates) '${c.name} · ${c.city}',
        ]),
        ..._section('Possible duplicates', [
          for (final d in data.nearDuplicates)
            '${d.a.name} ↔ ${d.b.name} · ${d.meters} m'
                '${d.sameName ? ' · same name' : ''}',
        ]),
        ..._section('Far from its city', [
          for (final f in data.farFromCity)
            '${f.name} · ${f.city} · ${f.km} km away',
        ]),
        ..._incompleteSection(data.incompleteProfiles),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Club data health')),
      body: _body(),
    );
  }
}
