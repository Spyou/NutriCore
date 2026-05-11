import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:nutri_check/core/config/off_config.dart';
import 'package:nutri_check/presentation/widgets/product_details_sheet.dart';
import 'package:openfoodfacts/openfoodfacts.dart';
import 'package:vibration/vibration.dart';

class ScanController extends GetxController {
  final GetStorage box = GetStorage();

  var scannedCodes = <String>[].obs;
  var recentProducts = <Product>[].obs;
  var currentProduct = Rxn<Product>();
  var isLoading = false.obs;
  var lookupError = ''.obs;

  static const Duration _barcodeCacheTtl = Duration(minutes: 10);
  static const String _barcodeCachePrefix = 'barcode_cache:';

  /// Fields requested for a single-product barcode lookup. Narrowed to
  /// exactly what the details sheet + AddToMealSheet render so the OFF
  /// payload stays small and the response returns faster.
  static const List<ProductField> _barcodeFields = [
    ProductField.BARCODE,
    ProductField.NAME,
    ProductField.BRANDS,
    ProductField.CATEGORIES,
    ProductField.NUTRIMENTS,
    ProductField.IMAGE_FRONT_URL,
    ProductField.IMAGE_FRONT_SMALL_URL,
    ProductField.INGREDIENTS_TEXT,
    ProductField.QUANTITY,
  ];

  /// Reads a cached barcode lookup. Returns null on miss, expiry, or any
  /// deserialization failure.
  Product? _readBarcodeCache(String code) {
    try {
      final dynamic raw = box.read('$_barcodeCachePrefix$code');
      if (raw is! Map) return null;
      final Map<String, dynamic> entry = Map<String, dynamic>.from(raw);
      final int savedAt = (entry['savedAt'] as num?)?.toInt() ?? 0;
      final int now = DateTime.now().millisecondsSinceEpoch;
      if (now - savedAt > _barcodeCacheTtl.inMilliseconds) return null;
      final dynamic productRaw = entry['product'];
      if (productRaw is! Map) return null;
      return Product.fromJson(Map<String, dynamic>.from(productRaw));
    } catch (e) {
      if (kDebugMode) {
        print('Barcode cache read failed: $e');
      }
      return null;
    }
  }

