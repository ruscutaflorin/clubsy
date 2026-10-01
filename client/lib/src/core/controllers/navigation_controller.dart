import 'package:get/get.dart';

class NavigationController extends GetxController {
  final _selectedPage = 0.obs;
  int get selectedPage => _selectedPage.value;

  void changePage(int index) {
    _selectedPage.value = index;
  }
}
