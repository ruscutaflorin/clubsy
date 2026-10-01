import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:clubsy/src/core/controllers/navigation_controller.dart';
import 'package:clubsy/src/core/controllers/club_controller.dart';
import 'package:clubsy/views/pages/club_map_page.dart';
import 'package:clubsy/views/pages/check_in_history_page.dart';
import 'package:clubsy/views/pages/profile_page.dart';
import 'package:clubsy/widgets/navbar_widget.dart';

class WidgetTree extends StatefulWidget {
  const WidgetTree({super.key});

  @override
  State<WidgetTree> createState() => _WidgetTreeState();
}

class _WidgetTreeState extends State<WidgetTree> {
  @override
  void initState() {
    super.initState();
    Get.find<ClubController>().refresh();
  }

  @override
  Widget build(BuildContext context) {
    final navigationController = Get.find<NavigationController>();

    const pages = [ClubMapPage(), CheckInHistoryPage(), ProfilePage()];

    return Scaffold(
      body: Obx(() {
        final index = navigationController.selectedPage;
        if (index >= 0 && index < pages.length) {
          return pages[index];
        }
        return pages[0];
      }),
      bottomNavigationBar: const NavbarWidget(),
    );
  }
}
