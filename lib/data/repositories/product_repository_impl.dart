import 'package:openfoodfacts/openfoodfacts.dart';

import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/product.dart' as domain;
import '../../domain/repositories/product_repository.dart';
import '../datasources/local_cache.dart';

class ProductRepositoryImpl implements ProductRepository {
  final LocalCache _localCache;

  ProductRepositoryImpl({required LocalCache localCache})
    : _localCache = localCache;

  static const _cacheDuration = Duration(minutes: 30);

  @override
  Future<Result<domain.Product>> getProductByBarcode(String barcode) async {
    if (barcode.length < 8 || barcode.length > 14) {
      return const Result.failure(
        ValidationFailure(message: 'Invalid barcode length'),
      );
    }

    final cacheKey = 'product_$barcode';
    try {
      final cached = _localCache.get<domain.Product>(cacheKey);
      if (cached != null) {
        return Result.success(cached);
      }

      final configuration = ProductQueryConfiguration(
        barcode,
        language: OpenFoodFactsLanguage.ENGLISH,
        version: ProductQueryVersion.v3,
        fields: [
          ProductField.BARCODE,
          ProductField.NAME,
          ProductField.BRANDS,
          ProductField.CATEGORIES,
          ProductField.NUTRIMENTS,
          ProductField.NUTRISCORE,
          ProductField.NOVA_GROUP,
          ProductField.INGREDIENTS_TEXT,
          ProductField.ALLERGENS,
          ProductField.LABELS,
          ProductField.IMAGES,
        ],
      );

      final result = await OpenFoodAPIClient.getProductV3(configuration);

      if (result.status == ProductResultV3.statusSuccess &&
          result.product != null) {
        final product = _convertToAppProduct(result.product!);
        _localCache.set(cacheKey, product, ttl: _cacheDuration);
        return Result.success(product);
      }

      return Result.failure(
        NotFoundFailure(message: 'Product not found for barcode: $barcode'),
      );
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(message: e.message));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<domain.Product>>> searchProducts(
    String query, {
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final configuration = ProductSearchQueryConfiguration(
        parametersList: [
          SearchTerms(terms: [query]),
          PageSize(size: pageSize),
        ],
        version: ProductQueryVersion.v3,
        language: OpenFoodFactsLanguage.ENGLISH,
        fields: [
          ProductField.BARCODE,
          ProductField.NAME,
          ProductField.BRANDS,
          ProductField.NUTRIMENTS,
          ProductField.NUTRISCORE,
          ProductField.IMAGES,
        ],
      );

      final result = await OpenFoodAPIClient.searchProducts(
        null,
        configuration,
      );

      if (result.products != null) {
        final products = result.products!
            .map((product) => _convertToAppProduct(product))
            .toList();
        return Result.success(products);
      }
      return const Result.success([]);
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(message: e.message));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  domain.Product _convertToAppProduct(Product offProduct) {
    return domain.Product(
      id: offProduct.barcode ?? '',
      barcode: offProduct.barcode,
      name: offProduct.productName ?? 'Unknown Product',
      brands: offProduct.brands,
      categories: offProduct.categories,
      categoriesTags: offProduct.categoriesTags ?? [],
      imageFrontUrl: offProduct.imageFrontUrl,
      imageFrontSmallUrl: offProduct.imageFrontSmallUrl,
      imageNutritionUrl: offProduct.imageNutritionUrl,
      imageIngredientsUrl: offProduct.imageIngredientsUrl,
      nutriments: offProduct.nutriments != null
          ? _convertNutriments(offProduct.nutriments!)
          : null,
      nutriscoreGrade: offProduct.nutriscore?.toUpperCase(),
      novaGroup: offProduct.novaGroup,
      ecoscoreGrade: offProduct.ecoscoreGrade?.toUpperCase(),
      ingredientsText: offProduct.ingredientsText,
      allergens: (offProduct.allergens as List<dynamic>?)?.cast<String>() ?? [],
      additives: (offProduct.additives as List<dynamic>?)?.cast<String>() ?? [],
      labels: offProduct.labelsTags ?? [],
      quantity: offProduct.quantity,
      servingSize: offProduct.servingSize,
      packaging: offProduct.packaging,
      stores: offProduct.stores,
      countries: offProduct.countries,
      lastModified: offProduct.lastModified,
    );
  }

  domain.Nutriments _convertNutriments(Nutriments offNutriments) {
    return domain.Nutriments(
      energyKcal100g: offNutriments
          .getValue(Nutrient.energyKCal, PerSize.oneHundredGrams)
          ?.toDouble(),
      energyKcalServing: offNutriments
          .getValue(Nutrient.energyKCal, PerSize.serving)
          ?.toDouble(),
      proteins100g: offNutriments
          .getValue(Nutrient.proteins, PerSize.oneHundredGrams)
          ?.toDouble(),
      proteinsServing: offNutriments
          .getValue(Nutrient.proteins, PerSize.serving)
          ?.toDouble(),
      carbohydrates100g: offNutriments
          .getValue(Nutrient.carbohydrates, PerSize.oneHundredGrams)
          ?.toDouble(),
      carbohydratesServing: offNutriments
          .getValue(Nutrient.carbohydrates, PerSize.serving)
          ?.toDouble(),
      sugars100g: offNutriments
          .getValue(Nutrient.sugars, PerSize.oneHundredGrams)
          ?.toDouble(),
      sugarsServing: offNutriments
          .getValue(Nutrient.sugars, PerSize.serving)
          ?.toDouble(),
      fat100g: offNutriments
          .getValue(Nutrient.fat, PerSize.oneHundredGrams)
          ?.toDouble(),
      fatServing: offNutriments
          .getValue(Nutrient.fat, PerSize.serving)
          ?.toDouble(),
      saturatedFat100g: offNutriments
          .getValue(Nutrient.saturatedFat, PerSize.oneHundredGrams)
          ?.toDouble(),
      saturatedFatServing: offNutriments
          .getValue(Nutrient.saturatedFat, PerSize.serving)
          ?.toDouble(),
      fiber100g: offNutriments
          .getValue(Nutrient.fiber, PerSize.oneHundredGrams)
          ?.toDouble(),
      fiberServing: offNutriments
          .getValue(Nutrient.fiber, PerSize.serving)
          ?.toDouble(),
      salt100g: offNutriments
          .getValue(Nutrient.salt, PerSize.oneHundredGrams)
          ?.toDouble(),
      saltServing: offNutriments
          .getValue(Nutrient.salt, PerSize.serving)
          ?.toDouble(),
      sodium100g: offNutriments
          .getValue(Nutrient.sodium, PerSize.oneHundredGrams)
          ?.toDouble(),
      sodiumServing: offNutriments
          .getValue(Nutrient.sodium, PerSize.serving)
          ?.toDouble(),
    );
  }
}
