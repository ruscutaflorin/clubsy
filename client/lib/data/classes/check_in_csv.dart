/// Turns the `GET /api/auth/me/export` payload into RFC 4180 CSV text of the
/// user's check-ins. Leaves out ids, email and coordinates.
String checkInsToCsv(Map<String, dynamic> export) {
  final rows = <List<String>>[
    ['date', 'time', 'club', 'city', 'address', 'distance_m', 'verification'],
  ];
  final checkIns = export['checkIns'];
  if (checkIns is List) {
    for (final c in checkIns) {
      if (c is! Map) continue;
      final club = c['club'] is Map ? c['club'] as Map : const {};
      final at = DateTime.tryParse('${c['checkedInAt']}')?.toLocal();
      final distance = c['distanceMeters'];
      rows.add([
        at == null
            ? ''
            : '${at.year.toString().padLeft(4, '0')}-${_two(at.month)}-${_two(at.day)}',
        at == null ? '' : '${_two(at.hour)}:${_two(at.minute)}',
        '${club['name'] ?? ''}',
        '${club['city'] ?? ''}',
        '${club['address'] ?? ''}',
        distance is num ? '${distance.round()}' : '',
        '${c['verificationMethod'] ?? ''}',
      ]);
    }
  }
  return rows.map((r) => r.map(_field).join(',')).join('\r\n');
}

String _two(int n) => n.toString().padLeft(2, '0');

String _field(String value) {
  var v = value;
  if (v.isNotEmpty && '=+-@'.contains(v[0])) v = "'$v";
  if (v.contains(RegExp(r'[,"\r\n]'))) v = '"${v.replaceAll('"', '""')}"';
  return v;
}
