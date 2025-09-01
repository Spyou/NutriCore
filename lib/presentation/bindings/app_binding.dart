import 'package:get/get.dart';
import 'package:nutri_check/presentation/controllers/scan_controller.dart';
import 'package:nutri_check/presentation/controllers/search_controller.dart';

import '../controllers/auth_controller.dart';
import '../controllers/home_controller.dart';
import '../controllers/main_controller.dart';
import '../controllers/nutrition_controller.dart';
import '../controllers/profile_controller.dart';
import '../services/nutrition_service.dart';
import '../services/user_service.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    // Services first
    Get.lazyPut(() => UserService());
    Get.lazyPut(() => NutritionService());

    Get.put(AuthController(), permanent: true);

    Get.put(ProfileController(), permanent: true);
    Get.put(NutritionController(), permanent: true);

    Get.lazyPut(() => MainController());
    Get.lazyPut(() => HomeController());
    Get.lazyPut(() => SearchController());
    Get.lazyPut(() => ScanController());
  }
}
