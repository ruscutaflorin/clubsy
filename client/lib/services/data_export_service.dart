import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:clubsy/data/classes/check_in_csv.dart';
import 'package:clubsy/services/auth_service.dart';

/// "Download my data": fetches the JSON export, writes it to the temp
/// directory and opens the share sheet.
class DataExportService {
  final AuthService _auth;

  DataExportService({AuthService? auth}) : _auth = auth ?? AuthService();

  Future<void> exportMyData() async {
    final data = await _auth.exportData();
    final date = DateTime.now().toIso8601String().substring(0, 10);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/clubsy-export-$date.json');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/json')],
        subject: 'My Clubsy data',
      ),
    );
  }

  Future<void> exportMyCheckInsCsv() async {
    final data = await _auth.exportData();
    final date = DateTime.now().toIso8601String().substring(0, 10);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/clubsy-check-ins-$date.csv');
    await file.writeAsString(checkInsToCsv(data));
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'text/csv')],
        subject: 'My Clubsy check-ins',
      ),
    );
  }
}
