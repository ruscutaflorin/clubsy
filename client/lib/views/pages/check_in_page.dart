import 'dart:async';

import 'package:flutter/material.dart';
import 'package:clubsy/data/classes/achievements_model.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:clubsy/data/classes/club_model.dart';
import 'package:clubsy/data/classes/location_problem.dart';
import 'package:clubsy/services/check_in_service.dart';
import 'package:clubsy/src/core/controllers/club_controller.dart';
import 'package:clubsy/src/core/controllers/navigation_controller.dart';
import 'package:clubsy/widgets/check_in_success_sheet.dart';

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
  final MobileScannerController _scanner = MobileScannerController();
  bool _isProcessing = false;
  bool _torchOn = false;
  String? _statusMessage;
  LocationProblem? _problem;

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }

  void _fail(LocationProblem problem) {
    _problem = problem;
    _statusMessage = locationProblemMessage(problem);
  }

  Future<Position?> _getCurrentPosition() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _fail(LocationProblem.permissionDeniedForever));
      return null;
    }
    if (permission == LocationPermission.denied) {
      setState(() => _fail(LocationProblem.permissionDenied));
      return null;
    }

    if (!await Geolocator.isLocationServiceEnabled()) {
      setState(() => _fail(LocationProblem.servicesDisabled));
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: 12),
        ),
      );
    } on TimeoutException {
      setState(() => _fail(LocationProblem.timeout));
      return null;
    }
  }

  Future<void> _handleDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final rawValue = capture.barcodes.firstOrNull?.rawValue;
    if (rawValue == null) return;

    _isProcessing = true;
    HapticFeedback.mediumImpact();
    await _scanner.stop();
    if (mounted) {
      setState(() {
        _statusMessage = null;
        _problem = null;
      });
    }

    var succeeded = false;
    try {
      final position = await _getCurrentPosition();
      if (position == null) return;

      final clubController = Get.find<ClubController>();
      final result = await clubController.checkIn(
        clubId: widget.club.id,
        qrPayload: rawValue,
        latitude: position.latitude,
        longitude: position.longitude,
        isMocked: position.isMocked,
        accuracyMeters: position.accuracy,
      );

      succeeded = true;
      if (!mounted) return;
      final viewOnMap = await showCheckInSuccessSheet(
        context,
        outcome: result.outcome,
        club: widget.club,
        extras: [
          if (result.tickedOffList)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Ticked off your list!',
                key: Key('tickedOffList'),
                style: TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          for (final badge in result.unlocked)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                badgeUnlockedText(badge),
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      );
      if (viewOnMap) {
        clubController.focusedClub.value = widget.club;
        Get.find<NavigationController>().changePage(0);
        Get.until((route) => route.isFirst);
      } else if (mounted) {
        Get.back();
      }
    } catch (e) {
      if (mounted) setState(() => _statusMessage = checkInFailureMessage(e));
    } finally {
      _isProcessing = false;
      if (mounted) {
        setState(() {});
        if (!succeeded) await _scanner.start();
      }
    }
  }

  Future<void> _toggleTorch() async {
    await _scanner.toggleTorch();
    if (mounted) setState(() => _torchOn = !_torchOn);
  }

  Widget? _problemAction() {
    switch (_problem) {
      case LocationProblem.permissionDeniedForever:
        return TextButton(
          onPressed: Geolocator.openAppSettings,
          child: const Text('Open app settings'),
        );
      case LocationProblem.servicesDisabled:
        return TextButton(
          onPressed: Geolocator.openLocationSettings,
          child: const Text('Open location settings'),
        );
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final action = _problemAction();
    return Scaffold(
      appBar: AppBar(
        title: Text('Check in at ${widget.club.name}'),
        actions: [
          IconButton(
            tooltip: 'Torch',
            icon: Icon(_torchOn ? Icons.flash_on : Icons.flash_off),
            onPressed: _toggleTorch,
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _scanner, onDetect: _handleDetect),
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _statusMessage!,
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    ?action,
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
