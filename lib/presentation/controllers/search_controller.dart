import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:nutri_check/core/config/off_config.dart';
import 'package:nutri_check/core/utils/components/custom_flushbar.dart';
import 'package:nutri_check/domain/repositories/preferences_repository.dart';
import 'package:nutri_check/presentation/controllers/auth_controller.dart';
import 'package:nutri_check/presentation/widgets/shared/add_to_meal_sheet.dart';
import 'package:openfoodfacts/openfoodfacts.dart';

class SearchController extends GetxController {
  final PreferencesRepository _preferencesRepository;

  SearchController({required PreferencesRepository preferencesRepository})
    : _preferencesRepository = preferencesRepository;

  final GetStorage _box = GetStorage();
  static const Duration _cacheTtl = Duration(minutes: 10);
  static const String _cacheKeyPrefix = 'search_cache:';

  var isLoading = false.obs;
  var searchQuery = ''.obs;
  var searchResults = <Product>[].obs;
  var recentSearches = <String>[].obs;
  var suggestedProducts = <Product>[].obs;
  var selectedCategory = 'all'.obs;
  var errorMessage = ''.obs;

  final RxInt currentPage = 1.obs;
  final RxBool hasMore = true.obs;
  final RxBool isLoadingMore = false.obs;
  static const int _pageSize = 50;

  /// Fields requested for each product in search results. Centralised here
  /// so the initial search and `loadMore` stay in sync.
  List<ProductField> get _searchFields => const [
        ProductField.BARCODE,
        ProductField.NAME,
        ProductField.BRANDS,
        ProductField.CATEGORIES,
        ProductField.NUTRIMENTS,
        ProductField.IMAGE_FRONT_URL,
        ProductField.IMAGE_FRONT_SMALL_URL,
      ];

  final TextEditingController textController = TextEditingController();

