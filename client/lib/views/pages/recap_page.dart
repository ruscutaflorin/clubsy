import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:clubsy/data/classes/recap.dart';
import 'package:clubsy/src/core/controllers/club_controller.dart';

const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];
const _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

/// Name of the last complete month, e.g. "September" in October.
String lastMonthName(DateTime now) => _months[(now.month + 10) % 12];

/// Period [from, to) of the last complete month, starting at 06:00 local.
(DateTime, DateTime) lastMonthRange(DateTime now) => (
  DateTime(now.year, now.month - 1, 1, 6),
  DateTime(now.year, now.month, 1, 6),
);

(DateTime, DateTime) yearRange(int year) =>
    (DateTime(year, 1, 1, 6), DateTime(year + 1, 1, 1, 6));

String _hhmm(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

/// The stylised 9:16 card. With [hideClubNames] it shows counts only.
class RecapCard extends StatelessWidget {
  final Recap recap;
  final String title;
  final bool hideClubNames;

  const RecapCard({
    super.key,
    required this.recap,
    required this.title,
    required this.hideClubNames,
  });

  @override
  Widget build(BuildContext context) {
    final top = recap.topClub;
    final latest = recap.latestNight;
    final lines = <String>[
      '${recap.distinctClubs} clubs in ${recap.distinctCities} cities',
      if (top != null)
        hideClubNames
            ? 'Top spot: ${recap.topClubVisits} visits'
            : 'Top club: ${top.name} (${recap.topClubVisits} visits)',
      if (recap.busiestWeekday != null)
        'Busiest night: ${_weekdays[recap.busiestWeekday! - 1]}',
      if (latest != null) 'Latest night: ${_hhmm(latest)}',
      '${recap.newClubs} new clubs',
    ];
    return AspectRatio(
      aspectRatio: 9 / 16,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3B1C7A), Color(0xFFE0457B)],
          ),
        ),
        child: DefaultTextStyle(
          style: const TextStyle(color: Colors.white, fontSize: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${recap.nightsOut}',
                style: const TextStyle(
                  fontSize: 80,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text('nights out'),
              const SizedBox(height: 24),
              for (final l in lines)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(l),
                ),
              const Spacer(),
              const Text(
                'Clubsy',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RecapPage extends StatefulWidget {
  const RecapPage({super.key});

  @override
  State<RecapPage> createState() => _RecapPageState();
}

class _RecapPageState extends State<RecapPage> {
  final _boundaryKey = GlobalKey();
  final _now = DateTime.now();
  int? _year;
  bool _hideNames = true;
  String? _error;

  Future<void> _share() async {
    try {
      final boundary =
          _boundaryKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/clubsy-recap.png');
      await file.writeAsBytes(data!.buffer.asUint8List());
      await Share.shareXFiles([XFile(file.path, mimeType: 'image/png')]);
    } catch (_) {
      if (mounted) setState(() => _error = "Couldn't share the recap");
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ClubController>();
    final years = List.generate(5, (i) => _now.year - i);
    final range = _year == null ? lastMonthRange(_now) : yearRange(_year!);
    final title = _year == null ? 'Your ${lastMonthName(_now)}' : 'Your $_year';
    return Scaffold(
      appBar: AppBar(title: const Text('Your nights')),
      body: Obx(() {
        final recap = buildRecap(
          controller.myCheckIns,
          from: range.$1,
          to: range.$2,
        );
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButton<int?>(
              key: const Key('recapPeriod'),
              value: _year,
              isExpanded: true,
              items: [
                DropdownMenuItem(
                  value: null,
                  child: Text('Last month (${lastMonthName(_now)})'),
                ),
                for (final y in years)
                  DropdownMenuItem(value: y, child: Text('$y')),
              ],
              onChanged: (v) => setState(() => _year = v),
            ),
            SwitchListTile(
              key: const Key('hideNamesToggle'),
              title: const Text('Hide club names on the card'),
              value: _hideNames,
              onChanged: (v) => setState(() => _hideNames = v),
            ),
            if (recap.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No nights out in this period',
                  textAlign: TextAlign.center,
                ),
              )
            else ...[
              RepaintBoundary(
                key: _boundaryKey,
                child: RecapCard(
                  recap: recap,
                  title: title,
                  hideClubNames: _hideNames,
                ),
              ),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
              FilledButton.icon(
                key: const Key('shareRecap'),
                onPressed: _share,
                icon: const Icon(Icons.ios_share),
                label: const Text('Share'),
              ),
            ],
          ],
        );
      }),
    );
  }
}
