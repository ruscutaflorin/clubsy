import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
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
    await Share.shareXFiles([
      XFile(file.path, mimeType: 'application/json'),
    ], subject: 'My Clubsy data');
  }
}
