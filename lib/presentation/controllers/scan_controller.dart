import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:nutri_check/presentation/widgets/product_details_sheet.dart';
import 'package:openfoodfacts/openfoodfacts.dart';
import 'package:vibration/vibration.dart';

class ScanController extends GetxController {
  final GetStorage box = GetStorage();

  var scannedCodes = <String>[].obs;
  var recentProducts = <Product>[].obs;
  var currentProduct = Rxn<Product>();
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _setupOpenFoodFacts();
    _loadDataSafely();
  }

  void _setupOpenFoodFacts() {
    OpenFoodAPIConfiguration.userAgent = UserAgent(
      name: 'NutriCheck',
      version: '1.0.0',
      system: 'Flutter App',
    );
    OpenFoodAPIConfiguration.globalLanguages = <OpenFoodFactsLanguage>[
      OpenFoodFactsLanguage.ENGLISH,
    ];
    OpenFoodAPIConfiguration.globalCountry = OpenFoodFactsCountry.INDIA;
  }

  void _loadDataSafely() {
    try {
      _cleanupOldData();
      dynamic savedCodesRaw = box.read('scanned_codes_v3');
      if (savedCodesRaw != null) {
        try {
          List<String> savedCodes = List<String>.from(savedCodesRaw);
          scannedCodes.assignAll(savedCodes);
        } catch (e) {
          scannedCodes.clear();
        }
      }

      dynamic savedProductsRaw = box.read('recent_products_v3');
      if (savedProductsRaw != null) {
        try {
          List<Product> products = [];

          if (savedProductsRaw is List) {
            for (var item in savedProductsRaw) {
              try {
                Map<String, dynamic> productMap = Map<String, dynamic>.from(
                  item,
                );
                Nutriments? nutriments;
                if (productMap['nutrition'] != null &&
                    productMap['nutrition'] is Map) {
                  Map<String, dynamic> nutritionData =
                      Map<String, dynamic>.from(productMap['nutrition']);
                  if (nutritionData.isNotEmpty &&
                      nutritionData.values.any((v) => v != null && v != 0)) {
                    try {
                      nutriments = Nutriments.fromJson({
                        'energy-kcal_100g': nutritionData['energy-kcal'] ?? 0.0,
                        'proteins_100g': nutritionData['proteins'] ?? 0.0,
                        'carbohydrates_100g':
                            nutritionData['carbohydrates'] ?? 0.0,
                        'fat_100g': nutritionData['fat'] ?? 0.0,
                        'fiber_100g': nutritionData['fiber'] ?? 0.0,
                        'sugars_100g': nutritionData['sugars'] ?? 0.0,
                        'sodium_100g': nutritionData['sodium'] ?? 0.0,
                      });
                      if (kDebugMode) {
                        print(
                          'Reconstructed nutrition for ${productMap['productName']}: ${nutritionData['energy-kcal']} kcal',
                        );
                      }
                    } catch (e) {
                      if (kDebugMode) {
                        print('Error reconstructing Nutriments: $e');
                      }
                    }
                  }
                }

                // Create Product object with reconstructed nutrition
                Product product = Product(
                  barcode: productMap['barcode']?.toString(),
                  productName: productMap['productName']?.toString(),
                  brands: productMap['brands']?.toString(),
                  imageFrontUrl: productMap['imageFrontUrl']?.toString(),
                  categoriesTagsInLanguages:
                      productMap['categoriesTagsInLanguages'] != null
                      ? {
                          OpenFoodFactsLanguage.ENGLISH:
                              productMap['categoriesTagsInLanguages'],
                        }
                      : null,
                  ingredientsText: productMap['ingredientsText']?.toString(),
                  nutriments: nutriments,
                );

                products.add(product);
              } catch (e) {
                print('Error parsing individual product: $e');
              }
            }
          }

          recentProducts.assignAll(products);
          print('Loaded ${products.length} products with nutrition data');
        } catch (e) {
          print('Error parsing products: $e');
          recentProducts.clear();
        }
      }
    } catch (e) {
      print('Error loading data: $e');
      scannedCodes.clear();
      recentProducts.clear();
    }
  }

  void _cleanupOldData() {
    try {
      box.remove('scanned_codes');
      box.remove('recent_products');
      box.remove('scanned_codes_v2');
      box.remove('recent_products_v2');
    } catch (e) {
      print('Error cleaning up: $e');
    }
  }

  void _saveDataSafely() {
    try {
      box.write('scanned_codes_v3', scannedCodes.toList());
      List<Map<String, dynamic>> productMaps = recentProducts.map((product) {
        Map<String, dynamic> nutritionMap = {};
        if (product.nutriments != null) {
          nutritionMap = {
            'energy-kcal': _getCalories(product).toDouble(),
            'proteins': _getNutrientValue(product, Nutrient.proteins),
            'carbohydrates': _getNutrientValue(product, Nutrient.carbohydrates),
            'fat': _getNutrientValue(product, Nutrient.fat),
            'fiber': _getNutrientValue(product, Nutrient.fiber),
            'sugars': _getNutrientValue(product, Nutrient.sugars),
            'sodium': _getNutrientValue(product, Nutrient.sodium),
          };
        }

        return {
          'barcode': product.barcode ?? '',
          'productName': product.productName ?? '',
          'brands': product.brands ?? '',
          'imageFrontUrl': product.imageFrontUrl ?? '',
          'categoriesTagsInLanguages': product.categoriesTagsInLanguages
              ?.toString(),
          'ingredientsText': product.ingredientsText,
          'allergens': product.allergens?.toString(),
          'labels': product.labels?.toString(),
          'savedAt': DateTime.now().toIso8601String(),
          'nutrition': nutritionMap,
        };
      }).toList();

      box.write('recent_products_v3', productMaps);

      if (kDebugMode) {
        print('Saved ${recentProducts.length} products with nutrition data');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving data: $e');
      }
    }
  }

  Future<void> scanBarcode(String barcode) async {
    if (scannedCodes.contains(barcode)) {
      if (kDebugMode) {
        print('Already scanned: $barcode');
      }
      Flushbar(
        title: 'Already Scanned $barcode',
        message: 'This product is already in your history.',
        duration: Duration(seconds: 2),
      ).show(Get.context!);
      return;
    }

    try {
      if (kDebugMode) {
        print('Scanning: $barcode');
      }
      isLoading.value = true;

      //haptic feedback
      HapticFeedback.lightImpact();
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(duration: 100);
      }
      scannedCodes.add(barcode);
      final config = ProductQueryConfiguration(
        barcode,
        language: OpenFoodFactsLanguage.ENGLISH,
        fields: [ProductField.ALL],
        version: ProductQueryVersion.v3,
      );

      final result = await OpenFoodAPIClient.getProductV3(config);

      if (result.status == ProductResultV3.statusSuccess &&
          result.product != null) {
        final product = result.product!;
        if (kDebugMode) {
          print('Found: ${product.productName}');
        }

        currentProduct.value = product;

        if (!recentProducts.any((p) => p.barcode == product.barcode)) {
          recentProducts.insert(0, product);

          if (recentProducts.length > 50) {
            recentProducts.removeLast();
          }
        }

        _saveDataSafely();
        if (kDebugMode) {
          print('Product added to history: ${product.productName}');
        }

        Get.bottomSheet(
          isScrollControlled: true,
          ProductDetailsSheet(product: product),
        );
      } else {
        // alert dialog
        Get.dialog(
          AlertDialog(
            title: Text('Product Not Found'),
            content: Text('No product found for barcode $barcode.'),
            actions: [
              TextButton(onPressed: () => Get.back(), child: Text('OK')),
            ],
          ),
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  void clearAllHistory() {
    Get.dialog(
      AlertDialog(
        title: Text('Clear History'),
        content: Text('Delete all scan history?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              scannedCodes.clear();
              recentProducts.clear();
              currentProduct.value = null;
              box.remove('scanned_codes_v3');
              box.remove('recent_products_v3');
              _cleanupOldData();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void refreshRecentProducts() {
    _loadDataSafely();
    print('History refreshed');
  }

  int _getCalories(Product product) {
    try {
      if (product.nutriments != null) {
        final value = product.nutriments!.getValue(
          Nutrient.energyKCal,
          PerSize.oneHundredGrams,
        );
        return value?.toInt() ?? 0;
      }
      return 0;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting calories: $e');
      }
      return 0;
    }
  }

  double _getNutrientValue(Product product, Nutrient nutrient) {
    try {
      if (product.nutriments != null) {
        final value = product.nutriments!.getValue(
          nutrient,
          PerSize.oneHundredGrams,
        );
        return value ?? 0.0;
      }
      return 0.0;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting nutrient ${nutrient.toString()}: $e');
      }
      return 0.0;
    }
  }

  String getNutritionSummary(Product product) {
    final calories = _getCalories(product);
    final proteins = _getNutrientValue(product, Nutrient.proteins);
    final carbs = _getNutrientValue(product, Nutrient.carbohydrates);
    final fats = _getNutrientValue(product, Nutrient.fat);

    return '$calories kcal • P:${proteins.toStringAsFixed(1)}g • C:${carbs.toStringAsFixed(1)}g • F:${fats.toStringAsFixed(1)}g';
  }

  void clearScannedCodes() {
    scannedCodes.clear();
    currentProduct.value = null;
    _saveDataSafely();
  }

  Future<void> deleteProductFromHistory(Product product) async {
    recentProducts.removeWhere((p) => p.barcode == product.barcode);
    scannedCodes.removeWhere((code) => code == product.barcode);
    _saveDataSafely();
    if (kDebugMode) {
      print('Product deleted: ${product.productName}');
    }
  }
}
