import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:clubsy/data/classes/club_form_validation.dart';
import 'package:clubsy/data/classes/club_model.dart';
import 'package:clubsy/data/classes/club_profile.dart';
import 'package:clubsy/src/core/controllers/admin_controller.dart';
import 'package:clubsy/views/pages/admin/admin_club_qr_page.dart';

/// Must match `MAX_CHECK_IN_DISTANCE_METERS` on the server.
const checkInRadiusMeters = 150.0;

/// Reads the device position, or throws a user-readable message.
Future<LatLng> currentLocation() async {
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    throw 'Location permission is needed to use your position';
  }
  if (!await Geolocator.isLocationServiceEnabled()) {
    throw 'Turn on location services and try again';
  }
  try {
    final p = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        timeLimit: Duration(seconds: 12),
      ),
    );
    return LatLng(p.latitude, p.longitude);
  } on TimeoutException {
    throw "Couldn't get a location fix, try again";
  }
}

/// Create (no [club]) or edit a club.
class AdminClubFormPage extends StatefulWidget {
  final ClubModel? club;
  final Future<LatLng> Function() locate;
  final bool showMap;

  const AdminClubFormPage({
    super.key,
    this.club,
    this.locate = currentLocation,
    this.showMap = true,
  });

  @override
  State<AdminClubFormPage> createState() => _AdminClubFormPageState();
}

class _AdminClubFormPageState extends State<AdminClubFormPage> {
  late final AdminController controller;
  late final Map<String, TextEditingController> text;
  late final Map<String, TextEditingController> extra;
  late final Set<String> genres;
  bool locating = false;
  String? locationError;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<AdminController>()
        ? Get.find<AdminController>()
        : Get.put(AdminController());
    controller.fieldErrors.clear();
    final c = widget.club;
    final initial = {
      'name': c?.name,
      'address': c?.address,
      'city': c?.city,
      'latitude': c?.latitude.toString(),
      'longitude': c?.longitude.toString(),
      'imageUrl': c?.imageUrl,
    };
    text = {
      for (final f in ClubFormValidation.fields)
        f: TextEditingController(text: initial[f] ?? '')
          ..addListener(() {
            // Server errors are stale once the field is edited.
            controller.fieldErrors.remove(f);
            setState(() {});
          }),
    };
    genres = {...?c?.genres};
    extra = {
      'description': TextEditingController(text: c?.description ?? ''),
      'instagramUrl': TextEditingController(text: c?.instagramUrl ?? ''),
      'websiteUrl': TextEditingController(text: c?.websiteUrl ?? ''),
      for (final day in weekdayKeys)
        'hours-$day': TextEditingController(
          text: hoursText(c?.openingHours, day),
        ),
    };
    for (final entry in extra.entries) {
      entry.value.addListener(() {
        controller.fieldErrors.remove(entry.key);
        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    for (final c in [...text.values, ...extra.values]) {
      c.dispose();
    }
    super.dispose();
  }

  String _v(String field) => text[field]!.text;

  bool get _profileValid =>
      ClubFormValidation.description(extra['description']!.text) == null &&
      ClubFormValidation.httpsUrl(extra['instagramUrl']!.text, 'Instagram') ==
          null &&
      ClubFormValidation.httpsUrl(extra['websiteUrl']!.text, 'Website') ==
          null &&
      weekdayKeys.every((d) => hoursTextError(extra['hours-$d']!.text) == null);

  /// The weekly schedule from the per-day fields, or null when every day is
  /// blank (no schedule).
  Map<String, dynamic>? get _openingHours {
    final hours = <String, dynamic>{};
    for (final day in weekdayKeys) {
      final slots = parseHoursText(extra['hours-$day']!.text);
      if (slots != null && slots.isNotEmpty) hours[day] = slots;
    }
    return hours.isEmpty ? null : hours;
  }

  bool get _valid =>
      _profileValid &&
      ClubFormValidation.isValid(
        name: _v('name'),
        address: _v('address'),
        city: _v('city'),
        latitude: _v('latitude'),
        longitude: _v('longitude'),
        imageUrl: _v('imageUrl'),
      );

  LatLng? get _point {
    if (ClubFormValidation.latitude(_v('latitude')) != null ||
        ClubFormValidation.longitude(_v('longitude')) != null) {
      return null;
    }
    return LatLng(
      double.parse(_v('latitude').trim()),
      double.parse(_v('longitude').trim()),
    );
  }

  Future<void> _useLocation() async {
    setState(() {
      locating = true;
      locationError = null;
    });
    try {
      final p = await widget.locate();
      text['latitude']!.text = p.latitude.toStringAsFixed(6);
      text['longitude']!.text = p.longitude.toStringAsFixed(6);
    } catch (e) {
      locationError = e.toString();
    }
    if (mounted) setState(() => locating = false);
  }

  Future<void> _submit() async {
    final fields = <String, dynamic>{
      'name': _v('name').trim(),
      'address': _v('address').trim(),
      'city': _v('city').trim(),
      'latitude': double.parse(_v('latitude').trim()),
      'longitude': double.parse(_v('longitude').trim()),
      if (_v('imageUrl').trim().isNotEmpty) 'imageUrl': _v('imageUrl').trim(),
      'description': extra['description']!.text.trim().isEmpty
          ? null
          : extra['description']!.text.trim(),
      'genres': genres.toList(),
      'openingHours': _openingHours,
      'instagramUrl': extra['instagramUrl']!.text.trim(),
      'websiteUrl': extra['websiteUrl']!.text.trim(),
    };
    final saved = await controller.saveClub(fields, id: widget.club?.id);
    if (saved == null || !mounted) return;
    if (widget.club == null) {
      Get.off(() => AdminClubQrPage(club: saved));
    } else {
      Get.back();
    }
  }

  Widget _field(
    String field,
    String label,
    String? Function(String?) validator, {
    TextInputType? keyboard,
  }) {
    return Obx(() {
      final server = controller.fieldErrors[field];
      final local = _v(field).isEmpty ? null : validator(_v(field));
      return TextField(
        key: Key('clubForm-$field'),
        controller: text[field],
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          errorText: server ?? local,
        ),
      );
    });
  }

  Widget _extraField(
    String field,
    String label,
    String? Function(String?) validator, {
    int maxLines = 1,
    TextInputType? keyboard,
  }) {
    return Obx(() {
      final server = controller.fieldErrors[field];
      final value = extra[field]!.text;
      return TextField(
        key: Key('clubForm-$field'),
        controller: extra[field],
        keyboardType: keyboard,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          errorText: server ?? (value.isEmpty ? null : validator(value)),
        ),
      );
    });
  }

