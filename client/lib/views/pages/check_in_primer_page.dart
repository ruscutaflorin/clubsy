import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clubsy/data/classes/club_model.dart';
import 'package:clubsy/views/pages/check_in_page.dart';

const checkInPrimerSeenKey = 'checkInPrimerSeen';

Widget _defaultScanner(ClubModel club) => CheckInPage(club: club);

/// Opens the check-in flow: the primer the first time, the scanner after that.
Future<void> openCheckIn(
  ClubModel club, {
  @visibleForTesting
  Widget Function(ClubModel club) checkInBuilder = _defaultScanner,
}) async {
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool(checkInPrimerSeenKey) ?? false) {
    await Get.to(() => checkInBuilder(club));
  } else {
    await Get.to(
      () => CheckInPrimerPage(club: club, checkInBuilder: checkInBuilder),
    );
  }
}

/// Explains camera and location use before the OS permission dialogs.
class CheckInPrimerPage extends StatelessWidget {
  final ClubModel club;
  final Widget Function(ClubModel club) checkInBuilder;

  const CheckInPrimerPage({
    super.key,
    required this.club,
    this.checkInBuilder = _defaultScanner,
  });

  Future<void> _continue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(checkInPrimerSeenKey, true);
    await Get.off(() => checkInBuilder(club));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Before you check in')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Point(
              icon: Icons.qr_code_scanner,
              text:
                  'Scan the QR code at the entrance. Clubsy asks for camera '
                  'access for this.',
            ),
            const _Point(
              icon: Icons.my_location,
              text:
                  'Your location is only read at the moment you check in, to '
                  'confirm you are at the club.',
            ),
            const _Point(
              icon: Icons.lock_outline,
              text: 'Your map is private. Only you can see it.',
            ),
            const Spacer(),
            FilledButton(
              key: const Key('primerContinue'),
              onPressed: _continue,
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Point extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Point({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 32),
          const SizedBox(width: 16),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
