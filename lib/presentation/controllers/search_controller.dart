import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nutri_check/core/utils/components/custom_flushbar.dart';
import 'package:nutri_check/presentation/controllers/auth_controller.dart';
import 'package:nutri_check/presentation/controllers/nutrition_controller.dart';
import 'package:openfoodfacts/openfoodfacts.dart';

class SearchController extends GetxController {
  var isLoading = false.obs;
  var searchQuery = ''.obs;
  var searchResults = <Product>[].obs;
  var recentSearches = <String>[].obs;
  var suggestedProducts = <Product>[].obs;
  var selectedCategory = 'all'.obs;

  final TextEditingController textController = TextEditingController();

  // Categories for filtering
  final List<String> categories = [
    'all',
    'beverages',
    'dairy',
    'snacks',
    'cereals',
    'fruits',
    'vegetables',
    'meat',
    'seafood',
    'bakery',
  ];

  @override
  void onInit() {
    super.onInit();
    _setupOpenFoodFacts();
    _loadRecentSearches();
    _loadSuggestedProducts();
  }

  @override
  void onClose() {
    textController.dispose();
    super.onClose();
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

  // Search products using OpenFoodFacts API
  Future<void> searchProducts(String query) async {
    if (query.trim().isEmpty) {
      searchResults.clear();
      return;
    }

    try {
      isLoading.value = true;
      searchQuery.value = query;

      // Add to recent searches
      if (!recentSearches.contains(query)) {
        recentSearches.insert(0, query);
        if (recentSearches.length > 10) {
          recentSearches.removeLast();
        }
        await _saveRecentSearch(query);
      }
      final SearchResult result = await OpenFoodAPIClient.searchProducts(
        null,
        ProductSearchQueryConfiguration(
          parametersList: [
            SearchTerms(terms: [query]),
          ],
          fields: [
            ProductField.BARCODE,
            ProductField.NAME,
            ProductField.BRANDS,
            ProductField.CATEGORIES,
            ProductField.NUTRIMENTS,
          ],
          language: OpenFoodFactsLanguage.ENGLISH,
          country: OpenFoodFactsCountry.INDIA,
          version: ProductQueryVersion.v3,
        ),
      );

      if (result.products != null) {
        searchResults.assignAll(result.products!);
        if (kDebugMode) {
          print('Found ${result.products!.length} products for: $query');
        }
      } else {
        searchResults.clear();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Search error: $e');
      }

      CustomThemeFlushbar(
        title: 'Search Error',
        message: 'Failed to search products: ${e.toString()}',
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Filter results
  void filterByCategory(String category) {
    selectedCategory.value = category;
    if (searchQuery.value.isNotEmpty) {
      searchProducts(searchQuery.value);
    }
  }

  // Clear search
  void clearSearch() {
    textController.clear();
    searchQuery.value = '';
    searchResults.clear();
  }

  // Load recent searches from Firebase
  Future<void> _loadRecentSearches() async {
    try {
      final authController = Get.find<AuthController>();
      if (authController.user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('user_preferences')
          .doc(authController.user!.uid)
          .get();

      if (doc.exists) {
        final data = doc.data();
        if (data?['recentSearches'] != null) {
          recentSearches.assignAll(List<String>.from(data!['recentSearches']));
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading recent searches: $e');
      }
    }
  }

  // Save recent search to Firebase
  Future<void> _saveRecentSearch(String query) async {
    try {
      final authController = Get.find<AuthController>();
      if (authController.user == null) return;

      await FirebaseFirestore.instance
          .collection('user_preferences')
          .doc(authController.user!.uid)
          .set({
            'recentSearches': recentSearches.toList(),
            'updatedAt': DateTime.now().toIso8601String(),
          }, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) {
        print('Error saving recent search: $e');
      }
    }
  }

  // suggested products
  Future<void> _loadSuggestedProducts() async {
    try {
      final SearchResult result = await OpenFoodAPIClient.searchProducts(
        null,
        ProductSearchQueryConfiguration(
          parametersList: [
            SearchTerms(terms: ['healthy', 'snacks']),
          ],
          fields: [
            ProductField.BARCODE,
            ProductField.NAME,
            ProductField.BRANDS,
            ProductField.NUTRIMENTS,
          ],
          language: OpenFoodFactsLanguage.ENGLISH,
          country: OpenFoodFactsCountry.INDIA,
          version: ProductQueryVersion.v3,
        ),
      );

      if (result.products != null) {
        suggestedProducts.assignAll(result.products!);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading suggested products: $e');
      }
    }
  }

  // Add product to nutrition log
  Future<void> addProductToNutrition(Product product) async {
    try {
      final nutritionController = Get.find<NutritionController>();
      final quantityController = TextEditingController(text: '100');
      String selectedMealType = 'meal';

      final result = await Get.dialog<Map<String, dynamic>>(
        AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text('Add to Nutrition Log'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                product.productName ?? 'Unknown Product',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              TextField(
                controller: quantityController,
                decoration: InputDecoration(
                  labelText: 'Quantity (grams)',
                  border: OutlineInputBorder(),
                  suffixText: 'g',
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedMealType,
                decoration: InputDecoration(
                  labelText: 'Meal Type',
                  border: OutlineInputBorder(),
                ),
                items: ['breakfast', 'lunch', 'dinner', 'snack', 'meal']
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.capitalize!),
                      ),
                    )
                    .toList(),
                onChanged: (value) => selectedMealType = value ?? 'meal',
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Get.back(), child: Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final quantity =
                    double.tryParse(quantityController.text) ?? 100;
                Get.back(
                  result: {'quantity': quantity, 'mealType': selectedMealType},
                );
              },
              child: Text('Add'),
            ),
          ],
        ),
      );

      if (result != null) {
        final quantity = result['quantity'] as double;
        final mealType = result['mealType'] as String;
        final factor = quantity / 100;

        final calories = getCalories(product);
        final proteins = getNutrientValue(product, Nutrient.proteins);
        final carbs = getNutrientValue(product, Nutrient.carbohydrates);
        final fats = getNutrientValue(product, Nutrient.fat);

        final meal = {
          'name': product.productName ?? 'Search Result',
          'calories': (calories * factor).round(),
          'proteins': (proteins * factor),
          'carbs': (carbs * factor),
          'fat': (fats * factor),
          'fiber': (getNutrientValue(product, Nutrient.fiber) * factor),
          'sugar': (getNutrientValue(product, Nutrient.sugars) * factor),
          'sodium': (getNutrientValue(product, Nutrient.sodium) * factor),
          'type': mealType,
          'time':
              '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
          'quantity': quantity,
          'barcode': product.barcode,
          'brands': product.brands,
          'notes': 'Added from search',
          'favorite': false,
        };

        await nutritionController.addMeal(meal);

        CustomThemeFlushbar(
          title: 'Success',
          message: '${product.productName} added to nutrition log',
        );
      }
    } catch (e) {
      CustomThemeFlushbar(
        title: 'Error',
        message: 'Failed to add product to nutrition log',
      );
    }
  }

  // Helper methods for nutrition values
  int getCalories(Product product) {
    try {
      return product.nutriments
              ?.getValue(Nutrient.energyKCal, PerSize.oneHundredGrams)
              ?.toInt() ??
          0;
    } catch (e) {
      return 0;
    }
  }

  double getNutrientValue(Product product, Nutrient nutrient) {
    try {
      return product.nutriments?.getValue(nutrient, PerSize.oneHundredGrams) ??
          0.0;
    } catch (e) {
      return 0.0;
    }
  }

  // Clear recent searches
  Future<void> clearRecentSearches() async {
    recentSearches.clear();

    try {
      final authController = Get.find<AuthController>();
      if (authController.user != null) {
        await FirebaseFirestore.instance
            .collection('user_preferences')
            .doc(authController.user!.uid)
            .update({'recentSearches': []});
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing recent searches: $e');
      }
    }

    CustomThemeFlushbar(title: 'Cleared', message: 'Recent searches cleared');
  }

  Widget buildCategoryIcon(Product product) {
    final categoryInfo = _getCategoryFromProduct(product);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: categoryInfo['gradient'] as List<Color>,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Icon(
          categoryInfo['icon'] as IconData,
          color: Colors.white,
          size: categoryInfo['size'] as double,
        ),
      ),
    );
  }