  Widget _profileFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _extraField(
          'description',
          'Description (optional)',
          ClubFormValidation.description,
          maxLines: 3,
        ),
        const SizedBox(height: 12),
        const Text('Music genres'),
        Wrap(
          spacing: 6,
          children: [
            for (final g in clubGenres)
              FilterChip(
                key: Key('clubFormGenre-$g'),
                label: Text(g),
                selected: genres.contains(g),
                onSelected: (on) => setState(() {
                  on ? genres.add(g) : genres.remove(g);
                }),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _extraField(
          'instagramUrl',
          'Instagram URL (optional)',
          (v) => ClubFormValidation.httpsUrl(v, 'Instagram'),
          keyboard: TextInputType.url,
        ),
        const SizedBox(height: 12),
        _extraField(
          'websiteUrl',
          'Website URL (optional)',
          (v) => ClubFormValidation.httpsUrl(v, 'Website'),
          keyboard: TextInputType.url,
        ),
        const SizedBox(height: 12),
        const Text('Opening hours (HH:MM-HH:MM, blank = closed)'),
        for (final day in weekdayKeys)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _extraField(
              'hours-$day',
              weekdayLabels[day]!,
              hoursTextError,
            ),
          ),
        Obx(() {
          final error = controller.fieldErrors['openingHours'];
          return error == null
              ? const SizedBox.shrink()
              : Text(error, style: const TextStyle(color: Colors.red));
        }),
      ],
    );
  }

  Widget _preview(LatLng point) => SizedBox(
    height: 180,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: FlutterMap(
        key: const Key('clubFormMap'),
        options: MapOptions(
          initialCenter: point,
          initialZoom: 16,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.none,
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.clubsy.app',
          ),
          CircleLayer(
            circles: [
              CircleMarker(
                point: point,
                radius: checkInRadiusMeters,
                useRadiusInMeter: true,
                color: Colors.blue.withValues(alpha: 0.2),
                borderColor: Colors.blue,
                borderStrokeWidth: 2,
              ),
            ],
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: point,
                width: 40,
                height: 40,
                alignment: Alignment.topCenter,
                child: const Icon(Icons.location_pin, color: Colors.red),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final editing = widget.club != null;
    final point = _point;
    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'Edit club' : 'New club')),
      // A Column (not a lazy ListView) so the submit button is always built.
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _field(
              'name',
              'Name',
              (v) => ClubFormValidation.required(v, 'Name'),
            ),
            const SizedBox(height: 12),
            _field(
              'address',
              'Address',
              (v) => ClubFormValidation.required(v, 'Address'),
            ),
            const SizedBox(height: 12),
            _field(
              'city',
              'City',
              (v) => ClubFormValidation.required(v, 'City'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _field(
                    'latitude',
                    'Latitude',
                    ClubFormValidation.latitude,
                    keyboard: const TextInputType.numberWithOptions(
                      signed: true,
                      decimal: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _field(
                    'longitude',
                    'Longitude',
                    ClubFormValidation.longitude,
                    keyboard: const TextInputType.numberWithOptions(
                      signed: true,
                      decimal: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                key: const Key('clubFormLocate'),
                onPressed: locating ? null : _useLocation,
                icon: const Icon(Icons.my_location),
                label: Text(locating ? 'Locating…' : 'Use my current location'),
              ),
            ),
            if (locationError != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  locationError!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            if (point != null && widget.showMap) ...[
              const SizedBox(height: 12),
              _preview(point),
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'Blue circle: the 150 m check-in radius around the pin.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
            const SizedBox(height: 12),
            _field(
              'imageUrl',
              'Image URL (optional)',
              ClubFormValidation.imageUrl,
              keyboard: TextInputType.url,
            ),
            const SizedBox(height: 12),
            _profileFields(),
            Obx(() {
              final error = controller.fieldErrors['_form'];
              return error == null
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        error,
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
            }),
            const SizedBox(height: 16),
            Obx(
              () => FilledButton(
                key: const Key('clubFormSubmit'),
                onPressed: !controller.isSaving.value && _valid
                    ? _submit
                    : null,
                child: Text(editing ? 'Save changes' : 'Create club'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
