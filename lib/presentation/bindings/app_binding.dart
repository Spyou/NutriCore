import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:nutri_check/data/datasources/firebase_datasource.dart';
import 'package:nutri_check/data/datasources/local_cache.dart';
import 'package:nutri_check/data/repositories/product_repository_impl.dart';
import 'package:nutri_check/data/repositories/nutrition_repository_impl.dart';
import 'package:nutri_check/data/repositories/user_repository_impl.dart';
import 'package:nutri_check/data/repositories/preferences_repository_impl.dart';
import 'package:nutri_check/domain/repositories/product_repository.dart';
import 'package:nutri_check/domain/repositories/nutrition_repository.dart';
import 'package:nutri_check/domain/repositories/user_repository.dart';
import 'package:nutri_check/domain/repositories/preferences_repository.dart';
import 'package:nutri_check/domain/usecases/calculate_bmr.dart';
import 'package:nutri_check/domain/usecases/search_products.dart';
import 'package:nutri_check/domain/usecases/get_product_by_barcode.dart';
import 'package:nutri_check/presentation/controllers/auth_controller.dart';
import 'package:nutri_check/presentation/controllers/home_controller.dart';
import 'package:nutri_check/presentation/controllers/main_controller.dart';
import 'package:nutri_check/presentation/controllers/nutrition_controller.dart';
import 'package:nutri_check/presentation/controllers/profile_controller.dart';
import 'package:nutri_check/presentation/controllers/scan_controller.dart';
import 'package:nutri_check/presentation/controllers/search_controller.dart';
import 'package:nutri_check/presentation/services/user_service.dart';
import 'package:nutri_check/presentation/services/nutrition_service.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => FirebaseDataSource(FirebaseFirestore.instance));
    Get.lazyPut(() => LocalCache());

    Get.lazyPut<ProductRepository>(
      () => ProductRepositoryImpl(localCache: Get.find()),
    );
    Get.lazyPut<NutritionRepository>(
      () => NutritionRepositoryImpl(firebaseDataSource: Get.find()),
    );
    Get.lazyPut<UserRepository>(
      () => UserRepositoryImpl(firebaseDataSource: Get.find()),
    );
    Get.lazyPut<PreferencesRepository>(
      () => PreferencesRepositoryImpl(firebaseDataSource: Get.find()),
    );

    Get.lazyPut(() => CalculateBMR());
    Get.lazyPut(() => SearchProducts(Get.find()));
    Get.lazyPut(() => GetProductByBarcode(Get.find()));

    Get.lazyPut(() => UserService());
    Get.lazyPut(() => NutritionService());

    Get.put(AuthController(), permanent: true);
    Get.put(
      ProfileController(
        userRepository: Get.find(),
        nutritionRepository: Get.find(),
        preferencesRepository: Get.find(),
      ),
      permanent: true,
    );
    Get.put(
      NutritionController(Get.find(), Get.find(), Get.find()),
      permanent: true,
    );
    Get.lazyPut(() => MainController(), fenix: true);
    Get.lazyPut(() => HomeController(), fenix: true);
    Get.lazyPut(
      () => SearchController(preferencesRepository: Get.find()),
      fenix: true,
    );
    Get.lazyPut(() => ScanController(), fenix: true);
  }
}