  /// Persists [product] under the barcode cache key. Silently skips on
  /// any serialization failure so a cache miss never crashes the scan flow.
  Future<void> _writeBarcodeCache(String code, Product product) async {
    try {
      box.write('$_barcodeCachePrefix$code', {
        'savedAt': DateTime.now().millisecondsSinceEpoch,
        'product': product.toJson(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Barcode cache write failed: $e');
      }
    }
  }

  @override
  void onInit() {
    super.onInit();
    OpenFoodFactsConfig.initialize();
    _loadDataSafely();
  }

  void _loadDataSafely() {
    try {
      _cleanupOldData();
      final dynamic savedCodesRaw = box.read('scanned_codes_v3');
      if (savedCodesRaw != null) {
        try {
          final List<String> savedCodes = List<String>.from(savedCodesRaw);
          scannedCodes.assignAll(savedCodes);
        } catch (e) {
          scannedCodes.clear();
        }
      }

      final dynamic savedProductsRaw = box.read('recent_products_v3');
      if (savedProductsRaw != null) {
        try {
          final List<Product> products = [];

          if (savedProductsRaw is List) {
            for (var item in savedProductsRaw) {
              try {
                if (item is! Map) {
                  if (kDebugMode) {
                    print('Skipping product entry of unexpected type: '
                        '${item.runtimeType}');
                  }
                  continue;
                }
                final Map<String, dynamic> productMap =
                    Map<String, dynamic>.from(item);

                Nutriments? nutriments;
                final dynamic rawNutrition = productMap['nutrition'];
                if (rawNutrition is Map) {
                  try {
                    final Map<String, dynamic> nutritionData =
                        Map<String, dynamic>.from(rawNutrition);
                    if (nutritionData.isNotEmpty &&
                        nutritionData.values.any((v) => v != null && v != 0)) {
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
                        debugPrint(
                          'Reconstructed nutrition for '
                          '${productMap['productName']}: '
                          '${nutritionData['energy-kcal']} kcal',
                        );
                      }
                    }
                  } catch (e) {
                    debugPrint('Error reconstructing Nutriments: $e');
                  }
                }

                // Safely read categories as a list of strings.
                List<String>? categoriesList;
                final dynamic rawCategories =
                    productMap['categoriesTagsInLanguages'];
                if (rawCategories is List) {
                  categoriesList = rawCategories
                      .map((e) => e?.toString() ?? '')
                      .where((e) => e.isNotEmpty)
                      .toList();
                }

                // Create Product object with reconstructed nutrition.
                final Product product = Product(
                  barcode: productMap['barcode'] as String?,
                  productName: productMap['productName'] as String?,
                  brands: productMap['brands'] as String?,
                  imageFrontUrl: productMap['imageFrontUrl'] as String?,
                  categoriesTagsInLanguages:
                      (categoriesList != null && categoriesList.isNotEmpty)
                      ? {OpenFoodFactsLanguage.ENGLISH: categoriesList}
                      : null,
                  ingredientsText: productMap['ingredientsText'] as String?,
                  nutriments: nutriments,
                );

                products.add(product);
              } catch (e, st) {
                // Fragile shape: log and skip this entry rather than
                // silently producing a malformed Product.
                debugPrint('Error parsing individual product: $e');
                debugPrint('$st');
              }
            }
          }

          recentProducts.assignAll(products);
          if (kDebugMode) {
            print('Loaded ${products.length} products with nutrition data');
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing products: $e');
          }
          recentProducts.clear();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading data: $e');
      }
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
      if (kDebugMode) {
        print('Error cleaning up: $e');
      }
    }
  }

  void _saveDataSafely() {
    try {
      box.write('scanned_codes_v3', scannedCodes.toList());
      final List<Map<String, dynamic>> productMaps = recentProducts.map((
        product,
      ) {
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

        // Persist categories as a real List<String> so it can be parsed
        // back on reload. Using .toString() produced "[a, b, c]" which
        // was unparseable.
        final List<String> categoriesForLanguage = product
                .categoriesTagsInLanguages?[OpenFoodFactsLanguage.ENGLISH] ??
            const <String>[];

        return {
          'barcode': product.barcode ?? '',
          'productName': product.productName ?? '',
          'brands': product.brands ?? '',
          'imageFrontUrl': product.imageFrontUrl ?? '',
          'categoriesTagsInLanguages': categoriesForLanguage,
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
    return _scanBarcodeInternal(barcode, bypassCache: false);
  }

  /// Public force-refresh entry point. Skips the local cache so a stale
  /// or incomplete OFF payload can be re-fetched on demand.
  Future<void> rescanBarcode(String code) async {
    return _scanBarcodeInternal(code, bypassCache: true);
  }

  Future<void> _scanBarcodeInternal(
    String barcode, {
    required bool bypassCache,
  }) async {
    // Reset the not-found state at the very start of every lookup so the
    // UI can rebind cleanly on rescan.
    lookupError.value = '';

    if (!bypassCache && scannedCodes.contains(barcode)) {
      if (kDebugMode) {
        print('Already scanned: $barcode');
      }
      final ctx = Get.context;
      if (ctx == null) return;
      Flushbar(
        title: 'Already Scanned $barcode',
        message: 'This product is already in your history.',
        duration: const Duration(seconds: 2),
      ).show(ctx);
      return;
    }

    try {
      if (kDebugMode) {
        print('Scanning: $barcode (bypassCache=$bypassCache)');
      }
      isLoading.value = true;

      //haptic feedback
      HapticFeedback.lightImpact();
      if (await Vibration.hasVibrator()) {
        Vibration.vibrate(duration: 100);
      }

      // Cache hit short-circuit. Only consult the cache on a normal scan;
      // a forced rescan always hits the network for a fresh payload.
      if (!bypassCache) {
        final cached = _readBarcodeCache(barcode);
        if (cached != null) {
          if (kDebugMode) {
            print('Barcode cache hit: $barcode → ${cached.productName}');
          }
          currentProduct.value = cached;
          if (!scannedCodes.contains(barcode)) {
            scannedCodes.add(barcode);
          }
          if (!recentProducts.any((p) => p.barcode == cached.barcode)) {
            recentProducts.insert(0, cached);
            if (recentProducts.length > 50) {
              recentProducts.removeLast();
            }
          }
          _saveDataSafely();
          Get.bottomSheet(
            isScrollControlled: true,
            ProductDetailsSheet(product: cached),
          );
          return;
        }
      }

      if (!scannedCodes.contains(barcode)) {
        scannedCodes.add(barcode);
      }

      // Use ProductQueryVersion(2) — mirrors what search controller uses
      // and returns faster than v3 in our usage. The narrowed field list
      // keeps the payload small.
      final config = ProductQueryConfiguration(
        barcode,
        language: OpenFoodFactsLanguage.ENGLISH,
        fields: _barcodeFields,
        version: const ProductQueryVersion(2),
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
        await _writeBarcodeCache(barcode, product);
        if (kDebugMode) {
          print('Product added to history: ${product.productName}');
        }

        Get.bottomSheet(
          isScrollControlled: true,
          ProductDetailsSheet(product: product),
        );
      } else {
        // Surface a not-found state so the page can render a friendly empty
        // view instead of leaving the previous product on screen.
        lookupError.value = 'Product not in our database';
        Get.dialog(
          AlertDialog(
            title: const Text('Product Not Found'),
            content: Text('No product found for barcode $barcode.'),
            actions: [
              TextButton(onPressed: () => Get.back(), child: const Text('OK')),
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
        title: const Text('Clear History'),
        content: const Text('Delete all scan history?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
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
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void refreshRecentProducts() {
    _loadDataSafely();
    if (kDebugMode) {
      print('History refreshed');
    }
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
