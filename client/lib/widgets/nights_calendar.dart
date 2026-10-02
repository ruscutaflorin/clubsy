import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:clubsy/data/classes/check_in_grouping.dart';
import 'package:clubsy/data/classes/check_in_model.dart';
import 'package:clubsy/data/classes/club_model.dart';
import 'package:clubsy/data/classes/nights_calendar.dart';
import 'package:clubsy/views/pages/club_details_page.dart';

const _initials = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
const _cell = 12.0;
const _gap = 2.0;

String _two(int n) => n.toString().padLeft(2, '0');

String _dateKey(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';

/// A year-at-a-glance grid of the nights out, Monday first, one cell per night.
class NightsCalendar extends StatelessWidget {
  final List<CheckInModel> checkIns;
  final int year;

  const NightsCalendar({super.key, required this.checkIns, required this.year});

  Map<DateTime, List<ClubModel>> _clubsByNight() {
    final result = <DateTime, List<ClubModel>>{};
    for (final c in checkIns) {
      final night = nightOf(c.checkedInAt.toLocal());
      if (night.year != year) continue;
      final clubs = result.putIfAbsent(night, () => []);
      if (!clubs.any((club) => club.id == c.club.id)) clubs.add(c.club);
    }
    return result;
  }

  void _showNight(BuildContext context, DateTime night, List<ClubModel> clubs) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(title: Text(formatNightLabel(night))),
            for (final club in clubs)
              ListTile(
                leading: const Icon(Icons.local_bar),
                title: Text(club.name),
                subtitle: Text(club.city),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  Get.to(() => ClubDetailsPage(club: club));
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = nightsCalendar(checkIns, year);
    final clubs = _clubsByNight();
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.08);
    final one = scheme.primary.withValues(alpha: 0.5);
    final many = scheme.primary;

    final jan1 = DateTime(year, 1, 1);
    final offset = jan1.weekday - 1;
    final total = DateTime.utc(year + 1).difference(DateTime.utc(year)).inDays;
    final columns = ((offset + total) / 7).ceil();

    Widget cell(int index) {
      final dayIndex = index - offset;
      if (dayIndex < 0 || dayIndex >= total) {
        return const SizedBox(width: _cell + _gap, height: _cell + _gap);
      }
      final date = DateTime(year, 1, 1 + dayIndex);
      final names = data.nights[date];
      final color = names == null ? muted : (names.length >= 2 ? many : one);
      final square = Container(
        key: Key('night_${_dateKey(date)}'),
        width: _cell,
        height: _cell,
        margin: const EdgeInsets.all(_gap / 2),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      );
      if (names == null) return square;
      return GestureDetector(
        onTap: () => _showNight(context, date, clubs[date] ?? []),
        child: square,
      );
    }

    String monthLabel(int col) {
      for (var row = 0; row < 7; row++) {
        final dayIndex = col * 7 + row - offset;
        if (dayIndex < 0 || dayIndex >= total) continue;
        final date = DateTime(year, 1, 1 + dayIndex);
        if (date.day == 1) return _initials[date.month - 1];
      }
      return '';
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var col = 0; col < columns; col++)
            Column(
              children: [
                SizedBox(
                  width: _cell + _gap,
                  height: 14,
                  child: Text(
                    monthLabel(col),
                    style: const TextStyle(fontSize: 10),
                    softWrap: false,
                    overflow: TextOverflow.visible,
                  ),
                ),
                for (var row = 0; row < 7; row++) cell(col * 7 + row),
              ],
            ),
        ],
      ),
    );
  }
}
