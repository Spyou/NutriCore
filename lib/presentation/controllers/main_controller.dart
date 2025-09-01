import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class MainController extends GetxController {
  var currentIndex = 0.obs;
  var isScanPageActive = false.obs;

  void changeIndex(int index) {
    final previousIndex = currentIndex.value;
    currentIndex.value = index;

    if (previousIndex == 2 && index != 2) {
      // Left scan page
      isScanPageActive.value = false;
      if (kDebugMode) {
        print('Left scan page - camera should pause');
      }
    } else if (previousIndex != 2 && index == 2) {
      // Entered scan page
      isScanPageActive.value = true;
      if (kDebugMode) {
        print('Entered scan page - camera should start');
      }
    }
  }

  bool get shouldScanPageBeActive => currentIndex.value == 2;
}