  Map<String, dynamic> _getCategoryFromProduct(Product product) {
    final productName = (product.productName ?? '').toLowerCase();
    final categories = (product.categories ?? '').toLowerCase();
    final brands = (product.brands ?? '').toLowerCase();
    final fullText = '$productName $categories $brands';

    // Chocolate & Sweets
    if (_containsAny(fullText, [
      'chocolate',
      'candy',
      'sweet',
      'cookie',
      'biscuit',
      'cake',
      'pastry',
      'dessert',
      'ice cream',
      'cadbury',
      'nestle',
      'kitkat',
      'snickers',
    ])) {
      return {
        'icon': Icons.cake,
        'gradient': [Colors.brown[400]!, Colors.brown[600]!],
        'size': 30.0,
        'category': 'Sweets & Desserts',
      };
    }

    // Dairy Products
    if (_containsAny(fullText, [
      'milk',
      'cheese',
      'yogurt',
      'yoghurt',
      'butter',
      'cream',
      'dairy',
      'lassi',
      'curd',
      'paneer',
      'amul',
      'mother dairy',
    ])) {
      return {
        'icon': Icons.water_drop,
        'gradient': [Colors.blue[300]!, Colors.blue[500]!],
        'size': 28.0,
        'category': 'Dairy Products',
      };
    }

    // Beverages
    if (_containsAny(fullText, [
      'drink',
      'juice',
      'soda',
      'cola',
      'pepsi',
      'coca',
      'water',
      'tea',
      'coffee',
      'beverage',
      'shake',
      'smoothie',
      'thumsup',
    ])) {
      return {
        'icon': Icons.local_drink,
        'gradient': [Colors.cyan[400]!, Colors.cyan[600]!],
        'size': 28.0,
        'category': 'Beverages',
      };
    }

    // Bakery & Bread
    if (_containsAny(fullText, [
      'bread',
      'bun',
      'roll',
      'toast',
      'bakery',
      'croissant',
      'muffin',
      'bagel',
      'baguette',
    ])) {
      return {
        'icon': Icons.bakery_dining,
        'gradient': [Colors.orange[400]!, Colors.orange[600]!],
        'size': 28.0,
        'category': 'Bakery',
      };
    }

    // Fruits
    if (_containsAny(fullText, [
      'fruit',
      'apple',
      'banana',
      'orange',
      'grape',
      'berry',
      'mango',
      'pineapple',
      'strawberry',
      'kiwi',
      'peach',
    ])) {
      return {
        'icon': Icons.apple,
        'gradient': [Colors.red[400]!, Colors.red[600]!],
        'size': 28.0,
        'category': 'Fruits',
      };
    }

    // Vegetables
    if (_containsAny(fullText, [
      'vegetable',
      'carrot',
      'broccoli',
      'spinach',
      'lettuce',
      'tomato',
      'cucumber',
      'pepper',
      'onion',
      'potato',
    ])) {
      return {
        'icon': Icons.eco,
        'gradient': [Colors.green[400]!, Colors.green[600]!],
        'size': 28.0,
        'category': 'Vegetables',
      };
    }

    // Meat & Protein
    if (_containsAny(fullText, [
      'meat',
      'chicken',
      'beef',
      'pork',
      'fish',
      'salmon',
      'tuna',
      'protein',
      'egg',
      'seafood',
    ])) {
      return {
        'icon': Icons.restaurant,
        'gradient': [Colors.red[700]!, Colors.red[900]!],
        'size': 28.0,
        'category': 'Meat & Protein',
      };
    }

    // Grains & Cereals
    if (_containsAny(fullText, [
      'cereal',
      'rice',
      'wheat',
      'oat',
      'grain',
      'pasta',
      'noodle',
      'quinoa',
      'barley',
      'corn',
    ])) {
      return {
        'icon': Icons.grass,
        'gradient': [Colors.amber[600]!, Colors.amber[800]!],
        'size': 28.0,
        'category': 'Grains & Cereals',
      };
    }

    // Nuts & Seeds
    if (_containsAny(fullText, [
      'nut',
      'almond',
      'peanut',
      'cashew',
      'walnut',
      'seed',
      'sunflower',
      'pumpkin',
    ])) {
      return {
        'icon': Icons.scatter_plot,
        'gradient': [Colors.brown[300]!, Colors.brown[500]!],
        'size': 26.0,
        'category': 'Nuts & Seeds',
      };
    }

    // Snacks & Fast Food
    if (_containsAny(fullText, [
      'snack',
      'chip',
      'crisp',
      'popcorn',
      'pretzel',
      'cracker',
      'fast food',
      'fries',
      'burger',
      'pizza',
    ])) {
      return {
        'icon': Icons.fastfood,
        'gradient': [Colors.deepOrange[400]!, Colors.deepOrange[600]!],
        'size': 28.0,
        'category': 'Snacks & Fast Food',
      };
    }

    // Condiments & Sauces
    if (_containsAny(fullText, [
      'sauce',
      'ketchup',
      'mayo',
      'mustard',
      'honey',
      'jam',
      'syrup',
      'vinegar',
      'oil',
      'spice',
    ])) {
      return {
        'icon': Icons.water_drop_outlined,
        'gradient': [Colors.yellow[600]!, Colors.yellow[800]!],
        'size': 26.0,
        'category': 'Condiments',
      };
    }

    // General Food
    return {
      'icon': Icons.restaurant_menu,
      'gradient': [Colors.grey[400]!, Colors.grey[600]!],
      'size': 28.0,
      'category': 'Food Product',
    };
  }

  bool _containsAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }

  // category name
  String getCategoryName(Product product) {
    final categoryInfo = _getCategoryFromProduct(product);
    return categoryInfo['category'] as String;
  }
}
