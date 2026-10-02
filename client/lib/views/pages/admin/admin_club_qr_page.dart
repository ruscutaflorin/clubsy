import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:clubsy/data/classes/club_model.dart';
import 'package:clubsy/src/core/controllers/admin_controller.dart';

/// Decodes a `data:image/png;base64,...` URL into PNG bytes.
Uint8List decodeQrDataUrl(String dataUrl) =>
    UriData.parse(dataUrl).contentAsBytes();

class AdminClubQrPage extends StatefulWidget {
  final ClubModel club;

  const AdminClubQrPage({super.key, required this.club});

  @override
  State<AdminClubQrPage> createState() => _AdminClubQrPageState();
}

class _AdminClubQrPageState extends State<AdminClubQrPage> {
  late final AdminController controller;
  String? error;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<AdminController>()
        ? Get.find<AdminController>()
        : Get.put(AdminController());
    if (controller.qrCodes[widget.club.id] == null) _run(controller.loadQr);
  }

  Future<void> _run(Future<String> Function(String) action) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await action(widget.club.id);
    } catch (e) {
      error = e.toString();
    }
    if (mounted) setState(() => busy = false);
  }

  Future<void> _confirmRotate() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rotate QR?'),
        content: const Text(
          'The printed QR at the venue will stop working immediately.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Rotate'),
          ),
        ],
      ),
    );
    if (ok == true) await _run(controller.rotateQr);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.club.name)),
      body: Center(
        child: Obx(() {
          final qr = controller.qrCodes[widget.club.id];
          if (qr != null) {
            return Column(
              children: [
                Expanded(
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: Image.memory(
                      decodeQrDataUrl(qr),
                      key: const Key('adminQrImage'),
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.none,
                    ),
                  ),
                ),
                if (error != null)
                  Text(error!, style: const TextStyle(color: Colors.red)),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: FilledButton.icon(
                    onPressed: busy ? null : _confirmRotate,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Rotate QR'),
                  ),
                ),
              ],
            );
          }
          if (error != null) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(error!),
                TextButton(
                  onPressed: () => _run(controller.loadQr),
                  child: const Text('Retry'),
                ),
              ],
            );
          }
          return const CircularProgressIndicator();
        }),
      ),
    );
  }
}
