import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:clubsy/data/classes/club_model.dart';
import 'package:clubsy/services/check_in_service.dart';
import 'package:clubsy/src/core/controllers/club_controller.dart';

/// The message CheckInPage shows for a failed check-in: the distance to the
/// venue when the server reported one, otherwise the exception's own message.
String checkInFailureMessage(Object error) {
  if (error is CheckInException && error.distanceMeters != null) {
    final rounded = error.distanceMeters!.round();
    return "You're ~$rounded m away — get within 150 m of the entrance";
  }
  if (error is CheckInException) return error.message;
  return error.toString().replaceFirst('Exception: ', '');
}

class CheckInPage extends StatefulWidget {
  final ClubModel club;

  const CheckInPage({super.key, required this.club});

  @override
  State<CheckInPage> createState() => _CheckInPageState();
}

class _CheckInPageState extends State<CheckInPage> {
  bool _isProcessing = false;
  String? _statusMessage;

  Future<Position?> _getCurrentPosition() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(
        () => _statusMessage = 'Location permission is required to check in',
      );
      return null;
    }

    if (!await Geolocator.isLocationServiceEnabled()) {
      setState(() => _statusMessage = 'Please enable location services');
      return null;
    }

    return Geolocator.getCurrentPosition();
  }

  Future<void> _handleDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final rawValue = capture.barcodes.firstOrNull?.rawValue;
    if (rawValue == null) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = null;
    });

    try {
      final position = await _getCurrentPosition();
      if (position == null) {
        setState(() => _isProcessing = false);
        return;
      }

      final clubController = Get.find<ClubController>();
      await clubController.checkIn(
        clubId: widget.club.id,
        qrPayload: rawValue,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (!mounted) return;
      Get.back();
      Get.snackbar('Checked in!', 'Welcome to ${widget.club.name}');
    } catch (e) {
      setState(() => _statusMessage = checkInFailureMessage(e));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Check in at ${widget.club.name}')),
      body: Stack(
        children: [
          MobileScanner(onDetect: _handleDetect),
          if (_isProcessing) const Center(child: CircularProgressIndicator()),
          if (_statusMessage != null)
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _statusMessage!,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
