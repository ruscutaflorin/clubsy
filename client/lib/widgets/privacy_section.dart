import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:clubsy/src/core/controllers/auth_controller.dart';

/// Profile section controlling whether friends can see my past nights.
class PrivacySection extends StatelessWidget {
  const PrivacySection({super.key});

  Future<void> _set(AuthController auth, bool value) async {
    try {
      await auth.updateProfile(shareNightsWithFriends: value);
    } catch (_) {
      Get.snackbar('Error', "Couldn't update your privacy setting.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    return Obx(
      () => SwitchListTile(
        key: const Key('shareNightsSwitch'),
        secondary: const Icon(Icons.lock_outline),
        title: const Text('Share my nights with friends'),
        subtitle: const Text(
          'Mutual friends who also share can see which clubs you visited and '
          'on which night, once the night has ended (after 06:00). Never the '
          'time, never where you are now. Off by default; hide single visits '
          'from History.',
        ),
        value: auth.user?['shareNightsWithFriends'] == true,
        onChanged: (v) => _set(auth, v),
      ),
    );
  }
}