  Timer? _debounce;
  int _searchId = 0; // monotonic — used to ignore stale responses

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
    OpenFoodFactsConfig.initialize();
    _loadRecentSearches();
    _loadSuggestedProducts();
  }

  @override
  void onClose() {
    _debounce?.cancel();
    textController.dispose();
    super.onClose();
  }

  /// Live-debounced entry point bound to the text field's `onChanged`.
  /// Flips `isLoading` immediately so the shimmer is visible before any
  /// network/cache work resolves.
  void onSearchChanged(String query) {
    _debounce?.cancel();
    final trimmed = query.trim();
    searchQuery.value = trimmed;
    // Reset pagination state for the new query.
    currentPage.value = 1;
    hasMore.value = true;
    if (trimmed.length < 2) {
      searchResults.clear();
      isLoading.value = false;
      errorMessage.value = '';
      return;
    }
    // Show shimmer instantly — even before API/cache resolves
    isLoading.value = true;
    _debounce = Timer(const Duration(milliseconds: 350), () {
      searchProducts(trimmed);
    });
  }

  /// Save a query to recent searches. Called on Enter / when a user
  /// taps a result — NOT on every keystroke. Avoids polluting history
  /// with partial queries.
  Future<void> rememberQuery(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    if (recentSearches.contains(q)) {
      // Move to top
      recentSearches.remove(q);
    }
    recentSearches.insert(0, q);
    if (recentSearches.length > 10) {
      recentSearches.removeLast();
    }
    await _saveRecentSearch(q);
  }

  /// Called from the search field's onSubmitted (Enter). Commits the
  /// query to history and ensures a fetch fires immediately.
  Future<void> commitSearch(String query) async {
    _debounce?.cancel();
    await rememberQuery(query);
    await searchProducts(query);
  }

  Future<void> searchProducts(String query) async {
    if (query.trim().isEmpty) {
      searchResults.clear();
      return;
    }

    // Reset pagination — every fresh search starts at page 1.
    currentPage.value = 1;
    hasMore.value = true;

    final int myId = ++_searchId;

    try {
      isLoading.value = true;
      errorMessage.value = '';
      searchQuery.value = query;

      // Try cache first (TTL 10 minutes). Skip the network entirely on hit.
      final cached = _readCache(query);
      if (cached != null) {
        // Delay so shimmer is actually visible on a cache hit — without
        // this, the loading state vanishes within a frame and users think
        // the UI is broken.
        await Future.delayed(const Duration(milliseconds: 350));
        if (myId != _searchId) return;
        searchResults.assignAll(cached);
        if (kDebugMode) {
          print('Loaded ${cached.length} cached products for: $query');
        }
        isLoading.value = false;
        return;
      }

      final SearchResult result = await OpenFoodAPIClient.searchProducts(
        null,
        ProductSearchQueryConfiguration(
          parametersList: [
            SearchTerms(terms: [query]),
            const PageSize(size: _pageSize),
            const PageNumber(page: 1),
          ],
          fields: _searchFields,
          language: OpenFoodFactsLanguage.ENGLISH,
          country: OpenFoodFactsCountry.INDIA,
          version: const ProductQueryVersion(2),
        ),
      );

      if (myId != _searchId) return;

      if (result.products != null) {
        searchResults.assignAll(result.products!);
        hasMore.value = result.products!.length >= _pageSize;
        _writeCache(query, result.products!);
        if (kDebugMode) {
          print('Page 1: ${result.products!.length} products, '
              'hasMore=${hasMore.value}, totalCount=${result.count}');
        }
      } else {
        searchResults.clear();
        hasMore.value = false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Search error: $e');
      }

      if (myId != _searchId) return;
      searchResults.clear();
      errorMessage.value = 'Search is taking a break. Tap to retry.';
    } finally {
      if (myId == _searchId) {
        isLoading.value = false;
      }
    }
  }

  /// Fetches the next page of results for the current query and appends
  /// them to [searchResults]. No-ops while a fetch is already in flight,
  /// when the previous page returned fewer than [_pageSize] items, or
  /// while the initial search is still loading.
  Future<void> loadMore() async {
    if (isLoadingMore.value || !hasMore.value || isLoading.value) return;
    final q = searchQuery.value.trim();
    if (q.length < 2) return;
    try {
      isLoadingMore.value = true;
      final nextPage = currentPage.value + 1;
      final result = await OpenFoodAPIClient.searchProducts(
        null,
        ProductSearchQueryConfiguration(
          parametersList: [
            SearchTerms(terms: [q]),
            const PageSize(size: _pageSize),
            PageNumber(page: nextPage),
          ],
          fields: _searchFields,
          language: OpenFoodFactsLanguage.ENGLISH,
          country: OpenFoodFactsCountry.INDIA,
          version: const ProductQueryVersion(2),
        ),
      );
      if (kDebugMode) {
        print('loadMore page $nextPage → '
            '${result.products?.length ?? 0} products');
      }
      if (result.products != null && result.products!.isNotEmpty) {
        searchResults.addAll(result.products!);
        currentPage.value = nextPage;
        if (result.products!.length < _pageSize) hasMore.value = false;
      } else {
        hasMore.value = false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('loadMore error on page ${currentPage.value + 1}: $e');
      }
      hasMore.value = false;
    } finally {
      isLoadingMore.value = false;
    }
  }

  void filterByCategory(String category) {
    selectedCategory.value = category;
    if (searchQuery.value.isNotEmpty) {
      searchProducts(searchQuery.value);
    }
  }

  void clearSearch() {
    textController.clear();
    searchQuery.value = '';
    searchResults.clear();
    currentPage.value = 1;
    hasMore.value = true;
    isLoadingMore.value = false;
  }

  String _cacheKey(String query) =>
      '$_cacheKeyPrefix${query.trim().toLowerCase()}';

  /// Reads cached search results for [query]. Returns null on miss,
  /// expiry, or any deserialization failure.
  List<Product>? _readCache(String query) {
    try {
      final dynamic raw = _box.read(_cacheKey(query));
      if (raw is! Map) return null;
      final Map<String, dynamic> entry = Map<String, dynamic>.from(raw);
      final int savedAt = (entry['savedAt'] as num?)?.toInt() ?? 0;
      final int now = DateTime.now().millisecondsSinceEpoch;
      if (now - savedAt > _cacheTtl.inMilliseconds) return null;
      final dynamic productsRaw = entry['products'];
      if (productsRaw is! List) return null;
      final List<Product> products = [];
      for (final item in productsRaw) {
        if (item is Map) {
          try {
            products.add(
              Product.fromJson(Map<String, dynamic>.from(item)),
            );
          } catch (_) {
            // Skip malformed entry rather than failing the whole cache.
          }
        }
      }
      return products;
    } catch (e) {
      if (kDebugMode) {
        print('Search cache read failed: $e');
      }
      return null;
    }
  }

  /// Persists [products] under the cache key for [query]. Silently
  /// skips on any serialization failure so a cache miss never crashes
  /// the search flow.
  void _writeCache(String query, List<Product> products) {
    try {
      final List<Map<String, dynamic>> productMaps = [];
      for (final p in products) {
        try {
          productMaps.add(p.toJson());
        } catch (_) {
          // Skip products that can't be serialized.
        }
      }
      _box.write(_cacheKey(query), {
        'savedAt': DateTime.now().millisecondsSinceEpoch,
        'products': productMaps,
      });
    } catch (e) {
      if (kDebugMode) {
        print('Search cache write failed: $e');
      }
    }
  }

  Future<void> _loadRecentSearches() async {
    try {
      if (!Get.isRegistered<AuthController>()) return;
      final authController = Get.find<AuthController>();
      if (authController.user == null) return;

      final result = await _preferencesRepository.getPreferences(
        authController.user!.uid,
      );
      if (result.isSuccess) {
        final searches = result.value.recentSearches;
        recentSearches.assignAll(searches);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading recent searches: $e');
      }
    }
  }

  Future<void> _saveRecentSearch(String query) async {
    try {
      if (!Get.isRegistered<AuthController>()) return;
      final authController = Get.find<AuthController>();
      if (authController.user == null) return;

      await _preferencesRepository.addRecentSearch(
        authController.user!.uid,
        query,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error saving recent search: $e');
      }
    }
  }

  Future<void> _loadSuggestedProducts() async {
    try {
      final SearchResult result = await OpenFoodAPIClient.searchProducts(
        null,
        ProductSearchQueryConfiguration(
          parametersList: [
            const SearchTerms(terms: ['healthy', 'snacks']),
          ],
          fields: [
            ProductField.BARCODE,
            ProductField.NAME,
            ProductField.BRANDS,
            ProductField.NUTRIMENTS,
            ProductField.IMAGE_FRONT_URL,
            ProductField.IMAGE_FRONT_SMALL_URL,
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

  Future<void> addProductToNutrition(Product product) async {
    final ctx = Get.context;
    if (ctx == null) return;
    await AddToMealSheet.show(ctx, product);
  }

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

  Future<void> clearRecentSearches() async {
    recentSearches.clear();

    try {
      if (Get.isRegistered<AuthController>()) {
        final authController = Get.find<AuthController>();
        if (authController.user != null) {
          await _preferencesRepository.clearRecentSearches(
            authController.user!.uid,
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing recent searches: $e');
      }
    }

    CustomThemeFlushbar.show(
      title: 'Cleared',
      message: 'Recent searches cleared',
    );
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

    return {
      'icon': Icons.restaurant_menu,
      'gradient': [Colors.grey[400]!, Colors.grey[600]!],
      'size': 28.0,
      'category': 'Food Product',
      'known': false,
    };
  }

  bool _containsAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }

  String getCategoryName(Product product) {
    final categoryInfo = _getCategoryFromProduct(product);
    return categoryInfo['category'] as String;
  }

  /// Returns a friendly category label only when the product matches a
  /// well-known category. Returns null when the product can't be confidently
  /// classified, so the UI can hide the pill instead of showing nonsense
  /// (the leading entry in OFF `categoriesTags` is often unreliable).
  String? getKnownCategoryName(Product product) {
    final productName = (product.productName ?? '').toLowerCase();
    final categories = (product.categories ?? '').toLowerCase();
    final brands = (product.brands ?? '').toLowerCase();
    final fullText = '$productName $categories $brands';

    const knownGroups = <String, List<String>>{
      'Sweets': [
        'chocolate', 'candy', 'sweet', 'cookie', 'biscuit', 'cake',
        'pastry', 'dessert', 'ice cream', 'cadbury', 'kitkat', 'snickers',
      ],
      'Dairy': [
        'milk', 'cheese', 'yogurt', 'yoghurt', 'butter', 'cream',
        'dairy', 'lassi', 'curd', 'paneer', 'amul',
      ],
      'Drinks': [
        'drink', 'juice', 'soda', 'cola', 'pepsi', 'coca', 'tea',
        'coffee', 'beverage', 'shake', 'smoothie', 'thumsup',
      ],
      'Bakery': [
        'bread', 'bun', 'roll', 'toast', 'bakery', 'croissant',
        'muffin', 'bagel', 'baguette',
      ],
      'Fruits': [
        'fruit', 'apple', 'banana', 'orange', 'grape', 'berry',
        'mango', 'pineapple', 'strawberry', 'kiwi', 'peach',
      ],
      'Vegetables': [
        'vegetable', 'carrot', 'broccoli', 'spinach', 'lettuce',
        'tomato', 'cucumber', 'pepper', 'onion', 'potato',
      ],
      'Meat': [
        'meat', 'chicken', 'beef', 'pork', 'fish', 'salmon', 'tuna',
        'egg', 'seafood',
      ],
      'Grains': [
        'cereal', 'rice', 'wheat', 'oat', 'grain', 'pasta', 'noodle',
        'quinoa', 'barley',
      ],
      'Nuts': [
        'almond', 'peanut', 'cashew', 'walnut', 'sunflower seed',
        'pumpkin seed',
      ],
      'Snacks': [
        'snack', 'chip', 'crisp', 'popcorn', 'pretzel', 'cracker',
        'fries', 'burger', 'pizza',
      ],
    };

    for (final entry in knownGroups.entries) {
      if (_containsAny(fullText, entry.value)) {
        return entry.key;
      }
    }
    return null;
  }
}
