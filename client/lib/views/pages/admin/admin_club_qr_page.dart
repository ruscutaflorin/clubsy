import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
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

  /// Writes the PNG to a temp file and opens the share sheet.
  Future<void> _share(String qr) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/clubsy-qr-${widget.club.id}.png');
      await file.writeAsBytes(decodeQrDataUrl(qr));
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          subject: widget.club.name,
        ),
      );
    } catch (_) {
      if (mounted) setState(() => error = "Couldn't share the QR code");
    }
  }

  /// Opens a sheet with the venue display URL (rotating QR) to copy or share.
  Future<void> _showDisplayLink() async {
    try {
      final url = await controller.loadDisplayLink(widget.club.id);
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        builder: (context) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Open this link on a screen at the door. The QR changes '
                'every 30 seconds. Rotating the QR invalidates the link.',
              ),
              const SizedBox(height: 12),
              SelectableText(url, key: const Key('displayLinkText')),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                children: [
                  FilledButton.icon(
                    key: const Key('displayLinkCopy'),
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: url));
                      if (context.mounted) Navigator.pop(context);
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy'),
                  ),
                  OutlinedButton.icon(
                    key: const Key('displayLinkShare'),
                    onPressed: () => SharePlus.instance.share(
                      ShareParams(text: url, subject: widget.club.name),
                    ),
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } catch (_) {
      if (mounted) setState(() => error = "Couldn't get the display link");
    }
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
                  child: Wrap(
                    spacing: 12,
                    children: [
                      FilledButton.icon(
                        key: const Key('adminQrShare'),
                        onPressed: busy ? null : () => _share(qr),
                        icon: const Icon(Icons.share),
                        label: const Text('Share / print'),
                      ),
                      OutlinedButton.icon(
                        key: const Key('adminQrDisplayLink'),
                        onPressed: busy ? null : _showDisplayLink,
                        icon: const Icon(Icons.tv),
                        label: const Text('Venue display link'),
                      ),
                      OutlinedButton.icon(
                        onPressed: busy ? null : _confirmRotate,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Rotate QR'),
                      ),
                    ],
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
