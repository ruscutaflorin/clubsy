import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:clubsy/src/core/controllers/navigation_controller.dart';

class NavbarWidget extends StatelessWidget {
  const NavbarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final navigationController = Get.find<NavigationController>();

    return Obx(() => NavigationBar(
          selectedIndex: navigationController.selectedPage,
          onDestinationSelected: navigationController.changePage,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: 'Map'),
            NavigationDestination(icon: Icon(Icons.history), label: 'History'),
            NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
          ],
        ));
  }
}
